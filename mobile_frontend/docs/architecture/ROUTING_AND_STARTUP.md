# SHAHM Flutter — Routing and Startup

**Current target (client revision 2026-11-20, D-A70–D-A73, D-A77, D-A78):** four tab branches (Home, My Orders, Wallet, My Account), Current Order as a protected standalone page shared with recovery, Settings/Terms/About from My Account, and no Notifications route. Implementation status: `../project/PROJECT_STATUS.md` §0.

Routes, the redirect policy, the startup sequence and the main navigation
shell. Decisions referenced: D-A04, D-A05, D-A15, D-A16, D-A23, D-A36, D-A38,
D-A40, D-A41, D-A50, D-R09, C-18, C-19, C-23, C-24, C-28, C-33, C-34, C-35.

---

## 1. Routes and approved target

`go_router` remains the sole routing authority; protected routes require a
server-validated session and loaded eligible profile. The approved
**target navigation** is:

| Path | Destination | Access |
|---|---|---|
| `/` | Splash | Public startup |
| `/no-internet` | No Internet | Public startup |
| `/login` | Login | Public |
| `/home` | Home | Protected, tab 0 «الرئيسية» |
| `/order-history` | My Orders (existing Order History feature) | Protected, tab 1 «طلباتي» |
| `/wallet` | Wallet | Protected, tab 2 «المحفظة» |
| `/profile` | My Account (Profile) | Protected, tab 3 «حسابي» (a true branch; no back button at its root) |
| `/current-order` | Current Order (standalone page above the shell, Back → Home) | Protected; outside the tab branches, inside the authenticated scope that owns `CurrentOrderCubit` |
| `/settings` | Settings (account deletion entry) | Protected page above the shell, Back → My Account |
| `/about` | About | Protected page above the shell, Back → My Account |

Terms & Conditions has no route: it reuses `LegalPageLauncher` /
`LegalLinks` exactly like Login (in-app page, or the truthful "not available
yet" popup while the URL is empty). There is **no** `/notifications` route
(D-A72); a deep link to it is unknown: the guard applies first, then a
signed-in captain sees the localized route-error surface (§2.1). The Home balance chip uses `context.go('/wallet')` (same branch, no
duplicate page). `StatefulShellRoute.indexedStack` remains the shell;
`AppNavBar` owns routing while `MainNavigationBar` is presentation only. No
`NavBarCubit`.

Keep one redirect policy in `route_guard.dart`. The actual router must
consume the validated server session, current user and profile-completion
rules; there is no self-registration or Admin/Merchant Flutter route.

Do not use `context.go` in feature Cubits. Features emit typed states;
GoRouter/route-level UI performs navigation.

## 2. Redirect policy (the only one)

`resolveRedirect({location, startup, session, debugPreviewActive})` in
`lib/util/routes/route_guard.dart`. It re-runs whenever `SplashCubit` or
`AppSessionCubit` emits, via `StreamRefreshListenable`.

| `AppSessionState` | Rule |
|---|---|
| `SessionAuthenticated` | Validated captain session **and loaded profile** only. Public login/splash routes redirect to `/home`; protected pages remain accessible according to role/profile. Incomplete profile remains Admin-managed and is ineligible for offers |
| `SessionUnauthenticated` | Everything except `/login` redirects to `/login`. A server-suspended/revoked account is treated as invalid, with credentials cleared. Debug builds only: see §8 |
| `SessionUnknown` | Protected routes are closed. `SplashOffline` goes to `/no-internet`. `SplashInitial` and every recoverable startup error go to `/`. While `SplashChecking` or `SplashResolved`, the user stays on the current public route |

- **No loops:** no rule redirects to the current location.
- **No bypass:** deep links, manual navigation and back navigation can't
  skip the policy.

### 2.1 Unknown and failed locations (R01, 2026-11-22)

`createAppRouter` passes `errorBuilder: RouteErrorScreen.fromState`. go_router
runs the redirect before building any page, so:

| Session | Unknown path (e.g. `/notifications`, `/x?token=…`) |
|---|---|
| `SessionAuthenticated` | `RouteErrorScreen`: «الصفحة غير موجودة» + one action «العودة إلى الرئيسية» (`context.go('/home')`, still subject to the guard) |
| `SessionUnauthenticated` | Redirected to `/login` (the error surface is never built) |
| `SessionUnknown` | The startup screen of the current Splash state |

- An unmatched location (`GoException` "no routes for location") is
  "not found"; **any other routing failure** shows «تعذّر فتح الصفحة» instead
  of being called "not found".
- Never shown: go_router's English page, the location (it may carry private
  query values), the exception text or a stack trace.
- No automatic redirect to Home for unknown paths (it would hide real
  errors), no side effects in `build`, no shell bar on the surface.
- Tests: `main_navigation_test.dart` group "route errors".

## 3. Startup sequence

`MainApp.initState` calls `AppConnectivityCubit.start()` and then
`SplashCubit.start()`. Startup runs once per launch. Splash's internet check
joins the monitor's first in-flight check, so there's one probe, not two.

```text
AppConnectivityCubit.check()
  ├─ disconnected ───────────► SplashOffline ─────────────► /no-internet
  ├─ checkFailed / unknown ──► SplashConnectivityCheckFailed (Splash + Retry)
  ▼ connected
CheckAuthStatus
  ├─ Unauthenticated ────────► session.markUnauthenticated ─► /login
  ├─ Blocked ────────────────► clear revoked credentials → /login
  ├─ ServiceUnavailable ─────► SplashServiceUnavailable
  ├─ Failure ────────────────► SplashFailure
  ▼ Authenticated
GetCurrentUser
  ├─ Loaded(user) ───────────► session.authenticate(user) ──► /home
  ├─ Unauthorized ───────────► session.markUnauthenticated ─► /login
  ├─ Blocked ────────────────► clear revoked credentials → /login
  ├─ Unavailable / Invalid ──► SplashProfileFailure
  └─ Failure ────────────────► SplashFailure
```

**Historical code states** (`lib/view/screens/splash_screen/cubit/splash_state.dart`):
- `SplashInitial`
- `SplashChecking`
- `SplashOffline`
- `SplashConnectivityCheckFailed`
- `SplashServiceUnavailable`
- `SplashProfileFailure`
- `SplashBlocked`
- `SplashFailure`
- `SplashResolved`

**Behavior rules:**
- **One run per launch:** `start()` runs once; rebuilds and re-shown screens
  never repeat it.
- **Retry:** `retry()` only from a recoverable state. It's ignored while a
  run is in progress, so there are no overlapping runs.
- **Stale results:** each `await` is followed by a check on the session
  attempt token, so a sign-out or a newer attempt makes earlier results void.
- **Automatic resume:** while `SplashOffline`, a `connected` event from the
  shared monitor triggers `retry()` automatically.
- **Order:** the user is published to `AppSessionCubit` before `SplashResolved`,
  so the router sees a fully loaded session.
- **No timers:** there are no timers or fixed branding delays (D-R09).

**Startup UI:**
- `SplashScreen` shows the logo plus `SplashStartupStatus`: a spinner, or an
  Arabic message plus Retry for each recoverable state.
- `NoInternetScreen` shows Retry, disabled while checking. Neither screen
  navigates.

## 4. Startup error routing summary

| Condition | Where the user ends up |
|---|---|
| Confirmed no internet | `/no-internet` with Retry, plus auto-resume on reconnect |
| Internet check failed or timed out | Splash: "could not verify connection" + Retry. Not shown as offline |
| Backend unreachable or timed out (auth check) | Splash: service unavailable + Retry |
| No session, or session rejected | `/login`; rejected credentials are cleared |
| Profile timeout, 5xx or malformed | Splash: profile error + Retry. The session is kept and no user is invented |
| Blocked/revoked account | Clear refresh credentials, end app session and show Login with permitted server account-status guidance. No protected route; Admin resolves any active delivery. Old SplashBlocked + Retry is a historical implementation state only |
| Unexpected error | Splash: generic error + Retry. Never treated as signed out |

## 5. Backend-free behavior (D-A16)

`AuthRepositoryPlaceholder.hasStoredSession()` always returns false, so a
real run always ends at `/login`. Authenticated paths are exercised only in
tests (`test/startup_flow_test.dart`, `test/splash_cubit_test.dart`).

## 6. Login and logout

**Login (implemented 2026-11-11, D-A33; D-A65 validation added 2026-11-14, Task 03):**

```text
LoginForm ──submit──► LoginCubit ──► Validators (D-A65: normalized username, password as typed)
                          │  valid
                          ▼
                 session.beginAttempt() ─► SignIn(normalized username, unchanged password)
                          │                  ├─ repository.signIn
                          │                  └─ GetCurrentUser
                          ▼
   SignInSuccess(user) ─► session.authenticate(user, token) ─► redirect: /login → /home
   any failure          ─► LoginState.failure ─► error toast (stay on /login)
```

- **Local validation (D-A65 and its supplement):** the username is
  outer-trimmed and, when it is a 10-digit phone in Arabic-Indic, Extended
  Arabic-Indic or mixed digits, converted to Latin digits; then it must be
  `[A-Za-z0-9_.]` and 4–30 characters. The password must be 8–128
  characters and is never trimmed; there is no weak-password check at
  sign-in. The same normalized username that was validated is sent to
  `SignIn`. Rules and messages: `../ui/SHARED_UI_COMPONENTS_REFERENCE.md`
  §7.2.
- **No navigation from the Cubit.** Home opens only because the session
  became authenticated with a validated user.
- **Stale responses:** a response after a sign-out is ignored (token check).
- **Today's behavior:** the placeholder repository reports "backend not
  configured", so a real run shows that toast and stays on Login (D-A35).
- **Forgot password:** a popup on the same route (`showForgotPasswordPopup`),
  not a separate page.
- **Forgot password** is part of `LoginForm`, directly under the password
  field (D-A39).
- **No account:** «ليس لديك حساب؟ تواصل مع الإدارة» below the form opens
  `showCreateAccountPopup` (the shared `AppPopup`), also on the same route.
  There is no registration route, form or API (D-A39).
- **Terms & Conditions (Task 13, 2026-11-15):** «الشروط والأحكام» under the
  no-account action (`LoginTermsAction`). **No route was added:** the page
  opens only in an in-app view through `LegalPageLauncher`, or the shared
  `AppPopup` says it is unavailable. The URL is **not yet provided**
  (`LegalLinks.termsAndConditions` is empty), so today every tap shows the
  "not available yet" popup. Not a consent step.
- **Logout and 401:** call `AppSessionCubit.endSession()`. The redirect then
  sends every route to `/login`, which also closes the main shell.

## 7. Main navigation and Current Order (D-A70, D-A73)

```text
App level: CurrentOrderCubit + recovery (reset on sign-out)
Shell scope (closed on sign-out): PendingOffersCubit, DeclinedOffersCubit,
                                  WalletCubit (R02: Home chip + Wallet)
 ├─ StatefulShellRoute.indexedStack → session listener → NewOfferSheetHost → AppNavBar
 │   ├─ branch 0 /home           HomeScreen
 │   ├─ branch 1 /order-history  OrderHistoryScreen («طلباتي»)
 │   ├─ branch 2 /wallet         WalletScreen
 │   └─ branch 3 /profile        ProfileScreen («حسابي»)
 ├─ /current-order   CurrentOrderScreen (standalone, Back → /home)
 ├─ /settings        SettingsScreen (Back → /profile)
 └─ /about           AboutScreen (Back → /profile)
```

`MainNavDestination`, the branch list and `mainShellRoutes` share one order;
nothing assumes five items or a center index. System Back from a non-Home
tab root returns to Home; inner pages pop first. The bar is hidden with an
open keyboard and is visible only in the shell (not on Current Order,
Settings or About).

**Active-order recovery (D-A73).** One owner, `CurrentOrderCubit`, holds the
authoritative active-order state and is shared by the shell, the standalone
page, the offer flow and recovery. Recovery triggers, and only these:

1. **Confirmed instant acceptance** (Home card or new-offer sheet): after the
   server confirms, re-read `GetActiveOrder`; navigate to `/current-order`
   only when the authoritative active order has the offer's `orderId`.
   Missing/mismatched/unconfirmed → a truthful recoverable notice, no
   navigation, no duplicate accept. Scheduled offers keep their view-only
   policy (D-A47/D-A61, D-P35 open).
2. **Foreground return** with a valid session: re-read once. Simultaneous
   triggers are coalesced; a trigger that arrives while an older read runs
   forces exactly one fresh follow-up read, so an old "none" cannot hide a
   newly accepted order. An unfinished order brings the captain to Current
   Order from any tab; an open offer sheet is closed first (closing is never
   a decline).
3. **Startup:** after Splash validates the session and loads the user, the
   active order is resolved before the post-login destination is chosen.
   Active → `/current-order`; confirmed none → `/home`; offline / failure /
   not configured → `/home` with the Current Order state explicit (never a
   fabricated "no order" and never a logout). The read is independent of
   location lookup.

A refreshed authoritative absence clears the order state; if the standalone
page is visible it shows the confirmed-empty state with Back to Home (no
stale persisted route keeps an order active). Sign-out closes the scope and
drops late answers. The decision "navigate to Current Order" is applied by
one route-level listener in the authenticated scope, driven by typed Cubit
state; `resolveRedirect` stays the single startup/auth policy and gains no
order rule. No polling, no timers, no competing navigation listeners, no
global event bus; the unauthenticated debug preview never triggers recovery.

**New-offer sheet (Task 36, retained).** `NewOfferSheetHost` pushes a
`ModalBottomSheetRoute` on the root navigator above any tab or protected
page, never outside the authenticated shell. A server-confirmed decline from
Home or the sheet refreshes `DeclinedOffersCubit` (Task 38), so My Orders
updates without tab switching. Dismissing the sheet is not a decline.

**Removed (D-A72):** the Notifications branch, `NotificationsCubit`, the
unread dot and the assigned-order notification tap.

**Home re-entry (implemented, Tasks 28–29).** The indexed stack keeps every
visited branch mounted, so returning to a tab runs no `initState` and no
app resume. Home's read models (availability, pending offers) are therefore
re-read by `HomeLifecycleBridge` at these moments only (counts per feature,
from `test/home_tab_reentry_test.dart` through the real router):

| Event | Loads per feature |
|---|---|
| First opening Home (mount) | 1 |
| Another tab → Home tab | 1 (before Task 28: 0) |
| Re-selecting the visible Home tab | 0 |
| Rebuilds (text scale, size, display name, Cubit state) | 0 |
| App resume with Home visible | 1, no permission prompt |
| App resume while another tab is visible | 0 (owner decision, Task 29; before: 1), then 1 on returning to Home |
| App resume while a full page covers Home | 0, then 1 when the page closes |
| Resume and switching to Home close together | 1 (the Cubit ignores a load while one runs) |
| Trigger while a load is running | 0 (the Cubit ignores it) |
| Sign-out | 0; the Cubits close with the shell and late answers are dropped; the next session gets new Cubits |

The re-entry signal is go_router's per-branch `TickerMode` (off for hidden
branches). An opaque page covering Home inside its branch also turns it
off, so returning from such a page re-reads once; a dialog does not. App
resume reads again only while Home is visible (the bridge caches the last
`TickerMode` value; a resume never changes it). No
such Home page exists yet. Nothing is polled and no TTL is applied; the
server still decides whether an offer is actionable.

**Load triggers per feature (current, 2026-11-22).** Each feature keeps its
own policy and its own small lifecycle code (the mechanics were compared in
R03; a shared helper would add indirection for ~15 lines while the policies
differ, so none was extracted):

| Feature (owner) | First show | Re-shown after another tab | App resume while visible | Resume while hidden | Other |
|---|---|---|---|---|---|
| Home availability + offers (`HomeLifecycleBridge`) | 1 | 1 | 1 | 0 | — |
| Home balance chip (shell `WalletCubit`) | 0 (the shell read it on creation) | 0 | 0 | 0 | Shell creation: 1 balance read, never statistics |
| My Orders (`OrderHistoryScreen`) | 1 if unread | 1 | 1 | 0 | A confirmed decline refreshes it |
| Wallet (`WalletScreen`, shell `WalletCubit`) | reads only what is unread (normally the statistics) | 1 balance + 1 statistics | **0 — open owner decision D-P42** | 0 | Retry; statistics Retry |
| Profile rating (`ProfileScreen`, R03) | 1 if unread | 1 (last value stays visible) | 1 | 0 | Retry |
| Current Order (app-level `CurrentOrderCubit`) | — | — | 1 recovery read (coalesced) | 1 | Confirmed acceptance; startup |

A trigger that arrives while the same read runs is ignored by its Cubit;
sign-out closes the shell scope and drops late answers; an account change
without sign-out clears the wallet before any read (R02).

### 7.1 Current Order and merchant pickup

**Implemented workflow (D-A81, 2026-11-22).** The existing protected
`/current-order` page renders the server-reported stage: pickup leg
(`accepted`/`heading_to_pickup`) → map, «فتح في خرائط Google», «تم الاستلام»
(PIN form); `picked_up` → delivery view without a map and «بدء التوصيل»;
`on_the_way` → «تم تسليم الطلب» (after a confirmation popup); unknown
status → explanation only. No route per stage and no new tab. On the
transition to `CurrentOrderDelivered` the page shows one success toast and
calls `context.go('/order-history')` once (the shell, mounted or created
then, re-reads history and wallet). Startup and foreground recovery
re-read the stage (including `on_the_way`); returning from Google Maps is
an ordinary foreground recovery, and `openCurrentOrderPage` / the recovery
push never duplicate the page. `resolveRedirect` treats delivered/ended as
"no active work" (Home); it gained no other order rule.

Opening Current Order fetches the server's single current active
order, or explicitly reports none/unavailable/not configured; never guess
from push or offline state. The response needs id, authoritative status,
merchant name, merchant pickup coordinates and instructions. The detailed
OpenAPI contract and scheduled-activation read model remain implementation
specification work.

- Show the current active order even when its merchant pickup coordinates
  are absent/invalid. Only the map is disabled, with a clear error.
- Merchant pickup geofence is configured in Backend, and `(0,0)` is **invalid
  for SHAHM service**. Do not normalize bad coordinates to a fake location.
- Google Maps Flutter + Google Routes API Essentials DRIVE draw the road
  route/distance/ETA from the captain to the **merchant**, without live
  traffic. A distinct "Open in Google Maps" action launches native Google
  Maps for pickup navigation. There is no customer pin or customer route.
- Required precise/background location and push permissions are requested
  when tapping **Available**, not at app startup. Tracking can continue in
  background as allowed; a separate Current Order GPS lookup is not a
  substitute for the approved 30-second reporting/90-second expiry policy.
- Merchant pickup uses a unique one-use four-digit order PIN validated by
  Backend, maximum three errors then Admin. The captain must separately tap
  **Start Delivery** after `picked_up` to move to `on_the_way`.

**Production boundary:** `ActiveOrderRepository`, `OrderWorkflowRepository`
and `PickupRouteRepository` are placeholders ("not configured"), so
production finds no real order, sends no command and computes no route;
the workflow is demonstrated with test repositories and the debug demo.
The Google map is built only with `--dart-define=SHAHM_GOOGLE_MAPS=true`
plus provisioned native keys; no live map, route or backend was exercised.

## 8. Temporary debug-only preview (D-A40)

**Purpose:** open the real main shell from Login while there's no backend,
so Home and the other tabs can be developed. **It must be removed** once a
real sign-in exists.

**How it works** (C-24):

```text
Login «معاينة التطبيق» ──► DebugShellPreview.enter() ──► context.go('/home')
                                                              │
resolveRedirect(session: SessionUnauthenticated, debugPreviewActive: true)
   main-shell route ─► allowed          anything else ─► /login (unchanged)
```

- **No session is created.** `AppSessionCubit` stays `SessionUnauthenticated`;
  there is no user, token, role or permission. Screens that will need the
  current user must handle its absence during a preview.
- **Debug only, gated twice:** `DebugShellPreview.isAvailable` and `isActive`
  are ANDed with `kDebugMode`, and `resolveRedirect` ANDs the argument with
  `kDebugMode` again. In profile and release builds the button isn't built,
  `enter()` does nothing, and the guard behaves exactly as in §2.
- **Scope:** only the four main-shell routes (and pages nested in them).
  Startup (`SessionUnknown`) is unaffected.
- **Lifetime:** in memory. Once pressed it stays on until the app restarts.

**Removing it:** search for `TODO(debug-preview)` and delete
`lib/util/routes/debug_shell_preview.dart`,
`lib/view/screens/authentication/widget/debug_preview_button.dart`, the
`debugPreviewActive` parameter and rule in `route_guard.dart`, the
`debugShellPreview` wiring in `go_router.dart` and `main.dart`,
`LoginScreen.onDebugPreview`, the two `debugPreview*` ARB keys, and the
matching tests. The real authentication flow doesn't change.

## 9. Tests

- `test/route_guard_test.dart`: the policy, the four shell routes, and the
  debug preview rule and switch.
- `test/main_navigation_test.dart`: branches, direct route entry, stack
  preservation, system back, shell visibility, keyboard, safe area and
  widths, all through the real `MainApp` and router; "route errors" (R01).
- `test/wallet_test.dart` "shared source (R02)" and the R02 real-app cases;
  `test/profile_settings_test.dart` "refresh" (R03).
- `test/current_order_test.dart`: the active-order use cases, the Cubit and
  the whole Current Order flow with test-only fakes.
- `test/login_screen_test.dart`: the preview button, including a simulated
  release build where the shell routes stay protected.
