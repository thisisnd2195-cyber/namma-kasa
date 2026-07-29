import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Module,
  Param,
  Patch,
  Post,
  UseGuards,
} from "@nestjs/common";
import { driverIssueSchema, type AccessClaims, type DriverIssue } from "@namma-kasa/shared";
import { ZodValidationPipe } from "../../common/pipes/zod-validation.pipe";
import { AuthModule } from "../auth/auth.module";
import { CurrentUser, Roles } from "../auth/decorators";
import { WardScopeGuard } from "../auth/guards/ward-scope.guard";
import { NotifyModule } from "../notify/notify.module";
import { IssuesService } from "./issues.service";

@Controller("driver/issues")
@Roles("driver")
export class DriverIssuesController {
  constructor(private readonly issues: IssuesService) {}

  /**
   * One tap, and no trip required: a breakdown can happen before the driver has
   * started, which is exactly when the Ward Admin most needs to know.
   */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  report(
    @Body(new ZodValidationPipe(driverIssueSchema)) body: DriverIssue,
    @CurrentUser() user: AccessClaims,
  ) {
    return this.issues.report(user.sub, body);
  }
}

@Controller("admin/driver-issues")
@Roles("super_admin", "ward_admin")
@UseGuards(WardScopeGuard)
export class AdminIssuesController {
  constructor(private readonly issues: IssuesService) {}

  @Get("wards/:wardId")
  list(@Param("wardId") wardId: string) {
    return this.issues.listForWard(wardId);
  }

  @Patch(":id/acknowledge")
  acknowledge(@Param("id") id: string, @CurrentUser() user: AccessClaims) {
    // A Super Admin has no ward of their own, and may close any ward's issue.
    return this.issues.acknowledge(id, user.role === "ward_admin" ? (user.wardId ?? null) : null);
  }
}

/**
 * Driver-reported problems (FR-DRV-07). Separate from TrackingModule because
 * it needs NotifyService, and NotifyModule already imports TrackingModule —
 * putting it there would close a cycle.
 */
@Module({
  imports: [AuthModule, NotifyModule],
  controllers: [DriverIssuesController, AdminIssuesController],
  providers: [IssuesService],
  exports: [IssuesService],
})
export class IssuesModule {}
