import { Kysely, PostgresDialect } from "kysely";
import { Pool } from "pg";
import type { Database } from "../../src/db/types";

const TEST_DATABASE_URL =
  process.env.TEST_DATABASE_URL ??
  process.env.DATABASE_URL ??
  "postgres://nammakasa:devpassword@localhost:5433/nammakasa";

export function createTestDb(): Kysely<Database> {
  return new Kysely<Database>({
    dialect: new PostgresDialect({ pool: new Pool({ connectionString: TEST_DATABASE_URL }) }),
  });
}

/**
 * Runs `fn` inside a transaction that is always rolled back, so schema tests
 * can insert freely without leaving residue for the next test.
 */
export async function inRollback(
  db: Kysely<Database>,
  fn: (trx: Kysely<Database>) => Promise<void>,
): Promise<void> {
  const sentinel = new Error("rollback");
  try {
    await db.transaction().execute(async (trx) => {
      await fn(trx as unknown as Kysely<Database>);
      throw sentinel;
    });
  } catch (err) {
    if (err !== sentinel) throw err;
  }
}
