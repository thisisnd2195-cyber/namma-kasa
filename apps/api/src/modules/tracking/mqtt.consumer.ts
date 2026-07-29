import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import mqtt, { type MqttClient } from "mqtt";
import { pingSchema } from "@namma-kasa/shared";
import { IngestService } from "./ingest.service";

const TOPIC = "trips/+/pings";

/**
 * Driver devices publish over MQTT because it survives the 2G/3G pockets a
 * collection round passes through: QoS 1, tiny payloads, and an offline queue
 * that replays on reconnect. The HTTPS endpoint is the fallback path.
 */
@Injectable()
export class MqttConsumer implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(MqttConsumer.name);
  private client?: MqttClient;

  constructor(
    private readonly config: ConfigService,
    private readonly ingest: IngestService,
  ) {}

  onModuleInit(): void {
    const url = this.config.get<string>("MQTT_URL");
    if (!url) {
      this.logger.warn("MQTT_URL not set; driver ingest will only accept HTTPS batches");
      return;
    }

    this.client = mqtt.connect(url, {
      clientId: `namma-kasa-ingest-${process.pid}`,
      username: this.config.get<string>("MQTT_USERNAME"),
      password: this.config.get<string>("MQTT_PASSWORD"),
      reconnectPeriod: 5_000,
    });

    this.client.on("connect", () => {
      this.client?.subscribe(TOPIC, { qos: 1 }, (error) => {
        if (error) this.logger.error(`Failed to subscribe to ${TOPIC}: ${error.message}`);
        else this.logger.log(`Ingesting driver pings from ${TOPIC}`);
      });
    });

    this.client.on("error", (error) => this.logger.error(`MQTT error: ${error.message}`));
    this.client.on("message", (topic, payload) => {
      void this.handle(topic, payload).catch((error: unknown) =>
        this.logger.error(`Ping ingest failed: ${String(error)}`),
      );
    });
  }

  private async handle(topic: string, payload: Buffer): Promise<void> {
    const tripId = topic.split("/")[1];
    if (!tripId) return;

    const context = await this.ingest.contextFor(tripId);
    if (!context) {
      // Trip already ended, or never existed: drop rather than resurrect it.
      return;
    }

    const raw: unknown = JSON.parse(payload.toString());
    const batch = Array.isArray(raw) ? raw : [raw];
    const parsed = batch.flatMap((item) => {
      const result = pingSchema.safeParse(item);
      return result.success ? [result.data] : [];
    });

    if (parsed.length === 0) return;
    await this.ingest.ingest(context, parsed);
  }

  async onModuleDestroy(): Promise<void> {
    await this.client?.endAsync();
  }
}
