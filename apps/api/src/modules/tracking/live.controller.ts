import { Controller, Get, Param, UseGuards } from "@nestjs/common";
import type { AccessClaims } from "@namma-kasa/shared";
import { CurrentUser, Roles } from "../auth/decorators";
import { WardScopeGuard } from "../auth/guards/ward-scope.guard";
import { IngestService } from "./ingest.service";
import { WatchdogService } from "./watchdog.service";

@Controller("admin/live")
@Roles("super_admin", "ward_admin")
@UseGuards(WardScopeGuard)
export class LiveController {
  constructor(
    private readonly ingest: IngestService,
    private readonly watchdog: WatchdogService,
  ) {}

  /** Ward dashboard: where every active auto is, and which have gone quiet. */
  @Get("wards/:wardId")
  async ward(@Param("wardId") wardId: string, @CurrentUser() _user: AccessClaims) {
    const [positions, alerts] = await Promise.all([
      this.ingest.livePositionsForWard(wardId),
      this.watchdog.trackingDropped(),
    ]);

    const wardAlerts = alerts.filter((alert) => alert.wardId === wardId);
    return {
      positions,
      alerts: wardAlerts.map((alert) => ({
        tripId: alert.tripId,
        registrationNumber: alert.registrationNumber,
        routeName: alert.routeName,
        silentForMin: Math.round(alert.silentForMs / 60_000),
      })),
    };
  }
}
