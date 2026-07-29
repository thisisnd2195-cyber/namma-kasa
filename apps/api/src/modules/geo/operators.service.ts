import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import type { Operator, createOperatorSchema, updateOperatorSchema } from "@namma-kasa/shared";
import type { z } from "zod";
import { DB, type Db } from "../../db/db.module";

type CreateOperator = z.infer<typeof createOperatorSchema>;
type UpdateOperator = z.infer<typeof updateOperatorSchema>;

@Injectable()
export class OperatorsService {
  constructor(@Inject(DB) private readonly db: Db) {}

  async list(): Promise<Operator[]> {
    const rows = await this.db
      .selectFrom("operators")
      .leftJoin("wards", "wards.operator_id", "operators.id")
      .select(({ fn }) => [
        "operators.id",
        "operators.name",
        "operators.type",
        "operators.config",
        "operators.status",
        fn.count<string>("wards.id").as("ward_count"),
      ])
      .groupBy(["operators.id"])
      .orderBy("operators.name")
      .execute();

    return rows.map((row) => ({
      id: row.id,
      name: row.name,
      type: row.type,
      config: row.config,
      status: row.status,
      wardCount: Number(row.ward_count),
    }));
  }

  async create(input: CreateOperator): Promise<Operator> {
    const row = await this.db
      .insertInto("operators")
      .values({ name: input.name, type: input.type, config: input.config })
      .returningAll()
      .executeTakeFirstOrThrow();
    return { ...row, wardCount: 0 };
  }

  async update(id: string, input: UpdateOperator): Promise<Operator> {
    // Retiring an operator that still runs wards would orphan them, so the
    // wards must be transferred or retired first (Clarifications CHK021).
    if (input.status === "retired") {
      const active = await this.db
        .selectFrom("wards")
        .select(({ fn }) => fn.countAll<string>().as("count"))
        .where("operator_id", "=", id)
        .where("status", "=", "active")
        .executeTakeFirstOrThrow();
      if (Number(active.count) > 0) {
        throw new HttpException(
          `Cannot retire an operator with ${active.count} active ward(s). Transfer them first.`,
          HttpStatus.CONFLICT,
        );
      }
    }

    const row = await this.db
      .updateTable("operators")
      .set({
        ...(input.name ? { name: input.name } : {}),
        ...(input.type ? { type: input.type } : {}),
        ...(input.config ? { config: input.config } : {}),
        ...(input.status ? { status: input.status } : {}),
        updated_at: new Date(),
      })
      .where("id", "=", id)
      .returningAll()
      .executeTakeFirst();

    if (!row) throw new HttpException("Operator not found", HttpStatus.NOT_FOUND);
    return row;
  }
}
