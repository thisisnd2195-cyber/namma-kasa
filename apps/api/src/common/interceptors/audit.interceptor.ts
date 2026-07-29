import { CallHandler, ExecutionContext, Inject, Injectable, NestInterceptor } from "@nestjs/common";
import type { Request } from "express";
import { tap } from "rxjs";
import { DB, type Db } from "../../db/db.module";
import type { AuthedRequest } from "../../modules/auth/decorators";

const MUTATIONS = new Set(["POST", "PATCH", "PUT", "DELETE"]);

/**
 * Records every successful admin mutation: who, what, when (NFR-05, CHK014).
 * Reads are not logged — the point is attributable change, not surveillance of
 * browsing. Audit rows are append-only by grant, so this is the only writer.
 */
@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(@Inject(DB) private readonly db: Db) {}

  intercept(context: ExecutionContext, next: CallHandler) {
    const request = context.switchToHttp().getRequest<Request & AuthedRequest>();
    const isAdminMutation =
      MUTATIONS.has(request.method) && request.path.startsWith("/v1/admin");

    if (!isAdminMutation) return next.handle();

    return next.handle().pipe(
      tap((result: unknown) => {
        const entityId =
          typeof result === "object" && result !== null && "id" in result
            ? String((result as { id: unknown }).id)
            : null;

        void this.db
          .insertInto("audit_log")
          .values({
            actor_id: request.claims?.sub ?? null,
            entity_type: request.path.split("/").filter(Boolean)[2] ?? "unknown",
            entity_id: entityId,
            action: `${request.method} ${request.path}`,
            before: null,
            after: (result ?? null) as Record<string, unknown> | null,
          })
          .execute()
          .catch(() => {
            // An audit write must never fail the user's request; the pino
            // request log retains the event if this insert is lost.
          });
      }),
    );
  }
}
