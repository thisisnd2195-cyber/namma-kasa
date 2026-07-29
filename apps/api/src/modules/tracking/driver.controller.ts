import { Body, Controller, Get, HttpCode, HttpStatus, Param, Patch, Post } from "@nestjs/common";
import {
  endTripSchema,
  pingBatchSchema,
  startTripSchema,
  type AccessClaims,
} from "@namma-kasa/shared";
import { ZodValidationPipe } from "../../common/pipes/zod-validation.pipe";
import { Throttle } from "../../common/rate-limit/rate-limit.guard";
import { CurrentUser, Roles } from "../auth/decorators";
import { IngestService } from "./ingest.service";
import { TripsService } from "./trips.service";

@Controller("driver")
@Roles("driver")
export class DriverController {
  constructor(
    private readonly trips: TripsService,
    private readonly ingest: IngestService,
  ) {}

  @Get("assignment")
  assignment(@CurrentUser() user: AccessClaims) {
    return this.trips.assignmentFor(user.sub);
  }

  @Post("trips")
  startTrip(
    @Body(new ZodValidationPipe(startTripSchema)) body: { passNumber: number },
    @CurrentUser() user: AccessClaims,
  ) {
    return this.trips.start(user.sub, body.passNumber);
  }

  @Patch("trips/:id/end")
  async endTrip(
    @Param("id") tripId: string,
    @Body(new ZodValidationPipe(endTripSchema))
    body: { reason?: "driver" | "auto_idle" | "admin"; distanceCoveredM?: number },
    @CurrentUser() user: AccessClaims,
  ) {
    await this.trips.requireOwnedTrip(tripId, user.sub);
    const context = await this.ingest.contextFor(tripId);
    const trip = await this.trips.end(tripId, body.reason ?? "driver", body.distanceCoveredM);
    if (context) await this.ingest.clearLiveState(context);
    return trip;
  }

  /**
   * HTTPS fallback for when MQTT is unreachable. Generous limit: a device
   * coming back from a dead zone replays its whole spool through here.
   */
  @Post("trips/:id/pings")
  @HttpCode(HttpStatus.ACCEPTED)
  @Throttle({ limit: 240, windowSec: 60 })
  async pings(
    @Param("id") tripId: string,
    @Body(new ZodValidationPipe(pingBatchSchema)) body: { pings: never[] },
    @CurrentUser() user: AccessClaims,
  ) {
    await this.trips.requireOwnedTrip(tripId, user.sub);
    const context = await this.ingest.contextFor(tripId);
    if (!context) return { accepted: 0, rejected: body.pings.length };
    return this.ingest.ingest(context, body.pings);
  }
}
