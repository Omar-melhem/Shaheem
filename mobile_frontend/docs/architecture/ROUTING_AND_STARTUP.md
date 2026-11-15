# SHAHM Flutter — Routing and Startup

**Approved route target vs code snapshot:** the old `/profile` tab exists only in the previously verified implementation. Wallet is the approved fifth branch; Profile is accessed via an AppBar/menu route. Route migrations are not yet coded in the supplied Flutter snapshot.

Routes, the redirect policy, the startup sequence and the main navigation
shell. Decisions referenced: D-A04, D-A05, D-A15, D-A16, D-A23, D-A36, D-A38,
D-A40, D-A41, D-A50, D-R09, C-18, C-19, C-23, C-24, C-28, C-33, C-34, C-35.

---

## 1. Routes and approved target

`go_router` remains the sole routing authority; protected routes require a
server-validated session and loaded eligible profile. The approved
**target navigation** is:

| Target path | Destination | Access |
|---|---|---|
| `/` | Splash | Public startup |
| `/no-internet` | No Internet | Public startup |
| `/login` | Login | Public |
| `/home` | Home | Protected, tab 0 |
| `/notifications` | Notifications | Protected, tab 1 |
| `/current-order` | Current Order (center) | Protected, tab 2 |
| `/order-history` | Order History | Protected, tab 3 |
| `/wallet` | Wallet (replaces Profile tab) | Protected, tab 4 |
| Profile route/path | Captain profile from AppBar/menu, **not bottom tab** | Protected; exact path to be defined during migration |

**Current implementation snapshot:** the old branch-4 route remains
`/profile` with a Profile placeholder, and Wallet isn't implemented. The
table above is an **approved target**, not a claim that these new routes
exist. Replace route constant, `StatefulShellBranch`, destination enum,
labels/ARB, icons and tests in one code migration. `StatefulShellRoute`
`indexedStack` remains the approved shell; `AppNavBar` owns routing while
`MainNavigationBar` is presentation only. No `NavBarCubit`.

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

## 7. Main navigation and Current Order (approved target D-A66, D-A68)

```text
StatefulShellRoute.indexedStack → AppNavBar
 ├─ branch 0 /home           HomeScreen
 ├─ branch 1 /notifications  NotificationsScreen
 ├─ branch 2 /current-order  CurrentOrderScreen (center)
 ├─ branch 3 /order-history  OrderHistoryScreen
 └─ branch 4 /wallet         WalletScreen
                 AppBar/menu → Profile
```

**Current snapshot:** branch 4 remains `/profile` until the approved migration.
Keep the branch list, destination enum and labels in lockstep. System Back
from a non-Home tab root returns to Home; inner page routes pop first. The
bar is hidden with an open keyboard and is visible only in the main shell.

**Backend-owned indicators:**
- `unreadCount` comes from Notifications Cubit and Backend/PostgreSQL; FCM
  delivery never determines whether a notification is read.
- `hasActiveOrder` is derived from the Backend current-delivery read model:
  `accepted`, `heading_to_pickup`, `picked_up`, `on_the_way`. A future
  scheduled commitment does **not** become active simply because it was
  assigned and its commission held.
- Refresh active-order state on successful authentication, captain
  acceptance, order-state changes, verified relevant push, app resume and
  opening Current Order; **no high-frequency polling**. Handle late replies
  and sign-out safely. Never display stale/fake active-order status.

### 7.1 Current Order and merchant pickup

Opening the center destination fetches the server's single current active
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

**Historical implementation:** `CurrentOrderCubit` currently loads through
placeholder repositories. It can show not-configured, empty, failure, or
active test-fake states. No live map/service exists in the supplied code.

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
- **Scope:** only the five main-shell routes (and pages nested in them).
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

- `test/route_guard_test.dart`: the policy, the five shell routes, and the
  debug preview rule and switch.
- `test/main_navigation_test.dart`: branches, direct route entry, stack
  preservation, system back, shell visibility, keyboard, safe area and
  widths, all through the real `MainApp` and router.
- `test/current_order_test.dart`: the active-order use cases, the Cubit and
  the whole Current Order flow with test-only fakes.
- `test/login_screen_test.dart`: the preview button, including a simulated
  release build where the shell routes stay protected.
