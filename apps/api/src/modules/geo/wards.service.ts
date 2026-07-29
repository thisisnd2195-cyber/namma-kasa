import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import * as argon2 from "argon2";
import { sql } from "kysely";
import type { GeoJsonArea, ImportReport, Ward } from "@namma-kasa/shared";
import type { z } from "zod";
import type {
  createWardAdminSchema,
  createWardSchema,
  importWardsSchema,
  updateWardSchema,
} from "@namma-kasa/shared";
import { DB, type Db } from "../../db/db.module";
import { GeoRepository } from "./geo.repository";

type CreateWard = z.infer<typeof createWardSchema>;
type UpdateWard = z.infer<typeof updateWardSchema>;
type ImportWards = z.infer<typeof importWardsSchema>;
type CreateWardAdmin = z.infer<typeof createWardAdminSchema>;

interface WardRow {
  id: string;
  operator_id: string;
  city_id: string;
  name: string;
  ward_code: string;
  boundary: string;
  ward_admin_user_id: string | null;
  status: "active" | "retired";
}

@Injectable()
export class WardsService {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly geo: GeoRepository,
  ) {}

  private toWard(row: WardRow): Ward {
    return {
      id: row.id,
      operatorId: row.operator_id,
      cityId: row.city_id,
      name: row.name,
      wardCode: row.ward_code,
      boundary: JSON.parse(row.boundary) as GeoJsonArea,
      wardAdminUserId: row.ward_admin_user_id,
      status: row.status,
    };
  }

  private selectWard() {
    return this.db
      .selectFrom("wards")
      .select([
        "id",
        "operator_id",
        "city_id",
        "name",
        "ward_code",
        sql<string>`ST_AsGeoJSON(boundary)`.as("boundary"),
        "ward_admin_user_id",
        "status",
      ]);
  }

  async list(wardId?: string): Promise<Ward[]> {
    let query = this.selectWard().orderBy("ward_code");
    if (wardId) query = query.where("id", "=", wardId);
    const rows = await query.execute();
    return rows.map((row) => this.toWard(row as WardRow));
  }

  async get(id: string): Promise<Ward> {
    const row = await this.selectWard().where("id", "=", id).executeTakeFirst();
    if (!row) throw new HttpException("Ward not found", HttpStatus.NOT_FOUND);
    return this.toWard(row as WardRow);
  }

  async create(input: CreateWard): Promise<Ward> {
    const operator = await this.db
      .selectFrom("operators")
      .select(["id", "status"])
      .where("id", "=", input.operatorId)
      .executeTakeFirst();
    if (!operator) throw new HttpException("Operator not found", HttpStatus.NOT_FOUND);
    if (operator.status === "retired") {
      throw new HttpException("Operator is retired", HttpStatus.CONFLICT);
    }

    await this.assertNoOverlap(input.boundary, input.cityId);

    const row = await this.db
      .insertInto("wards")
      .values({
        operator_id: input.operatorId,
        city_id: input.cityId,
        name: input.name,
        ward_code: input.wardCode,
        boundary: this.geo.multi(input.boundary),
      })
      .returning([
        "id",
        "operator_id",
        "city_id",
        "name",
        "ward_code",
        sql<string>`ST_AsGeoJSON(boundary)`.as("boundary"),
        "ward_admin_user_id",
        "status",
      ])
      .executeTakeFirstOrThrow()
      .catch((error: unknown) => this.translateTriggerError(error));

    return this.toWard(row as WardRow);
  }

  async update(id: string, input: UpdateWard): Promise<Ward> {
    const current = await this.get(id);

    if (input.boundary) {
      await this.assertNoOverlap(input.boundary, input.cityId ?? current.cityId, id);
    }

    await this.db
      .updateTable("wards")
      .set({
        ...(input.name ? { name: input.name } : {}),
        ...(input.wardCode ? { ward_code: input.wardCode } : {}),
        ...(input.status ? { status: input.status } : {}),
        ...(input.boundary ? { boundary: this.geo.multi(input.boundary) } : {}),
        updated_at: new Date(),
      })
      .where("id", "=", id)
      .execute();

    // A reshaped ward can strand households inside routes that no longer
    // contain them; they go back to the review queue rather than silently
    // keeping a wrong route (CHK017).
    if (input.boundary) await this.geo.reflagStrandedHouseholds(id);

    return this.get(id);
  }

  /** Preview endpoint: what a boundary change would break, before committing. */
  async editImpact(id: string, boundary: GeoJsonArea) {
    await this.get(id);
    return this.geo.editImpact(id, boundary);
  }

  /**
   * Bulk import is per-feature: a bad polygon rejects itself with a reason and
   * the rest still land, because a 200-ward file should not fail whole for one
   * overlap (CHK018).
   */
  async import(input: ImportWards): Promise<ImportReport> {
    const report: ImportReport = { accepted: [], rejected: [] };

    for (const feature of input.featureCollection.features) {
      const wardCode = String(feature.properties.ward_code ?? feature.properties.code ?? "");
      const name = String(feature.properties.name ?? wardCode);

      if (!wardCode) {
        report.rejected.push({ wardCode: "(missing)", reason: "Feature has no ward_code" });
        continue;
      }

      try {
        const ward = await this.create({
          operatorId: input.operatorId,
          cityId: input.cityId,
          name,
          wardCode,
          boundary: feature.geometry,
        });
        report.accepted.push({ wardCode, id: ward.id });
      } catch (error) {
        report.rejected.push({
          wardCode,
          reason: error instanceof HttpException ? error.message : "Invalid geometry",
        });
      }
    }

    return report;
  }

  async createWardAdmin(input: CreateWardAdmin): Promise<{ userId: string }> {
    const ward = await this.get(input.wardId);
    if (ward.wardAdminUserId) {
      throw new HttpException("This ward already has an admin", HttpStatus.CONFLICT);
    }

    const existing = await this.db
      .selectFrom("users")
      .select("id")
      .where("phone", "=", input.phone)
      .executeTakeFirst();
    if (existing) {
      throw new HttpException("This number already has an account", HttpStatus.CONFLICT);
    }

    const user = await this.db
      .insertInto("users")
      .values({
        phone: input.phone,
        auth_provider: "password",
        password_hash: await argon2.hash(input.password, { type: argon2.argon2id }),
        role: "ward_admin",
        consented_at: new Date(),
      })
      .returning("id")
      .executeTakeFirstOrThrow();

    await this.db
      .updateTable("wards")
      .set({ ward_admin_user_id: user.id })
      .where("id", "=", input.wardId)
      .execute();

    return { userId: user.id };
  }

  private async assertNoOverlap(
    boundary: GeoJsonArea,
    cityId: string,
    excludeWardId?: string,
  ): Promise<void> {
    const overlap = await this.geo.overlapWith(boundary, cityId, excludeWardId);
    if (!overlap) return;

    throw new HttpException(
      {
        title: "Ward boundary conflict",
        message: `Boundary overlaps existing ward: ${overlap.name}`,
        conflict: overlap.conflict,
      },
      HttpStatus.CONFLICT,
    );
  }

  /**
   * The trigger is the real authority on boundary conflicts; this keeps its
   * error from surfacing as a 500 if the pre-check ever misses a case.
   */
  private translateTriggerError(error: unknown): never {
    const message = error instanceof Error ? error.message : "";
    const conflict = /overlaps existing ward: (.+)$/.exec(message);
    if (conflict) {
      throw new HttpException(
        { title: "Ward boundary conflict", message: `Boundary overlaps existing ward: ${conflict[1]}` },
        HttpStatus.CONFLICT,
      );
    }
    throw error;
  }
}
