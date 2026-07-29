import { afterAll, describe, expect, it } from "vitest";
import mqtt, { type MqttClient } from "mqtt";
import { ConfigService } from "@nestjs/config";
import { MqttTokenService } from "../src/modules/tracking/mqtt-token.service";

/**
 * Broker connectivity. These exist because a complete MQTT ingest outage once
 * passed every other gate in this suite: nothing else here actually opens a
 * connection, so "the config is written" and "the broker accepts us" had drifted
 * apart without a single failing test.
 *
 * Constitution V: the critical flow is driver -> broker -> ingest, and the first
 * hop was untested.
 */
const MQTT_URL = process.env.MQTT_URL ?? "mqtt://localhost:1883";
const CONNECT_TIMEOUT_MS = 4_000;

const tokens = new MqttTokenService(
  new ConfigService({ JWT_SECRET: process.env.JWT_SECRET ?? "dev-only-change-me" }),
);

const open: MqttClient[] = [];
afterAll(() => {
  for (const client of open) client.end(true);
});

async function connect(options: mqtt.IClientOptions): Promise<MqttClient> {
  const client = mqtt.connect(MQTT_URL, {
    ...options,
    connectTimeout: CONNECT_TIMEOUT_MS,
    reconnectPeriod: 0, // fail once rather than retrying forever
  });
  open.push(client);

  return new Promise((resolve, reject) => {
    client.once("connect", () => resolve(client));
    client.once("error", reject);
    client.once("close", () => reject(new Error("closed before connecting")));
  });
}

/**
 * Resolves true when the broker accepts the publish, false when it refuses.
 *
 * A denied QoS-1 publish never returns a PUBACK — EMQX disconnects instead — so
 * waiting on the ack alone hangs until the test times out. Racing the ack
 * against the disconnect is what distinguishes "accepted" from "refused".
 */
async function canPublish(client: MqttClient, topic: string): Promise<boolean> {
  const acked = client
    .publishAsync(topic, JSON.stringify({ probe: true }), { qos: 1 })
    .then(() => true)
    .catch(() => false);

  const refused = new Promise<boolean>((resolve) => {
    client.once("close", () => resolve(false));
    client.once("disconnect", () => resolve(false));
    client.once("error", () => resolve(false));
  });

  const timedOut = new Promise<boolean>((resolve) => setTimeout(() => resolve(false), 3_000));

  return Promise.race([acked, refused, timedOut]);
}

describe("broker authentication", () => {
  it("accepts the ingest consumer's credentials", async () => {
    const username = process.env.MQTT_USERNAME ?? "namma-kasa-ingest";
    const password = process.env.MQTT_PASSWORD ?? "devpassword";

    const client = await connect({ clientId: `test-consumer-${Date.now()}`, username, password });
    expect(client.connected).toBe(true);

    // The consumer's whole job: subscribing to every trip's ping topic.
    await expect(client.subscribeAsync("trips/+/pings", { qos: 1 })).resolves.toBeDefined();
  });

  it("refuses a client with no credentials", async () => {
    await expect(connect({ clientId: `test-anon-${Date.now()}` })).rejects.toThrow();
  });

  it("refuses a client with a bad password", async () => {
    await expect(
      connect({ clientId: `test-bad-${Date.now()}`, username: "someone", password: "wrong" }),
    ).rejects.toThrow();
  });

  it("accepts a device presenting a per-trip token", async () => {
    const tripId = crypto.randomUUID();
    const credentials = tokens.issue(crypto.randomUUID(), tripId);

    const client = await connect({
      clientId: `test-device-${Date.now()}`,
      username: credentials.username,
      password: credentials.password,
    });
    expect(client.connected).toBe(true);
  });
});

describe("broker authorization (contracts/realtime.md §1)", () => {
  it("lets a device publish to its own trip topic", async () => {
    const tripId = crypto.randomUUID();
    const credentials = tokens.issue(crypto.randomUUID(), tripId);

    const client = await connect({
      clientId: `test-own-${Date.now()}`,
      username: credentials.username,
      password: credentials.password,
    });

    expect(await canPublish(client, `trips/${tripId}/pings`)).toBe(true);
  });

  /**
   * The reason per-trip tokens exist. A stolen phone holding a valid token must
   * not be able to forge another auto's trail.
   */
  it("stops a device publishing to another trip's topic", async () => {
    const ownTrip = crypto.randomUUID();
    const otherTrip = crypto.randomUUID();
    const credentials = tokens.issue(crypto.randomUUID(), ownTrip);

    const client = await connect({
      clientId: `test-other-${Date.now()}`,
      username: credentials.username,
      password: credentials.password,
    });

    expect(await canPublish(client, `trips/${otherTrip}/pings`)).toBe(false);
  });
});
