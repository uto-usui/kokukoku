# Documentation Improvement Design

**Date:** 2026-02-25
**Status:** Approved
**Approach:** Minimal (A) — leverage existing structure, minimize new files

## Problem

Planning/strategy docs are excellent (~30 KB across ai/todo/). Code-level documentation is zero — no `///` comments on any public type or function across 2,000 LOC. No CHANGELOG or ADRs exist.

## Scope

### 1. CHANGELOG.md
- Keep a Changelog format (https://keepachangelog.com)
- Populate Unreleased section + reconstruct past milestones from git log
- Location: repo root

### 2. ADRs (3-5 records)
- Lightweight ADR format (Title, Status, Context, Decision, Consequences)
- Only decisions not obvious from reading the code
- Location: `docs/adr/`
- Initial ADRs:
  - 001: endDate-based time model (vs elapsed counting)
  - 002: SwiftData for persistence (vs UserDefaults, Core Data)
  - 003: BoundaryStopPolicy as enum with consumption semantics
  - 004: TimerEngine as pure stateless functions (vs methods on TimerStore)

### 3. API Documentation (`///` comments)
- **In scope:** Domain layer (TimerTypes.swift, TimerEngine.swift), Service protocols (NotificationServicing, FocusModeServicing)
- **Out of scope:** View layer, private helpers, TimerStore internals
- Follow Swift Documentation Markup conventions (Summary, Discussion, Parameters, Returns, Throws)

### 4. CLAUDE.md
- No separate ARCHITECTURE.md — CLAUDE.md continues to serve that role
- No changes needed for this effort

## Out of Scope
- DocC catalog
- View layer documentation
- TimerStore internal method docs
- Generating static doc sites

## Success Criteria
- `///` comments on all public types and functions in Domain/ and Service protocols
- CHANGELOG.md with meaningful history
- 3-4 ADRs covering non-obvious design decisions
- `make lint` still passes
