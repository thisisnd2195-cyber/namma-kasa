import { Module, OnModuleInit } from "@nestjs/common";
import { GeoModule } from "../geo/geo.module";
import { TrackingModule } from "../tracking/tracking.module";
import { IngestService } from "../tracking/ingest.service";
import { LiveGateway } from "../tracking/live.gateway";
import { ResidentController } from "./resident.controller";
import { ComplianceModule } from "../compliance/compliance.module";
import { ResidentService } from "./resident.service";

@Module({
  imports: [ComplianceModule, GeoModule, TrackingModule],
  controllers: [ResidentController],
  providers: [ResidentService],
  exports: [ResidentService],
})
export class ResidentModule implements OnModuleInit {
  constructor(
    private readonly ingest: IngestService,
    private readonly resident: ResidentService,
    private readonly live: LiveGateway,
  ) {}

  /**
   * Every accepted position does two resident-facing things: it may prove a
   * house was served, and it moves the marker on anyone watching that route.
   */
  onModuleInit(): void {
    this.ingest.onPosition(async (context, position) => {
      await this.resident.recordCollectionsNear(
        context.tripId,
        context.routeId,
        context.passNumber,
        position,
      );

      this.live.broadcastPosition(context.routeId, {
        type: "position",
        tripId: context.tripId,
        registrationNumber: context.registrationNumber,
        passNumber: context.passNumber,
        lat: position.lat,
        lng: position.lng,
        heading: position.heading,
        at: position.at,
      });
    });
  }
}
