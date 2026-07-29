import { Module, OnModuleInit } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { Body, Controller, HttpCode, HttpStatus, Post } from "@nestjs/common";
import { z } from "zod";
import type { AccessClaims, WasteType } from "@namma-kasa/shared";
import { ZodValidationPipe } from "../../common/pipes/zod-validation.pipe";
import { CurrentUser } from "../auth/decorators";
import { IngestService } from "../tracking/ingest.service";
import { TrackingModule } from "../tracking/tracking.module";
import { weekdayIST, serviceDateIST } from "../tracking/trips.service";
import { DB, type Db } from "../../db/db.module";
import { Inject } from "@nestjs/common";
import { GeofenceService, proximityDedupKey } from "./geofence.service";
import { NotifyService } from "./notify.service";
import { ConsolePushSender, FcmPushSender, PUSH_SENDER } from "./push-sender";

const registerDeviceSchema = z.object({ fcmToken: z.string().min(10) });

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

@Module({
  imports: [TrackingModule],
  controllers: [NotifyController],
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
