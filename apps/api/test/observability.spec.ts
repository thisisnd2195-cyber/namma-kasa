import { afterAll, describe, expect, it } from "vitest";
import { ArgumentsHost, HttpException, HttpStatus } from "@nestjs/common";
import { firstValueFrom, of } from "rxjs";
import type { CallHandler, ExecutionContext } from "@nestjs/common";
import { createTestDb } from "./helpers/db";
import { AuditInterceptor } from "../src/common/interceptors/audit.interceptor";
import { ProblemFilter } from "../src/common/filters/problem.filter";

const db = createTestDb();

afterAll(async () => {
  await db.destroy();
});

/** Minimal Nest plumbing: these units only read a request and a result. */
function contextFor(method: string, path: string, sub?: string): ExecutionContext {
  const request = { method, path, claims: sub ? { sub } : undefined };
  return {
    switchToHttp: () => ({ getRequest: () => request }),
  } as unknown as ExecutionContext;
}

const handlerReturning = (value: unknown): CallHandler => ({ handle: () => of(value) });

/** The insert is fire-and-forget, so give it a moment to land. */
async function settle(): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, 150));
}

describe("admin actions are attributable (SC-010)", () => {
  const interceptor = new AuditInterceptor(db);

  async function actor(): Promise<string> {
    const row = await db
      .selectFrom("users")
      .select("id")
      .where("role", "in", ["ward_admin", "super_admin"])
      .executeTakeFirstOrThrow();
    return row.id;
  }

  it("writes who, what and when for an admin mutation", async () => {
    const sub = await actor();
    const before = new Date();

    await firstValueFrom(
      interceptor.intercept(
        contextFor("POST", "/v1/admin/wards", sub),
        handlerReturning({ id: "11111111-1111-1111-1111-111111111111", name: "Test" }),
      ),
    );
    await settle();

    const row = await db
      .selectFrom("audit_log")
      .selectAll()
      .where("actor_id", "=", sub)
      .where("action", "=", "POST /v1/admin/wards")
      .orderBy("at", "desc")
      .executeTakeFirst();

    expect(row, "no audit row was written for an admin mutation").toBeDefined();
    expect(row!.actor_id).toBe(sub); // who
    expect(row!.entity_type).toBe("wards"); // what
    expect(row!.entity_id).toBe("11111111-1111-1111-1111-111111111111");
    expect(row!.at.getTime()).toBeGreaterThanOrEqual(before.getTime() - 1000); // when
  });

  it("does not log reads — attributable change, not browsing history", async () => {
    const sub = await actor();
    const beforeCount = await auditCount(sub);

    await firstValueFrom(
      interceptor.intercept(contextFor("GET", "/v1/admin/wards", sub), handlerReturning([])),
    );
    await settle();

    expect(await auditCount(sub)).toBe(beforeCount);
  });

  it("ignores non-admin mutations", async () => {
    const sub = await actor();
    const beforeCount = await auditCount(sub);

    await firstValueFrom(
      interceptor.intercept(
        contextFor("POST", "/v1/resident/complaints", sub),
        handlerReturning({ id: "x" }),
      ),
    );
    await settle();

    expect(await auditCount(sub)).toBe(beforeCount);
  });

  it("still records the action when the result carries no id", async () => {
    const sub = await actor();

    await firstValueFrom(
      interceptor.intercept(
        contextFor("DELETE", "/v1/admin/operators", sub),
        handlerReturning(undefined),
      ),
    );
    await settle();

    const row = await db
      .selectFrom("audit_log")
      .selectAll()
      .where("actor_id", "=", sub)
      .where("action", "=", "DELETE /v1/admin/operators")
      .orderBy("at", "desc")
      .executeTakeFirst();

    expect(row).toBeDefined();
    expect(row!.entity_id).toBeNull();
  });

  async function auditCount(sub: string): Promise<number> {
    const row = await db
      .selectFrom("audit_log")
      .select(({ fn }) => fn.countAll<string>().as("count"))
      .where("actor_id", "=", sub)
      .executeTakeFirstOrThrow();
    return Number(row.count);
  }
});

/**
 * A boundary clash is reported with the conflicting geometry attached as an
 * RFC 9457 extension member, which is what the portal draws as a visual diff
 * (FR-WARD-05). That has been dropped once already by a filter that copied
 * only the standard fields, and the fix shipped without a regression test.
 */
describe("problem details keep their extension members (FR-WARD-05)", () => {
  const filter = new ProblemFilter();

  function capture(): { host: ArgumentsHost; sent: () => Record<string, unknown> } {
    let body: Record<string, unknown> = {};
    const response = {
      status: () => response,
      type: () => response,
      json: (payload: Record<string, unknown>) => {
        body = payload;
        return response;
      },
    };
    const host = {
      switchToHttp: () => ({
        getResponse: () => response,
        getRequest: () => ({ url: "/v1/admin/wards", path: "/v1/admin/wards" }),
      }),
    } as unknown as ArgumentsHost;
    return { host, sent: () => body };
  }

  it("carries the conflicting geometry through to the response", async () => {
    const conflictGeometry = {
      type: "Polygon",
      coordinates: [
        [
          [77.5, 12.9],
          [77.6, 12.9],
          [77.6, 13.0],
          [77.5, 13.0],
          [77.5, 12.9],
        ],
      ],
    };

    const { host, sent } = capture();
    filter.catch(
      new HttpException(
        {
          message: "Boundary overlaps existing ward W-12",
          conflictsWith: { wardCode: "W-12", geometry: conflictGeometry },
        },
        HttpStatus.CONFLICT,
      ),
      host,
    );

    const body = sent();
    expect(body.status).toBe(409);
    expect(body.detail).toMatch(/overlaps existing ward/i);
    // The whole point: without this the portal has nothing to draw.
    expect(body.conflictsWith).toEqual({ wardCode: "W-12", geometry: conflictGeometry });
  });

  it("renders a plain string message without inventing extensions", () => {
    const { host, sent } = capture();
    filter.catch(new HttpException("Outside your ward", HttpStatus.FORBIDDEN), host);

    const body = sent();
    expect(body.status).toBe(403);
    expect(body.detail).toBe("Outside your ward");
    expect(body.conflictsWith).toBeUndefined();
  });
});
