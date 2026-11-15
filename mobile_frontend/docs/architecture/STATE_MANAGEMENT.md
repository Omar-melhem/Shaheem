# SHAHM Flutter — State Management

**Approved target through 2026-11-14.** Existing Cubits below describe historical implemented boundaries, not a connected Backend. See D-A53–D-A68 for final integration requirements.

How state is managed in the Flutter app. Decisions referenced: D-A03, D-A11,
D-A13, D-A20, D-A38, D-A41, D-R06, D-R07, C-33.

---

## 1. Cubit or Bloc

| Use | When | Examples |
|---|---|---|
| **Cubit** | Simple state with straightforward methods | Availability toggle, loading one screen, a filter, a simple form |
| **Bloc** | Several explicit events, or workflows that benefit from event handling | Order accept/reject/progress, complex multi-source operations |
| **Neither** | Static values or stateless helpers | Typography, colors, validators, `AppTools` |

**Shared rules:**
1. Choose the simplest tool; don't use Bloc just because the project uses BLoC.
2. **No business logic in widgets.** Cubits and Blocs call **use cases**,
   never APIs or storage.
3. **Don't duplicate rules** across Cubits or screens.
4. **Model states explicitly:** loading, success, empty, failure. Prefer
   sealed state classes (see `SplashState`, `AppSessionState`).
5. **No Cubit per tiny widget.**
6. **Stale async results:** Cubits that run async work must ignore results
   that were superseded (by a newer attempt, a sign-out, or `close()`).

## 2. App-level vs feature-scoped state

| State holder | Scope | Created | Purpose |
|---|---|---|---|
| `AppConnectivityCubit` | App-wide, one instance | `MainApp.initState` | Internet reachability for every route |
| `AppSessionCubit` | App-wide, one instance | `MainApp.initState` | Session readiness and the current `AppUser` |
| `SplashCubit` | App-wide instance, startup-only role | `MainApp.initState` | Orchestrates startup; idle after it resolves |
| `LoginCubit` | Feature (Login) | The `/login` route builder (`BlocProvider`); closed when Login leaves the tree | Login form values, field errors, submission (§3) |
| `CurrentOrderCubit` | Main shell (one instance while the shell is open) | The shell route builder (`BlocProvider`); closed on sign-out | The captain's active order, its pickup state and the captain's location (§3.2). Read by the Current Order screen and by `AppNavBar` |
| `HomeAvailabilityCubit` (Task 24) | Feature (Home route inside the shell) | The Home route builder (`BlocProvider`); closed on sign-out | The captain's **server-confirmed** availability and the enable/disable flow (§3.3). Read only by the Home availability card |
| `PendingOffersCubit` (Task 26) | Feature (Home route inside the shell) | The Home route builder (`BlocProvider`); closed on sign-out | The offers the server says this captain can still accept, and the accept/decline commands (§3.3). Read only by Home's «طلبات بانتظار القبول» |
| Future wallet/order feature state | Feature | Feature route or screen | Server-backed wallet summary and ledger; choose Cubit or Bloc based on workflow complexity. No client-side wallet calculations or holds (D-A25, D-A28, D-A50) |

- **Making state app-wide** needs real cross-feature demand.
- **Theme and locale:** neither can change at runtime, so they have no Cubit.
  Arabic is fixed through gen_l10n (D-A30); no locale Cubit or picker exists.
- **No `AppUserCubit`** (D-R07): the user belongs to `AppSessionCubit`.
- **Providing app-level Cubits:** they're provided with `BlocProvider.value`
  above the router. Read them with `context.watch` or `context.read`.
- **Feature Cubits are never global.**
- **Navigation has no Cubit** (D-A38). The selected tab is GoRouter's branch
  state, and the bar's indicators are plain inputs:
  - `hasActiveOrder` and `isCheckingActiveOrder` are derived by `AppNavBar`
    from the shared `CurrentOrderCubit` backed by server state. Refresh on
    sign-in, order acceptance, status changes, verified push, resume and
    opening Current Order, without polling or a second copy of the state.
  - `unreadCount` belongs to the future Notifications Cubit and comes from
    Backend/PostgreSQL. In the old unintegrated snapshot the honest default
    (`0`) is still shown; **zero is not the production source of truth**.
  - Don't add a `NavBarCubit`, and don't fetch anything inside the bar.
- **The debug preview is not session state** (D-A40): `DebugShellPreview` is
  a temporary in-memory switch read by the route guard. `AppSessionCubit`
  never changes because of it.

Details of the app-level Cubits: `GLOBAL_SERVICES.md`. The startup Cubit:
`ROUTING_AND_STARTUP.md`.

## 3. Form validation flow (D-A20)

Every form follows this pattern. `LoginCubit` is the reference
implementation (§3.1).

```text
Widget ──onChanged/onSubmit──► FeatureCubit ──calls──► Validators.* (pure)
   ▲                               │                     └─► ValidationError?
   └────── renders state ◄─────────┘  (values, per-field errors, submit status)
                                   └─on valid submit──► use case ──► repository
```

**The form's Cubit:**
- Holds the field values, a `ValidationError?` per field, and a submit status
  (`idle` / `submitting` / `success` / `failure`).
- Validates fields with `Validators.*`.
- **Ignores submit while one is in flight** (no overlapping submissions).

**Everything else:**
- **Widgets** show `validationMessage(context.l10n, error)` and never
  re-implement a rule.
- **Server checks** (such as wrong credentials) come from the use case
  result, never from a validator.
- **Client validation** is not a security boundary.
- **No global `ValidationCubit`** (D-R06).

### 3.1 `LoginCubit` (D-A65 validation implemented 2026-11-14, Task 03)

Files: `lib/view/screens/authentication/cubit/login_cubit.dart` and
`login_state.dart`.

| Member | Behavior |
|---|---|
| `usernameChanged(value)` | Stores the username **exactly as typed** and clears its error |
| `passwordChanged(value)` | Stores the password **privately in the Cubit**, unchanged, and clears its error |
| `submit()` | Ignored while submitting or after success. Computes `Validators.normalizeLoginUsername(state.username)`, validates with `Validators.loginUsername` (which checks that same normalized value) and `loginPassword`; if either fails, emits the field errors and stops. Otherwise emits `submitting`, takes a session token (`AppSessionCubit.beginAttempt`), calls `SignIn` with the **normalized username and the password exactly as typed**, and maps the result |

**Username normalization applies only to the outgoing value.** Outer
whitespace is trimmed, and a 10-digit phone typed in Arabic-Indic, Extended
Arabic-Indic or mixed digits becomes Latin digits. `LoginState.username`
and the visible field keep the raw input, so the captain never sees their
text rewritten. The password is never trimmed or otherwise altered (D-A65
and its supplement).

`LoginState`:
- `username`, `usernameError`, `passwordError`.
- `status`: `idle`, `submitting`, `success`.
- `failure`: `invalidCredentials`, `accountBlocked`, `noInternet`,
  `serviceUnavailable`, `profileFailure`, `backendNotConfigured`,
  `unexpected`.
- `failureCount`, so a repeated identical failure toasts again.

**The password is never in the state** (D-A34), and `toString` lists only
status and errors.

**On success:** it calls `AppSessionCubit.authenticate(user, token)`, then
emits `success`. The router redirect, not the Cubit, then opens Home. A
response that arrives after a sign-out (stale token) is ignored.

**UI:**
- `LoginForm` renders field errors inline, and holds the Forgot Password
  action under the password field.
- `LoginScreen` turns `failure` into an error toast through
  `loginFailureMessage`. The old generic handling of `accountBlocked` is
  historical; the **approved server rule immediately revokes suspended
  sessions** and returns users to Login. Wrong credentials stay generic.

Validator API and rules: `../ui/SHARED_UI_COMPONENTS_REFERENCE.md` §7.

### 3.2 `CurrentOrderCubit` (historical implementation; final server rules approved)

Files: `lib/view/screens/current_order_screen/cubit/current_order_cubit.dart`
and `current_order_state.dart`. Not a form; listed here as the reference for
a load-and-display feature.

| State | Meaning | `hasActiveOrder` |
|---|---|---|
| `CurrentOrderInitial` | Nothing looked up yet | false |
| `CurrentOrderLoading` | A lookup is running | false |
| `CurrentOrderEmpty` | The server answered: no active order | false |
| `CurrentOrderNotConfigured` | No orders backend is connected; nothing was checked. Permanent until integrated, **not** an outage: no Retry | false |
| `CurrentOrderFailure(kind)` | A real lookup failure: `noInternet`, `serviceUnavailable` or `unexpected`. Retryable | false |
| `CurrentOrderActive(order, pickup?, captainLocation?)` | The server reported an active order. `pickup` is the restaurant's well-formed coordinates, or null when missing or malformed (`canShowMap` false). `captainLocation` is read only when a map can be shown | true |

Active-order existence and pickup availability are **independent**: an
order without usable coordinates is still `CurrentOrderActive` and lights
the bar's indicator; only its map is unavailable (C-33).

| Member | Behavior |
|---|---|
| `load()` | Ignored while `CurrentOrderLoading`. Emits loading, calls `GetActiveOrder`, maps the result. For an order whose pickup is mappable it then calls `GetCaptainLocation` |
| `retryLocation()` | Only from `CurrentOrderActive` with a mappable pickup and a location result; reads the location again without repeating the order lookup |

- **No cache and no client status policy:** the server decides what is
  active; every `load()` replaces the state. Its final active statuses are
  `accepted`, `heading_to_pickup`, `picked_up`, `on_the_way` and future
  scheduled commitments are separate (D-A68).
- **Failures are never "empty":** an error or a missing backend can't look
  like "no active order", and can't light the bar's active-order indicator.
- **Stale answers:** a generation counter and `isClosed` drop results that
  arrive after a newer lookup or after sign-out.
- **Privacy:** no state overrides `toString`, so order and restaurant
  details don't reach logs.

### 3.3 Approved new feature state (not implemented)

- **Availability:** the command part is **implemented** as
  `HomeAvailabilityCubit` (Task 24):
  - the toggle's value is the last server-confirmed status only;
  - enabling checks the session, then backend readiness (not configured
    means no prompts), then the requirements without prompts, then shows an
    explanation, then the prompts on «متابعة», then re-checks, then sends
    the server command;
  - disabling sends only the command;
  - unknown outcomes keep the last confirmed status with an "unconfirmed"
    notice;
  - a generation counter, `isClosed` and the session check drop late
    answers;
  - Home reloads on open, on returning to the Home tab and on resume
    while Home is visible, without prompting.

  **Pending offers (Task 26):** `PendingOffersCubit`.
  - The list is exactly the server's last answer: nothing is filtered or
    expired locally, and an id the server didn't list is never sent.
  - "Not configured" and "confirmed empty" are distinct states.
  - One command at a time; a card leaves the list only after a
    server-confirmed accept or decline, and then the list is re-read.
  - A confirmed accept asks `CurrentOrderCubit` to refresh (no
    navigation).
  - Unknown outcomes and "no longer available" disable that card until a
    refresh.
  - Loaded on open, on returning to the Home tab, on resume while Home is
    visible and on explicit refresh; never polled.

  **Not implemented:** location tracking, 30 s uploads, the 90 s freshness
  rule, FCM/APNs, the real permission adapter and the backend.
- **Notifications Cubit:** server-backed notification list and unread count;
  FCM is a delivery hint, not authoritative read state.
- **Wallet Cubit:** server total/available/holds/ledger, without calculating
  financial consequences on the phone.
- **Order workflow Bloc/Cubit:** use cases for task-oriented POST commands,
  not a mutable status PATCH field. Always recheck server state and typed
  business error codes; use stable idempotency keys per attempted operation.
- **Scheduled future commitments:** shown separately from the single active
  delivery, even though commission was reserved on Admin assignment.

## 3.4 Screen composition vs Cubit state vs UI effects (Home, Task 27)

A screen widget composes; Cubits own async business state; small widgets
own Flutter-only resources and presentation side effects.

| Concern | Owner on Home |
|---|---|
| Page layout (app bar, one `CustomScrollView`, sliver padding) | `HomeScreen`, a `StatelessWidget` (`view/home_screen.dart`) |
| Availability and offers state, commands, stale-result and duplicate guards | `HomeAvailabilityCubit`, `PendingOffersCubit` (route-scoped, unchanged) |
| Initial load (once per mount), reload when Home is shown again (Task 28) and on app resume only while Home is visible (Task 29), listener disposal | `HomeLifecycleBridge` (`widget/`), the only `StatefulWidget`: it owns one `AppLifecycleListener` and no business state |
| Permission explanation popup | `HomeAvailabilityRationaleListener` (`BlocListener` + `showAppPopup`); the Cubit only exposes `pendingRationale` |
| Section UI | `HomeGreeting`, `HomeAvailabilityCard` / `HomeAvailabilityNotice`, `PendingOffersHeader` / `PendingOffersSliver`, `HomeAppBar` / `WalletBalanceChip`, one per file in `widget/` |

Rules:
- **`StatefulWidget` is not forbidden.** Use it only when Flutter-local
  lifecycle, animation, controller or focus state requires it, never for
  business state.
- **No `BuildContext`, widgets, ARB strings, popups or layout math in
  Cubits;** no eligibility or request state in widgets. UI callbacks that
  call `cubit.accept(id)`, `cubit.requestChange(value)` and similar are
  correct; don't wrap them in extra Cubits (no `HomeCubit`).
- **Subscribe where the data is used,** to the smallest value:
  `HomeGreeting` uses `context.select` for the display name, and each
  section watches only its own Cubit. A greeting change rebuilds only the
  greeting (tested in `test/home_architecture_test.dart` with widget
  identity). The availability and offers sections were already
  independent.
- **Keep lists lazy:** `SliverList.separated` with `ValueKey(offer.id)`;
  no `shrinkWrap` lists or `children: offers.map(...)`.
- **Load in one place:** never in `build`, and never twice (route plus
  widget).

## 4. Testing state

- **Cubit tests:** plain `flutter_test` with fakes from `test/fakes.dart` (no
  `bloc_test` package). Cover transitions, retry and duplicate-call guards,
  and stale results.
- **Examples:** `test/splash_cubit_test.dart`, `test/connectivity_test.dart`,
  `test/current_order_test.dart`.
