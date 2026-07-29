import { Body, Controller, HttpCode, HttpStatus, Post } from "@nestjs/common";
import {
  loginRequestSchema,
  otpSendRequestSchema,
  otpVerifyRequestSchema,
  refreshRequestSchema,
  registerRequestSchema,
} from "@namma-kasa/shared";
import { ZodValidationPipe } from "../../common/pipes/zod-validation.pipe";
import { Public } from "./decorators";
import { AuthService } from "./auth.service";

@Controller("auth")
@Public()
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post("otp/send")
  @HttpCode(HttpStatus.ACCEPTED)
  sendOtp(@Body(new ZodValidationPipe(otpSendRequestSchema)) body: { phone: string }) {
    return this.auth.sendOtp(body.phone);
  }

  @Post("otp/verify")
  @HttpCode(HttpStatus.OK)
  verifyOtp(
    @Body(new ZodValidationPipe(otpVerifyRequestSchema)) body: { phone: string; code: string },
  ) {
    return this.auth.verifyOtp(body.phone, body.code);
  }

  @Post("register")
  register(
    @Body(new ZodValidationPipe(registerRequestSchema))
    body: Parameters<AuthService["register"]>[0],
  ) {
    return this.auth.register(body);
  }

  @Post("login")
  @HttpCode(HttpStatus.OK)
  login(
    @Body(new ZodValidationPipe(loginRequestSchema)) body: Parameters<AuthService["login"]>[0],
  ) {
    return this.auth.login(body);
  }

  @Post("refresh")
  @HttpCode(HttpStatus.OK)
  refresh(@Body(new ZodValidationPipe(refreshRequestSchema)) body: { refreshToken: string }) {
    return this.auth.refresh(body.refreshToken);
  }
}
