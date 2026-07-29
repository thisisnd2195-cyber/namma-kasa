import { Injectable, Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";

export const PUSH_SENDER = Symbol("PUSH_SENDER");

export interface PushMessage {
  tokens: string[];
  title: string;
  body: string;
  data: Record<string, string>;
}

export interface PushSender {
  send(message: PushMessage): Promise<{ delivered: number; failedTokens: string[] }>;
}

/** Development: pushes go to the log, so the flow is testable without Firebase. */
@Injectable()
export class ConsolePushSender implements PushSender {
  async send(message: PushMessage): Promise<{ delivered: number; failedTokens: string[] }> {
    console.log(
      `[dev-push] ${message.tokens.length} device(s) — ${message.title} | ${message.body}`,
    );
    return { delivered: message.tokens.length, failedTokens: [] };
  }
}

/**
 * FCM is the only realistic push channel for an Android-only launch. Loaded
 * lazily so the service account is not required to boot the API.
 */
@Injectable()
export class FcmPushSender implements PushSender {
  private readonly logger = new Logger(FcmPushSender.name);
  private messaging?: {
    sendEachForMulticast: (message: unknown) => Promise<{
      responses: { success: boolean }[];
      successCount: number;
    }>;
  };

  constructor(private readonly config: ConfigService) {}

  private async messagingClient() {
    if (this.messaging) return this.messaging;

    const raw = this.config.get<string>("FCM_SERVICE_ACCOUNT_JSON");
    if (!raw) throw new Error("FCM_SERVICE_ACCOUNT_JSON is required when PUSH_SENDER=fcm");

    const admin = (await import("firebase-admin")) as unknown as {
      apps: unknown[];
      initializeApp: (options: unknown) => void;
      credential: { cert: (value: unknown) => unknown };
      messaging: () => never;
    };

    if (admin.apps.length === 0) {
      admin.initializeApp({ credential: admin.credential.cert(JSON.parse(raw)) });
    }
    this.messaging = admin.messaging();
    return this.messaging;
  }

  async send(message: PushMessage): Promise<{ delivered: number; failedTokens: string[] }> {
    if (message.tokens.length === 0) return { delivered: 0, failedTokens: [] };

    const messaging = await this.messagingClient();
    const result = await messaging.sendEachForMulticast({
      tokens: message.tokens,
      notification: { title: message.title, body: message.body },
      data: message.data,
      android: { priority: "high" },
    });

    const failedTokens = result.responses.flatMap((response, index) =>
      response.success ? [] : [message.tokens[index]],
    );
    if (failedTokens.length > 0) {
      this.logger.warn(`${failedTokens.length} push token(s) rejected`);
    }
    return { delivered: result.successCount, failedTokens };
  }
}
