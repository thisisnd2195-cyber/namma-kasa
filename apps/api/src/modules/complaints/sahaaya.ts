import { Injectable, Logger } from "@nestjs/common";

export const SAHAAYA_CLIENT = Symbol("SAHAAYA_CLIENT");

export interface SahaayaComplaint {
  complaintId: string;
  category: string;
  description: string | null;
  wardCode: string;
  addressLine: string;
  raisedAt: Date;
}

export interface SahaayaClient {
  /** Returns the reference Sahaaya assigns, or null if it declined. */
  push(complaint: SahaayaComplaint): Promise<string | null>;
}

/**
 * FR-CMP-04: mirror BBMP-ward complaints into Sahaaya 2.0 so residents do not
 * have to file the same thing twice.
 *
 * BBMP has not published an integration contract, so this is the seam and not
 * the integration: the gating, the eligibility rules, and the call site are
 * real, and the transport is a stub that logs. Swapping in a live client is a
 * matter of providing another SahaayaClient — no caller changes.
 */
@Injectable()
export class LoggingSahaayaClient implements SahaayaClient {
  private readonly logger = new Logger("SahaayaSync");

  async push(complaint: SahaayaComplaint): Promise<string | null> {
    this.logger.log(
      `Would sync complaint ${complaint.complaintId} (${complaint.category}) ` +
        `for ward ${complaint.wardCode} to Sahaaya 2.0`,
    );
    return null;
  }
}
