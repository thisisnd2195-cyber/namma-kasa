import { Body, Controller, Get, HttpCode, HttpStatus, Param, Patch, Post, Query, UseGuards } from "@nestjs/common";
import {
  assignAutoToDriverSchema,
  assignRouteToAutoSchema,
  createAutoSchema,
  createDriverSchema,
  updateAutoSchema,
  updateDriverSchema,
  type AccessClaims,
} from "@namma-kasa/shared";
import { HttpException } from "@nestjs/common";
import { ZodValidationPipe } from "../../common/pipes/zod-validation.pipe";
import { CurrentUser, Roles } from "../auth/decorators";
import { WardScopeGuard } from "../auth/guards/ward-scope.guard";
import { FleetService } from "./fleet.service";

@Controller("admin")
@Roles("super_admin", "ward_admin")
@UseGuards(WardScopeGuard)
export class FleetController {
  constructor(private readonly fleet: FleetService) {}

  /** A ward admin is pinned to their own ward; a super admin must name one. */
  private wardOf(user: AccessClaims, wardId?: string): string {
    const resolved = user.role === "ward_admin" ? user.wardId : (wardId ?? user.wardId);
    if (!resolved) {
      throw new HttpException("wardId query parameter is required", HttpStatus.BAD_REQUEST);
    }
    return resolved;
  }

  // ------------------------------------------------------------------- autos

  @Get("autos")
  listAutos(
    @CurrentUser() user: AccessClaims,
    @Query("wardId") wardId?: string,
    @Query("available") available?: string,
  ) {
    return this.fleet.listAutos(this.wardOf(user, wardId), available === "true");
  }

  @Post("autos")
  createAuto(
    @Body(new ZodValidationPipe(createAutoSchema)) body: never,
    @CurrentUser() user: AccessClaims,
  ) {
    return this.fleet.createAuto(body, user.sub);
  }

  @Patch("autos/:id")
  updateAuto(@Param("id") id: string, @Body(new ZodValidationPipe(updateAutoSchema)) body: never) {
    return this.fleet.updateAuto(id, body);
  }

  @Post("autos/:id/assign-route")
  @HttpCode(HttpStatus.NO_CONTENT)
  async assignRoute(
    @Param("id") autoId: string,
    @Body(new ZodValidationPipe(assignRouteToAutoSchema))
    body: { routeId: string; effectiveFrom?: Date },
    @CurrentUser() user: AccessClaims,
  ): Promise<void> {
    await this.fleet.assignAutoToRoute(autoId, body.routeId, user.sub, body.effectiveFrom);
  }

  @Get("autos/:id/assignments")
  assignments(@Param("id") autoId: string) {
    return this.fleet.assignmentHistory(autoId);
  }

  // ----------------------------------------------------------------- drivers

  @Get("drivers")
  listDrivers(@CurrentUser() user: AccessClaims, @Query("wardId") wardId?: string) {
    return this.fleet.listDrivers(this.wardOf(user, wardId));
  }

  @Post("drivers")
  createDriver(@Body(new ZodValidationPipe(createDriverSchema)) body: never) {
    return this.fleet.createDriver(body);
  }

  @Patch("drivers/:id")
  updateDriver(
    @Param("id") id: string,
    @Body(new ZodValidationPipe(updateDriverSchema)) body: never,
  ) {
    return this.fleet.updateDriver(id, body);
  }

  @Post("drivers/:id/assign-auto")
  @HttpCode(HttpStatus.NO_CONTENT)
  async assignAuto(
    @Param("id") driverId: string,
    @Body(new ZodValidationPipe(assignAutoToDriverSchema))
    body: { autoId: string; effectiveFrom?: Date },
    @CurrentUser() user: AccessClaims,
  ): Promise<void> {
    await this.fleet.assignDriverToAuto(driverId, body.autoId, user.sub, body.effectiveFrom);
  }
}
