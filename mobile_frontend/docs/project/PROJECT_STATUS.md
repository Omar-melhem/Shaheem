# SHAHM Flutter — Project Status

**Documentation reconciliation: 2026-11-14.** This report describes the **last supplied Flutter code snapshot**, not a new build. Owner-approved target decisions through 2026-11-14 were documented only; source code, backend, device tests and dependency audits were **not** changed or rerun in this documentation pass. Earlier verification rows are historical, not current test results.

The current state of the Flutter app, last verified against source code on
**2026-11-11**. Product decisions were updated on **2026-11-12**. The Flutter
source tree (`mobile_frontend/`) was not included in the workspace used for
the 2026-11-12 and 2026-11-14 documentation-only updates, so those updates
changed documentation only; they do not claim that any newly approved feature
has been implemented or re-verified.

**Later read-only inspection (Task 01 preflight, 2026-11-14):** a repository
checkout containing the Flutter source was inspected without building or
running tests. Its code matched the snapshot described here (for example the
`/profile` branch, placeholder repositories, required-only Login validators,
no `get_it`, no bundled fonts). This was a source inspection only; the test
results in §5 remain historical.

Status key:
- **Implemented:** in the code and covered by tests.
- **Planned:** requested direction, not built.
- **Pending:** blocked on a decision.
- **Rejected:** decided against.

---

## 1. Implemented

| Area | What exists | Key paths |
|---|---|---|
| App composition | `main()` creates the services once. `MainApp` creates the app-level Cubits, provides them above the router, and owns the router and the lifecycle listener | `lib/main.dart` |
| Routing | 8 routes: 3 public (`/`, `/no-internet`, `/login`) and the 5 protected main-shell branches (`/home`, `/notifications`, `/current-order`, `/order-history`, `/profile`). A single redirect policy | `lib/util/routes/` |
| Main navigation (2026-11-11, D-A36; refined by R9) | `StatefulShellRoute.indexedStack` with five branches; `AppNavBar` shell (selection from the router, `goBranch`, system back, bar hidden with the keyboard); visual `MainNavigationBar` with the raised central **Current Order** button (map-pin icon), selected states, an unread-dot input (default: none; no data source yet), active-order and loading inputs fed by `CurrentOrderCubit`, two-line labels instead of shrinking, RTL, safe area applied once, accessibility | `lib/view/navigation/`, `lib/view/widget/navigation/` |
| Current Order (2026-11-11, D-A41) | **Structure only; not functional end to end.** `CurrentOrderScreen` + shell-scoped `CurrentOrderCubit` with distinct states: loading, no active order, backend not connected (no Retry), failure with Retry, and the active order's pickup view (restaurant card, captain-location status, map area; the map area says when the restaurant location is unavailable). Domain boundaries `ActiveOrderRepository` / `GetActiveOrder` and `CaptainLocationRepository` / `GetCaptainLocation`, each with a placeholder that reports "not configured". **A real run shows «خدمة الطلبات غير مفعّلة في التطبيق بعد»**; the other states are reachable only with test fakes. No map widget, route, location provider or permission exists | `lib/view/screens/current_order_screen/`, `lib/domain/`, `lib/data/repositories/` |
| Home header and availability (Task 24, 2026-11-15) | **UI and orchestration implemented; availability API-blocked.** App bar: «الرئيسية» when it fits, read-only total wallet chip (integer fils → JOD, «—» + "unavailable" label without data, never 0.000; no action until a Wallet route exists); no Profile button (still the fifth tab, D-A66 pending). Body: greeting from `AppUser.displayName` (no-name fallback; debug preview has no user) and availability card with `AppAvailabilityToggle`. `HomeAvailabilityCubit` + domain ports `CaptainAvailabilityRepository`, `AvailabilityPermissionGateway`, use cases; Available only after backend confirmation. **A real run shows «تفعيل استقبال الطلبات غير متاح بعد…» with the toggle disabled** (both placeholders report "not configured"; no prompt ever appears) | `lib/view/screens/home_screen/`, `lib/view/widget/toggle/`, `lib/domain/`, `lib/data/repositories/`, `lib/helper/money/` |
| Home pending offers (Task 26, 2026-11-15) | **UI and orchestration implemented; offers API-blocked.** Section «طلبات بانتظار القبول» below the availability card: a lazily built `SliverList` of `AppOrderOfferCard` (any number of offers, full width inside the screen padding, content height); count only from a server list; distinct loading / not connected / no session / confirmed empty / offline / failure states; accept/decline server-confirmed only (one at a time; stale or unknown outcomes disable the card until refresh); a confirmed accept asks Current Order to refresh. `OrderOfferRepository` (TO SPECIFY) with a "not configured" placeholder: **a real run shows «خدمة الطلبات غير متصلة بعد…» and no cards**. Standalone design preview: `flutter run -t lib/preview/home_offers_preview.dart` (sample data only, caption «معاينة تصميم — بيانات افتراضية», commands report "nothing sent") | `lib/view/screens/home_screen/`, `lib/view/widget/order/`, `lib/domain/`, `lib/data/repositories/`, `lib/preview/` |
| Debug-only preview (**temporary**, D-A40) | Login button «معاينة التطبيق» opens the real shell in debug builds without any session. Remove when a real sign-in exists (`TODO(debug-preview)`) | `lib/util/routes/debug_shell_preview.dart`, `route_guard.dart`, Login |
| Startup flow | Internet check → `CheckAuthStatus` → `GetCurrentUser` → session published. Recoverable error states with Retry. Stale-result protection | `lib/view/screens/splash_screen/cubit/` |
| Connectivity | One monitor, an app-wide Cubit, pause and resume with the lifecycle, a global offline banner | `lib/helper/network/`, `lib/view/app_state/connectivity/` |
| Session | `AppSessionCubit` (unknown, unauthenticated, authenticated(user)), `endSession()` | `lib/view/app_state/session/` |
| Auth domain | `AppUser`, typed auth exceptions (including invalid credentials, network unavailable and backend not configured), `AuthRepository` contract (including `signIn`), `CheckAuthStatus`, `GetCurrentUser`, `SignIn`, `SignOut` | `lib/domain/` |
| Auth data | **Temporary placeholder:** always "no stored session"; `signIn` reports "backend not configured"; no network, no fake user. `AppUserModel` with identifier validation (no JSON parsing yet) | `lib/data/` |
| Screens | Splash (logo, progress, errors), No Internet, **Login (complete UI + `LoginCubit`, 2026-11-11)**: username and password, password toggle, inline field errors (required, plus the D-A65 username length/character and password length rules with the owner-approved Arabic wording, Task 03), error toasts, forgot-password action directly under the password field, username typed LTR with autocorrect/suggestions off and both fields on the shared field style (Task 11), a Terms & Conditions action that opens in-app only (URL **not yet provided**, so it shows a "not available yet" popup; Task 13), no-account action with its create-account popup (D-A39), responsive layout. Home (**empty shell**, now branch 0 of the main shell). **Placeholders only** (title + under-construction state, no business logic): Notifications, Order History, Profile. Current Order: see its own row | `lib/view/screens/`, `lib/view/navigation/` |
| Localization | gen_l10n, Arabic-only and default (`app_ar.arb`, generated `AppLocalizations`). All screens and shared widgets migrated; `AppStrings` removed. RTL comes from the locale | `l10n.yaml`, `lib/helper/translation/` |
| Responsive | `responsive_framework` 1.5.1. Breakpoints defined once (`AppBreakpoints`) and registered in `MainApp`. Login, No Internet and the Splash status use the shared width and padding helpers | `lib/util/responsive/`, `lib/main.dart` |
| Design tokens | `AppColor` (palette taken from the web prototype, not finalized for Flutter (D-P18), plus an extra color block awaiting review (D-P21)), `AppTheme.light`, `TextThemeStyle`, `AppImages` | `lib/theme/`, `lib/util/` |
| Shared UI | 11 text widgets on `AppTextWidget`; **`AppTextFormField` (contract refactored in Task 08, 2026-11-14: required non-blank `label`, behavior arguments plus one `AppTextFieldStyle` for appearance, collision asserts), `AppButton`, `AppTextButton`, `AppPopup`/`showAppPopup`, `AppToast`/`showAppToast`** (2026-11-11); `AppTools` (loading, dialogs and toasts delegating to the new components, bottom sheet, unfocus); `AndroidLoading`, `IosLoading`, `CustomePadding`; `MainNavigationBar`, `MainNavDestination`, `UnderConstructionPlaceholder`, `AppStatusMessage` (2026-11-11) | `lib/view/widget/`, `lib/util/tools/` |
| Validators | Required, phone and optional phone (10 digits), and the **D-A65 Login rules (Task 03, 2026-11-14)**: username outer-trimmed, a 10-digit Arabic-Indic/Extended/mixed phone converted to Latin digits (`normalizeLoginUsername`), `[A-Za-z0-9_.]` then 4–30 length; password 8–128, never trimmed, no weak-password check at sign-in. Localized messages. Login validates and submits the same normalized username | `lib/util/validators/` |
| Assets | `assets/images/png/shahm_logo.png` (official transparent logo), registered in `pubspec.yaml` | `assets/` |

**Not implemented:**
- Any real backend call or credential storage. Login is fully built but
  can't succeed in a real run: the placeholder reports "backend not
  configured" (D-A35).
- Orders, offers, wallet, maps, GPS, notifications.
- Notifications and Order History remain placeholders. The current Profile
  placeholder is also still in code, but its approved replacement is Wallet
  (D-A50), which has not been implemented.
- **Current Order's data and map:** no orders backend or active-order
  contract (D-P25), no map provider, API key or map widget (D-P27), no
  location provider or platform permission (D-P28), no route line and no
  external navigation (D-P29). In a real run the destination can only say
  that the orders service isn't connected, and the bar never shows the
  active-order look.
- A data source for the unread dot (D-P24).
- The Wallet destination/screen, AppBar balance, ledger and manual recharge
  notification flow (approved target D-A50, not implemented).
- Instant-order broadcast and progressive concurrent dispatch (D-A45–D-A46).
- Scheduled-order Admin/WhatsApp workflow and future-commitment display
  (D-A47).
- Background GPS tracking and push notifications (D-A48; platform/provider
  implementation pending; providers now approved D-A57–D-A58).
- Post-pickup Admin incident handling and direct reassignment (D-A51).
- Route line, distance and duration for car deliveries (D-A52; provider
  implementation/configuration pending; Maps/Routes now approved D-A62).

## 2. Planned (next likely steps; not started)

- **Backend direction (approved, D-A43, D-A53–D-A56):** ASP.NET Core Web API,
  ASP.NET Identity, PostgreSQL/EF Core, REST `/api/v1` with OpenAPI, the
  JWT/refresh/one-device session model and RFC 9457 errors are approved
  (ledger D-P02). No backend has been implemented yet, and the concrete
  OpenAPI endpoints, DTOs, auth scopes and SignalR event schemas are not yet
  written; Flutter integration and code migration are not implemented.
- **Real sign-in:** an API-backed `AuthRepository` (`signIn`,
  `validateSession`, `getCurrentUser`) plus secure credential storage.
  Approved architecture under D-A53–D-A56; **blocked on implementation and concrete OpenAPI contract**, not on owner permission.
- **Login field rules (D-A65 and its supplement):** client-side validation
  **implemented and tested in Task 03** (see §1 Validators and §5). Still
  not implemented: the backend Identity rules, Admin account creation/reset,
  and the backend common/weak-password policy for create/reset, whose
  policy/list is still to be specified.
- **401 handling:** an HTTP client layer that classifies failures and calls
  controlled refresh on expired access tokens, then `AppSessionCubit.endSession()`
  on confirmed revoked/failed refresh. **Do not log out on every 401
  without checking refresh**. Server integration not implemented.
- **Tab features:** the real Notifications and Order History screens, plus
  the approved Wallet screen replacing the current Profile placeholder
  (D-P07, D-A50). The Flutter app is captain-only (D-A42).
- **Current Order, in this order:** an API-backed `ActiveOrderRepository`
  once the contract exists (D-P25); a map widget for `PickupMapBuilder`
  (D-P27); a location implementation of `CaptainLocationRepository` plus the
  platform permissions (D-P28).
- **Unread indicator:** connect `unreadCount` in `AppNavBar` once
  notification state exists (D-P24).
- **Remove the debug preview** (D-A40) when real sign-in works.
- Implement the approved captain Wallet navigation/screen and server-backed
  wallet data (D-A50, D-P10).
- Implement the approved instant dispatch, scheduled commitment and
  post-pickup reassignment flows only after the corresponding backend contracts
  are defined (D-A45–D-A51, D-P02, D-P25, D-P32).
- **Implement the approved** Google Maps/Routes, `location` +
  `permission_handler`, FCM/APNs and their platform configuration; validate
  on real Android/iOS devices. No provider selection is pending.

## 3. Approved target backlog versus genuinely unspecified technical details

**Owner approvals are not blockers:** D-P02–P33 now have owner-approved
business/architecture resolutions, except deferred D-P19. Consult
`ARCHITECTURAL_DECISIONS.md` §1.1/§3 and `PRODUCT_OVERVIEW.md`.

| Priority | Implementation/specification item | Current status |
|---|---|---|
| 1 | ASP.NET Core Identity/PostgreSQL REST API, OpenAPI concrete DTOs and policies, JWT 15-min/rotating 90-day refresh/one-device/suspension, RFC 9457 errors | Approved architecture, **not implemented** |
| 2 | Atomic dispatch + wallet (20%, nearest-fils, -1,000-fils floor, scheduled immediate hold, post-pickup pending settlement, idempotency, outbox) | Approved business rules, **not implemented** |
| 3 | Public broadcast 5 km/10 km/all city, global OFF withdrawal, 2-minute private offers, scheduled commitment separation and 30-minute cutoff | Approved, **not implemented** |
| 4 | Flutter `get_it` composition, secure storage, backend repositories, available/active-order flows, Notifications Cubit, Wallet tab and AppBar/profile/menu | Approved, **not implemented** |
| 5 | GPS `location` + `permission_handler` 30s target/90s freshness, FCM/APNs, Google Maps + Routes API DRIVE, server geofence, external pickup navigation | Approved, **not implemented; device/config tests pending** |
| 6 | Bundled IBM Plex Sans Arabic, Ink text default, central AppColor scales and web synchronization, app display names, login validators, verified code cleanup | Approved, **not implemented** |
| 7 | Precise scheduled-future-commitment read model and activation, OpenAPI response schemas, SignalR event contracts; inspect separate web wallet contract | **Technical specification/verification still required**, not owner decisions to reinvent |
| 8 | Automated WhatsApp volunteer response deadline | **Not approved and not required** for manual MVP; Admin can close invitations manually |

No Flutter `dart format`, `flutter analyze`, `flutter test` or real-device
checks have been run in this documentation-only revision. Older test results
in §5 remain historical.

## 4. Known issues and housekeeping

| Item | Detail |
|---|---|
| Password length unit (owner decision required) | Flutter `Validators.loginPassword` counts Unicode code points (`runes.length`); ASP.NET Core Identity's `PasswordValidator` counts UTF-16 code units (`password.Length`), has no maximum, and rejects whitespace-only passwords. The units differ only for supplementary characters (e.g. emoji) at the 8/128 boundaries. Not changed; the backend contract must state one unit (Task 04 review) |
| Semantic status colors (owner decision required) | The `AppTextFormField` resting border now uses `AppColor.inputBorder` (`inkMuted`, 5.37:1 on white, 4.74:1 on cream; Task 10). Still open: the error color is Material's default `#B00020` (`AppTheme` sets no `error`) and the disabled border is the Material 3 fallback (`onSurface` alpha 97); exact semantic error/warning/success/disabled colors are **not approved**. Web token sources not synchronized |
| Unused legacy `SplashBloc` | `lib/view/screens/splash_screen/bloc/` is not used. It is the only `flutter analyze` finding (info: `meta` not a declared dependency). Removal **approved** (D-A64); inspect usage before deleting, retain SplashCubit. Not yet done |
| Fonts | **Resolved (Task 10, 2026-11-15):** IBM Plex Sans Arabic (official IBM release 1.1.0, SIL OFL 1.1) bundled in weights 300–700 and registered as `IBMPlexSansArabic`; theme, `TextThemeStyle`, text widgets and button labels use it. Not bundled: weights 100, 200 and 450 |
| Text colors | **Resolved (Task 10):** `TextThemeStyle` and every shared text widget default to Ink `#242424`, including `Headline4` |
| Layering | `util/tools/` imports widgets from `view/widget/` (a util → view dependency). Approved move to `view/widget/loading/`; not fixed in supplied source |
| Timing-based test | One service stream test in `test/connectivity_test.dart` uses real 60 ms delays and may be flaky on a slow CI |
| Temporary debug preview | Debug builds can open the main shell from Login without a session (D-A40). It is inert in profile and release builds, and must be removed once sign-in is real |
| History icon direction | Phosphor icons mirror in RTL, so the Order History arrow points clockwise in Arabic (C-22). Awaiting review |
| Device coverage of the navigation | Checked on an iPhone 17 simulator (portrait) only. Not checked on a device: Android, landscape, other screen sizes, and the keyboard (widget tests only) |
| Reference screenshot | No image was attached to R9 or R10. The review used the iPhone 17 simulator screenshots captured during R9 (error state at 9:18) |
| Platform coverage | One debug run on the iOS simulator (2026-11-11). No Android run, no physical device, no release build |
| Uncommitted work | As of 2026-11-11, most Flutter work is uncommitted. `docs/` is trackable again (C-38) but not yet added |

### Release compliance (pointer)

The canonical store-submission checklist is
`../release/STORE_SUBMISSION_COMPLIANCE.md` (Task 14, documentation only,
policy baseline 2026-11-15). It **lists requirements and evidence; it is not
implemented compliance work** and not store approval. It replaces the Task 13
legal-links table that was here (its items are rows P-01, P-04 and A-14
there). **Release readiness: BLOCKED.** Main blockers recorded there: no
Privacy Policy (URL or in-app link); no live backend or reviewer account;
placeholder screens and the Terms URL not yet provided; template package/bundle
IDs and app names; Android release signed with debug keys; no `INTERNET`
permission in the main Android manifest; the unused `location` plugin merging
precise-location and location foreground-service permissions (Android) while
iOS has no purpose strings; no physical-device or release-build testing.

### Custom widget inventory (Task 12, 2026-11-15; analysis only except `AppTextButton`)

Rules: `../ui/CUSTOM_WIDGET_CONTRACT_STANDARD.md`. One component per task. "R" = intrinsic `required`.

| Widget (path under `lib/view/widget/`) | Purpose | Arguments | Real consumers (`lib/`) | Redundant / dead / gaps | Tests | Priority |
|---|---|---|---|---|---|---|
| `AppTextFormField` + `AppTextFieldStyle` (`text_field/`) | Standard input | R `label`; behavior args; one `style` | Login (2 fields) | Migrated (Task 08, Task 11). Error/disabled colors still Material fallbacks (owner decision) | `custom_widgets_test` (27), Login | Done |
| `AppTextButton` (`buttons/`) | Low-emphasis action | R `label`, R nullable `onPressed`; `icon`, `iconPosition`, `color`, `textStyle`, `padding` | Login ×2, `AppPopup` secondary actions, Current Order Retry | Migrated (Task 12) | `custom_widgets_test` (14 + popup), callers | Done |
| `AppButton` (`buttons/`) | Primary filled action with loading | `label` **or** `child` (asserts), R nullable `onPressed`; `icon`, `iconPosition`, `isLoading`, `expand`, `width`, `height`, `padding`, `borderRadius`, `border`, `backgroundColor`, `foregroundColor`, `textStyle`, `loadingSemanticLabel` | Login, debug preview, `AppPopup`, `AppStatusMessage` | Migrated (Task 18): `textStyle` merges; color precedence `foregroundColor` > `textStyle.color` > onPrimary; long labels wrap (were truncated); asserts for blank label, label + child, expand + width, negative sizes. All arguments kept (unused ones are generic behavior). Open: icon-only `child` accessibility / `child` removal (owner) | `custom_widgets_test` (29), callers | Done |
| `AppPopup`, `AppPopupAction`, `showAppPopup` (`pop_up_screen/`) | Modal dialog with actions | `title`, `message`, `content`, `icon`, `actions`, `showCloseButton`, `maxWidth`; action: R `label`, `onPressed`, `isPrimary`, `isDestructive`, `closesPopup` | `tools.dart` (2 wrappers), Login forgot password, create account, Terms | Migrated (Task 17): keyboard/large-text layout fixed, debug asserts for empty popup, dead action and an undismissible popup. Destructive color is still Material `error` (unapproved token) | `custom_widgets_test` (popup + keyboard groups), Login | Done |
| `AppToast`, `showAppToast` (`toast/`) | Transient status message | R `message`, R `type`; `icon`, `actionLabel`, `onAction`, `onClose`; helper: `duration`, `showCloseButton` | `tools.dart` (4 wrappers), Login | Migrated (Task 19): asserts for action pairing, blank message/label, non-positive duration, unmounted context; action runs once and never from a closing or replaced toast; a burst shows only the latest; action wraps under the message instead of overflowing; height kept above the keyboard. All arguments kept. Open (owner): status colors (warning white on `sandDark` 3.29:1), action timeout under screen readers | `custom_widgets_test` (43), Login | Done |
| `AppStatusMessage` (`status/`) | Empty / error / loading / unavailable state | R `icon`, R `title`; `message`, `actionLabel`, `onAction`, `isLoading` | Current Order (6 call sites), `UnderConstructionPlaceholder` | Migrated (Task 20): asserts for `actionLabel`/`onAction` pairing (were dropped silently), blank title, empty/blank message. Layout, semantics, colors and callers unchanged. Open (owner): `icon` required while the spinner replaces it; loading has no semantic flag beyond the title | `custom_widgets_test` (36), Current Order, navigation | Done |
| `UnderConstructionPlaceholder` (`placeholder/`) | Placeholder tab body | R `icon`, R `message` | Notifications, Order History, Profile | Audited (Task 21): **no defect, no production change**. Thin wrapper justified (shared ARB heading, consistent layout/semantics via `AppStatusMessage`, whose blank-message assert covers it). Temporary by design and a store blocker. Noted: the screens' AppBar titles truncate at text scale 3 (screen-level, not this widget) | `custom_widgets_test` (6), navigation tests | Done |
| `MainNavigationBar`, `MainNavDestination` (`navigation/`) | Five-destination bar | R `selectedIndex`, R `onDestinationSelected`; `unreadCount`, `hasActiveOrder`, `isCheckingActiveOrder` | `AppNavBar` | Audited (Task 22): presentation-only boundary confirmed; asserts added for out-of-range `selectedIndex` and negative `unreadCount`. Fifth tab still Profile (D-A66 Wallet migration pending, not implemented). Open (owner): labels truncate with "…" at text scale ≥ 2 on 320/375 px (real font) | `main_navigation_bar_test` (39), navigation tests | Done (migration deferred) |
| `AppOrderOfferCard` (`order/`, new in Task 26) | One order offer with accept/decline | R `offer`, R nullable `onAccept`, R nullable `onDecline`; `busyAction`, `notice` | Home pending offers | New; presentation only, intents only, theme error red for «رفض», one semantics summary, wraps at text scale 3 | `home_offers_test` | Done |
| `AppAvailabilityToggle` (`toggle/`, new in Task 24) | Controlled switch row for an on/off command | R `value`, R nullable `onChanged`, R `label`; `supportingText`, `isBusy` | Home availability card | New; follows the standard (controlled value, intent callback, busy guard, one semantics node, 48 px) | `app_availability_toggle_test` (18) | Done |
| Text widgets `AppTextWidget`, `Headline1`–`6`, `BodyText1`/`2`, `Subtitle1`/`2`, `Caption` (`text/`) | Typed text presets | R `title`; `style`, `maxLines`, `overflow`, `textAlign`, `textDecoration`, `color`, `fontSize` (+ `fontWeight` on 4) | **None** in screens (tests only) | Migrated (Task 23): `style` now merges (precedence dedicated > style > default); dedicated params no longer ignored when `style` is set. API, defaults and one-line/ellipsis default unchanged. Open (owner): keep / replace with `Text` + theme / smaller set; `maxLines: null` cannot mean "unlimited" | `text_widgets_test` (77), `shared_widgets_test`, brand theme | Done (keep/remove decision pending) |
| `CustomePadding` (`padding/`) | Legacy padding wrapper | R `child`; `top`, `bottom`, `left`, `right` | `util/tools/android_loading.dart` only | Duplicates Flutter `Padding`; physical left/right, not logical; misspelled name. Part of the approved `util/tools` → `view/widget/loading/` move | None | With the loading move |

## 5. Latest verification

All commands run in `mobile_frontend/`.

| Date | Command | Result |
|---|---|---|
| 2026-11-11 | `flutter pub get` | OK (added `responsive_framework` 1.5.1 and the SDK `flutter_localizations`) |
| 2026-11-11 | `flutter gen-l10n` | OK: generated `lib/helper/translation/generated/app_localizations.dart` and `app_localizations_ar.dart` |
| 2026-11-11 | `dart format .` | Clean |
| 2026-11-11 | `flutter analyze` | 1 issue: the existing info in the unused `SplashBloc` (`depend_on_referenced_packages`, `meta`). No new issues |
| 2026-11-11 | `flutter test` | **170 passed, 0 failed** (11 test files), after the post-implementation audit. Before the audit: 165; before the Login task: 101 |
| — | Platform build or device run | **Not performed** |
| 2026-11-12 | Documentation-only decision update | Updated product/decision/status guidance. Flutter format, analyze, tests and device run **not performed** because `mobile_frontend/` source tree was not available in this workspace |

**Login validation task (Task 03), 2026-11-14** — run in this repository:

| Command | Result |
|---|---|
| `flutter gen-l10n` | OK: generated output gained only the 3 new keys (`usernameLengthInvalid`, `usernameFormatInvalid`, `passwordLengthInvalid`) |
| `dart format` (9 changed Dart files) | OK (2 test files reformatted) |
| `flutter test test/validators_test.dart test/login_cubit_test.dart test/login_screen_test.dart` | **89 passed, 0 failed** |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info (`depend_on_referenced_packages`). No new issues |
| `flutter test` (full suite) | **310 passed, 0 failed** |
| Platform build or device run | **Not performed** |

**Main navigation task (R8), 2026-11-11:**

| Command | Result |
|---|---|
| Baseline before the task: `flutter analyze` / `flutter test` | 1 existing info / 170 passed |
| `flutter pub add phosphor_icons` | OK: added `phosphor_icons` 3.0.1 |
| `flutter pub get` | OK |
| `flutter gen-l10n` | OK (17 new ARB keys) |
| `dart format .` | Clean (96 files, 0 changed) |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info. No new issues |
| `flutter test` | **237 passed, 0 failed** (13 test files) |
| Platform build or device run | **Not performed** |

**Active order and UI refinement task (R9), 2026-11-11:**

| Command | Result |
|---|---|
| `flutter pub get` | OK (no dependency change) |
| `flutter gen-l10n` | OK |
| `dart format .` | Clean (110 files, 0 changed) |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info. No new issues |
| `flutter test` | **278 passed, 0 failed** (14 test files) |
| `flutter run` (debug) on the iPhone 17 simulator, iOS 26.5 | Built and ran with a temporary, since-deleted entrypoint that injected fake data. Screenshots reviewed for Notifications, Current Order (empty, error, pickup view, loading) and Home with an active order |
| Android, physical device, release build | **Not performed** |

**Current Order review (R10), 2026-11-11:**

| Command | Result |
|---|---|
| `flutter gen-l10n` | OK |
| `dart format` (changed files) | Clean |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info |
| `flutter test` | **282 passed, 0 failed** |
| `git check-ignore -v mobile_frontend/docs/...` | Not ignored (exit 1). `ios/Podfile.lock`, `build/`, `.dart_tool/` still ignored |
| `git status` | 14 Markdown files under `docs/` show as untracked. Nothing committed |
| Simulator | Not re-run; the layout code was not changed |

Per-file counts from the last run (R10):

| File | Tests |
|---|---|
| `auth_use_cases_test.dart` | 16 |
| `connectivity_test.dart` | 16 |
| `current_order_test.dart` | 42 |
| `custom_widgets_test.dart` | 19 |
| `localization_responsive_test.dart` | 15 |
| `login_cubit_test.dart` | 19 |
| `login_screen_test.dart` | 25 |
| `main_navigation_bar_test.dart` | 24 |
| `main_navigation_test.dart` | 29 |
| `route_guard_test.dart` | 15 |
| `shared_widgets_test.dart` | 8 |
| `splash_cubit_test.dart` | 19 |
| `startup_flow_test.dart` | 18 |
| `validators_test.dart` | 17 |

`fakes.dart` (test doubles) and `test_app.dart` (the shared localized and
responsive test host) contain no tests.

**AppTextFormField contract refactor (Task 08), 2026-11-14** — run in this repository:

| Command | Result |
|---|---|
| `dart format` (3 changed Dart files) | OK |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info. No new issues |
| `flutter test test/custom_widgets_test.dart` | **43 passed** (the `AppTextFormField` group grew from 4 to 27 tests) |
| `flutter test test/login_screen_test.dart` | **28 passed** (Login regression; `login_form.dart` not edited) |
| `flutter test` (full suite, 16 files) | **334 passed, 0 failed** |
| `flutter gen-l10n` | Not needed (no ARB change) |
| Platform build or device run | **Not performed** for this task |

**Brand typography, colors and Login foundation (Task 10), 2026-11-15** — run in this repository:

| Command | Result |
|---|---|
| `flutter pub get` | Not run separately; `flutter analyze`/`test` resolved the new `fonts:` entry. `pubspec.lock` content unchanged (diff still only the earlier `phosphor_icons` entry) |
| `dart format` (changed Dart files only) | OK |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info. No new issues |
| `flutter test test/brand_theme_test.dart test/custom_widgets_test.dart test/shared_widgets_test.dart test/login_screen_test.dart` | **89 passed** (new `brand_theme_test.dart`: 10) |
| `flutter test` (full suite, 17 files) | **344 passed, 0 failed** |
| `git diff --check` | Clean |
| `flutter build ios --simulator --debug` + `simctl` launch on iPhone 17 (iOS 26.5) | Login screenshot: IBM Plex Sans Arabic glyphs, cream background, Ink heading, visible input borders, maroon button. Not observed: typing, errors, keyboard, popups. No Android or physical-device run |

**Login field consistency and username input (Task 11), 2026-11-15** — run in this repository:

| Command | Result |
|---|---|
| `dart format` (`login_form.dart`, `login_screen_test.dart`) | OK |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info. No new issues |
| `flutter test test/login_screen_test.dart` | **36 passed** (8 new: matching borders, username LTR with RTL label/error/icon, 5 usernames incl. `_ali`, `captain.`, `captain_01` and a phone in Latin and Arabic-Indic digits, password privacy/toggle) |
| Same LTR tests with `textDirection` temporarily removed | Failed as expected (all 5 username rendering tests), then the change was restored |
| `flutter test` (full suite, 17 files) | **352 passed, 0 failed** |
| `git diff --check` (touched files) | Clean |
| Platform build or device run | **Not performed** for this task (widget tests only) |

**Custom widget standard and `AppTextButton` pilot (Task 12), 2026-11-15** — run in this repository:

| Command | Result |
|---|---|
| Temporary probe test (deleted afterwards) on the pre-change `AppTextButton` | A color set only in `textStyle` rendered as primary; any `textStyle` dropped the w600 weight. Color, disabled state, icon placement (RTL/LTR), padding, 48 px minimum, semantics and 320 px / text scale 3.0 wrapping already worked |
| `dart format` (`app_text_button.dart`, `custom_widgets_test.dart`) | OK |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info. No new issues |
| `flutter test test/custom_widgets_test.dart test/login_screen_test.dart test/current_order_test.dart test/brand_theme_test.dart` | **145 passed** (`AppTextButton`: 14, replacing the earlier single test; 1 new `AppPopup` destructive-action test) |
| `flutter test` (full suite, 17 files) | **366 passed, 0 failed** |
| `git diff --check` (touched files) | Clean |
| Platform build or device run | **Not performed** for this task (widget tests only) |

**Login Terms & Conditions action (Task 13), 2026-11-15** — run in this repository:

| Command | Result |
|---|---|
| Plugin source review (`url_launcher` 6.3.3, `url_launcher_android` 6.3.33, `url_launcher_ios` 6.4.2 in the pub cache) | `LaunchMode.inAppWebView`: Android always starts the plugin's own `WebViewActivity` (Custom Tabs skipped), throws on failure, no external fallback, no JavaScript bridge or download handler; iOS presents `SFSafariViewController`, throws or returns false on failure, no fallback. The generic platform default reports only `platformDefault` as supported, so the app stops there |
| `flutter gen-l10n` | OK: generated output gained only the 3 new keys (`termsAndConditions`, `termsUnavailableMessage`, `termsOpenFailedMessage`) |
| `dart format` (touched Dart files) | OK |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info |
| `flutter test test/legal_page_launcher_test.dart` | **27 passed** (empty URL, 13 untrusted values, 4 unsupported platforms, unsupported mode, open/refused/error with a single attempt, the real adapter's exact channel request, no launch when support is unconfirmed) |
| `flutter test test/login_screen_test.dart` | **49 passed** (13 new Terms tests) |
| `flutter test` (full suite, 18 files) | **406 passed, 0 failed** |
| Pre-existing issue found | `AppPopup` overflows with the keyboard open at text scale ≥ 2.0 (Forgot Password too: 30 px at 2.0, 206 px at 3.0). Not changed (shared widget, out of scope); the Terms action hides the keyboard before showing a popup **Resolved in Task 17** (shared popup layout) |
| Android/iOS device or simulator run | **Not performed** for this task |

**Store submission compliance documentation (Task 14), 2026-11-15** — documentation only; no Dart, Gradle, Xcode, manifest or dependency change, no Flutter build or test run. Official Apple and Google pages re-read on 2026-11-15 (list in the checklist §11); the owner's reference snapshot `16_SHAHM_STORE_SUBMISSION_POLICY_REFERENCE_2026-11-15.md` cross-checked afterwards (same 13 sources; added the Terms-checkbox distinction and customer-phone/wallet data notes); repository evidence from `build.gradle.kts`, the Android/iOS manifests and `Info.plist`, `project.pbxproj`, `pubspec.yaml`/`pubspec.lock`, plugin manifests in the pub cache and `GeneratedPluginRegistrant.m`. Internal Markdown links checked by script.

**AppPopup keyboard overflow and contract (Task 17), 2026-11-15** — run in this repository:

| Command | Result |
|---|---|
| Baseline `flutter test test/custom_widgets_test.dart test/login_screen_test.dart` (before edits) | 106 passed |
| New reproducing tests on the **original** `AppPopup` | Overflow reproduced: **30 px at text scale 2.0, 206 px at 3.0** (320×568, 260 px keyboard), up to 1,308 px with a long title; 11 of the new tests fail on the original code |
| Root cause | `app_popup.dart` (original lines 103–149): in a `Column(mainAxisSize: min)` only the body was `Flexible`; icon, title and the action `Wrap` were inflexible, so they overflowed the height `Dialog` leaves after the keyboard inset |
| `dart format` (`app_popup.dart`, `custom_widgets_test.dart`, `login_screen_test.dart`) | OK |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info |
| `flutter test test/custom_widgets_test.dart test/login_screen_test.dart test/shared_widgets_test.dart` | **141 passed** |
| `flutter test` (full suite, 18 files) | **433 passed, 0 failed** |
| `git diff --check` | Task files clean; 2 pre-existing trailing-whitespace lines in `app_text_form_field.dart` (owner edit, untouched) |
| Device / simulator check | **Not performed** (opening the keyboard needs UI interaction not available here); widget tests only |

**AppButton contract (Task 18), 2026-11-15** — run in this repository:

| Command | Result |
|---|---|
| Baseline `flutter test test/custom_widgets_test.dart test/login_screen_test.dart test/brand_theme_test.dart test/current_order_test.dart` (before edits) | 185 passed |
| Temporary probe (deleted) on the original `AppButton` | `textStyle` dropped the bold weight; `textStyle.color` rendered as onPrimary; long labels truncated to one line with an ellipsis at 320 px (scale 1.0 and 3.0); label + child dropped the label silently; expand + width ignored width; blank label not caught. Worked: foreground/icon color, own icon color, disabled colors, background, padding, radius, border, width, minimum height, loading size/semantics |
| New tests on the **original** `AppButton` | 14 fail (all 9 long-label width/scale cases, blank label, label/child, color precedence, size/expand asserts, textStyle merge); all pass after the fix |
| `dart format` (`app_button.dart`, `custom_widgets_test.dart`) | OK |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info |
| `flutter test` (custom widgets, Login, brand theme, Current Order, shared widgets) | **217 passed** |
| `flutter test` (full suite, 18 files) | **457 passed, 0 failed** |
| `git diff --check` | Task files clean; 2 pre-existing trailing-whitespace lines in `app_text_form_field.dart` (owner edit, untouched) |
| Device / simulator check | **Not performed** (widget tests only) |

**AppToast contract (Task 19), 2026-11-15** — run in this repository:

| Command | Result |
|---|---|
| Baseline `flutter test test/custom_widgets_test.dart test/login_screen_test.dart test/shared_widgets_test.dart` (before edits) | 165 passed |
| Temporary probes (deleted) on the original `AppToast` | Action ran twice on a double tap and ran from a toast being replaced; a burst of three showed the stale middle toast and delayed the latest by 4 s; with an action the row overflowed at 320 px (scale 1) and at every width at scale 2–3, and at 375/450 px the message was squeezed into a sliver (toast up to full screen height); at 320×480 with the keyboard and scale 3 the toast went off screen (Scaffold assert) with the close button under the keyboard; label-only / callback-only actions and a blank message passed silently. Worked: icons, colors, white content, status announcement, 48 px close and action targets, RTL order, 4 s timeout, placement above the keyboard at normal size |
| New tests on the **original** `AppToast` | 22 fail (6 asserts, double tap, close-then-action, replaced action, burst, all 9 width/scale cases, all 3 keyboard cases); all pass after the fix |
| `dart format` (`app_toast.dart`, `custom_widgets_test.dart`) | OK |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info |
| `flutter test` (custom widgets, Login, shared widgets) | **202 passed** |
| `flutter test` (full suite) | **494 passed, 0 failed** |
| `git diff --check` | Task files clean; 2 pre-existing trailing-whitespace lines in `app_text_form_field.dart` (owner edit, untouched) |
| Device / simulator check | **Not performed** (widget tests only; native screen-reader announcements not verified) |

**AppStatusMessage contract (Task 20), 2026-11-15** — run in this repository:

| Command | Result |
|---|---|
| Baseline `flutter test test/current_order_test.dart test/main_navigation_test.dart test/main_navigation_bar_test.dart test/custom_widgets_test.dart` (before edits) | 236 passed |
| Temporary probe (deleted) on the original | Label-only and callback-only actions dropped silently; blank title and empty message rendered (empty message left a 32 px gap). Worked: icon/spinner swap, theme fonts and colors, one live-region label (title + message), silent spinner, named button, all 18 width/scale/height cases without overflow |
| New tests on the **original** | 4 fail (both pairing asserts, blank title, blank message); all 36 pass after the fix |
| `dart format` (`app_status_message.dart`, `custom_widgets_test.dart`) | OK |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info |
| `flutter test` (Current Order, navigation, navigation bar, custom widgets) | **272 passed** |
| `flutter test` (full suite) | **530 passed, 0 failed** |
| `git diff --check` | Task files clean; 2 pre-existing trailing-whitespace lines in `app_text_form_field.dart` (owner edit, untouched) |
| Device / simulator check | **Not performed** (widget tests only) |

**Still open from Task 19 (`AppToast`, not changed here):** warning toast white on `sandDark` is 3.29:1 (below 4.5:1); a toast with an action still times out under a screen reader; possible nested live-region announcement (device check).

**UnderConstructionPlaceholder audit (Task 21), 2026-11-15** — run in this repository:

| Command | Result |
|---|---|
| Baseline `flutter test test/main_navigation_test.dart test/custom_widgets_test.dart` (before edits) | 206 passed |
| Temporary probe (deleted) | Blank message rejected through `AppStatusMessage`; heading from ARB, exact message and icon passed through, no action/loading; the three screens at 320/375/450 px × scale 1/3 × 640/300 px height: no overflow, heading/message never truncated. Only the screens' AppBar titles truncate at scale 3 (outside this widget) |
| Production code | **No change** (no defect found) |
| New evidence tests | 5 (delegation, blank-message guard, each real screen at 320×300 scale 3) |
| `dart format` (`custom_widgets_test.dart`) | OK |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info |
| `flutter test` (navigation, custom widgets) | **211 passed** |
| `flutter test` (full suite) | **535 passed, 0 failed** |
| `git diff --check` | Task files clean; 2 pre-existing trailing-whitespace lines in `app_text_form_field.dart` (owner edit, untouched) |
| Device / simulator check | **Not performed** (widget tests only) |

**MainNavigationBar audit (Task 22), 2026-11-15** — run in this repository:

| Command | Result |
|---|---|
| Baseline `flutter test test/main_navigation_bar_test.dart test/main_navigation_test.dart test/current_order_test.dart` (before edits) | 95 passed |
| Temporary probes (deleted) | Out-of-range `selectedIndex` (−1, 7) silently selected nothing; negative `unreadCount` silently hid the dot. Boundary sound: no routing/Cubit/session in the bar; shell passes no `unreadCount`. With the **real font**, labels truncate with "…" at text scale ≥ 2 on 320 px (3 labels) and 375 px (Profile); no truncation at scale 1 or at 450 px. (The default test font draws glyphs as squares, so the earlier width tests could not see real truncation.) |
| New tests on the **original** bar | 2 fail (both asserts); 13 evidence tests pass on both (checking + active, repeated taps, real-font fit in RTL/LTR, scale cap) |
| `dart format` (`main_navigation_bar.dart`, `main_navigation_bar_test.dart`) | OK |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info |
| `flutter test` (navigation bar, navigation, Current Order) | **110 passed** |
| `flutter test` (full suite) | **550 passed, 0 failed** |
| `git diff --check` | Task files clean (both untracked, checked directly); 2 pre-existing trailing-whitespace lines in `app_text_form_field.dart` (owner edit, untouched) |
| Device / simulator check | **Not performed** (widget tests only) |

**Text widget family (Task 23), 2026-11-15** — run in this repository:

| Command | Result |
|---|---|
| Baseline `flutter test test/shared_widgets_test.dart test/brand_theme_test.dart` (before edits) | 18 passed |
| New `test/text_widgets_test.dart` (77 tests, real IBM Plex Sans Arabic) on the **original** code | 37 fail: for all 11 wrappers a `style` replaced the default (partial style lost weight/size/Ink; style values beat nothing), and `color`/`fontSize`/`textDecoration`/`fontWeight` were ignored when `style` was set. 40 pass on both (defaults, dedicated-only, alignment/forwarding, semantics, sizes) |
| Fix | `AppTextWidget.build`: default `.merge(style).merge(dedicated)`; protected `fontWeightOverride` hook (null by default) overridden in `Headline4`, `Headline5`, `BodyText1`, `BodyText2`. Other 7 wrappers untouched |
| After the fix | 77/77 pass; originals restored for a re-check: 37 fail again; fix restored byte-identical |
| `dart format` (5 source files, new test file) | OK |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info |
| `flutter test` (text widgets, shared widgets, brand theme) | **95 passed** |
| `flutter test` (full suite) | **627 passed, 0 failed** |
| `git diff --check` | Task files clean; new untracked test file checked directly; 2 pre-existing trailing-whitespace lines in `app_text_form_field.dart` (owner edit, untouched) |
| Device / simulator check | **Not performed** (widget tests only) |

**Owner proposal (not implemented):** the 11 wrappers have no production consumer. Options: (a) keep them as the typed presets; (b) use `Text` with `Theme.of(context).textTheme` (already IBM Plex/Ink) and delete the family; (c) keep a smaller semantic set (e.g. title / body / caption). (b) or (c) delete public classes and need approval; no call sites in `lib/` would change.

**Next candidate (recommendation only):** none of the shared widgets remain unaudited; open owner decisions are listed above (nav-label truncation, D-A66, text-widget keep/remove, toast colors).

**Home header and availability (Task 24), 2026-11-15** — run in this repository:

| Command | Result |
|---|---|
| Baseline `flutter test test/main_navigation_test.dart test/current_order_test.dart test/localization_responsive_test.dart test/startup_flow_test.dart` (before edits) | 104 passed |
| `flutter gen-l10n` (29 new ARB keys, copy pending owner/legal review) | OK |
| New `test/home_availability_test.dart` (Cubit flow, use cases, placeholders, JOD format) | 33 passed |
| New `test/app_availability_toggle_test.dart` (real font) | 18 passed |
| New `test/home_screen_test.dart` (real font; app bar, greeting, card, flow, resume, sizes, real `MainApp`) | 38 passed |
| Mutation: Cubit made optimistic (Available before the server answers) | 3 tests fail (all-granted, rejected, command failure); restored byte-identical |
| `dart format` (changed Dart files only) | OK |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info |
| `flutter test` (full suite) | **716 passed, 0 failed** |
| `git diff --check` | Task files clean; new untracked files checked directly (no trailing spaces, no raw bidi characters); 2 pre-existing trailing-whitespace lines in `app_text_form_field.dart` (owner edit, untouched) |
| Native files | **Not changed** (no manifest, `Info.plist`, Podfile, Gradle or dependency edit) |
| Device / simulator check | **Not performed**; real OS prompts, background behaviour and screen readers need a physical device |

**Home pending offers (Task 26), 2026-11-15** — run in this repository:

| Command | Result |
|---|---|
| Task 25 debug demo removed (`debug_demo/`, its test, 23 ARB keys, router argument, Home branch, docs) | No reference left in `lib/`, `test/`, `docs/`; the D-A40 Login preview kept |
| Baseline after removal `flutter test` | 716 passed |
| `flutter gen-l10n` (23 new offer ARB keys) | OK |
| New `test/home_offers_test.dart` (Cubit, use cases, placeholder, card, Home section, real app, preview) | 56 passed |
| Mutation: card removed on tap (optimistic) | 9 tests fail; restored byte-identical |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info |
| `flutter test` (full suite) | **772 passed, 0 failed** |
| `git diff --check` | Task files clean; new untracked files checked directly; `web_frontend/src/main.tsx` blank line at EOF is an owner edit (untouched) |

**Home architecture refactor (Task 27), 2026-11-15** — run in this repository:

| Command | Result |
|---|---|
| Baseline targeted tests (Home, offers, availability, toggle, navigation, Login, Current Order) before edits | 269 passed |
| Refactor | `home_screen.dart` 643 → 83 lines, now a `StatelessWidget`; 9 section files in `home_screen/widget/`; moved classes verified identical except added `super.key` and the chip's local text measurement |
| Same targeted tests after the refactor | 269 passed |
| New `test/home_architecture_test.dart` | 8 passed: structure, one load per mount, one per resume, none after teardown, rebuild scope, lazy list. On the **original** file, 2 fail (structure, and the greeting-scope check: the old root `context.watch` rebuilt the app bar) |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info |
| `flutter test` (full suite) | **780 passed, 0 failed** |
| Simulator (iPhone 17 Pro, design preview) | Home renders as before (screenshot compared) |

**Home tab re-entry freshness (Task 28), 2026-11-15** — run in this repository:

| Command | Result |
|---|---|
| Existing focused tests (Home, offers, availability, toggle, navigation, nav bar, Current Order, Login) before the fix | 316 passed |
| New `test/home_tab_reentry_test.dart` (real `MainApp`, GoRouter indexed stack, `AppNavBar`, counting fakes) on the **pre-fix** code | 6 of 15 fail: returning to Home from each of the 4 other tabs loads 0 instead of 1 per feature; return after a resume elsewhere; return from a page covering Home |
| Fix | `HomeLifecycleBridge` re-reads both features once when go_router's per-branch `TickerMode` turns back on (see `ROUTING_AND_STARTUP.md` §7). No new listener, timer, Cubit, dependency or public API |
| Same 15 + 316 after the fix | 331 passed |
| Lazy list (375×800, including the scroll cache area) | 100 and 500 offers: 2 cards built initially, during a card's command, after it and after tab re-entry. Counted work only; no wall-clock or memory benchmark |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info |
| `flutter test` (full suite) | **795 passed, 0 failed** |
| Device/simulator | Not run for this task (widget tests only) |

**Home visible-only refresh (Task 29), 2026-11-15** — owner decision: Home refreshes when it becomes visible, and on resume only while visible:

| Command | Result |
|---|---|
| Focused tests before the change | 331 passed |
| Updated/new tests in `test/home_tab_reentry_test.dart` on the **pre-fix** code | 2 fail: resume with another tab visible loads (2, 2) instead of (1, 1); resume with a full page covering Home loads (2, 2) instead of (1, 1). The overlapping resume + Home-tap test already passed (Cubit in-flight guard) |
| Fix | `HomeLifecycleBridge`: the resume callback loads only when the cached `TickerMode` value says Home is visible. No new listener, timer, Cubit, dependency or public API |
| Focused tests after the fix | 333 passed |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info |
| `flutter test` (full suite) | **797 passed, 0 failed** |
| Device/simulator | Not run (widget tests only) |

**Order card icons and soft divider (Task 31), 2026-11-15:**

| Check | Result |
|---|---|
| Pictured card | The owner's `HomeOrderPreviewCard` (`home_screen/widget/order11.dart`), placed by the owner in `HomeScreen` above the real offers list; production offers use `AppOrderOfferCard` |
| Change | Both cards: storefront / map pin / checkered flag / coins icons (Phosphor Regular, 20 px, `AppColor.secondary`, 8 px gap, no semantics) and a divider of `AppColor.border` at 55 %, 0.7 px. No constructor, callback, copy, button or color-token change |
| Baseline full suite (owner preview present, before the change) | 765 passed, 32 failed. 22 fail because the preview pushes the real offers list down on Home; 10 because the preview's fee row overflowed at 320 px and text scale 2–3 |
| New `test/order_card_icons_test.dart` | 39 passed (38 of them fail on the pre-change cards) |
| Full suite after | 814 passed, 22 failed: the same 22, all caused by the preview being on Home (with the preview removed temporarily, 836/836 passed; `home_screen.dart` restored byte-identical). The 10 overflow failures are fixed (the fee label is now `Flexible`) |
| `flutter analyze` | 1 issue: the same existing `SplashBloc` info |
| Simulator (iPhone 17, design preview entry) | Both cards render with the icons and the soft line (screenshot checked) |

**Custom widget standard rewrite + order-card pilot (Task 32), 2026-11-15:** `CUSTOM_WIDGET_CONTRACT_STANDARD.md` rewritten as a lean, idiomatic Flutter guide (when to create a widget, composition, `required` vs business validation, theme first, dumb UI, sizing/RTL, performance without myths, proportional tests, three examples, approval gate, checklist); `CLAUDE.md` rule and docs index updated. Pilot: `AppOrderOfferCard` already met the guide, so its code is **unchanged**; the design preview already renders it with typed fixtures. The owner's `HomeOrderPreviewCard` (`order11.dart`, rewritten by the owner and no longer placed on Home) is left untouched pending an owner decision; its 12 stale Task 31 tests were removed. Baseline 833 passed / 3 failed (those stale tests) → **824 passed, 0 failed**. `flutter analyze`: the existing `SplashBloc` info plus the owner's unused `order11.dart` import in `home_screen.dart` (left as is). No widget, token, dependency or behavior change.

**One order card (Task 33), 2026-11-15:** owner-approved. The owner's `HomeOrderPreviewCard` design moved into `AppOrderOfferCard` (Material outlined storefront/location/flag/payments icons, owner spacing, soft line `AppColor.border` at 45 %, 0.7 px, forest fee amount, outlined «رفض»); ARB labels, money formatting, semantics, busy/disabled states and the public API kept. **Deleted:** `home_screen/widget/order11.dart` (`HomeOrderPreviewCard`) and the commented-out `widget/order/order_card.dart`; the unused import in `home_screen.dart` removed. Tests: baseline 824 passed (analyze: 2 issues incl. the unused import) → **825 passed**; one decline-color assertion updated to the outlined design, one outlined-states test added, two Home tests made to settle the lazy list before tapping/asserting (no assertion removed). `flutter analyze`: only the existing `SplashBloc` info. Simulator (iPhone 17, design preview): matches the owner design.

**Blockers for real offers:** offers API contract (TO SPECIFY: endpoints, DTOs, error codes, `Idempotency-Key`), dispatch rounds/private offers and expiry on the backend, push/SignalR transport, the real Current Order API.

**Blockers for real availability:** backend API contract (TO SPECIFY: endpoints, DTOs, Problem Details codes, `Idempotency-Key` handling); native permission setup (Android `ACCESS_BACKGROUND_LOCATION`, `POST_NOTIFICATIONS`; iOS `NSLocationWhenInUseUsageDescription` / `NSLocationAlwaysAndWhenInUseUsageDescription`, `UIBackgroundModes` `location`/`remote-notification`, `permission_handler` Podfile macros) with approved copy; a plugin-backed `AvailabilityPermissionGateway`; GPS uploads every 30 s with 90 s freshness; FCM/APNs registration; Play background-location declaration and prominent disclosure (G-04); physical-device validation.

## 6. History

| Date | Milestone |
|---|---|
| 2026-11-14 | **Documentation-only reconciliation:** superseded decisions synchronized; no Flutter/backend code changed and no tests rerun. OpenAPI/Identity/SignalR/outbox/idempotency, Broadcast OFF/rounds, GPS 30s upload/90s freshness, scheduled holds/30-min cutoff, Admin settlement, service geofence, maps/FCM, brand/font/DI documented. |
| 2026-11-14 | **Login validation (Task 03):** D-A65 username/password rules and the owner-approved supplement (phone-digit normalization, exact Arabic messages, weak-password policy kept server-side) implemented in the validators and `LoginCubit`, with tests. No backend, branding or layout change |
| 2026-11-14 | **Post-validation review (Task 04, documentation only):** Task 03 source re-verified; Login-validation wording synced in routing, state-management, decisions, shared-UI and Claude Project docs; password length unit recorded as an open owner decision. No code or test changes |
| 2026-11-14 | **AppTextFormField contract (Task 08):** owner-approved API implemented: required non-blank `label`, `AppTextFieldStyle` for every visual state (with working border widths), asserts for controller/initialValue, multi-line obscuring, `endIcon` vs visibility toggle and keyboard assistance on obscured fields; toggle disabled on disabled fields; unused arguments removed; `showObscureToggle` renamed `showVisibilityToggle`. Login layout, entry behavior and appearance unchanged. `docs/ui/CUSTOM_WIDGET_CONTRACT_STANDARD.md` added |
| 2026-11-15 | **Brand foundation (Task 10):** IBM Plex Sans Arabic bundled and applied through `AppTheme`, `TextThemeStyle`, text widgets and button labels; Ink default text; `AppColor.inputBorder` for a WCAG-compliant field border; `AppButton` height became a minimum so large text no longer clips. Login layout, copy, validation and auth unchanged |
| 2026-11-15 | **One order card (Task 33):** owner preview design moved into `AppOrderOfferCard`; duplicate preview card and stub deleted |
| 2026-11-15 | **Custom widget standard (Task 32):** policy rewritten as a concise idiomatic Flutter guide; `AppOrderOfferCard` pilot already compliant (no code change) |
| 2026-11-15 | **Order card icons (Task 31):** storefront, pickup pin, checkered-flag delivery area and coins fee icons plus a softened sand divider on `AppOrderOfferCard` and the owner's Home preview card. No API, copy or token change |
| 2026-11-15 | **Home visible-only refresh (Task 29):** app resume no longer reloads a hidden Home (another tab or a full page in front); becoming visible still reads once; visible-Home resume unchanged. No UI, copy, API or dependency change |
| 2026-11-15 | **Home tab re-entry (Task 28):** returning to the retained Home tab re-reads availability and offers once (previously nothing, so a stale offers list could stay on screen); re-selecting Home, rebuilds and dialogs load nothing; resume behaviour unchanged. 15 routing tests through the real router. No UI, copy, API or dependency change |
| 2026-11-15 | **Home architecture (Task 27):** `HomeScreen` became a thin `StatelessWidget`; sections moved to one file each under `home_screen/widget/`; `HomeLifecycleBridge` owns the single lifecycle listener and the loads; `HomeAvailabilityRationaleListener` owns the popup; the greeting selects only the display name. No UI, copy, API or behaviour change; 8 tests |
| 2026-11-15 | **Home pending offers (Task 26):** «طلبات بانتظار القبول» with the new `AppOrderOfferCard`, `PendingOffersCubit`, `OrderOfferRepository` + "not configured" placeholder and a standalone design preview; 56 tests. The Task 25 debug availability demo (added earlier the same day) was removed; the D-A40 Login preview remains. No native, dependency, tab or route change |
| 2026-11-15 | **Home header and availability (Task 24):** Task 15 Option A on Home (title when it fits, read-only wallet total with «—» fallback, greeting, availability card); new `AppAvailabilityToggle`; `HomeAvailabilityCubit` with server-confirmed state, staged permission flow behind ports and honest "not configured" placeholders; 89 new tests. No native, dependency, tab or route change |
| 2026-11-15 | **Text widget family (Task 23):** `AppTextWidget` style precedence fixed (default, then `style`, then dedicated parameters) so a partial style keeps the font, weight and Ink and dedicated parameters are no longer ignored; `fontWeightOverride` hook in the 4 wrappers with `fontWeight`; 77 real-font tests. No API, default or caller change |
| 2026-11-15 | **MainNavigationBar (Task 22):** audit; debug asserts for out-of-range `selectedIndex` and negative `unreadCount`; 15 tests (input contract, real-font label fit, text-scale cap). Fifth tab still Profile; label truncation at text scale ≥ 2 on narrow widths recorded for an owner decision. No API, visual, routing or caller change |
| 2026-11-15 | **UnderConstructionPlaceholder (Task 21):** audit only; no defect and no production change; 5 evidence tests (delegation, blank-message guard via `AppStatusMessage`, three real screens at large text). Screen AppBar title truncation at scale 3 noted for a separate task |
| 2026-11-15 | **AppStatusMessage (Task 20):** debug asserts for `actionLabel`/`onAction` pairing, blank title and empty/blank message; 36 direct widget tests (states, fonts, semantics, centering, sizes, keyboard, RTL/LTR, placeholder). No public API, layout, color or caller change |
| 2026-11-15 | **AppToast (Task 19):** debug asserts for action pairing, blank message/label, non-positive duration and unmounted context; action runs once and never from a closing or replaced toast; replacement drops queued toasts; the action wraps under the message instead of overflowing; the toast stays above the keyboard and scrolls at extreme text sizes. No public API, color or copy change; callers untouched |
| 2026-11-15 | **AppButton (Task 18):** `textStyle` merged over the default, `textStyle.color` honored (precedence `foregroundColor` > `textStyle.color` > onPrimary), long labels wrap instead of being truncated, debug asserts for invalid content/size combinations; no public API change; callers untouched |
| 2026-11-15 | **AppPopup (Task 17):** keyboard-open / large-text overflow fixed in the shared popup (scrollable icon/title/body, pinned actions, actions scroll only when nothing else fits); debug asserts for invalid setups; no public API, copy or color change |
| 2026-11-15 | **Store submission checklist (Task 14, documentation only):** `docs/release/STORE_SUBMISSION_COMPLIANCE.md` created with Apple/Google requirements, repository evidence, blockers, owner inputs and a pre-submission audit; linked from `docs/README.md` and `CLAUDE.md` §13. No code or configuration changed |
| 2026-11-15 | **Login Terms & Conditions (Task 13):** «الشروط والأحكام» `AppTextButton` under the no-account action; `LegalLinks` (URL not yet provided) and `LegalPageLauncher` (in-app web view only, HTTPS only, no fallback); truthful "not available yet" popup; release readiness blocked on the Terms URL/content and the Privacy Policy. No route, package, auth or layout change otherwise |
| 2026-11-15 | **Custom widget standard and `AppTextButton` (Task 12):** `CUSTOM_WIDGET_CONTRACT_STANDARD.md` extended (minimal API without a quota, truthful `required` incl. nullable callbacks, verified overrides, precedence, no hidden routing/backend, one component per migration, checklist and breaking-change gate) and referenced from `CLAUDE.md`; inventory recorded. `AppTextButton`: `textStyle.color` honored, `textStyle` merged over the default, blank-label assert. No constructor change, no screen changed |
| 2026-11-15 | **Login fields (Task 11):** owner-approved: the per-call field style overrides were removed so both Login fields use the shared defaults; the username's typed text is LTR with autocorrect and suggestions off. Validation, normalization, password behavior, copy and layout unchanged |
| 2026-11-10 | Routing (`go_router`), `AppColor`, logo asset, Splash |
| 2026-11-10 | Internet check, No Internet screen, auth placeholder, Login and Home shells |
| 2026-11-11 | User-profile bootstrap, typed errors, session state, redirect policy |
| 2026-11-11 | GetX-free shared UI components, validators rebuilt to SHAHM rules, Splash widget extraction |
| 2026-11-11 | App-wide connectivity monitor and banner, lifecycle handling, split auth use cases |
| 2026-11-11 | Documentation consolidated into this structure |
| 2026-11-11 | Arabic gen_l10n localization, central responsive breakpoints, shared form/button/popup/toast components, Login feature (`LoginCubit`, `SignIn`) |
| 2026-11-11 | Post-implementation audit: fractional breakpoint boundaries verified; blocked-account message at Login gated behind D-P16 (generic error for now); toast screen-reader text moved to an ARB pattern; D-P22 (username trimming) and D-P23 (platform app names) recorded as pending |
| 2026-11-11 | Main navigation foundation (R8): five-branch shell, `MainNavigationBar` with Phosphor icons, four placeholder screens, Login forgot-password move and no-account popup, temporary debug-only preview |
| 2026-11-11 | Center action corrected to Current Order (R9): map-pin icon and «الطلب الحالي», active-order lookup states and integration boundaries (no backend, map or location yet), bar spacing and text-scaling refinement, `AppStatusMessage`, first simulator run |
| 2026-11-11 | Current Order review (R10): not-configured separated from outages in copy and actions; (0, 0) no longer rejected (D-P31 pending); an order without usable coordinates stays active with only the map off; `docs/` un-ignored |
| 2026-11-12 | Product decision update: instant broadcast rounds, manual scheduled-order workflow, background GPS and offer-notification requirements, wallet commission/credit-limit/recharge rules, Wallet navigation target, and Admin-only post-pickup reassignment documented (D-A44–D-A52). Documentation only; Flutter implementation and verification not performed |
