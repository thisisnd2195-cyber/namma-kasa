import { Controller, Delete, Get, HttpCode, HttpStatus, Module } from "@nestjs/common";
import type { AccessClaims } from "@namma-kasa/shared";
import { CurrentUser, Public } from "../auth/decorators";
import { ComplianceService } from "./compliance.service";
import { DashboardsController } from "./dashboards.controller";
import { RollupsService } from "./rollups.service";
import { MetricsService } from "./metrics.service";

@Controller()
export class ComplianceController {
  constructor(
    private readonly compliance: ComplianceService,
    private readonly metrics: MetricsService,
  ) {}

  /** DPDP requires a self-service path, not an email to support (NFR-04). */
  @Delete("me")
  @HttpCode(HttpStatus.ACCEPTED)
  async deleteAccount(@CurrentUser() user: AccessClaims) {
    const { erasesAfter } = await this.compliance.requestDeletion(user.sub);
    return {
      erasesAfter,
      note:
        "Your personal details will be erased. Collection records stay in the ward's " +
        "history without your name attached.",
    };
  }

  @Get("me/retention-policy")
  retentionPolicy() {
    return this.compliance.retentionPolicy;
  }

  /** Prometheus scrape target (NFR-09). Public: it carries no personal data. */
  @Get("metrics")
  @Public()
  @HttpCode(HttpStatus.OK)
  async metricsEndpoint(): Promise<string> {
    return this.metrics.render();
  }
}

@Module({
  controllers: [DashboardsController, ComplianceController],
  providers: [RollupsService, ComplianceService, MetricsService],
  exports: [ComplianceService, MetricsService, RollupsService],
})
export class ComplianceModule {}
