import { CanActivate, ExecutionContext, HttpException, HttpStatus, Injectable } from "@nestjs/common";
import type { Request } from "express";
import type { AuthedRequest } from "../decorators";

/**
 * A Ward Admin may only address their own ward (FR-WARD-06). Super Admins are
 * unscoped. Applied to admin routes that carry a wardId in params, query, or
 * body — server-side, never trusting the client to filter.
 */
@Injectable()
export class WardScopeGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<Request & AuthedRequest>();
    const claims = request.claims;
    if (!claims) throw new HttpException("Authentication required", HttpStatus.UNAUTHORIZED);
    if (claims.role === "super_admin") return true;

    if (claims.role !== "ward_admin") {
      throw new HttpException("Not allowed for this role", HttpStatus.FORBIDDEN);
    }
    if (!claims.wardId) {
      throw new HttpException("No ward assigned to this account", HttpStatus.FORBIDDEN);
    }

    const target =
      (request.params as Record<string, string>)?.wardId ??
      (request.query as Record<string, string>)?.wardId ??
      (request.body as Record<string, string>)?.wardId;

    if (target && target !== claims.wardId) {
      throw new HttpException("Outside your ward", HttpStatus.FORBIDDEN);
    }
    return true;
  }
}
