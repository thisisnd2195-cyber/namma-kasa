import { Module } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { GeoModule } from "../geo/geo.module";
import { AuthController } from "./auth.controller";
import { AuthService } from "./auth.service";
import { TokensService } from "./tokens.service";
import { OtpService } from "./otp/otp.service";
import { ConsoleOtpSender, Msg91OtpSender, OTP_SENDER } from "./otp/otp-sender";
import { AuthGuard } from "./guards/auth.guard";
import { WardScopeGuard } from "./guards/ward-scope.guard";

@Module({
  imports: [GeoModule],
  controllers: [AuthController],
  providers: [
    AuthService,
    TokensService,
    OtpService,
    AuthGuard,
    WardScopeGuard,
    {
      provide: OTP_SENDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        config.get<string>("OTP_SENDER") === "msg91"
          ? new Msg91OtpSender(config)
          : new ConsoleOtpSender(),
    },
  ],
  exports: [TokensService, AuthGuard, WardScopeGuard],
})
export class AuthModule {}
