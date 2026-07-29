import { afterAll, describe, expect, it } from "vitest";
import { Reflector } from "@nestjs/core";
import type { ExecutionContext } from "@nestjs/common";
import { AuthGuard } from "../src/modules/auth/guards/auth.guard";
import { WardScopeGuard } from "../src/modules/auth/guards/ward-scope.guard";
import { IS_PUBLIC, REQUIRED_ROLES } from "../src/modules/auth/decorators";
import { buildAuthStack } from "./helpers/services";

const stack = buildAuthStack();
afterAll(async () => {
  await stack.close();
});

interface RequestShape {
  headers?: Record<string, string>;
  params?: Record<string, string>;
  query?: Record<string, string>;
  body?: Record<string, string>;
  claims?: unknown;
}

/** Minimal ExecutionContext: the guards only read the HTTP request and metadata. */
function contextFor(request: RequestShape, metadata: Record<string, unknown> = {}) {
  const handler = () => undefined;
  const controller = class {};
  const reflector = new Reflector();

  // Reflector reads metadata off the handler/class, so attach it there.
  for (const [key, value] of Object.entries(metadata)) {
    Reflect.defineMetadata(key, value, handler);
  }

  const ctx = {
    switchToHttp: () => ({ getRequest: () => request }),
    getHandler: () => handler,
    getClass: () => controller,
  } as unknown as ExecutionContext;

  return { ctx, reflector, request };
}

describe("AuthGuard", () => {
  it("denies an unauthenticated request by default", () => {
    const { ctx, reflector } = contextFor({ headers: {} });
    const guard = new AuthGuard(reflector, stack.tokens);
    expect(() => guard.canActivate(ctx)).toThrow(/Authentication required/);
  });

  it("allows routes explicitly marked public", () => {
    const { ctx, reflector } = contextFor({ headers: {} }, { [IS_PUBLIC]: true });
    const guard = new AuthGuard(reflector, stack.tokens);
    expect(guard.canActivate(ctx)).toBe(true);
  });

  it("rejects a malformed or forged token", () => {
    const { ctx, reflector } = contextFor({ headers: { authorization: "Bearer not-a-jwt" } });
    const guard = new AuthGuard(reflector, stack.tokens);
    expect(() => guard.canActivate(ctx)).toThrow(/Invalid or expired token/);
  });

  it("attaches claims and enforces the required role", () => {
    const token = stack.tokens.signAccess({
      sub: "11111111-1111-1111-1111-111111111111",
      role: "driver",
      wardId: null,
      routeId: null,
      deviceId: "d1",
    });

    const allowed = contextFor({ headers: { authorization: `Bearer ${token}` } }, {
      [REQUIRED_ROLES]: ["driver"],
    });
    const guard = new AuthGuard(allowed.reflector, stack.tokens);
    expect(guard.canActivate(allowed.ctx)).toBe(true);
    expect((allowed.request.claims as { role: string }).role).toBe("driver");

    const denied = contextFor({ headers: { authorization: `Bearer ${token}` } }, {
      [REQUIRED_ROLES]: ["super_admin"],
    });
    expect(() => new AuthGuard(denied.reflector, stack.tokens).canActivate(denied.ctx)).toThrow(
      /Not allowed for this role/,
    );
  });
});

describe("WardScopeGuard (FR-WARD-06)", () => {
  const wardA = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
  const wardB = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
  const guard = new WardScopeGuard();

  it("lets a super admin address any ward", () => {
    const { ctx } = contextFor({
      claims: { sub: "x", role: "super_admin" },
      params: { wardId: wardB },
    });
    expect(guard.canActivate(ctx)).toBe(true);
  });

  it("lets a ward admin address their own ward", () => {
    const { ctx } = contextFor({
      claims: { sub: "x", role: "ward_admin", wardId: wardA },
      params: { wardId: wardA },
    });
    expect(guard.canActivate(ctx)).toBe(true);
  });

  it("blocks a ward admin reaching into another ward", () => {
    const { ctx } = contextFor({
      claims: { sub: "x", role: "ward_admin", wardId: wardA },
      params: { wardId: wardB },
    });
    expect(() => guard.canActivate(ctx)).toThrow(/Outside your ward/);
  });

  it("checks the body and query too, not just path params", () => {
    const viaBody = contextFor({
      claims: { sub: "x", role: "ward_admin", wardId: wardA },
      body: { wardId: wardB },
    });
    expect(() => guard.canActivate(viaBody.ctx)).toThrow(/Outside your ward/);

    const viaQuery = contextFor({
      claims: { sub: "x", role: "ward_admin", wardId: wardA },
      query: { wardId: wardB },
    });
    expect(() => guard.canActivate(viaQuery.ctx)).toThrow(/Outside your ward/);
  });

  it("refuses residents and drivers outright", () => {
    for (const role of ["resident", "driver"] as const) {
      const { ctx } = contextFor({ claims: { sub: "x", role, wardId: wardA } });
      expect(() => guard.canActivate(ctx)).toThrow(/Not allowed for this role/);
    }
  });
});
