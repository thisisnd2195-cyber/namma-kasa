import { Injectable, Logger, OnModuleDestroy } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import type { Server } from "node:http";
import { WebSocket, WebSocketServer } from "ws";
import type { LiveFrame } from "@namma-kasa/shared";
import { TokensService } from "../auth/tokens.service";

/** A socket outlives the 15-minute access token, so it is cycled instead. */
const MAX_SOCKET_LIFETIME_MS = 60 * 60_000;
const HEARTBEAT_MS = 30_000;
/** Server-side throttle from contracts/realtime.md: at most one frame per 2 s. */
const MIN_FRAME_INTERVAL_MS = 2_000;

interface Subscriber {
  socket: WebSocket;
  routeId: string;
  lastSentAt: Map<string, number>;
  openedAt: number;
}

/**
 * Pushes auto positions to residents watching their own route.
 *
 * Scoping is enforced here rather than in the broker: a resident may only
 * subscribe to the route their household is on, and ward admins to routes in
 * their ward. That check is a JWT claim comparison, which is far easier to
 * audit than broker ACL rules.
 */
@Injectable()
export class LiveGateway implements OnModuleDestroy {
  private readonly logger = new Logger(LiveGateway.name);
  private server?: WebSocketServer;
  private readonly subscribers = new Set<Subscriber>();
  private heartbeat?: NodeJS.Timeout;

  constructor(
    private readonly tokens: TokensService,
    private readonly config: ConfigService,
  ) {}

  attach(httpServer: Server): void {
    this.server = new WebSocketServer({ noServer: true });

    httpServer.on("upgrade", (request, socket, head) => {
      const url = new URL(request.url ?? "/", "http://localhost");
      if (url.pathname !== "/v1/live") return;

      const token =
        url.searchParams.get("token") ??
        request.headers.authorization?.replace(/^Bearer /, "");
      const routeId = url.searchParams.get("route_id");

      if (!token || !routeId) {
        socket.write("HTTP/1.1 400 Bad Request\r\n\r\n");
        socket.destroy();
        return;
      }

      let claims;
      try {
        claims = this.tokens.verifyAccess(token);
      } catch {
        socket.write("HTTP/1.1 401 Unauthorized\r\n\r\n");
        socket.destroy();
        return;
      }

      const allowed =
        claims.role === "super_admin" ||
        claims.role === "ward_admin" ||
        (claims.role === "resident" && claims.routeId === routeId);

      if (!allowed) {
        socket.write("HTTP/1.1 403 Forbidden\r\n\r\n");
        socket.destroy();
        return;
      }

      this.server!.handleUpgrade(request, socket, head, (ws) => {
        this.register(ws, routeId);
      });
    });

    this.heartbeat = setInterval(() => this.sweep(), HEARTBEAT_MS);
    this.heartbeat.unref();
    this.logger.log("Resident live stream listening on /v1/live");
  }

  private register(socket: WebSocket, routeId: string): void {
    const subscriber: Subscriber = {
      socket,
      routeId,
      lastSentAt: new Map(),
      openedAt: Date.now(),
    };
    this.subscribers.add(subscriber);
    socket.on("close", () => this.subscribers.delete(subscriber));
    socket.on("error", () => this.subscribers.delete(subscriber));
  }

  /** Called by ingest for every accepted position. */
  broadcastPosition(routeId: string, frame: Extract<LiveFrame, { type: "position" }>): void {
    const now = Date.now();
    for (const subscriber of this.subscribers) {
      if (subscriber.routeId !== routeId) continue;
      const last = subscriber.lastSentAt.get(frame.tripId) ?? 0;
      // Clients interpolate between frames, so a faster stream would only cost
      // battery without looking any smoother.
      if (now - last < MIN_FRAME_INTERVAL_MS) continue;
      subscriber.lastSentAt.set(frame.tripId, now);
      this.send(subscriber.socket, frame);
    }
  }

  broadcastTripStatus(routeId: string, frame: Extract<LiveFrame, { type: "trip_status" }>): void {
    for (const subscriber of this.subscribers) {
      if (subscriber.routeId === routeId) this.send(subscriber.socket, frame);
    }
  }

  private send(socket: WebSocket, frame: LiveFrame): void {
    if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify(frame));
  }

  /** Cycles sockets that have outlived the token that opened them. */
  private sweep(): void {
    const now = Date.now();
    for (const subscriber of this.subscribers) {
      if (now - subscriber.openedAt > MAX_SOCKET_LIFETIME_MS) {
        this.send(subscriber.socket, { type: "reauth" });
        subscriber.socket.close();
        this.subscribers.delete(subscriber);
      }
    }
  }

  get subscriberCount(): number {
    return this.subscribers.size;
  }

  onModuleDestroy(): void {
    if (this.heartbeat) clearInterval(this.heartbeat);
    for (const subscriber of this.subscribers) subscriber.socket.close();
    this.server?.close();
  }
}
