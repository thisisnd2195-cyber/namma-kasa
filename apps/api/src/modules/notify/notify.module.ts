import { Module, OnModuleInit } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import {
  Body,
  Controller,
  ForbiddenException,
  HttpCode,
  HttpStatus,
  NotFoundException,
  Post,
} from "@nestjs/common";
import { z } from "zod";
import type { AccessClaims, WasteType } from "@namma-kasa/shared";
import { ZodValidationPipe } from "../../common/pipes/zod-validation.pipe";
import { CurrentUser, Roles } from "../auth/decorators";
import { scheduleChangeCopy } from "./templates";
import { IngestService } from "../tracking/ingest.service";
import { TrackingModule } from "../tracking/tracking.module";
import { weekdayIST, serviceDateIST } from "../tracking/trips.service";
import { DB, type Db } from "../../db/db.module";
import { Inject } from "@nestjs/common";
import { GeofenceService, proximityDedupKey } from "./geofence.service";
import { NotifyService } from "./notify.service";
import { ConsolePushSender, FcmPushSender, PUSH_SENDER } from "./push-sender";

const registerDeviceSchema = z.object({ fcmToken: z.string().min(10) });

const advisorySchema = z.object({
  routeId: z.string().uuid(),
  note: z.string().trim().min(1).max(200),
});

@Controller("notifications")
export class NotifyController {
  constructor(private readonly notify: NotifyService) {}

  @Post("devices")
  @HttpCode(HttpStatus.NO_CONTENT)
  async register(
    @Body(new ZodValidationPipe(registerDeviceSchema)) body: { fcmToken: string },
    @CurrentUser() user: AccessClaims,
  ): Promise<void> {
    await this.notify.registerDevice(user.sub, body.fcmToken);
  }
}

/**
 * Ward-wide advisories: a holiday, a road closure, a truck breakdown. Without
 * this the only way a resident learns collection is not coming is by waiting
 * for it (FR-NOTIF-04, Clarifications CHK041).
 */
@Controller("admin/advisories")
@Roles("super_admin", "ward_admin")
export class AdvisoryController {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly notify: NotifyService,
  ) {}

  @Post()
  @HttpCode(HttpStatus.ACCEPTED)
  async broadcast(
    @Body(new ZodValidationPipe(advisorySchema)) body: { routeId: string; note: string },
    @CurrentUser() user: AccessClaims,
  ) {
    const route = await this.db
      .selectFrom("routes")
      .select(["id", "ward_id"])
      .where("id", "=", body.routeId)
      .executeTakeFirst();
    if (!route) throw new NotFoundException("Route not found");
    if (user.role === "ward_admin" && route.ward_id !== user.wardId) {
      throw new ForbiddenException("Outside your ward");
    }

    const residents = await this.db
      .selectFrom("households as h")
      .innerJoin("users as u", "u.id", "h.user_id")
      .select(["u.id as userId", "u.locale"])
      .where("h.route_id", "=", body.routeId)
      .where("u.status", "=", "active")
      .execute();

    for (const resident of residents) {
      await this.notify.queue({
        userId: resident.userId,
        kind: "schedule_change",
        copy: scheduleChangeCopy(resident.locale, body.note),
        data: { kind: "schedule_change", routeId: body.routeId },
      });
    }

    return { notified: residents.length };
  }
}

@Module({
  imports: [TrackingModule],
  controllers: [NotifyController, AdvisoryController],
  providers: [
    GeofenceService,
    NotifyService,
    {
      provide: PUSH_SENDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        config.get<string>("PUSH_SENDER") === "fcm"
          ? new FcmPushSender(config)
          : new ConsolePushSender(),
    },
  ],
  exports: [NotifyService, GeofenceService],
})
export class NotifyModule implements OnModuleInit {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly ingest: IngestService,
    private readonly geofence: GeofenceService,
    private readonly notify: NotifyService,
  ) {}

  /**
   * The alert that makes the product work: as the auto moves, any household
   * whose radius it enters gets told once for this pass.
   */
  onModuleInit(): void {
    this.ingest.onPosition(async (context, position) => {
      const hits = await this.geofence.hitsFor(
        context.routeId,
        context.passNumber,
        position,
      );
      if (hits.length === 0) return;

      const wasteTypes = await this.todayWasteTypes(context.routeId);
      const serviceDate = serviceDateIST();

      for (const hit of hits) {
        await this.notify.queueProximity({
          userId: hit.userId,
          locale: hit.locale,
          distanceM: hit.distanceM,
          wasteTypes,
          routeId: context.routeId,
          tripId: context.tripId,
          dedupKey: proximityDedupKey(
            hit.householdId,
            context.routeId,
            serviceDate,
            context.passNumber,
          ),
        });
      }
    });
  }

  private async todayWasteTypes(routeId: string): Promise<WasteType[]> {
    const route = await this.db
      .selectFrom("routes")
      .select("waste_type_schedule")
      .where("id", "=", routeId)
      .executeTakeFirst();
    const schedule = (route?.waste_type_schedule ?? {}) as Record<string, WasteType[]>;
    return schedule[String(weekdayIST())] ?? [];
  }
}
