<!--
Sync Impact Report
- Version change: 2.0.0 → 3.0.0 (MAJOR: mobile framework redefined React Native → Flutter,
  language principle redefined from TypeScript-everywhere, single-source-of-truth principle
  redefined from shared Zod imports to backend-owned contracts with generated clients)
- Modified principles:
  - II. Strong Engineering Discipline (TypeScript-everywhere → per-stack language discipline)
  - III. Separate Mobile and Web Codebases (mobile: React Native/Expo → Flutter)
  - IV. Single Source of Truth for Data → IV. Single Source of Truth for Contracts
  - V. Test What Matters (example flow updated to trip tracking; non-semantic)
- Added sections: none
- Removed sections: none
- Other changes: Technology Constraints rewritten (languages split TS/Dart, Flutter mobile,
  Node.js backend resolved as the only backend option, tile-hosting rule added)
- Templates requiring updates:
  - ✅ .specify/templates/plan-template.md — Constitution Check gate is generic; no edit needed
  - ✅ .specify/templates/spec-template.md — no constitution-specific sections; no edit needed
  - ✅ .specify/templates/tasks-template.md — no constitution-specific sections; no edit needed
  - ⚠ README.md — describes the current Expo/React Native + Supabase-direct scaffold, which
    this amendment supersedes; update it when the repo is restructured (deferred intent, see
    Next Actions in the amendment summary — code changes are out of scope for this command)
- Follow-up TODOs: none
-->

# Namma Kasa Constitution

## Core Principles

### I. Simplicity and Elegance (NON-NEGOTIABLE)

Code MUST favor the simplest design that solves the problem at hand. Clear code beats
clever code: no premature abstraction, no speculative generality (YAGNI), no framework
features adopted without a present need. Functions stay small and single-purpose; modules
expose minimal surface area. If a reviewer needs a comment to understand a block, first
try rewriting the block. Any complexity that survives MUST be justified in the PR
description and in the plan's Complexity Tracking section.

### II. Strong Engineering Discipline

Each stack uses its language at maximum strictness: TypeScript strict mode for the
backend, web app, and shared packages (`any` forbidden except at typed third-party
boundaries, each use narrowly justified); Dart with strict analyzer options and null
safety for the mobile app. Lint, format, and static analysis MUST pass before merge — no
warnings suppressed without an inline reason. Errors are handled where they can be acted
on and surfaced honestly to users; silent catch-and-continue is forbidden. Names describe
intent; dead code is deleted, not commented out.

### III. Separate Mobile and Web Codebases

The mobile app and the web app are independent codebases in separate folders: the mobile
app is **Flutter** in `apps/mobile` (Android launch; iOS is a later build target of the
same codebase, never a rewrite); the web app lives in `apps/web` using React +
TypeScript, suited to public, shareable, server-rendered pages. Each app owns its UI code
outright; UI components MUST NOT be shared across the two apps. Behavioral consistency
between the apps comes from the backend contract (Principle IV), not from shared UI code.

### IV. Single Source of Truth for Contracts

The data model, validation rules, and API contracts are defined once in the Node.js
backend (Zod schemas in the shared TypeScript package, published as an OpenAPI
document). TypeScript consumers (web, backend modules) import the shared schemas
directly; the Flutter app consumes a **generated Dart client** derived from the OpenAPI
document. Hand-written duplicate models on any client are a defect. A contract change
MUST update the schema, regenerate clients, and update all consumers in the same change
set.

### V. Test What Matters

Business logic and shared schemas MUST have unit tests; critical user flows (trip
tracking and proximity notification end-to-end) MUST have integration coverage before
release. Tests accompany the change that makes them necessary — a bug fix without a
regression test is incomplete. UI snapshot churn is not a substitute for behavioral
assertions.

## Technology Constraints

- **Languages**: TypeScript for backend, web, and shared packages; Dart for mobile.
- **Mobile (Android)**: Flutter in `apps/mobile`; min Android 8 (API 26); iOS later from
  the same codebase.
- **Web**: React + TypeScript in `apps/web` (currently Next.js); server rendering for
  public, shareable pages.
- **Backend**: Node.js (TypeScript) modular monolith owning business logic and data
  access. PostgreSQL + PostGIS (with time-series extension where needed) is the
  datastore; managed services may back Postgres/auth/storage, but domain logic lives in
  the Node.js layer, not in clients.
- **Maps**: MapLibre GL with zero-cost tiles (self-hosted or free-tier providers);
  public osm.org tile servers are prohibited in production. Map SDK stays behind an
  internal abstraction so the provider can be swapped without an app rewrite.
- **Repo**: pnpm + Turborepo monorepo (`apps/*`, `packages/*`); the Flutter app lives in
  `apps/mobile` alongside the JS/TS workspaces.
- **Localization**: Kannada and English are both first-class in user-facing surfaces.

## Development Workflow

- Features follow the Spec Kit flow: `/speckit-specify` → `/speckit-plan` →
  `/speckit-tasks` → `/speckit-implement`; plans MUST pass the Constitution Check gate
  against this document.
- Quality gates before merge: `pnpm typecheck`, `pnpm lint`, and `pnpm build` green at
  the workspace root; `flutter analyze` and `flutter test` green in `apps/mobile`; new
  tests green.
- Work lands via small, reviewable changes on branches off `main`; commit messages
  explain why, not just what.

## Governance

This constitution supersedes ad-hoc practice. Amendments are made by editing this file
in a dedicated change that states the rationale and bumps the version per semantic
versioning: MAJOR for removing/redefining a principle, MINOR for adding or materially
expanding one, PATCH for clarifications. Every spec and plan MUST include a
constitution compliance check; violations are either fixed or explicitly justified in
Complexity Tracking. Reviews MUST reject changes that conflict with Principles I–V
without documented justification.

**Version**: 3.0.0 | **Ratified**: 2026-07-29 | **Last Amended**: 2026-07-29
