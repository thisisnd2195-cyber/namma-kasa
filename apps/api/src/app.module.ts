import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { LoggerModule } from "nestjs-pino";
import { validateEnv } from "./config/config.schema";
import { DbModule } from "./db/db.module";

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate: validateEnv,
    }),
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
  ],
})
export class AppModule {}
