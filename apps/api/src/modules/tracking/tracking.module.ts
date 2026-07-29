import { Module } from "@nestjs/common";
import { AuthModule } from "../auth/auth.module";
import { DriverController } from "./driver.controller";
import { IngestService } from "./ingest.service";
import { LiveController } from "./live.controller";
import { LiveGateway } from "./live.gateway";
import { MqttConsumer } from "./mqtt.consumer";
import { TripsService } from "./trips.service";
import { WatchdogService } from "./watchdog.service";

@Module({
  imports: [AuthModule],
  controllers: [DriverController, LiveController],
  providers: [TripsService, IngestService, WatchdogService, MqttConsumer, LiveGateway],
  exports: [TripsService, IngestService, WatchdogService, LiveGateway],
})
export class TrackingModule {}
