# BeeMoo — design handoff to Claude Code

## Overview
BeeMoo is a subscription speech-and-language practice app for young children. This bundle
specifies the native iOS app: a home page of four umbrellas, an activity list per umbrella,
and activity runners. **How Much** (Words & Concepts) is fully specified — 36 screens teaching
nine quantity concepts. The other seven Words & Concepts activities are named but not yet designed.

## About the design files
The files in `prototype/` are **design references written in HTML** — a working prototype of
the intended look and behaviour, not production code to port. The task is to **rebuild these
designs in SwiftUI** using the repo's own patterns. Read the prototype to answer "how does this
behave", read the specs in `specs/` for structure and rules, and read `config/` for the actual data.

`prototype/` is a snapshot; art paths inside it resolve to `../art`. The canonical prototype
lives at the project root of the design workspace.

## Fidelity
**High-fidelity.** Colours, typography, spacing, radii and shadows in `tokens.md` are final and
should be matched. Layout proportions are final. What is *not* final: the art itself (see
`config/art-manifest.json`), and two known defects listed under Open items.

## Decisions already made
| Area | Decision |
|---|---|
| Repo | `beemoo-official/BeemooArticulation` stays the master app; target name is not being changed |
| UI framework | SwiftUI |
| Devices | iPhone + iPad |
| Orientation | Shell is portrait; **activities are landscape-only** |
| Data | Backend-first. No local-only source of truth; SwiftData template scaffolding gets deleted |
| Backend | Custom API, **Django + Django REST Framework** |
| Content | Remote from day one; app ships without activity art |
| Offline | Cache-as-you-go — art caches after first view; new activities need network |
| Accounts | Parent-only for v1. SLP views deferred |
| Auth | Sign in with Apple + email |
| IAP | StoreKit 2 with server-side validation via App Store Server API |
| Narration | Third-party TTS API, streamed and cached per prompt |
| Art | SVG where the art allows, PNG for illustrations |
| Specs | Patterns, not screens — one doc per screen type; `config/` covers the per-screen data |

## Build order
1. **App shell + navigation** (`specs/00-app-shell.md`, `specs/01-home.md`, `specs/02-activity-list.md`).
   Home → Words & Concepts → activity list. No activity runner yet. Delete `Item.swift` and the
   SwiftData container in `BeemooArticulationApp.swift`; replace with an `APIClient` environment object.
2. **Activity runner** for How Much (`specs/03-activity-runner.md`), driven by `config/how-much.json`.
3. **Progress, modals, paywall** (`specs/04-progress-and-modals.md`, `specs/05-paywall-iap.md`).

## What lives where
- `tokens.md` — colours, type, spacing, radii, shadows, motion
- `specs/00-app-shell.md` — orientation control, navigation model, iPad
- `specs/01-home.md` — home page
- `specs/02-activity-list.md` — umbrella activity list
- `specs/03-activity-runner.md` — the six screen types, state machine, gating, settings effects
- `specs/04-progress-and-modals.md` — progress, rewards, tips, switch child, settings
- `specs/05-paywall-iap.md` — paywall and subscription
- `api/contract.md` — endpoints, models, auth, receipt validation, caching
- `config/activities.json` — umbrellas and the activity catalogue
- `config/how-much.json` — all 36 screens
- `config/art-manifest.json` — every asset, its kind, and whether it should be redrawn as SVG
- `art/` — current crops (reference quality, not final)
- `prototype/` — the HTML prototype

## Open items — do not silently resolve these
1. **Screen 8 (cat food, NONE)** — the source art shows two empty bowls, so the ONE and MANY
   distractors are indistinguishable. The trial is invalid until the art is regenerated. Flagged
   in `how-much.json` as `note`.
2. **Screens 21 / 22 (pitchers)** — the highlight ring position is a guess. Confirm which pitcher
   gets the ring before shipping.
3. **Seven remaining Words & Concepts activities** — listed in `activities.json` with
   `status: "stub"`. They have names and descriptions only. Do not invent their content.

## How this stays in sync
The design workspace and this repo share `design/`. Design changes land as commits to `design/`;
Claude Code implements against them. When Swift-side naming or structure changes, the design side
re-reads the repo and reconciles. The `config/*.json` files are the shared contract — same data
feeds the HTML prototype and the API. Keep the JSON shape stable; change it in one place.
