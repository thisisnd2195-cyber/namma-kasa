import { CanActivate, ExecutionContext, HttpException, HttpStatus, Injectable } from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import type { Request } from "express";
import type { UserRole } from "@namma-kasa/shared";
import { IS_PUBLIC, REQUIRED_ROLES, type AuthedRequest } from "../decorators";
import { TokensService } from "../tokens.service";

/**
 * Global gate: verifies the bearer token, attaches claims, and enforces role
 * requirements. Ward scoping is a separate concern (WardScopeGuard) because it
 * needs the resource being addressed, not just the caller.
 */
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly tokens: TokensService,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const request = context.switchToHttp().getRequest<Request & AuthedRequest>();
    const header = request.headers.authorization;
    if (!header?.startsWith("Bearer ")) {
      throw new HttpException("Authentication required", HttpStatus.UNAUTHORIZED);
    }

    const claims = this.tokens.verifyAccess(header.slice(7));
    request.claims = claims;

    const required = this.reflector.getAllAndOverride<UserRole[]>(REQUIRED_ROLES, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (required?.length && !required.includes(claims.role)) {
      throw new HttpException("Not allowed for this role", HttpStatus.FORBIDDEN);
    }

    return true;
  }
}
