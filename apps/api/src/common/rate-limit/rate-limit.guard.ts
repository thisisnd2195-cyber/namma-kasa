import {
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  SetMetadata,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import type { Request } from "express";
import type Redis from "ioredis";
import { REDIS } from "../../redis/redis.module";
import type { AuthedRequest } from "../../modules/auth/decorators";

export interface RateLimit {
  /** Requests allowed inside the window. */
  limit: number;
  windowSec: number;
  /** Defaults to the caller (user id, else IP). */
  scope?: "caller" | "ip";
}

export const RATE_LIMIT = "rate-limit";
export const Throttle = (config: RateLimit): MethodDecorator & ClassDecorator =>
  SetMetadata(RATE_LIMIT, config);

/** Applied globally; endpoints without @Throttle get the default budget. */
const DEFAULT: RateLimit = { limit: 120, windowSec: 60 };

@Injectable()
export class RateLimitGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    @Inject(REDIS) private readonly redis: Redis,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const config =
      this.reflector.getAllAndOverride<RateLimit>(RATE_LIMIT, [
        context.getHandler(),
        context.getClass(),
      ]) ?? DEFAULT;

    const request = context.switchToHttp().getRequest<Request & AuthedRequest>();
    const identity =
      config.scope === "ip" ? request.ip : (request.claims?.sub ?? request.ip ?? "anonymous");
    const key = `rl:${request.method}:${request.route?.path ?? request.path}:${identity}`;

    const hits = await this.redis.incr(key);
    if (hits === 1) await this.redis.expire(key, config.windowSec);

    if (hits > config.limit) {
      const retryAfter = await this.redis.ttl(key);
      throw new HttpException(
        `Too many requests. Retry in ${Math.max(retryAfter, 1)}s.`,
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
    return true;
  }
}
