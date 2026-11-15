# SHAHM Flutter — Global Services and App-Level State

**Note:** existing Cubits and repository method names below describe the 2026-11-11 Flutter snapshot. The authoritative new target is approved in D-A53–D-A58; no production integration has been implemented in the available source.

The app-wide connectivity monitor, global banner, lifecycle handling, session
state and the auth use cases. Decisions referenced: D-A10 to D-A18, D-R02,
D-R07, D-R08.

---

## 1. What is app-wide

| Component | Path | Instances |
|---|---|---|
| `InternetConnectionService` (`InternetConnectionCheckerPlusService`) | `lib/helper/network/internet_connection_service.dart` | 1, created in `main()` |
| `AppConnectivityCubit` + `AppConnectivityState` | `lib/view/app_state/connectivity/` | 1, created in `MainApp` |
| `GlobalConnectivityBanner` | `lib/view/app_state/connectivity/global_connectivity_banner.dart` | Mounted once in `MaterialApp.router`'s `builder` |
| `AppSessionCubit` + `AppSessionState` | `lib/view/app_state/session/` | 1, created in `MainApp` |
| `AuthRepository` (currently `AuthRepositoryPlaceholder`) | contract in `lib/domain/repositories/`, implementation in `lib/data/repositories/` | 1, created in `main()` |
| `CheckAuthStatus`, `GetCurrentUser`, `SignIn`, `SignOut` | `lib/domain/use_cases/` | Stateless, built in `MainApp` (`SignIn` is passed to the router for `LoginCubit`) |

Composition and ownership are described in `ARCHITECTURE.md` §4.

## 2. Connectivity

### 2.1 Service

```dart
enum InternetReachability { unknown, connected, disconnected, checkFailed }

abstract class InternetConnectionService {
  Stream<InternetReachability> get statusChanges; // probes only while listened to
  Future<InternetReachability> checkNow();        // bounded; never unknown
  Future<void> dispose();
}
```

`InternetConnectionCheckerPlusService({connection, checkInterval = 10 s,
checkTimeout = 10 s})`:
- **Real reachability:** it makes real requests to public endpoints, rather
  than reading the Wi-Fi state. Built on `internet_connection_checker_plus`
  3.1.2.
- **Owns its package instance:** `createInstance` rather than the singleton,
  so `dispose()` is safe.
- **Stream:** probes every 10 s only while it has a listener, and emits only
  on change. This is not high-frequency (D-R08).
- **`checkNow()`:**
  - A timeout or error gives `checkFailed`, **never** `disconnected`.
  - Concurrent calls share one probe.
- **No package types** are exposed to Cubits or UI.

### 2.2 `AppConnectivityCubit`

State: `AppConnectivityState { status, isChecking, isDisconnected }`, which
starts `unknown`.

| Method | Behavior |
|---|---|
| `start()` | Subscribe once and run the initial check. Repeated calls do nothing |
| `check()` → `Future<InternetReachability>` | Shared bounded check. A newer stream event supersedes an in-flight check result |
| `pauseMonitoring()` / `resumeMonitoring()` | Cancel the subscription / resubscribe plus one check (resume only after a pause) |
| `close()` | Cancels the subscription |

### 2.3 Lifecycle (D-A18)

`MainApp` owns an `AppLifecycleListener`:
- `onPause` calls `pauseMonitoring`.
- `onResume` calls `resumeMonitoring`.

**How it behaves:**
- **Stale events:** cancelling and later resubscribing (the package README's
  guidance) avoids buffered stale events.
- **Background:** no probes run.
- **Process restart:** monitoring doesn't continue after the OS suspends or
  kills the app. A new process starts with `unknown` and a fresh check.
- **Session:** it is **not** revalidated on resume, and Splash isn't shown
  again.

### 2.4 Global banner

`GlobalConnectivityBanner(child:)` wraps the routed Navigator. It shows a top
bar (in the primary color, inside the safe area) with «لا يوجد اتصال
بالإنترنت» and Retry, which calls the shared `check()` and is disabled while
checking.

**Shown only when:**
- The connection is confirmed `disconnected`, **and**
- The session isn't `SessionUnknown`. During startup, `NoInternetScreen`
  handles offline instead.

**Behavior:**
- `checkFailed` and `unknown` never show it.
- It never navigates.
- The routed child keeps its position in the tree, so toggling the banner
  doesn't rebuild routes or lose their state.
- The top inset is removed from the child while the bar is visible.
- `GlobalConnectivityBanner.barKey` identifies the bar in tests.

### 2.5 Rules for consumers

- **Display:** `context.watch<AppConnectivityCubit>().state`. **One-shot
  check:** `context.read<AppConnectivityCubit>().check()`.
- **Never** create a service, subscribe to it, or add a banner from a screen
  or feature Cubit.
- **Not an API gate** (D-A12):
  - Don't block requests on the cached state, and don't assume they'll
    succeed.
  - Classify each request failure from its real error.
  - An internet probe says nothing about SHAHM backend health.

| State | Meaning | UI |
|---|---|---|
| `disconnected` | No usable public internet | Global banner; startup shows No Internet |
| `connected` | Public internet reachable | No banner |
| `checkFailed` / `unknown` | No reliable result | No "offline" claim; bounded retry at startup |
| Backend unavailable | Internet OK, SHAHM API failing | Feature or service error with Retry |
| Request-specific failure | One request failed | Handled by the repository or feature |

## 3. Session and current user

### 3.1 Approved backend session contract (D-A53)

- ASP.NET Core Identity manages users, Admin permissions, roles, passwords and
  active/suspended status. Admin creates accounts, resets passwords and
  completes profiles; an incomplete captain profile cannot receive offers.
- Access JWT: **15-minute** lifetime, retained **in memory** on Flutter.
  Refresh token: hashed on server, rotated on refresh, **90-day idle
  expiration** renewed on valid authenticated activity. Flutter stores the
  refresh credential only in `flutter_secure_storage`.
- Only one device session is active per captain. A new sign-in immediately
  invalidates the older session while preserving any in-progress order.
  Account suspension/revocation must affect both protected API requests
  and refresh-token renewal immediately, even if an access token has not
  naturally expired. Admin handles the captain's active delivery.
- On an expired access token, try one controlled refresh/retry flow; do
  **not** sign out on every ordinary `401` before checking whether refresh
  can succeed. On rejected/expired/revoked refresh or suspended account,
  clear local credentials and sign out; on a network outage/5xx keep the
  recoverable session state and show a specific error, never an invented
  invalid-password or logged-out response.
- Username is case-insensitive on the server. Trim only its outer spaces
  at sign-in; send password unchanged. Password and tokens are never logged.

### 3.2 Approved REST, realtime, notifications and GPS services

- `data/` owns typed REST clients generated and tested against OpenAPI.
  Use POST business commands for order state changes and stable RFC 9457
  Problem Details error codes. Keep domain repositories and use cases
  independent of generated types.
- SignalR pushes foreground changes, while FCM/APNs provide mobile push;
  **PostgreSQL** remains authoritative for orders, offers, wallet and unread
  notifications. Resume/reconnect or relevant push triggers a REST recheck.
  Never hold a persistent mobile SignalR channel in the background as a
  requirement.
- PostgreSQL transactional outbox persists critical business events with
  operation records; worker retries delivery. Device push cannot be
  guaranteed and must have bounded offer TTL. Enforce expiry on REST accept.
- GPS target updates every 30s and freshness for new offers is 90s as
  checked by Backend. No new offers when location expires; do not cancel an
  existing delivery. Availability requires location **and** push permission.
- End-user navigation state: `AppSessionCubit` is the single memory-only
  holder of user/session readiness. `NotificationsCubit` (future) is the
  state holder for server unread count; `CurrentOrderCubit` (existing shell
  instance) refreshes at approved events, without periodic polling.

### 3.3 Historical Flutter domain contract (not yet production-integrated)

`AuthRepository` has `hasStoredSession`, `validateSession`, `getCurrentUser`,
`signIn`, `clearSession`. Existing use cases are `CheckAuthStatus`,
`GetCurrentUser`, `SignIn`, `SignOut`. `AppSessionCubit` states:
`SessionUnknown`, `SessionUnauthenticated`, `SessionAuthenticated(user)`.
Its attempt-generation checks still guard against stale async results;
`endSession()` invalidates attempts and signs out.

The current repository is a deliberate **BackendNotConfigured** placeholder.
Do not fabricate a session or claim failed network integration means no
active order. Adapt the error mapping and 401/refresh handling during the
real auth feature migration. Blocked credentials must **not** be retained
under the outdated D-P16 pending policy.

## 4. Remaining implementation work (not undecided product rules)

Write the concrete auth/OpenAPI DTOs, token rotation/session database tables,
server-side suspension and one-device invalidation, centralized HTTP error
handling, notification token registration, SignalR groups/events and GPS
uploads. The backend and real credential storage were not present in the
supplied Flutter code; device and integration testing has not been run.

## 5. Tests

- `test/connectivity_test.dart`: the service (real package with a custom
  check callback, no network) and the Cubit (start-once, stale checks,
  pause and resume, close).
- `test/auth_use_cases_test.dart`: every use-case outcome and the model
  mapping.
- `test/splash_cubit_test.dart`: startup transitions, reuse of the shared
  check, auto-resume, stale results.
- `test/startup_flow_test.dart`: the full app.
  - The banner on Home and on Login from the same global state.
  - The banner hidden for `checkFailed`, mounted once, page state kept, and
    a single monitor subscription.
  - Logout.
