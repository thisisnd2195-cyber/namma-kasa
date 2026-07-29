import { Body, Controller, Get, Module, Param, Patch, Post, Query, UseGuards } from "@nestjs/common";
import {
  complaintStatusSchema,
  createComplaintSchema,
  createRatingSchema,
  updateComplaintSchema,
  type AccessClaims,
  type ComplaintStatus,
} from "@namma-kasa/shared";
import { ZodValidationPipe } from "../../common/pipes/zod-validation.pipe";
import { Throttle } from "../../common/rate-limit/rate-limit.guard";
import { CurrentUser, Roles } from "../auth/decorators";
import { WardScopeGuard } from "../auth/guards/ward-scope.guard";
import { NotifyModule } from "../notify/notify.module";
import { ComplaintsService } from "./complaints.service";

@Controller("resident")
@Roles("resident")
export class ResidentComplaintsController {
  constructor(private readonly complaints: ComplaintsService) {}

  @Post("complaints")
  // Spam here costs a Ward Admin their queue, so the cap is deliberately tight.
  @Throttle({ limit: 10, windowSec: 3600 })
  create(
    @Body(new ZodValidationPipe(createComplaintSchema)) body: never,
    @CurrentUser() user: AccessClaims,
  ) {
    return this.complaints.create(user.sub, body);
  }

  @Get("complaints")
  list(@CurrentUser() user: AccessClaims) {
    return this.complaints.listForResident(user.sub);
  }

  @Post("ratings")
  rate(
    @Body(new ZodValidationPipe(createRatingSchema)) body: never,
    @CurrentUser() user: AccessClaims,
  ) {
    return this.complaints.rate(user.sub, body);
  }
}

@Controller("admin/complaints")
@Roles("super_admin", "ward_admin")
@UseGuards(WardScopeGuard)
export class AdminComplaintsController {
  constructor(private readonly complaints: ComplaintsService) {}

  @Get()
  list(
    @CurrentUser() user: AccessClaims,
    @Query("wardId") wardId?: string,
    @Query("status") status?: string,
  ) {
    const ward = user.role === "ward_admin" ? (user.wardId as string) : (wardId as string);
    const parsed = status ? complaintStatusSchema.parse(status) : undefined;
    return this.complaints.listForWard(ward, parsed as ComplaintStatus | undefined);
  }

  @Patch(":id")
  update(
    @Param("id") id: string,
    @Body(new ZodValidationPipe(updateComplaintSchema)) body: never,
    @CurrentUser() user: AccessClaims,
  ) {
    return this.complaints.updateStatus(id, body, user);
  }
}

@Module({
  imports: [NotifyModule],
  controllers: [ResidentComplaintsController, AdminComplaintsController],
  providers: [ComplaintsService],
  exports: [ComplaintsService],
})
export class ComplaintsModule {}
