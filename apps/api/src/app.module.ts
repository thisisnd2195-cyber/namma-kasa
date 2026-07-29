import { Module } from "@nestjs/common";
import { APP_GUARD, APP_INTERCEPTOR } from "@nestjs/core";
import { ConfigModule } from "@nestjs/config";
import { LoggerModule } from "nestjs-pino";
import { validateEnv } from "./config/config.schema";
import { DbModule } from "./db/db.module";
import { RedisModule } from "./redis/redis.module";
import { AuthModule } from "./modules/auth/auth.module";
import { GeoModule } from "./modules/geo/geo.module";
import { FleetModule } from "./modules/fleet/fleet.module";
import { TrackingModule } from "./modules/tracking/tracking.module";
import { ResidentModule } from "./modules/resident/resident.module";
import { IssuesModule } from "./modules/issues/issues.module";
import { NotifyModule } from "./modules/notify/notify.module";
import { ComplaintsModule } from "./modules/complaints/complaints.module";
import { ComplianceModule } from "./modules/compliance/compliance.module";
import { AuthGuard } from "./modules/auth/guards/auth.guard";
import { RateLimitGuard } from "./common/rate-limit/rate-limit.guard";
import { AuditInterceptor } from "./common/interceptors/audit.interceptor";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),
    LoggerModule.forRoot({
      pinoHttp: {
        transport:
          process.env.NODE_ENV === "production"
            ? undefined
            : { target: "pino-pretty", options: { singleLine: true } },
        // Phone numbers and tokens must never reach the log stream (NFR-05).
        redact: ["req.headers.authorization", "req.body.phone", "req.body.password"],
      },
    }),
    DbModule,
    RedisModule,
    AuthModule,
    GeoModule,
    FleetModule,
    TrackingModule,
    ResidentModule,
    NotifyModule,
    IssuesModule,
    ComplaintsModule,
    ComplianceModule,
  ],
  providers: [
    // Deny by default: every route needs a token unless marked @Public.
    { provide: APP_GUARD, useClass: AuthGuard },
    { provide: APP_GUARD, useClass: RateLimitGuard },
    { provide: APP_INTERCEPTOR, useClass: AuditInterceptor },
  ],
})
export class AppModule {}
