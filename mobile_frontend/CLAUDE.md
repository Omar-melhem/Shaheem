# CLAUDE.md — SHAHM Flutter App

Permanent instructions for Claude Code in `mobile_frontend/`. Keep this file
short. Details live in `docs/` (see the index at the end). **Read the docs
listed for your task before implementing anything.**

## 1. Project identity

- **SHAHM (شهم)** is a delivery-operations platform connecting merchants
  (restaurants, cafés, stores…) with delivery captains, managed by an Admin.
  See `docs/project/PRODUCT_OVERVIEW.md`.
- This folder is the **Flutter mobile app**. The React web prototype in
  `../web_frontend/` is a separate project with its own `CLAUDE.md`.
- **UI:** Arabic only, RTL. Default geography: Amman, Jordan. Currency: JOD
  (د.أ).
- **Target roles still pending:** which roles the mobile app serves is
  undecided. Don't assume captain-only or multi-role.
- **No backend yet:** never invent endpoints, payloads, tokens or rules.

## 2. Working approach

1. Act as a senior Flutter engineer. Work **one screen or feature at a time**,
   and only what was requested.
2. **Inspect existing files first.** Reuse before creating, and never
   duplicate a service, Cubit, widget or helper.
3. **Plan before coding.** List the files you'll touch, the state manager
   choice, the layers involved, and any package.
4. **Ask** (one direct question) only when ambiguity blocks a correct
   implementation.
5. **Never delete, rename or broadly refactor** without the user's approval.
   Mention any deletion in the plan.
6. **Never claim** something works, or a test passed, unless you ran it.
7. **Pending decisions:** don't make decisions marked Pending in
   `docs/decisions/ARCHITECTURAL_DECISIONS.md`. Ask instead.

## 3. Tech stack

- Flutter and Dart with null safety.
- State: `flutter_bloc` (Cubit and Bloc).
- Navigation: `go_router`.
- Connectivity: `internet_connection_checker_plus`.
- Localization: `gen_l10n` (ARB). Responsive: `responsive_framework`.
- Dependency injection: plain constructor injection from `lib/main.dart`.
  **No DI package** until one is approved.
- **Packages:** recommend one only with a reason (problem solved, why it fits,
  lighter alternatives, and `flutter pub add` command). Install only after
  approval.
- Declared-but-unused packages (maps, http…) are Pending (D-P12): don't use.

## 4. Architecture (Clean Architecture, adapted)

```text
lib/
├── data/     DTOs/models, data sources, repository implementations, mapping
├── domain/   entities, repository contracts, use cases, typed errors (no Flutter)
├── helper/   app-level service integrations (e.g. network monitor)
├── theme/    colors, typography, ThemeData
├── util/     constants, strings, routes, validators, UI tools
└── view/     screens, widgets, Cubits/Blocs, app-level state (view/app_state/)
```

- **Dependency direction:** `view → domain ← data`. Domain never imports
  Flutter, `data` or `view`.
- **No business logic in widgets.** Widgets render state and dispatch
  actions.
- **Cubits/Blocs call use cases.** They never call APIs or storage directly.
- **No new top-level folders** without approval.
- Use `snake_case` files, lowercase folders, `PascalCase` classes, and
  `camelCase` members.

Details: `docs/architecture/ARCHITECTURE.md`.

## 5. State management

- **Cubit** for simple state. **Bloc** only for multi-event or complex
  workflows. Never use state management for static constants.
- **App-level state** (one instance, created in `MainApp`, provided above the
  router): `AppConnectivityCubit`, `AppSessionCubit`, plus `SplashCubit` for
  startup orchestration.
- **Feature Cubits** (Login, Create Order…) stay scoped to their feature.
- **No `AppUserCubit`:** the current user lives in `AppSessionCubit`.
- Model loading, success, empty and failure states explicitly.

Details: `docs/architecture/STATE_MANAGEMENT.md`.

## 6. Routing

- `go_router`:
  - Paths: `lib/util/routes/routes_string.dart`.
  - Router: `lib/util/routes/go_router.dart` (`createAppRouter`).
- **One redirect policy:** `resolveRedirect` in `route_guard.dart` is the only
  place startup and auth navigation is decided. Screens never call `go` for
  startup or auth flow.
- **Protected routes** open only when the session is authenticated and the
  profile is loaded.
- `context.go` replaces the location; `context.push` stacks a page.

Details: `docs/architecture/ROUTING_AND_STARTUP.md`.

## 7. App-level services

- **One internet monitor:** `InternetConnectionService` →
  `AppConnectivityCubit` → `GlobalConnectivityBanner`, mounted once in
  `MaterialApp.router`'s `builder`.
  - Screens read the state; they never start monitors or add banners.
  - Connectivity is feedback only, not an API-request gate.
- **Session and user:** `AppSessionCubit` holds the session and the user.
  - `CheckAuthStatus` and `GetCurrentUser` are reusable use cases.
  - Distinguish offline, check failed, backend unavailable, unauthenticated,
    blocked and invalid profile. Never collapse errors into "unauthenticated".

Details: `docs/architecture/GLOBAL_SERVICES.md`.

## 8. UI rules

- **Colors and typography:** colors come from `AppColor`; typography from
  `TextThemeStyle` and the shared text widgets.
- **Strings:** all UI text lives in `helper/translation/app_ar.arb`, read
  via `context.l10n`; never hard-coded. Never edit generated files.
- **Responsive:** breakpoints only in `AppBreakpoints` (registered once in
  `MainApp`). Adapt layout; forms scroll and cap their width.
- **Widget separation:**
  - Screen files only compose and coordinate.
  - Meaningful custom widgets go in separate files: feature widgets in
    `view/screens/<feature>/widget/`, cross-feature widgets in
    `view/widget/<category>/`.
  - Don't split trivial wrappers into files.
- **Reuse** shared widgets (`AppTextFormField`, `AppButton`,
  `AppTextButton`, `showAppPopup`, `showAppToast`, text widgets), tools and
  validators. Never put validators or business rules in `tools.dart`.
- **RTL:** comes from the Arabic locale; use start/end, never left/right.

Details: `docs/ui/DESIGN_SYSTEM.md` and
`docs/ui/SHARED_UI_COMPONENTS_REFERENCE.md`.

## 9. Product rules that code must respect

- **Order states and wallet rules:** listed in
  `docs/project/PRODUCT_OVERVIEW.md`. Don't rename or skip states.
- **Wallet (D-A29):** money in fils, never `double`; all holds and debits
  are server-side. One global, admin-set commission % of the delivery fee
  (no per-captain rates). On accept, the commission (not the fee) is held
  and snapshotted. Recharges are credited only after admin confirmation.
- **Server authority:** the server is the final authority for eligibility,
  acceptance, wallet and concurrency. Client checks are convenience only.

## 10. Code comments (mandatory)

Every new or materially changed meaningful component gets **English**
comments. That covers files, classes, public APIs, widgets, Cubit states and
transitions, business rules, error handling, repositories, models and tests.
- Explain **what, why, and how** when it isn't obvious.
- Use `///` for public APIs and `//` for internal reasoning.
- No filler comments, and no commented-out code.
- Update comments when behavior changes.

## 11. Testing and verification

After every change, in `mobile_frontend/`:

```bash
dart format <changed files>      # format only what you changed
flutter analyze
flutter test
```

- **Tests:** add or adjust them for domain rules, Cubits and key widgets.
  Use fakes from `test/fakes.dart`. Never put fake authenticated paths in
  production code.
- **Reporting:** report actual results. Separate existing issues from
  regressions. Never claim a device run or platform build that didn't
  happen.
- **Task report:** end each task with what was done, the files changed,
  packages, commands and results, what remains, and confirmation that
  comments are in English. Then wait for direction.

## 12. Documentation maintenance

- All Markdown is in **English**.
- **Updating docs:** when you change a public API, a responsibility, a
  decision or the project status, update the matching doc in the same task.
- **Decisions:** record each one in `docs/decisions/ARCHITECTURAL_DECISIONS.md`.
  Never mark a suggestion as Approved.
- **Status:** update `docs/project/PROJECT_STATUS.md` after each feature.
- **Archive:** superseded documents go to `docs/archive/`. Never delete
  documentation.

## 13. Documentation index — what to read for each task

| Task | Read |
|---|---|
| Any task | This file, `docs/project/PROJECT_STATUS.md`, `docs/decisions/ARCHITECTURAL_DECISIONS.md` |
| New screen or feature | `docs/architecture/ARCHITECTURE.md`, `docs/architecture/STATE_MANAGEMENT.md`, `docs/ui/DESIGN_SYSTEM.md`, `docs/ui/SHARED_UI_COMPONENTS_REFERENCE.md` |
| Business logic (orders, wallet, dispatch, eligibility) | `docs/project/PRODUCT_OVERVIEW.md` |
| Navigation, startup, login, logout | `docs/architecture/ROUTING_AND_STARTUP.md` |
| Connectivity, session, current user, lifecycle | `docs/architecture/GLOBAL_SERVICES.md` |
| Forms and validation | `docs/ui/SHARED_UI_COMPONENTS_REFERENCE.md` §7 |
| History of requirements | `docs/archive/` |

Full index: `docs/README.md`.
