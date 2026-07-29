import { Inject, Injectable } from "@nestjs/common";
import type Redis from "ioredis";
import { REDIS } from "../../redis/redis.module";

/**
 * Load-shedding order from Clarifications CHK043. Ingest and notifications are
 * protected last: losing a ping loses evidence, and losing an alert means a
 * resident waits at the gate. Everything else can degrade first.
 */
export enum DegradationLevel {
  /** Everything on. */
  normal = 0,
  /** Live map cadence stretches from 2 s to 10 s. */
  slowLive = 1,
  /** Resident sockets paused; the app shows a banner and falls back to polling. */
  pauseLive = 2,
  /** Admin dashboards degrade to counts only. */
  minimal = 3,
}

const KEY = "degradation:level";

@Injectable()
export class DegradationService {
  constructor(@Inject(REDIS) private readonly redis: Redis) {}

  async level(): Promise<DegradationLevel> {
    const raw = await this.redis.get(KEY);
    return raw ? (Number(raw) as DegradationLevel) : DegradationLevel.normal;
  }

  async setLevel(level: DegradationLevel): Promise<void> {
    await this.redis.set(KEY, String(level));
  }

  /** Server emit interval for the resident live stream, in milliseconds. */
  async liveIntervalMs(): Promise<number> {
    const level = await this.level();
    return level >= DegradationLevel.slowLive ? 10_000 : 2_000;
  }

  async liveStreamEnabled(): Promise<boolean> {
    return (await this.level()) < DegradationLevel.pauseLive;
  }
}
