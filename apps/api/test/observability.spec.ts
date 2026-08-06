import { afterAll, describe, expect, it } from "vitest";
import { ArgumentsHost, HttpException, HttpStatus } from "@nestjs/common";
import { firstValueFrom, of } from "rxjs";
import type { CallHandler, ExecutionContext } from "@nestjs/common";
import { createTestDb } from "./helpers/db";
import { AuditInterceptor } from "../src/common/interceptors/audit.interceptor";
import { ProblemFilter } from "../src/common/filters/problem.filter";
import { MetricsService } from "../src/modules/compliance/metrics.service";

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

describe("scrape metrics (NFR-09)", () => {
  const metrics = new MetricsService(db);

  /**
   * 00:15 IST, an instant whose UTC date is the *previous* day. Fixed rather
   * than relative to now so the two only ever disagree on purpose: a scrape in
   * the 00:00–05:30 IST window used to report the previous service day's
   * counts, because service_date is an IST day but `current_date` is UTC.
   */
  const scrapedAt = new Date("2026-03-10T00:15:00+05:30");
  const serviceDay = "2026-03-10";

  function tripsToday(rendered: string, wardCode: string): number {
    const line = rendered
      .split("\n")
      .find((l) => l.startsWith(`namma_kasa_trips_today{ward="${wardCode}"}`));
    if (!line) throw new Error(`No trips_today sample for ward ${wardCode}`);
    return Number(line.split(" ").pop());
  }

  it("counts a trip by its IST service day, not the server's UTC day", async () => {
    expect(scrapedAt.toISOString().slice(0, 10)).not.toBe(serviceDay);

    const route = await db
      .selectFrom("routes as r")
      .innerJoin("wards as w", "w.id", "r.ward_id")
      .select(["r.id as routeId", "w.ward_code as wardCode"])
      .where("w.status", "=", "active")
      .executeTakeFirstOrThrow();
    const auto = await db
      .selectFrom("trips")
      .select(["auto_id", "driver_id"])
      .where("route_id", "=", route.routeId)
      .executeTakeFirstOrThrow();

    await db.deleteFrom("trips").where("service_date", "=", serviceDay).execute();
    const before = tripsToday(await metrics.render(scrapedAt), route.wardCode);

    await db
      .insertInto("trips")
      .values({
        route_id: route.routeId,
        auto_id: auto.auto_id,
        driver_id: auto.driver_id,
        pass_number: 1,
        service_date: serviceDay,
        status: "completed",
        started_at: scrapedAt,
        ended_at: scrapedAt,
        end_reason: "driver",
      })
      .execute();

    try {
      // Only the trip filed under that IST day counts. Reading the server's UTC
      // day instead would pick up whatever ran on 2026-03-09 — and, in the live
      // system, would swap the whole ward's numbers back a day until 05:30.
      expect(before).toBe(0);
      expect(tripsToday(await metrics.render(scrapedAt), route.wardCode)).toBe(1);
    } finally {
      await db.deleteFrom("trips").where("service_date", "=", serviceDay).execute();
    }
  });
});
