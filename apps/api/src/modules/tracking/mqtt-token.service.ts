import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import jwt from "jsonwebtoken";

/**
 * Short-lived credential a driver device presents to the broker.
 *
 * The trip topic is only knowable once the trip exists, so the ACL cannot ride
 * on the ordinary access token. Minting a per-trip token instead means a
 * compromised device can publish to exactly one trip's topic and nothing else,
 * and only until the trip could plausibly still be running.
 */
const TOKEN_TTL_SECONDS = 12 * 3600;

export interface MqttCredentials {
  username: string;
  password: string;
  expiresInSec: number;
}

@Injectable()
export class MqttTokenService {
  constructor(private readonly config: ConfigService) {}

  issue(driverUserId: string, tripId: string): MqttCredentials {
    const secret = this.config.getOrThrow<string>("JWT_SECRET");

    // EMQX reads this claim shape for authorization; `pub` is the whole grant.
    const payload = {
      sub: driverUserId,
      username: driverUserId,
      acl: {
        pub: [`trips/${tripId}/pings`],
        sub: [] as string[],
        all: [] as string[],
      },
    };

    return {
      username: driverUserId,
      password: jwt.sign(payload, secret, { expiresIn: TOKEN_TTL_SECONDS }),
      expiresInSec: TOKEN_TTL_SECONDS,
    };
  }
}
