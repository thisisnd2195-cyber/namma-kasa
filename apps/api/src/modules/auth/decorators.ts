import { SetMetadata, createParamDecorator, type ExecutionContext } from "@nestjs/common";
import type { AccessClaims, UserRole } from "@namma-kasa/shared";

export const IS_PUBLIC = "auth:public";
export const REQUIRED_ROLES = "auth:roles";

/** Opts an endpoint out of the global auth guard (OTP, login, refresh). */
export const Public = (): MethodDecorator & ClassDecorator => SetMetadata(IS_PUBLIC, true);

export const Roles = (...roles: UserRole[]): MethodDecorator & ClassDecorator =>
  SetMetadata(REQUIRED_ROLES, roles);

export interface AuthedRequest {
  claims?: AccessClaims;
}

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AccessClaims => {
    const request = ctx.switchToHttp().getRequest<AuthedRequest>();
    if (!request.claims) throw new Error("CurrentUser used on an unauthenticated route");
    return request.claims;
  },
);
