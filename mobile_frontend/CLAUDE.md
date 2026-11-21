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
- **Captains only (D-A42):** this Flutter app serves captains. Admin and
  Merchant use separate web portals; never add their routes, destinations or
  screens here.
- **No backend yet:** the backend architecture is approved (D-A53–D-A56) but
  not built, and concrete OpenAPI endpoints/DTOs are not written. Never
  invent endpoints, payloads, tokens or rules.
- **Authority:** the latest explicit owner approvals in
  `docs/decisions/ARCHITECTURAL_DECISIONS.md` (§1.1 and the resolution
  ledger) and `docs/project/PRODUCT_OVERVIEW.md` govern intended behavior.
  `docs/project/PROJECT_STATUS.md` plus inspection of the source govern what
  actually exists. An approved target is not proof of implemented code.
  Historical prompts, archive material and C-entries are not implementation
  contracts.

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
   Mention any deletion in the plan. **Standing approval (D-A79, 2026-11-20):**
   the removals and public-API changes of the client revision (notification
   feed, recharge UI and its contact helper, five-tab/center-button/unread/
   active-order navigation inputs, Home Profile button, `/profile` overlay,
   commission-hold fields and logic, exclusively orphaned dependencies) are
   authorized; delete them fully — no commented-out code, hidden routes or
   stubs. Other deletions still need approval.
6. **Never claim** something works, or a test passed, unless you ran it.
7. **Pending decisions:** don't make decisions marked Pending in
   `docs/decisions/ARCHITECTURAL_DECISIONS.md`. Ask instead.

## 3. Tech stack

- Flutter and Dart with null safety.
- State: `flutter_bloc` (Cubit and Bloc).
- Navigation: `go_router`.
- Connectivity: `internet_connection_checker_plus`.
- Localization: `gen_l10n` (ARB). Responsive: `responsive_framework`.
- Navigation icons: `phosphor_icons` (D-A37).
- Dependency injection (D-A17, D-A64): approved target is `get_it`
  registrations at the composition root (feature registration modules
  allowed), with constructor injection into repositories, use cases and
  Cubits; no `get_it` lookups inside them and no `injectable` code
  generation. The current code still uses plain constructor wiring from
  `lib/main.dart`; migrate only in a task that asks for it.
- **Packages:** recommend one only with a reason (problem solved, why it fits,
  lighter alternatives, and `flutter pub add` command). Install only after
  approval.
- **Declared packages:** approval is specific, not blanket. Google Maps
  Flutter/Routes, `location`, `permission_handler` and `url_launcher`
  (external navigation) are approved for their feature tasks (D-A57, D-A62).
  Remove a declared package only after auditing `lib/`, `test/`, the
  Android/iOS folders and transitive needs (D-A64, `docs/architecture/ARCHITECTURE.md` §6).
  Never change dependencies outside a task that asks for it.

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
- **Authenticated scope:** `CurrentOrderCubit` (with active-order recovery)
  is shared by the shell, the standalone Current Order page and the offer
  flow; it survives tab changes and closes on sign-out (D-A73).
- **Feature Cubits** (Login, Create Order…) stay scoped to their feature.
  There is no `NotificationsCubit` (feature removed, D-A72).
- **No `AppUserCubit`:** the current user lives in `AppSessionCubit`.
- Model loading, success, empty and failure states explicitly.

Details: `docs/architecture/STATE_MANAGEMENT.md` (§3.4: screen composition vs Cubit
state vs lifecycle/presentation effects, with Home as the example).

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
- **Main shell (D-A70):** four branches of one
  `StatefulShellRoute.indexedStack`, in RTL reading order: 0 Home `/home`,
  1 My Orders `/order-history`, 2 Wallet `/wallet`, 3 My Account `/profile`.
  `MainNavDestination`, the branch list and `mainShellRoutes` keep this
  order; never assume five items or a center index. `AppNavBar` is the
  shell; the visual `MainNavigationBar` knows no routes or feature state and
  has no unread/active-order inputs. No `NavBarCubit`.
- **Current Order (D-A41 meaning, D-A73 placement):** protected standalone
  page `/current-order` outside the tabs, Back returns to Home. It opens
  after a confirmed instant acceptance for the matching `orderId`, and
  recovery re-reads the server's active order on startup and foreground
  return (coalesced, session-guarded; failure ≠ "no order"). It never
  creates an order; the destination is the restaurant, never the customer.
  The server decides what is active; never fake an order, coordinate or map.
- **No Notifications route or feed (D-A72).** Operational order push stays a
  hint to re-read offers/orders.
- **Debug preview (temporary, D-A40):** the only unauthenticated way into the
  shell, and only under `kDebugMode`. Never widen it; remove it when sign-in
  is real (`TODO(debug-preview)`).

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

- **Colors and typography (D-A69):** white backgrounds, red primary
  actions, black/gray tabs, semantic green only for available/success and
  semantic red for errors/destructive actions. Colors come from `AppColor` /
  `ThemeData`; typography from `TextThemeStyle` and the shared text widgets.
  No color literals in screens.
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
- **Custom widgets:** prefer built-in composition and `ThemeData`; make
  only essential inputs `required`; no speculative API, style classes or
  Cubits, and no duplicate preview implementation. Read
  `docs/ui/CUSTOM_WIDGET_CONTRACT_STANDARD.md` (incl. its approval gate)
  before implementing.
- **RTL:** comes from the Arabic locale; use start/end, never left/right.

Details: `docs/ui/DESIGN_SYSTEM.md` and
`docs/ui/SHARED_UI_COMPONENTS_REFERENCE.md`.

## 9. Product rules that code must respect

- **Order states and wallet rules:** listed in
  `docs/project/PRODUCT_OVERVIEW.md`. Don't rename or skip states.
- **Wallet (D-A74–D-A76):** money in fils, never `double`. **No commission
  holds** anywhere. One global, admin-set commission % of the delivery fee,
  snapshotted on the order; the server debits it **once** on confirmed
  delivery completion (never on accept/decline). One balance, no
  held/available fields. Maximum resulting balance after a recharge is
  **5,000 fils**, enforced by the server only; the app shows authoritative
  values faithfully and never clamps. Recharges are credited only after
  Admin confirmation; the captain UI has no recharge action and lists only
  commission debits, plus lifetime delivered-count and earnings cards
  (earnings formula pending, D-P36).
- **Profile and deletion (D-A77, D-A78):** «حسابي» tab with name, phone,
  rating, Settings / Terms / About; account deletion only after explicit
  confirmation through a repository port; never fake a deletion.
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
  production code (the debug preview, D-A40, creates no session).
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
| Business logic (orders, wallet, dispatch, eligibility, profile, deletion) | `docs/project/PRODUCT_OVERVIEW.md` |
| Navigation, startup, login, logout | `docs/architecture/ROUTING_AND_STARTUP.md` |
| Connectivity, session, current user, lifecycle | `docs/architecture/GLOBAL_SERVICES.md` |
| Forms and validation | `docs/ui/SHARED_UI_COMPONENTS_REFERENCE.md` §7 |
| New or changed shared widget | `docs/ui/CUSTOM_WIDGET_CONTRACT_STANDARD.md`, `docs/ui/SHARED_UI_COMPONENTS_REFERENCE.md` |
| Any release-related task (store builds, signing, permissions, GPS, push, privacy/legal links, metadata) | `docs/release/STORE_SUBMISSION_COMPLIANCE.md` (consult **before** starting; re-verify store policies against the official sources it lists) |
| History of requirements | `docs/archive/` |

Full index: `docs/README.md`.
<!-- SHAHM_DEMO_START claude-removal -->

## SHAHM DEMO REMOVAL CONTRACT (Task 37)

A debug-only demonstration mode is installed (`lib/demo/`, fixtures in
`assets/demo/fixtures/`, started with
`flutter run --debug --dart-define=SHAHM_DEMO=true`).

When the owner says «احذف الديمو», «إزالة الوضع التجريبي» or
“REMOVE SHAHM DEMO”, run from `mobile_frontend/`:

```bash
bash tool/demo/remove_demo.sh --dry-run
bash tool/demo/remove_demo.sh --apply
```

- Follow the script's safety checks; NEVER `git reset`, `git checkout` or
  `git clean` owner changes.
- Verify `flutter analyze`, `flutter test` and that no demo UI, wiring,
  route, flag, fixture import or asset reference remains.
- The removal is preauthorized by the owner's Task 37 request; stop and
  report only if an owner-edited conflict makes it unsafe.
- Remove the demo before any store or release build: its fixtures are
  declared assets and would be packaged.

<!-- SHAHM_DEMO_END claude-removal -->
