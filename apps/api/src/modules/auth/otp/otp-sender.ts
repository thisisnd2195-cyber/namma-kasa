import { Inject, Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";

export const OTP_SENDER = Symbol("OTP_SENDER");

export interface OtpSender {
  send(phone: string, code: string): Promise<void>;
}

/**
 * Local development: the code goes straight to stdout, no SMS provider needed.
 * Deliberately console.log rather than the Nest logger — this line is a
 * developer affordance that must stay greppable and never be filtered by log
 * level or redaction.
 */
@Injectable()
export class ConsoleOtpSender implements OtpSender {
  async send(phone: string, code: string): Promise<void> {
    console.log(`[dev-otp] ${phone} ${code}`);
  }
}

/**
 * MSG91 requires DLT-registered templates in India, which have a lead time —
 * until that clears, OTP_SENDER=console keeps the flow testable.
 */
@Injectable()
export class Msg91OtpSender implements OtpSender {
  constructor(@Inject(ConfigService) private readonly config: ConfigService) {}

  async send(phone: string, code: string): Promise<void> {
    const authKey = this.config.get<string>("MSG91_AUTH_KEY");
    if (!authKey) throw new Error("MSG91_AUTH_KEY is required when OTP_SENDER=msg91");

    const response = await fetch("https://control.msg91.com/api/v5/otp", {
      method: "POST",
      headers: { "Content-Type": "application/json", authkey: authKey },
      body: JSON.stringify({ mobile: phone, otp: code }),
    });
    if (!response.ok) {
      throw new Error(`MSG91 rejected the OTP request: ${response.status}`);
    }
  }
}
