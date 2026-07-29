import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import type { Auto, Driver } from "@namma-kasa/shared";
import type {
  createAutoSchema,
  createDriverSchema,
  updateAutoSchema,
  updateDriverSchema,
} from "@namma-kasa/shared";
import type { z } from "zod";
import { DB, type Db } from "../../db/db.module";

type CreateAuto = z.infer<typeof createAutoSchema>;
type UpdateAuto = z.infer<typeof updateAutoSchema>;
type CreateDriver = z.infer<typeof createDriverSchema>;
type UpdateDriver = z.infer<typeof updateDriverSchema>;

@Injectable()
export class FleetService {
  constructor(@Inject(DB) private readonly db: Db) {}

  // ------------------------------------------------------------------ autos

  async listAutos(wardId: string, availableOnly = false): Promise<Auto[]> {
    let query = this.db.selectFrom("autos").selectAll().where("ward_id", "=", wardId);
    // The assignment screen must only offer autos that can actually take a
    // route right now (FR-FLEET-02).
    if (availableOnly) query = query.where("status", "=", "available");

    const rows = await query.orderBy("registration_number").execute();
    return rows.map((row) => ({
      id: row.id,
      registrationNumber: row.registration_number,
      capacityKg: row.capacity_kg,
      wardId: row.ward_id,
      photos: row.photos,
      status: row.status,
    }));
  }

  async createAuto(input: CreateAuto, actorId: string): Promise<Auto> {
    const existing = await this.db
      .selectFrom("autos")
      .select("id")
      .where("registration_number", "=", input.registrationNumber)
      .executeTakeFirst();
    if (existing) {
      throw new HttpException("This registration number is already onboarded", HttpStatus.CONFLICT);
    }

    const row = await this.db
      .insertInto("autos")
      .values({
        registration_number: input.registrationNumber,
        capacity_kg: input.capacityKg ?? null,
        ward_id: input.wardId,
        photos: input.photos,
        onboarded_by: actorId,
      })
      .returningAll()
      .executeTakeFirstOrThrow();

    return {
      id: row.id,
      registrationNumber: row.registration_number,
      capacityKg: row.capacity_kg,
      wardId: row.ward_id,
      photos: row.photos,
      status: row.status,
    };
  }

  async updateAuto(id: string, input: UpdateAuto): Promise<Auto> {
    // An auto cannot go to maintenance or retirement mid-trip; the trip has to
    // finish first, otherwise a live trip loses its vehicle (CHK022).
    if (input.status && input.status !== "available" && input.status !== "assigned") {
      const active = await this.db
        .selectFrom("trips")
        .select("id")
        .where("auto_id", "=", id)
        .where("status", "=", "active")
        .executeTakeFirst();
      if (active) {
        throw new HttpException(
          "This auto is on an active trip. End the trip first.",
          HttpStatus.CONFLICT,
        );
      }
      await this.closeOpenAssignments("auto_route_assignments", "auto_id", id);
    }

    const row = await this.db
      .updateTable("autos")
      .set({
        ...(input.capacityKg !== undefined ? { capacity_kg: input.capacityKg } : {}),
        ...(input.photos ? { photos: input.photos } : {}),
        ...(input.status ? { status: input.status } : {}),
        updated_at: new Date(),
      })
      .where("id", "=", id)
      .returningAll()
      .executeTakeFirst();

    if (!row) throw new HttpException("Auto not found", HttpStatus.NOT_FOUND);
    return {
      id: row.id,
      registrationNumber: row.registration_number,
      capacityKg: row.capacity_kg,
      wardId: row.ward_id,
      photos: row.photos,
      status: row.status,
    };
  }

  // ----------------------------------------------------------------- drivers

  async listDrivers(wardId: string): Promise<Driver[]> {
    const rows = await this.db
      .selectFrom("drivers")
      .selectAll()
      .where("ward_id", "=", wardId)
      .orderBy("full_name")
      .execute();

    return rows.map((row) => ({
      id: row.id,
      wardId: row.ward_id,
      fullName: row.full_name,
      phone: row.phone,
      licenseNumber: row.license_number,
      photoUrl: row.photo_url,
      emergencyContact: row.emergency_contact,
      status: row.status,
      hasAccount: row.user_id !== null,
    }));
  }

  /**
   * Creating the driver record is what lets that phone number register in the
   * app at all — the pre-provisioning half of FR-AUTH-05.
   */
  async createDriver(input: CreateDriver): Promise<Driver> {
    const existing = await this.db
      .selectFrom("drivers")
      .select("id")
      .where("phone", "=", input.phone)
      .executeTakeFirst();
    if (existing) {
      throw new HttpException("A driver with this number already exists", HttpStatus.CONFLICT);
    }

    const row = await this.db
      .insertInto("drivers")
      .values({
        ward_id: input.wardId,
        full_name: input.fullName,
        phone: input.phone,
        license_number: input.licenseNumber,
        photo_url: input.photoUrl ?? null,
        emergency_contact: input.emergencyContact ?? null,
      })
      .returningAll()
      .executeTakeFirstOrThrow();

    return {
      id: row.id,
      wardId: row.ward_id,
      fullName: row.full_name,
      phone: row.phone,
      licenseNumber: row.license_number,
      photoUrl: row.photo_url,
      emergencyContact: row.emergency_contact,
      status: row.status,
      hasAccount: false,
    };
  }

  async updateDriver(id: string, input: UpdateDriver): Promise<Driver> {
    if (input.status === "inactive") {
      const active = await this.db
        .selectFrom("trips")
        .select("id")
        .where("driver_id", "=", id)
        .where("status", "=", "active")
        .executeTakeFirst();
      if (active) {
        throw new HttpException(
          "This driver is on an active trip. End the trip first.",
          HttpStatus.CONFLICT,
        );
      }
      await this.closeOpenAssignments("driver_auto_assignments", "driver_id", id);
    }

    await this.db
      .updateTable("drivers")
      .set({
        ...(input.fullName ? { full_name: input.fullName } : {}),
        ...(input.licenseNumber ? { license_number: input.licenseNumber } : {}),
        ...(input.photoUrl !== undefined ? { photo_url: input.photoUrl ?? null } : {}),
        ...(input.emergencyContact !== undefined
          ? { emergency_contact: input.emergencyContact ?? null }
          : {}),
        ...(input.status ? { status: input.status } : {}),
        updated_at: new Date(),
      })
      .where("id", "=", id)
      .execute();

    const drivers = await this.db
      .selectFrom("drivers")
      .selectAll()
      .where("id", "=", id)
      .executeTakeFirst();
    if (!drivers) throw new HttpException("Driver not found", HttpStatus.NOT_FOUND);

    return {
      id: drivers.id,
      wardId: drivers.ward_id,
      fullName: drivers.full_name,
      phone: drivers.phone,
      licenseNumber: drivers.license_number,
      photoUrl: drivers.photo_url,
      emergencyContact: drivers.emergency_contact,
      status: drivers.status,
      hasAccount: drivers.user_id !== null,
    };
  }

  // ------------------------------------------------------------- assignments

  /**
   * Reassignment closes the open row and opens a new one. History is never
   * rewritten, so "who was driving on the 14th" stays answerable (FR-FLEET-04).
   */
  async assignAutoToRoute(
    autoId: string,
    routeId: string,
    actorId: string,
    effectiveFrom = new Date(),
  ): Promise<void> {
    const auto = await this.db
      .selectFrom("autos")
      .select(["ward_id", "status"])
      .where("id", "=", autoId)
      .executeTakeFirst();
    if (!auto) throw new HttpException("Auto not found", HttpStatus.NOT_FOUND);
    if (auto.status === "retired" || auto.status === "maintenance") {
      throw new HttpException(`Auto is ${auto.status}`, HttpStatus.CONFLICT);
    }

    const route = await this.db
      .selectFrom("routes")
      .select("ward_id")
      .where("id", "=", routeId)
      .executeTakeFirst();
    if (!route) throw new HttpException("Route not found", HttpStatus.NOT_FOUND);
    if (route.ward_id !== auto.ward_id) {
      throw new HttpException("Auto and route belong to different wards", HttpStatus.CONFLICT);
    }

    await this.db.transaction().execute(async (trx) => {
      await trx
        .updateTable("auto_route_assignments")
        .set({ effective_to: effectiveFrom })
        .where("auto_id", "=", autoId)
        .where("effective_to", "is", null)
        .execute();

      await trx
        .insertInto("auto_route_assignments")
        .values({
          auto_id: autoId,
          route_id: routeId,
          assigned_by: actorId,
          effective_from: effectiveFrom,
        })
        .execute();

      await trx.updateTable("autos").set({ status: "assigned" }).where("id", "=", autoId).execute();
    });
  }

  async assignDriverToAuto(
    driverId: string,
    autoId: string,
    actorId: string,
    effectiveFrom = new Date(),
  ): Promise<void> {
    const driver = await this.db
      .selectFrom("drivers")
      .select(["ward_id", "status"])
      .where("id", "=", driverId)
      .executeTakeFirst();
    if (!driver) throw new HttpException("Driver not found", HttpStatus.NOT_FOUND);
    if (driver.status === "inactive") {
      throw new HttpException("Driver is inactive", HttpStatus.CONFLICT);
    }

    const auto = await this.db
      .selectFrom("autos")
      .select("ward_id")
      .where("id", "=", autoId)
      .executeTakeFirst();
    if (!auto) throw new HttpException("Auto not found", HttpStatus.NOT_FOUND);
    if (auto.ward_id !== driver.ward_id) {
      throw new HttpException("Driver and auto belong to different wards", HttpStatus.CONFLICT);
    }

    await this.db.transaction().execute(async (trx) => {
      // Close both sides: the driver's previous auto and the auto's previous
      // driver, since each may only have one open assignment.
      await trx
        .updateTable("driver_auto_assignments")
        .set({ effective_to: effectiveFrom })
        .where((eb) => eb.or([eb("driver_id", "=", driverId), eb("auto_id", "=", autoId)]))
        .where("effective_to", "is", null)
        .execute();

      await trx
        .insertInto("driver_auto_assignments")
        .values({
          driver_id: driverId,
          auto_id: autoId,
          assigned_by: actorId,
          effective_from: effectiveFrom,
        })
        .execute();
    });
  }

  async assignmentHistory(autoId: string) {
    const routes = await this.db
      .selectFrom("auto_route_assignments as a")
      .innerJoin("routes as r", "r.id", "a.route_id")
      .select(["a.id", "a.auto_id", "a.route_id", "a.effective_from", "a.effective_to", "r.name as routeName"])
      .where("a.auto_id", "=", autoId)
      .orderBy("a.effective_from", "desc")
      .execute();

    const drivers = await this.db
      .selectFrom("driver_auto_assignments as d")
      .innerJoin("drivers as dr", "dr.id", "d.driver_id")
      .select(["d.id", "d.driver_id", "d.auto_id", "d.effective_from", "d.effective_to", "dr.full_name as driverName"])
      .where("d.auto_id", "=", autoId)
      .orderBy("d.effective_from", "desc")
      .execute();

    return { routes, drivers };
  }

  private async closeOpenAssignments(
    table: "auto_route_assignments" | "driver_auto_assignments",
    column: "auto_id" | "driver_id",
    id: string,
  ): Promise<void> {
    await this.db
      .updateTable(table)
      .set({ effective_to: new Date() })
      .where(column, "=", id)
      .where("effective_to", "is", null)
      .execute();
  }
}
