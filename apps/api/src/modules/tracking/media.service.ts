import { HttpException, HttpStatus, Inject, Injectable, Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { randomUUID } from "node:crypto";
import { sql } from "kysely";
import type { MediaType } from "@namma-kasa/shared";
import { DB, type Db } from "../../db/db.module";

/** Photos upload straight to object storage; the API never proxies the bytes. */
const PRESIGN_TTL_SECONDS = 300;
/** Cap per trip so a stuck client cannot fill the bucket (Clarifications CHK047). */
const MAX_PROOFS_PER_TRIP = 10;

@Injectable()
export class MediaService {
  private readonly logger = new Logger(MediaService.name);
  private readonly s3: S3Client;
  private readonly bucket: string;
  private readonly publicBase: string;

  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly config: ConfigService,
  ) {
    const endpoint = this.config.getOrThrow<string>("S3_ENDPOINT");
    this.bucket = this.config.get<string>("S3_BUCKET", "namma-kasa-media");
    this.publicBase = `${endpoint}/${this.bucket}`;
    this.s3 = new S3Client({
      endpoint,
      region: "ap-south-1",
      // MinIO needs path-style addressing; S3 accepts it too.
      forcePathStyle: true,
      credentials: {
        accessKeyId: this.config.get<string>("S3_ACCESS_KEY", "minioadmin"),
        secretAccessKey: this.config.get<string>("S3_SECRET_KEY", "minioadmin"),
      },
    });
  }

  async presign(params: {
    tripId?: string;
    prefix: string;
    contentType: string;
  }): Promise<{ uploadUrl: string; objectUrl: string; uploadId: string }> {
    if (params.tripId) {
      const existing = await this.db
        .selectFrom("media_uploads")
        .select(({ fn }) => fn.countAll<string>().as("count"))
        .where("trip_id", "=", params.tripId)
        .executeTakeFirstOrThrow();
      if (Number(existing.count) >= MAX_PROOFS_PER_TRIP) {
        throw new HttpException(
          `A trip can carry at most ${MAX_PROOFS_PER_TRIP} photos`,
          HttpStatus.CONFLICT,
        );
      }
    }

    const uploadId = randomUUID();
    const extension = params.contentType.split("/")[1]?.replace("jpeg", "jpg") ?? "jpg";
    const key = `${params.prefix}/${uploadId}.${extension}`;

    const uploadUrl = await getSignedUrl(
      this.s3,
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        ContentType: params.contentType,
      }),
      { expiresIn: PRESIGN_TTL_SECONDS },
    );

    return { uploadUrl, objectUrl: `${this.publicBase}/${key}`, uploadId };
  }

  /** Called once the client's PUT succeeds, so half-finished uploads leave no row. */
  async confirm(params: {
    tripId: string;
    driverId: string;
    objectUrl: string;
    type: MediaType;
    geo?: { lat: number; lng: number };
    capturedAt?: Date;
  }): Promise<{ id: string }> {
    const row = await this.db
      .insertInto("media_uploads")
      .values({
        trip_id: params.tripId,
        driver_id: params.driverId,
        type: params.type,
        object_url: params.objectUrl,
        geo: params.geo
          ? sql<string>`ST_SetSRID(ST_MakePoint(${params.geo.lng}, ${params.geo.lat}), 4326)`
          : null,
        captured_at: params.capturedAt ?? new Date(),
      })
      .returning("id")
      .executeTakeFirstOrThrow();

    return { id: row.id };
  }
}
