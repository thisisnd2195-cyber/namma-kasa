import { PipeTransform } from "@nestjs/common";
import type { ZodSchema, z } from "zod";

/**
 * Validates a request payload against a shared Zod contract. ZodError is
 * rendered as problem+json by ProblemFilter, so nothing is caught here.
 */
export class ZodValidationPipe<T extends ZodSchema> implements PipeTransform {
  constructor(private readonly schema: T) {}

  transform(value: unknown): z.infer<T> {
    return this.schema.parse(value);
  }
}
