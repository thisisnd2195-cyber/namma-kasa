import { Controller, Get, Query, UseGuards } from "@nestjs/common";
import type { AccessClaims } from "@namma-kasa/shared";
import { CurrentUser, Roles } from "../auth/decorators";
import { WardScopeGuard } from "../auth/guards/ward-scope.guard";
import { RollupsService } from "./rollups.service";

/**
 * The Super Admin's city view (FR-DASH-02) and the missed-pickup sweep
 * (FR-DASH-03). Read-only: nothing here changes state.
 */
@Controller("admin/dashboard")
export class DashboardsController {
  constructor(private readonly rollups: RollupsService) {}

  /** City rollups are a Super Admin's job; a Ward Admin sees their own ward. */
  @Get("city")
  @Roles("super_admin")
  city() {
    return this.rollups.city();
  }

  @Get("missed-pickups")
  @Roles("super_admin", "ward_admin")
  @UseGuards(WardScopeGuard)
  missed(@Query("wardId") wardId: string, @CurrentUser() user: AccessClaims) {
    // A Ward Admin is pinned to their own ward whatever the query says; the
    // scope guard has already rejected anything else.
    const scope = user.role === "ward_admin" ? (user.wardId ?? undefined) : wardId || undefined;
    return this.rollups.missedPickups(scope);
  }
}
