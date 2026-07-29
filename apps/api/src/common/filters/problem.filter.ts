import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus } from "@nestjs/common";
import type { Request, Response } from "express";
import { ZodError } from "zod";

/**
 * Renders every error as RFC 9457 application/problem+json, the single error
 * shape promised by contracts/api.md.
 */
@Catch()
export class ProblemFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let title = "Internal Server Error";
    let detail: string | undefined;

    if (exception instanceof ZodError) {
      status = HttpStatus.UNPROCESSABLE_ENTITY;
      title = "Validation Failed";
      detail = exception.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; ");
    } else if (exception instanceof HttpException) {
      status = exception.getStatus();
      title = exception.name.replace(/Exception$/, "");
      const body = exception.getResponse();
      if (typeof body === "string") {
        detail = body;
      } else {
        const message = (body as { message?: string | string[] }).message;
        detail = Array.isArray(message) ? message.join("; ") : message;
      }
    } else if (exception instanceof Error) {
      detail = process.env.NODE_ENV === "production" ? undefined : exception.message;
    }

    response
      .status(status)
      .type("application/problem+json")
      .json({
        type: "about:blank",
        title,
        status,
        ...(detail ? { detail } : {}),
        instance: request.originalUrl,
      });
  }
}
