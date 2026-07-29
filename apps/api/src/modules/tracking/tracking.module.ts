import { Module } from "@nestjs/common";
import { DriverController } from "./driver.controller";
import { IngestService } from "./ingest.service";
import { LiveController } from "./live.controller";
import { MqttConsumer } from "./mqtt.consumer";
import { TripsService } from "./trips.service";
import { WatchdogService } from "./watchdog.service";

@Module({
  controllers: [DriverController, LiveController],
  providers: [TripsService, IngestService, WatchdogService, MqttConsumer],
  exports: [TripsService, IngestService, WatchdogService],
})
export class TrackingModule {}
