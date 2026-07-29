# Namma Kasa — mobile

Flutter app carrying both surfaces in one binary: **resident** (where is the auto,
when is it coming) and **driver** (run a trip, share position, report a problem).
Android is the launch target; iOS comes later from the same codebase.

Which surface a user sees is decided by the role on their account, chosen once at
the entry screen.

## Running

```sh
flutter run --dart-define=API_BASE=http://<LAN-IP>:4000/v1
```

Use your machine's **LAN IP**, not `localhost` — a phone or emulator resolves
`localhost` to itself. The API and its infrastructure must already be running;
see [../../docs/operations.md](../../docs/operations.md).

## Checks

```sh
flutter analyze
flutter test      # 28 tests
```

`flutter analyze` **excludes** `packages/namma_kasa_api`, the generated client.
Only `flutter test` compiles it, so analyze passing says nothing about whether
the generated code builds. Run both.

## Layout

```
lib/src/core/       API client, session, map, theme tokens, notifications
lib/src/resident/   home + live map, feedback, alert settings, proximity maths
lib/src/driver/     home, trip tracker, ping spool, photo capture, issue report
lib/l10n/           English and Kannada ARB files
packages/           generated API client — never edited by hand
```

## The generated API client

`packages/namma_kasa_api` is generated from the backend's OpenAPI document.
**Editing it is a defect.** Change the Zod schema in `packages/shared` and run
`pnpm contracts:generate` from the repo root.

Transport stays on Dio rather than the generated client's `http`, because the
interceptor that silently rotates the 15-minute access token lives there.

## Things worth knowing

**The ping spool is unbounded for a trip's duration.** A driver through a dead
zone must not lose the trail — the trail is the evidence that collection
happened. It replays in sequence order on reconnect.

**Background tracking dies quietly on most Indian handsets.** OEM battery
managers kill unexempted apps regardless of Android's own exemption. The
first-run wizard reads `Build.MANUFACTURER` and shows that phone's steps; see
`lib/src/driver/oem_steps.dart`.

**Distance must agree with the server.** The server decides the proximity push
with `ST_DWithin` on a geography. `lib/src/resident/proximity.dart` computes the
map's label, and the two disagreeing means the resident is told two different
things about the same auto.

**Both languages are load-bearing.** English and Kannada are a requirement, not
polish. The resident's choice is stored server-side, because the same value picks
the language of their push notifications.
