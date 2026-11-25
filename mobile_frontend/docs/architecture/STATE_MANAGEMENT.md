# SHAHM Flutter — State Management

**2026-11-24 amendment (D-A82/D-A83), implemented in the client 2026-11-24:** Home no
longer consumes wallet state; remove its exclusive balance input/selector
and eager read. Keep one session-safe Wallet source and completion
invalidation. Home greeting selects only first-name presentation from the
existing session, without another user store/read. Current/history details
extend typed read models; reuse a complete session-owned history item and
introduce a detail read owner only if an actual on-demand lookup is needed.
Preserve CurrentOrderCubit, commands, recovery, timeout/session guards and
coalescing. The R02 chip-sharing descriptions below are pre-migration source,
not a requirement to keep a Home chip or fetch a balance for its emblem.

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
| `CurrentOrderCubit` (scope moved by D-A73) | Authenticated scope: one instance shared by the four-tab shell, the standalone `/current-order` page, the offer flow and recovery; survives tab changes | Created once above the shell and the standalone page; closed on sign-out | The captain's authoritative active order, its pickup state and the captain's location (§3.2), plus coalesced recovery reads (acceptance, startup, foreground return). Read by the Current Order page, the offer flow and the recovery navigation listener. Not read by the navigation bar |
| `HomeAvailabilityCubit` (Task 24) | Feature (Home route inside the shell) | The Home route builder (`BlocProvider`); closed on sign-out | The captain's **server-confirmed** availability and the enable/disable flow (§3.3). Read only by the Home availability card |
| `PendingOffersCubit` (Task 26; shell-scoped since Task 36) | Main shell | The shell route builder (`BlocProvider`); closed on sign-out | The offers the server says this captain can still accept, and the accept/decline commands (§3.3). Read by Home's «طلبات بانتظار القبول» and by `NewOfferSheetHost` (the new-offer sheet above every tab) |
| `DeclinedOffersCubit` (Task 36; shell-scoped since Task 38) | Main shell | The shell route builder (`BlocProvider`); closed on sign-out | The offers **this captain** declined, as the server records them (read-only; a decline never adds a row locally). Read by Order History. `load()` runs on first entry, tab return, visible resume and Retry; `refresh()` runs after a server-confirmed decline (`PendingOffersCubit.onDeclineConfirmed`): ignored before the first load, coalesced into exactly one follow-up read while a load is running, dropped after sign-out/close |
| `WalletCubit` (shell-scoped since R02, 2026-11-22) | Main shell: **one** instance shared by Home's balance chip and the Wallet tab | The shell route builder (`BlocProvider(lazy: false)`, which calls `loadBalance()` once); closed on sign-out | One server balance and the 7-day commission-debit history (D-A76). No holds, no recharge command, no client calculation. Home selects `state.balanceFils` (`BlocSelector`); Wallet watches the whole state. Session-safe: values are tagged with the signed-in captain (`sessionOwner`, the user id); a shell-level session listener calls `syncSession()`, so an account change clears them before any read and a late answer for the previous captain is dropped |
| Wallet delivery statistics (D-A76) | Same `WalletCubit`, independent read | Read only by Wallet (`ensureLoaded()` on first show, `load()` on re-show), never by Home | Lifetime delivered-order count and earnings from an explicit typed read model with their own loading / unavailable / not configured states; a statistics failure never clears the balance; unknown never reads as zero; earnings unavailable until D-P36 |
| Profile rating (D-A77) | Feature (Profile branch) | Profile route builder; closed on sign-out | Typed rating read model (unknown vs no ratings vs value); name/phone are read from `AppSessionCubit`, never copied into a second store. Reloaded on re-show and visible resume since R03; a re-read keeps the confirmed value on screen; overlapping triggers send one request |

- **Current Order workflow (D-A81, 2026-11-22).** The one app-level
  `CurrentOrderCubit` also owns the stage commands: `confirmPickup(rawPin)`,
  `startDelivery()`, `completeDelivery()` and `checkCommandStatus()`. Its
  `CurrentOrderActive` carries the authoritative order (stage =
  `order.status` as the server reported it), the pickup map inputs
  (captain location, route — pickup leg only) and one
  `OrderCommandFeedback` (sending, or the typed error of the last command
  for this order). Rules: a command is offered only for its server stage;
  one at a time; a malformed PIN sends nothing; the PIN is never stored in
  state; each start/complete attempt keeps its operation key after an
  **unconfirmed** outcome and the action stays blocked until
  `checkCommandStatus()` reconciles (pickup/start: a fresh read;
  completion: `GetOrderOutcome`, because a missing active order does not
  prove delivery); a read of an absent order while a command is in flight
  is not applied; answers for another order/assignment/session are
  dropped. A re-read of a shown order keeps it on screen (no loading flash)
  and keeps the feedback only while order, assignment and stage are
  unchanged. Confirmed completion → `CurrentOrderDelivered(receipt)`; a
  reconciled cancellation/reassignment → `CurrentOrderEnded`. No second
  active-order cache and no Cubit per button.
- **Completed deliveries (D-A81).** `CompletedDeliveriesCubit` is
  shell-scoped like `DeclinedOffersCubit`: `load()` (first page), `loadMore()`
  (server cursor), `refresh()` (coalesced; nothing before the first entry).
  After `CurrentOrderDelivered` the shell's listener calls it and
  `WalletCubit.invalidate()` (balance/debits, plus statistics only if Wallet
  read them; a read in flight gets one follow-up). A refresh failure never
  turns a confirmed delivery into a failure and never resends completion.
- **One owner per cross-screen read model (R02, lesson L-02).** When two
  screens show the same server value (the balance on Home and Wallet), they
  select it from **one** Cubit at their least common scope. A second Cubit,
  a cache or a screen input fed from elsewhere is forbidden: two owners can
  disagree after a debit, and a removed demo hook once was the only source.
  Lift the existing owner instead of adding one, keep unrelated reads of
  that Cubit lazy, and tag session-scoped data with the session owner.
| Account deletion (D-A78) | Feature (`/settings`) | Settings route builder | Confirmation → one submission → typed outcome; on completed deletion it asks `AppSessionCubit.endSession()` so every per-user scope closes |

- **Making state app-wide** needs real cross-feature demand.
- **Theme and locale:** neither can change at runtime, so they have no Cubit.
  Arabic is fixed through gen_l10n (D-A30); no locale Cubit or picker exists.
- **No `AppUserCubit`** (D-R07): the user belongs to `AppSessionCubit`.
- **Providing app-level Cubits:** they're provided with `BlocProvider.value`
  above the router. Read them with `context.watch` or `context.read`.
- **Feature Cubits are never global.**
- **Navigation has no Cubit** (D-A38). The selected tab is GoRouter's branch
  state, and the bar's indicators are plain inputs:
  - The bar has **no** indicator inputs (D-A70): no unread count (feature
    removed, D-A72) and no active-order/loading state (Current Order is a
    standalone page, D-A73).
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

### 3.2 `CurrentOrderCubit` (shared active-order owner, D-A73)

**Recovery (D-A73):** besides `load()`, the Cubit exposes a coalesced
recovery read used by confirmed acceptance, startup and foreground return.
While a read runs, a new trigger marks the result stale and schedules
exactly one follow-up read, so an older "none" cannot overwrite a newer
accepted assignment. A confirmed absence replaces any previous active order.
Failure/not configured never become "none". The navigation decision is made
by a route-level listener from typed state, never inside the Cubit.


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
  - **Shell-scoped since Task 36**, so `NewOfferSheetHost` can present a
    newly listed offer as a bottom sheet above any tab or the Profile
    route. The host keeps only offer ids (first list = already on Home;
    later unseen ids queued; ids gone from the server list forgotten), one
    sheet at a time, foreground and signed-in only, and re-reads once on
    resume if a sheet was waiting. It owns no offer data and sends commands
    through this Cubit. After a confirmed instant accept it calls
    `CurrentOrderCubit.refreshed()` and opens Current Order only for the
    offer's `orderId`.

  **Not implemented:** location tracking, 30 s uploads, the 90 s freshness
  rule, FCM/APNs, the real permission adapter and the backend.
- **Notifications Cubit — removed (D-A72, 2026-11-20).** Historical
  description of the deleted Task 35 implementation: `NotificationsCubit`,
  scoped to the main shell (closed on sign-out) because the screen and the
  bar's unread dot share it. Loads the server list (Admin announcements,
  assigned orders) and unread count via `GetNotifications`; loads when the
  tab is first built, when it becomes visible again, and on resume only
  while visible. Keeps the list while re-reading, clears it on any failure,
  drops late answers. Read-only: no mark-as-read, no local count. FCM is a
  delivery hint, not authoritative read state. The assigned-order tap
  re-reads `CurrentOrderCubit` and opens Current Order only on an `orderId`
  match (screen-side, not in a Cubit).
- **Wallet Cubit (Task 34, revised by D-A74/D-A76; scope changed by R02 —
  see §2, which is current):** `WalletCubit`, historically
  scoped to the Wallet route (closed on sign-out). Reads the **single**
  server balance and the last-7-days commission debits through `GetWallet`
  (the one place the display window is applied); no held/available fields,
  no credit list in the UI; nothing is calculated on the phone. Statuses: initial, loading, noSession, notConfigured, noInternet,
  failure, loaded; the last overview stays visible while re-reading and is
  cleared by any failure; late answers (newer load, sign-out, close) are
  dropped. Read-only: no recharge/payment command. *Historical until R02:*
  the Home chip was a screen input that production left null and only the
  debug demo filled. **Current:** the router selects the shell
  `WalletCubit`'s `balanceFils` into `HomeScreen(walletBalanceFils:)`; with
  the production placeholder it is null («—», "not configured").
- **Order workflow Bloc/Cubit:** use cases for task-oriented POST commands,
  not a mutable status PATCH field. Always recheck server state and typed
  business error codes; use stable idempotency keys per attempted operation.
- **Scheduled future commitments:** shown separately from the single active
  delivery (no commission reservation exists, D-A74).

## 3.4 Screen composition vs Cubit state vs UI effects (Home, Task 27)

A screen widget composes; Cubits own async business state; small widgets
own Flutter-only resources and presentation side effects.

| Concern | Owner on Home |
|---|---|
| Page layout (app bar, one `CustomScrollView`, sliver padding) | `HomeScreen`, a `StatelessWidget` (`view/home_screen.dart`) |
| Availability and offers state, commands, stale-result and duplicate guards | `HomeAvailabilityCubit` (route-scoped), `PendingOffersCubit` (shell-scoped since Task 36, same instance) |
| Initial load (once per mount), reload when Home is shown again (Task 28) and on app resume only while Home is visible (Task 29), listener disposal | `HomeLifecycleBridge` (`widget/`), the only `StatefulWidget`: it owns one `AppLifecycleListener` and no business state |
| Permission explanation popup | `HomeAvailabilityRationaleListener` (`BlocListener` + `showAppPopup`); the Cubit only exposes `pendingRationale` |
| Section UI | `HomeGreeting`, `HomeAvailabilityCard` / `HomeAvailabilityNotice`, `PendingOffersHeader` / `PendingOffersSliver`, `HomeAppBar` (D-A82: emblem, no wallet chip), one meaningful section per file in `widget/` |

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
