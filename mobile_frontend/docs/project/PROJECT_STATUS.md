# SHAHM Flutter — Project Status

## 0. Current target and implementation summary (client revision, 2026-11-20)

**Authority:** target rules are D-A69–D-A79 (decisions §1.2) and
`PRODUCT_OVERVIEW.md`. This table is the **current** status; §1–§4 below are
older snapshots kept for traceability and are reconciled here where they
conflict (for example §1 still lists five tabs, Notifications and holds —
those rows are historical). §5 verification rows are dated history; only
the rows dated 2026-11-20 describe this revision's runs.

Baseline inspected before this revision (HEAD `829fdef` plus uncommitted
Tasks 34–38 work): five tabs with Wallet fifth and `/profile` as an overlay;
Notifications feed with unread dot; Wallet with total/available/held,
«طلب شحن» popup and credit/debit selector; forest Accept; cream
backgrounds; Task 38 full-fee sheet and confirmed-decline refresh present;
debug demo (Task 37) installed.

| Area | Target (decision) | Implementation status | Backend/owner gap |
|---|---|---|---|
| Docs | Canonical docs reconciled (Task 39) | **Done 2026-11-20** (documentation only) | — |
| Theme | Red/white/neutral, black/gray tabs (D-A69) | **Implemented** (`AppColor`, `AppTheme`, offer card/sheet, field focus/disabled, AppButton pressed/disabled) | Owner may revise shades centrally |
| Navigation | Four tabs, Profile tab, no center button (D-A70) | **Implemented** | — |
| Home AppBar | Greeting + availability + balance chip; no Profile button (D-A71) | **Implemented** (content-sized bar; `HomeActiveOrderCard` in body) | Availability API, permission adapter |
| Notifications | Feed removed; order push retained (D-A72) | **Implemented** (feature, demo seed and keys deleted; offer sheet flow kept) | Push adapter, FCM/APNs credentials, event schema |
| Current Order recovery | Standalone page, acceptance/startup/resume recovery (D-A73) | **Implemented** with test repositories and the demo; app-level `CurrentOrderCubit` with coalesced reads | Real `ActiveOrderRepository` (production placeholder = not configured, so no real process-restart recovery) |
| Wallet | One balance, no holds, no recharge UI, debit-only history (D-A74, D-A76) | **Implemented** (`heldFils`/`availableFils`/`WalletCredit`/recharge popup/`RechargeContact` deleted) | Wallet API (endpoints, DTOs, window) |
| Balance ceiling | 5,000 fils after credit, server-enforced (D-A75) | Documented contract only; Flutter shows values faithfully | Server enforcement; D-P38 existing over-cap balances |
| Wallet metrics | Lifetime delivered count + earnings (D-A76) | **UI + read model implemented**; earnings always "unavailable" (D-P36); production placeholder = not configured | Statistics contract; earnings formula **D-P36** |
| Profile | Name, phone, rating, Settings/Terms/About (D-A77) | **Implemented** (+ sign-out entry; About shows version "unavailable": no version source) | Rating contract/scale **D-P37**; Terms/Privacy URLs **D-P40** |
| Account deletion | Confirmed, typed outcomes (D-A78) | **Flow implemented**; production adapter = not configured (nothing sent or deleted) | Deletion contract **D-P39** |
| Demo | Updated manifest/fixtures, removable | **Updated**; dry run OK on live tree; `--apply` rehearsed on a full copy (analyze + 972 tests passed); live demo still installed | — |

**API-dependent gaps (none of these exist in the checkout; `backend/` is
empty):** active-order read model/endpoint; offers list/accept/decline
commands; wallet balance + commission-debit history; lifetime delivery
statistics; rating read model; account-deletion command and session
revocation; availability command; push token registration and order-event
schema; Terms and Privacy Policy URLs.

### 0.1 Audit remediation (2026-11-22, D-A80) — current

Uncommitted working tree on `cefad0a`. Tracker:
`../quality/REMEDIATION_STATUS.md`; revised reports:
`../quality/reports/2026-11-22-post-fix/`.

| Area | Now implemented | Still open |
|---|---|---|
| Routing | Localized route-error surface (`RouteErrorScreen`); guard unchanged | — |
| Wallet source | One shell-scoped `WalletCubit` for Home chip and Wallet; session-owner tagging; demo Home hook removed | Real wallet API (B-05); Wallet resume read D-P42 |
| Refresh | Profile rating on re-show / visible resume | — |
| Timeouts | Explicit per-operation policy; deletion timeout = unconfirmed | — |
| Cleanup | `AppTools`, loading widgets, `CustomePadding`, `SplashBloc`, chip helpers deleted; Current Order navigation helper extracted | Text-widget family D-P43 |
| Shared UI | Typed `AppPopupAction<T>.result`; `AppButton` on both Retry surfaces | — |
| Localization | ICU line/sentence keys for composed text | 3 unused generic dialog keys (recommendation) |
| Platform | «شهم» names, `INTERNET` in the main manifest, 5 unneeded packages removed | Bundle/package IDs, location purpose strings and disclosures, merged-manifest/device verification, version source (package approval) |
| Demo tooling | Narrow historical-audit classification; manifest updated; rehearsal on a copy | Live demo still installed (owner removes it when wanted) |
| Data | Atomic dictionary (125 IDs) and backlog B-01…B-10 | All contracts; D-P25, D-P35–D-P41 |

**Counts (final source):** 11 Cubits, 0 Blocs, 16 `StatefulWidget` (10
production, 3 demo, 3 preview), 2 `ChangeNotifier`; 344 paths; screens:
10 logical (2 partial UI/workflow: My Orders, Current Order; 8 complete UI
awaiting integration, content or device verification), 1 approved missing
capability (future commitments, not a screen). These numbers belong to this
snapshot; recompute them per `../quality/AUDIT_METHOD.md`.

### 0.2 Current Order workflow (D-A81, 2026-11-22) — current

| Part | Client implementation | Demonstrated with | Live / configured |
|---|---|---|---|
| Stage page | One `/current-order` page: pickup leg, delivery leg (no map), unknown status | widget tests; debug demo | No backend: production reports "not configured" |
| Pickup PIN | Form in `AppPopup` with pinned actions; syntax-only validation; typed wrong/locked/conflict/unknown outcomes; replaceable `ConfirmPickup` boundary | tests; demo server PIN | Server verification contract missing |
| Start Delivery | Separate command, only from `picked_up` | tests; demo | Contract missing |
| Completion | Confirmation popup; one command; receipt; unknown outcome → outcome lookup; same key on retry | tests; demo (one completed delivery + one debit) | Contract, idempotency and the atomic debit are **server** work |
| Optional phone | Shown only when supplied; never blocks | tests; demo (with and without phone) | — |
| History / wallet refresh | `CompletedDeliveriesCubit` (paging by cursor), `WalletCubit.invalidate()`, one switch to «طلباتي» | tests; demo | Completed-delivery and wallet contracts missing |
| Google map | `GooglePickupMap` adapter (merchant + captain markers, route polyline when supplied, bounded camera) | **not rendered** (no keys) | Needs keys + `SHAHM_GOOGLE_MAPS=true`; iOS debug simulator build compiles the native setup |
| Route | `PickupRouteRepository` port; placeholder "not configured" | tests (no route → honest line) | Routes access design (backend proxy vs app-restricted key) missing |
| External Google Maps | `PickupNavigationLauncher` (Android `google.navigation`, iOS `comgooglemaps`, non-browser) | unit tests (URIs, outcomes) | Not launched on a device |

**Exact remaining gates:** OpenAPI for the active-order read (stage,
assignment, area, optional phone), confirm-pickup (errors, attempts),
start, complete (idempotency, receipt), outcome lookup, completed-delivery
list (paging) and wallet/statistics reads; FCM/SignalR stage-change hints;
Google Maps keys (restricted) and billing; the Routes access design;
location provider integration (D-A57); a device walkthrough.

**Verification (2026-11-22, working tree on `cefad0a`):** `flutter analyze`
no issues; `flutter test` **1,056 passed**; demo dry run OK; `--apply`
rehearsal on a full copy: removed, 1,027 tests passed afterwards, workflow
UI/ports and placeholders intact; `flutter build ios --simulator --debug`
succeeded; Gradle debug/release **manifest merge** succeeded (INTERNET,
Maps query, label, empty key). `flutter build apk --debug` **fails** on a
pre-existing toolchain gap: `permission_handler_android` 14.1.1 needs
compileSdk 37, the project uses 36 with AGP 9.0.1 (upgrade task, not part
of this change). **No simulator/device walkthrough was performed**, no keyed map,
no live backend or database.

### 0.3 Home and order-details revision (2026-11-24, D-A82/D-A83) — client implemented

Uncommitted working tree on `e9b92d8`. Client code, test fakes and the
debug demo only; no backend, endpoint, database write, device or simulator
run.

| Area | Implemented | Remaining (backend/owner) |
|---|---|---|
| Home wallet shortcut | **Removed**: `WalletBalanceChip` (file deleted), `walletBalanceFils` on `HomeScreen`/`HomeAppBar`, the router `BlocSelector`, the chip-only ARB keys. The shell `WalletCubit` is now **lazy** (its eager `loadBalance()` existed only for the chip and was deleted); Home causes no wallet read. Wallet tab, session tagging and completion invalidation unchanged | — |
| Home emblem | `AppImages.homeLogo` added first, then `HomeAppBar` shows it at the logical end (height 44, `BoxFit.contain`, one localized label, no action). `AppImages.logo`/Login untouched | Visual check on a device |
| Greeting | `HomeGreeting.firstName`: first non-empty whitespace token; generic greeting otherwise; Profile keeps the full name | — |
| Home offer card | `AppOrderOfferCard` has one full-width Accept; `onDecline` removed; a sheet-started decline keeps Accept disabled. `NewOrderOfferSheet` Decline, `PendingOffersCubit.decline` and declined history unchanged | — |
| Delivery details | `ActiveOrder` + `customerName`, `deliveryNotes`, `deliveryFeeFils` (+ `contactName`, `deliveryNote`); shared `OrderDeliveryDetails` (`view/widget/order/`) on the delivery leg; `CustomerContactCard` deleted (superseded) | Active-order contract fields |
| Completed-order details | `CompletedDelivery` + `customerName`, `customerPhone`, `deliveryNotes`; tappable `CompletedDeliveryTile`; protected sub-route `/order-history/completed/:orderId` → `CompletedOrderDetailsScreen` reading the session's record (`CompletedDeliveriesState.recordFor`); explicit unavailable state; no per-row fetch | History detail contract, server ownership checks, snapshot persistence, retention/redaction (unspecified) |

**Verification (2026-11-24T19:26Z):** `flutter gen-l10n` OK; `dart format`
on changed Dart files: 0 changed; `flutter analyze`: 3 warnings, all
unused imports in the owner's uncommitted `login_screen.dart`; `flutter
test`: **1,048 passed, 2 failed** — `login_screen_test` "offline and backend
failures…" and `demo_mode_test` "Login shows the badge…", both a second
Login submit whose button is pushed below the 800×600 test viewport by the
owner's uncommitted Login/logo changes (the Login test passes with HEAD's
`login_screen.dart` on a scratch copy). Demo dry run OK. Owner fixes made
only where they blocked required checks: a missing comma after the
owner's new `companyWordmark` ARB key (plus its metadata line), and demo
tests now use the owner's demo username from `auth.json`.

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
- *(Superseded by D-A72: no unread dot.)*
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
- *(Superseded by D-A72)* ~~Unread indicator~~: was "connect `unreadCount` in `AppNavBar` once
  notification state exists (D-P24)".
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
| 2 | Atomic dispatch + wallet (20%, nearest-fils, no holds, one completion debit, 5,000-fils balance ceiling, D-P41 floor point, post-pickup pending settlement, idempotency, outbox; D-A74/D-A75) | Approved business rules, **not implemented** |
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
| 2026-11-22 (audit remediation) | `flutter gen-l10n`; `dart format --set-exit-if-changed` on changed/new Dart files | OK; 0 files changed |
| 2026-11-22 | `flutter analyze` | **No issues** (baseline info from the dead `SplashBloc` gone) |
| 2026-11-22 | `flutter test` | **1,034 passed, 0 failed** |
| 2026-11-22 | `bash tool/demo/remove_demo.sh --dry-run` (live) | OK, nothing changed |
| 2026-11-22 | `--apply` rehearsal on a full copy in the session scratchpad | Demo removed; tool's gen-l10n/analyze/test passed; 1,006 tests after removal; baseline reports byte-identical; scanner negative checks rejected (stray import, edited baseline, `docs/` asset, Dart reference) |
| 2026-11-22 | `plutil -lint ios/Runner/Info.plist`; `xmllint` main Android manifest | OK. No device, simulator, release or merged-manifest build was run |
| 2026-11-20 | `flutter gen-l10n`; `dart format lib test` | OK |
| 2026-11-20 | `flutter analyze` | 1 issue: the existing `SplashBloc` info (baseline) |
| 2026-11-20 | `flutter test` | **1,001 passed, 0 failed** (the notifications suite was deleted with the feature; new suites: active-order recovery, Profile/Settings) |
| 2026-11-20 | `bash tool/demo/remove_demo.sh --dry-run` (live tree) | Dry run OK, nothing changed |
| 2026-11-20 | `remove_demo.sh --apply` on a full copy of the working tree | Removed; gen-l10n, analyze and 972 tests passed; restored files contain no Notifications, five-tab, hold, recharge or old-palette code |
| 2026-11-20 | iPhone 17 simulator (iOS 26.5, 402×874 pt), debug demo driven via the Dart VM service | Login, Home AppBar, new-offer sheet → accept → standalone Current Order, Back → Home card, Wallet, background (Settings app) → foreground recovery to Current Order from the Wallet tab, Back → Wallet, Profile, Settings → deletion confirmation → "not configured". Text scale 3.1 found a Home overflow under the demo strip → fixed and covered by a regression test. No physical device, no release build |
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

**Offer-sheet full fee + declined-history refresh (Task 38), 2026-11-16** — owner-requested:

| Item | Result |
|---|---|
| New-offer sheet | One money row only: «أجرة التوصيل كاملة» with `deliveryFeeFils` as sent (e.g. `3.000 د.أ` for a 3,000-fils offer with a 600-fils commission snapshot), instant and scheduled, in every mode. Commission rate/amount, computed net, the earnings heading and note were removed (ARB keys `offerEarningsHeading`, `offerCommissionLabel`, `offerCommissionLabelNoRate`, `offerNetEarningsLabel`, `offerEarningsNote` and the then-unused `helper/money/percent_format.dart` deleted). Accept is still blocked for a missing/inconsistent snapshot (`offerAcceptBlock`, unchanged); domain snapshot and wallet contract unchanged. Home card unchanged |
| Declined history | `DeclinedOffersCubit` moved from the Order History route to the shell (documented scope change; same sign-out lifetime, nothing read before Order History opens). New `refresh()`: ignored before the first load, coalesced into one follow-up read when it arrives during a load, dropped after sign-out/close. `PendingOffersCubit.onDeclineConfirmed` (new, mirrors `onAcceptConfirmed`) calls it after a **server-confirmed** decline from Home or the sheet, so the record appears while Order History stays visible, newest first, with no navigation. «لاحقاً»/dismiss, an unconfirmed/failed decline and an accept never refresh it. First entry, tab return, visible resume and Retry unchanged |
| Tests | Baseline 1,007 passed / 1 failed (a pre-existing date-dependent demo test: fixed demo clock vs the real Wallet clock) → **1,015 passed, 0 failed**. Sheet tests now assert the full fee as the only amount (no %, no minus, no net, also for missing/inconsistent snapshots); new: decline while Order History is visible (one re-read, new row first, «لاحقاً» and unconfirmed add nothing), accept never re-reads history, `refresh()` coalescing/stale/sign-out, `onDeclineConfirmed` only on confirmation |
| `flutter analyze` | 1 issue: the existing `SplashBloc` info |
| Dependencies | None added or changed |

<!-- SHAHM_DEMO_START status-demo -->
**Debug-only demonstration mode (Task 37), 2026-11-15 — temporary, removable:** `flutter run --debug --dart-define=SHAHM_DEMO=true` runs the real app with fictional JSON fixtures (`assets/demo/fixtures/`), a fictional demo captain (`demo_captain` / `Demo1234!`, token deliberately not a JWT, memory only), a «وضع تجريبي — بيانات وهمية» strip on every screen with «إظهار طلب جديد» and demo tools, and simulated in-memory accept/decline. Inert without the define and in profile/release builds, but the fixtures are declared assets and are packaged in every build: **remove before any release** with `bash tool/demo/remove_demo.sh --apply` (details: `tool/demo/README.md`). Not a backend.

**Demo consistency (Task 38), 2026-11-16:** in the authenticated demo, Home's wallet chip shows the demo wallet's `totalFils` (the same in-memory overview the Wallet tab reads; 18.750 د.أ with the fixtures, «—» when signed out); a demo reset re-reads the declined-offers history in place. Verified interactively on the iPhone 17 simulator (iOS 26.5, 402×874 pt) with pointer events injected into the running debug app through the Dart VM service (no physical device, no release build): Login → Home chip 18.750 = Wallet total (available 15.750, held 3.000) → chip opens Wallet → recharge popup "not available" → Order History (1 row) → «إظهار طلب جديد» → sheet with only «أجرة التوصيل كاملة 3.000 د.أ» → decline → new row first, same tab → «لاحقاً» → still 2 → reset → 1 row in place → accept → matching Current Order with map unavailable → text size accessibility-XL (scale 2.35): chip fits, sheet fee wraps, actions scroll above the safe area → sign-out → re-login 18.750 → ordinary launch without the define shows plain Login. Observed, not changed here: at scale 2.35 the bottom tab labels break mid-word.

<!-- SHAHM_DEMO_END status-demo -->
**New-order offer sheet, card actions, declined offers, Wallet title (Task 36), 2026-11-15** — owner-requested:

| Item | Result |
|---|---|
| New-offer sheet | `NewOrderOfferSheet` presented by `NewOfferSheetHost` (mounted once in the shell, root navigator) above any tab or the Profile route when the server list gains an unseen offer; one at a time, deduplicated by id, foreground and signed-in only, never on Splash/Login; «لاحقاً» / barrier / back close without answering (not while a command runs) |
| Content | «حالي» / «مؤجل» badge, merchant, pickup, delivery **area**, scheduled pickup time (scheduled only), full fee, snapshot commission rate + amount, net = fee − commission (integer fils; estimate, not a wallet credit); "not available" when the server sent nothing |
| Actions | Accept only for an instant offer with a complete snapshot; instant accept confirmed → `CurrentOrderCubit.refreshed()` → Current Order only for the matching `orderId`, otherwise an honest popup; decline confirmed → sheet closes, no navigation; failures keep the sheet with the reason |
| Scheduled offers | Shown with type and time; **Accept off** ("Admin confirms directly") — D-A47 / D-A61 unchanged; owner decision D-P35 opened |
| State | `PendingOffersCubit` moved from the Home route to the shell (Home and the sheet share it); `CaptainOrderOffer` gained optional `kind`, `orderId`, `scheduledPickupAt`, `commission` (`OfferCommissionSnapshot`); `CurrentOrderCubit.refreshed()` (Notifications reuses it) |
| Order History | «العروض التي رفضتها»: read-only server records (`OrderHistoryRepository`, `GetDeclinedOffers`, `DeclinedOffersCubit`, `DeclinedOfferTile`); placeholder reports "not configured"; no local row after a decline; completed-delivery history still a later task |
| Card / Wallet | `AppOrderOfferCard` «قبول» forest + check icon, «رفض» outlined error + close icon; Wallet app bar title is text only |
| Design preview | `lib/preview/new_offer_sheet_preview.dart`: the real sheet with labelled fictional instant/scheduled offers; not imported by the app |
| Tests | Baseline 926 passed → **984 passed** (new `test/new_offer_sheet_test.dart`: 59; Order History removed from the placeholder-screen test; navigation placeholder test and two card-color assertions updated to the forest accept) |
| `flutter analyze` | 1 issue: the existing `SplashBloc` info |

**Blocked / TO SPECIFY:** offers wire fields for kind, `orderId`, scheduled pickup time and the commission snapshot (rate, amount); the declined-offers history query; push/SignalR as a trigger to re-read offers; D-P35 (in-app acceptance of scheduled offers) and a future-commitments destination. Until then, no production offer opens the sheet (the placeholder reports "not configured").

**Wallet app bar + operational Notifications (Task 35), 2026-11-15** — owner-requested:

| Item | Result |
|---|---|
| Wallet app bar | Profile action removed (no action slot, button, tooltip or semantics node). Home app bar keeps Profile; Profile still opens Wallet |
| Notifications screen | Placeholder replaced: title + «الإشعارات التشغيلية», lazy list of `NotificationCard` (Admin announcement: server title/message/time, informational; assigned order: «لديك طلب مسند» only, never order details), «جديد» marker from server read state, honest loading / not configured / signed out / offline / failure + Retry / confirmed-empty states |
| Data | `NotificationRepository` + `GetNotifications` (newest first) + shell-scoped `NotificationsCubit`; `NotificationRepositoryPlaceholder` reports "not configured" (no list, no count, no network). Unread dot = server `unreadCount` only |
| Assigned tap | Re-reads `CurrentOrderCubit`; opens the Current Order tab only if the server's active order has the notified `orderId`; different / no order, orders not configured or failed check → popup, nothing else shown; one check at a time. A notice without an order reference is not tappable |
| Design preview | `lib/preview/notifications_preview.dart`: real screen, two labelled fictional notices; orders source is the real placeholder |
| Tests | Baseline 894 passed → **926 passed** (new `test/notifications_test.dart`: 32). Updated: Wallet "Profile on Wallet app bar" test → "no Profile on Wallet, Home keeps it" (scales 1 and 3); Notifications removed from the placeholder-screen test; navigation placeholder test now expects the not-configured line |
| `flutter analyze` | 1 issue: the existing `SplashBloc` info |
| Simulator (iPhone 17) | Wallet preview app bar (no Profile icon) and Notifications preview screenshots checked; navigation and taps verified in widget tests only |

**Blocked / TO SPECIFY:** notifications API (list, paging, unread count, read mutation), server kind mapping and the assigned-order reference field, push/SignalR re-read triggers, a destination for future (scheduled) assignments; deep-linking to a specific order beyond the current active order is **not** available (Current Order shows only the server's single active order).

**Wallet navigation, 7-day history and recharge contact (Task 34), 2026-11-15** — owner-approved (D-A50 / D-A66 supplement):

| Item | Result |
|---|---|
| Navigation | Five tabs, Wallet fifth (`/wallet`); Profile is a protected route above the shell (`/profile`) from the Home app bar (the Wallet app bar action was removed in Task 35); Home balance chip (also «—») and Profile «المحفظة» open the same Wallet tab |
| Wallet screen | Server total / available / held (fils, «—» when unknown, negatives kept), «طلب شحن», selectors «سجل الشحن» / «سجل الخصم», lazy cards (`WalletCreditCard`, `WalletDebitCard`), honest loading / not configured / no session / offline / failure / confirmed-empty states |
| Data | `WalletRepository` + `GetWallet` (7-day display window, start inclusive, newest first, future-dated excluded) + `WalletCubit`; `WalletRepositoryPlaceholder` reports "not configured" (no balance, no history, no network) |
| Recharge contact | `AppPopup` with the official number and «نسخ الرقم» (`Clipboard.setData`, success/failure shown in the popup only after the result); `RechargeContact.whatsAppNumber` is **null** (no official number provided), so the popup says it is unavailable and has no copy action. No request, payment or ledger write |
| Design preview | `lib/preview/wallet_preview.dart` renders the real Wallet screen with labelled fictional data (negative total, credit, long-name debits) |
| Tests | Baseline 825 passed → **894 passed** (new `test/wallet_test.dart`: 68; one new guard test). Updated for the fifth-tab migration: bar, navigation, guard, Home app bar and tab re-entry tests (Profile → Wallet; the Home "read-only chip" assertion now expects a Wallet button and a Profile action) |
| `flutter analyze` | 1 issue: the existing `SplashBloc` info |
| Simulator (iPhone 17) | Wallet design preview screenshot checked (balances incl. negative sign order, «طلب شحن», selectors, credit card). Navigation taps and clipboard copy verified in widget tests only (no tap automation on the simulator) |

**Blocked / TO SPECIFY:** wallet API (endpoints, DTOs, errors, pagination, server-side window), the official recharge WhatsApp number, feeding the Home chip from the wallet source, Wallet reload on app resume.

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
| 2026-11-16 | **Offer sheet + history refresh (Task 38):** the new-offer sheet shows only the full delivery fee (owner change; accept gating unchanged); `DeclinedOffersCubit` shell-scoped with a coalescing `refresh()` after a confirmed decline, so Order History updates while visible; full suite 1,015 passed |
| 2026-11-15 | **New-offer sheet (Task 36):** shell-level bottom sheet for newly listed offers (type, area, fee/commission/net, forest accept), shell-scoped offers Cubit, declined-offers history section (read-only), forest accept + icons on the card, Wallet title text only; scheduled acceptance left to owner decision D-P35 |
| 2026-11-15 | **Notifications (Task 35):** Wallet app bar Profile action removed; operational Notifications screen (Admin + assigned order), verified assigned-order tap, server-only unread dot; placeholder backend |
| 2026-11-15 | **Wallet (Task 34):** Wallet fifth tab, Profile from the app bar, read-only balances, 7-day recharge/debit history, contact-only «طلب شحن» popup with clipboard copy; placeholder backend, no recharge number configured |
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
