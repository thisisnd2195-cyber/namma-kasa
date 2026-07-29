import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from "@nestjs/common";
import {
  assignHouseholdRouteSchema,
  createOperatorSchema,
  createRouteSchema,
  recordRoutePathSchema,
  createWardAdminSchema,
  createWardSchema,
  geoJsonAreaSchema,
  importWardsSchema,
  updateOperatorSchema,
  updateRouteSchema,
  updateWardSchema,
} from "@namma-kasa/shared";
import { ZodValidationPipe } from "../../common/pipes/zod-validation.pipe";
import { CurrentUser, Roles, type AuthedRequest } from "../auth/decorators";
import { WardScopeGuard } from "../auth/guards/ward-scope.guard";
import type { AccessClaims } from "@namma-kasa/shared";
import { OperatorsService } from "./operators.service";
import { RoutesService } from "./routes.service";
import { WardsService } from "./wards.service";
import { HouseholdsService } from "./households.service";

@Controller("admin")
export class AdminGeoController {
  constructor(
    private readonly operators: OperatorsService,
    private readonly wards: WardsService,
    private readonly routes: RoutesService,
    private readonly households: HouseholdsService,
  ) {}

  // ---------------------------------------------------------- operators [super]

  @Get("operators")
  @Roles("super_admin")
  listOperators() {
    return this.operators.list();
  }

  @Post("operators")
  @Roles("super_admin")
  createOperator(@Body(new ZodValidationPipe(createOperatorSchema)) body: never) {
    return this.operators.create(body);
  }

  @Patch("operators/:id")
  @Roles("super_admin")
  updateOperator(
    @Param("id") id: string,
    @Body(new ZodValidationPipe(updateOperatorSchema)) body: never,
  ) {
    return this.operators.update(id, body);
  }

  // -------------------------------------------------------------- wards

  @Get("wards")
  @Roles("super_admin", "ward_admin")
  listWards(@CurrentUser() user: AccessClaims) {
    // A ward admin sees exactly one ward; a super admin sees the city.
    return this.wards.list(user.role === "ward_admin" ? (user.wardId ?? undefined) : undefined);
  }

  @Get("wards/:wardId")
  @Roles("super_admin", "ward_admin")
  @UseGuards(WardScopeGuard)
  getWard(@Param("wardId") wardId: string) {
    return this.wards.get(wardId);
  }

  @Post("wards")
  @Roles("super_admin")
  createWard(@Body(new ZodValidationPipe(createWardSchema)) body: never) {
    return this.wards.create(body);
  }

  @Patch("wards/:wardId")
  @Roles("super_admin")
  updateWard(
    @Param("wardId") wardId: string,
    @Body(new ZodValidationPipe(updateWardSchema)) body: never,
  ) {
    return this.wards.update(wardId, body);
  }

  /** Dry run: what a boundary change would strand, before committing to it. */
  @Post("wards/:wardId/edit-impact")
  @Roles("super_admin")
  editImpact(
    @Param("wardId") wardId: string,
    @Body(new ZodValidationPipe(geoJsonAreaSchema)) boundary: never,
  ) {
    return this.wards.editImpact(wardId, boundary);
  }

  @Post("wards/import")
  @Roles("super_admin")
  importWards(@Body(new ZodValidationPipe(importWardsSchema)) body: never) {
    return this.wards.import(body);
  }

  @Post("ward-admins")
  @Roles("super_admin")
  createWardAdmin(@Body(new ZodValidationPipe(createWardAdminSchema)) body: never) {
    return this.wards.createWardAdmin(body);
  }

  // ------------------------------------------------------------- routes [ward]

  @Get("routes")
  @Roles("super_admin", "ward_admin")
  @UseGuards(WardScopeGuard)
  listRoutes(@Query("wardId") wardId: string, @CurrentUser() user: AccessClaims) {
    return this.routes.listForWard(wardId || (user.wardId as string));
  }

  @Post("routes")
  @Roles("super_admin", "ward_admin")
  @UseGuards(WardScopeGuard)
  createRoute(@Body(new ZodValidationPipe(createRouteSchema)) body: never) {
    return this.routes.create(body);
  }

  @Patch("routes/:id")
  @Roles("super_admin", "ward_admin")
  updateRoute(@Param("id") id: string, @Body(new ZodValidationPipe(updateRouteSchema)) body: never) {
    return this.routes.update(id, body);
  }

  /** Trips whose trail this route could adopt (FR-ROUTE-04). */
  @Get("routes/:id/recordable-trips")
  @Roles("super_admin", "ward_admin")
  recordableTrips(@Param("id") id: string) {
    return this.routes.recordableTrips(id);
  }

  /** Adopt a driven trip's trail as this route's path (FR-ROUTE-04). */
  @Post("routes/:id/recorded-path")
  @Roles("super_admin", "ward_admin")
  recordRoutePath(
    @Param("id") id: string,
    @Body(new ZodValidationPipe(recordRoutePathSchema)) body: { tripId: string },
  ) {
    return this.routes.recordPathFromTrip(id, body.tripId);
  }

  // ------------------------------------------------------ household review queue

  @Get("households/review-queue")
  @Roles("super_admin", "ward_admin")
  reviewQueue(@CurrentUser() user: AccessClaims, @Query("wardId") wardId?: string) {
    return this.households.reviewQueue(
      user.role === "ward_admin" ? (user.wardId as string) : (wardId as string),
    );
  }

  @Patch("households/:id/route")
  @Roles("super_admin", "ward_admin")
  assignHouseholdRoute(
    @Param("id") id: string,
    @Body(new ZodValidationPipe(assignHouseholdRouteSchema)) body: { routeId: string },
    @CurrentUser() user: AccessClaims,
  ) {
    return this.households.assignRoute(id, body.routeId, user);
  }
}

export type { AuthedRequest };
