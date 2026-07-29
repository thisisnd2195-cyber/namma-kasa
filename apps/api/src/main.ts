import "reflect-metadata";
import { NestFactory } from "@nestjs/core";
import { Logger } from "nestjs-pino";
import { AppModule } from "./app.module";
import { ProblemFilter } from "./common/filters/problem.filter";
import { LiveGateway } from "./modules/tracking/live.gateway";

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  app.useLogger(app.get(Logger));
  app.useGlobalFilters(new ProblemFilter());
  app.setGlobalPrefix("v1");
  app.enableCors({ origin: true, credentials: true });

  const port = Number(process.env.PORT ?? 4000);
  await app.listen(port);

  // The resident live stream shares the HTTP listener via an upgrade handler.
  app.get(LiveGateway).attach(app.getHttpServer());
}

void bootstrap();
