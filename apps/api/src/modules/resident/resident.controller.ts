import { Body, Controller, Get, Patch } from "@nestjs/common";
import {
  residentSettingsSchema,
  updateHouseholdSchema,
  type AccessClaims,
} from "@namma-kasa/shared";
import { ZodValidationPipe } from "../../common/pipes/zod-validation.pipe";
import { CurrentUser, Roles } from "../auth/decorators";
import { ResidentService } from "./resident.service";

@Controller("resident")
@Roles("resident")
export class ResidentController {
  constructor(private readonly resident: ResidentService) {}

  @Get("home")
  home(@CurrentUser() user: AccessClaims) {
    return this.resident.home(user.sub);
  }

  /** Moving the pin re-runs ward and route derivation (FR-RES-04). */
  @Patch("household")
  updateHousehold(
    @Body(new ZodValidationPipe(updateHouseholdSchema)) body: never,
    @CurrentUser() user: AccessClaims,
  ) {
    return this.resident.updateHousehold(user.sub, body);
  }

  @Patch("settings")
  updateSettings(
    @Body(new ZodValidationPipe(residentSettingsSchema)) body: never,
    @CurrentUser() user: AccessClaims,
  ) {
    return this.resident.updateSettings(user.sub, body);
  }
}
