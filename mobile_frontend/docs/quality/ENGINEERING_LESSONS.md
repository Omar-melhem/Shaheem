# SHAHM Flutter — Engineering Lessons (enduring prevention rules)

One entry per **confirmed** issue (or confirmed audit mistake). Each says
what happened, how sure we are, the smallest fix, how it was verified and
the rule that stops it recurring. Recommendations that were not
implemented are listed at the end with their rationale, not as lessons.
Tracker: [`REMEDIATION_STATUS.md`](REMEDIATION_STATUS.md). Counting rules:
[`AUDIT_METHOD.md`](AUDIT_METHOD.md).

All entries below: source revision `cefad0a` plus the uncommitted
remediation working tree, verified 2026-11-22 (results:
`REMEDIATION_STATUS.md` and `../project/PROJECT_STATUS.md` §5).

---

## L-01 — Unknown routes render localized safe UI (ARCH-08 / LOC-01)

- **Scenario:** a signed-in captain opens an unknown or removed path (for
  example the removed notifications path). `resolveRedirect` correctly lets
  protected-looking paths through for a valid session, and `GoRouter` had no
  `errorBuilder`, so go_router's English "Page Not Found" with the raw URI
  appeared.
- **Confidence:** source-confirmed; now covered by widget tests through the
  real router.
- **Impact:** non-Arabic, technical text; a URI that may contain private
  query values shown on screen.
- **Fix:** `errorBuilder: RouteErrorScreen.fromState` (`AppStatusMessage`,
  new ARB keys, one "back to Home" action). Unmatched location → "not
  found"; any other routing error → a separate "could not open" message.
- **Verification:** `main_navigation_test.dart` "route errors" (signed in /
  signed out / unresolved session; no English text, no path; Home action).
- **Rule:** every `GoRouter` has a localized `errorBuilder`; the guard runs
  first and stays the only auth policy; never show the location or the
  exception; never silently redirect unknown paths to Home.
- **Recurrence check:** the route-error tests; reviewing any new router.

## L-02 — Both Home and Wallet select one session-scoped wallet read (API-05)

- **Scenario:** Home's balance chip was a screen input. Production passed
  null; only the debug demo injected a value through a router hook. So the
  approved "same single balance source" (D-A71) existed only in the demo.
- **Confidence:** source-confirmed (`go_router.dart`, Home route).
- **Impact:** production Home could never show a balance even after a
  wallet API existed; removing the demo would have removed the only source.
- **Fix:** the existing `WalletCubit` moved from the Wallet route to the
  shell (`lazy: false`, `loadBalance()` once); Home selects `balanceFils`,
  Wallet reads statistics lazily (`ensureLoaded()`). Values are tagged with
  the session owner; a shell session listener calls `syncSession()`, so an
  account replacement clears them and drops late answers. The demo
  connector and its hooks were deleted as redundant.
- **Verification:** `wallet_test.dart` "shared source (R02)" (read counts,
  zero/negative/over-cap kept, unknown is null, stale old-captain answer
  dropped, sign-out) and real-app cases (chip = Wallet, statistics failure
  independent, «—» on failure); demo dry run and isolated `--apply`
  rehearsal.
- **Rule:** a value shown on several screens has exactly **one** owner at
  their least common scope; lift the existing owner rather than adding a
  second Cubit/cache; define each load trigger explicitly; keep unrelated
  reads lazy; never derive a balance from history or substitute zero.
- **Recurrence check:** review any new `BlocProvider` for an already-owned
  read model; the R02 read-count tests.

## L-03 — Count definitions from the snapshot, not hand-maintained totals (REV-01/02)

- **Scenario:** the first audit reported 14 Cubits and 21 state owners
  (actual: 11 Cubits, 1 dead Bloc, 16 `StatefulWidget`, 2
  `ChangeNotifier`), claimed every runtime file was "fully read", and counted
  an approved-but-undesigned capability next to screens.
- **Confidence:** reproduced by re-counting with the documented command.
- **Impact:** wrong numbers propagate into plans and tests.
- **Fix:** `AUDIT_METHOD.md` (counting commands, exclusions, coverage
  wording, screen/capability categories); revised reports recomputed from
  the final source.
- **Rule:** recompute every count from the snapshot with a stated command
  and list the classes; separate inventory membership from content read;
  never hard-code audit totals in tests or docs.

## L-04 — Refresh read models on the moments a feature defines (STATE-01)

- **Scenario:** the Profile rating loaded once per session, unlike Home and
  My Orders, so it could stay stale until restart.
- **Confidence:** source-confirmed.
- **Fix:** Profile reloads on re-show and on resume while visible, using the
  same mechanics as My Orders; a re-read keeps the confirmed value on
  screen; overlapping triggers send one request.
- **Verification:** `profile_settings_test.dart` "refresh".
- **Decision recorded:** no shared lifecycle helper — the mechanics are
  ~15 lines and the policies differ per feature (Wallet has no resume read,
  D-P42). A `StatefulWidget` owning an `AppLifecycleListener` is correct.
- **Rule:** every read model has a written trigger table
  (`ROUTING_AND_STARTUP.md` §7); no loads in `build`, no polling; resume
  reads only while visible.

## L-05 — A command timeout is unconfirmed, never failure or success (ARCH-06)

- **Scenario:** timeouts were mapped implicitly by catch-alls. For reads that
  was acceptable, but the account-deletion timeout became
  `AccountDeletionFailure`, whose copy says "the request could not be sent
  and your account was not deleted" — false when the request may have
  arrived.
- **Confidence:** source-confirmed; now unit-tested.
- **Fix:** explicit `on TimeoutException` everywhere; new
  `AccountDeletionUnconfirmed` / `AccountDeletionFlow.unconfirmed` with
  truthful copy and no resend from the same screen.
- **Verification:** `timeout_policy_test.dart`.
- **Rule:** reads: timeout = service did not answer (service-unavailable
  where the contract has it, else retryable failure), never offline/empty/
  zero/logout. Commands: timeout = unknown outcome; no "not sent", no
  success, no rejection, no automatic resend. Table:
  `GLOBAL_SERVICES.md` §3.4.

## L-06 — Delete verified-dead code; don't keep it because a test calls it (ARCH-02/03, SW-04)

- **Scenario:** `AppTools` (except one unfocus call), both loading widgets,
  `CustomePadding`, the chip sizing helpers and the whole legacy
  `SplashBloc` (which also redefined `SplashState`/`SplashInitial`) had no
  production caller; tests alone kept them alive; `SplashBloc` was the only
  analyzer finding and the only direct `bloc` importer.
- **Confidence:** source-confirmed by repository-wide search (lib, test,
  preview, tool, native).
- **Fix:** deleted with their exclusive tests; unfocus inlined with the same
  `hasPrimaryFocus` check; the direct `bloc` dependency removed
  (`flutter_bloc` keeps it transitively); `SplashCubit` untouched.
- **Verification:** `flutter analyze` clean (the baseline info is gone);
  full test suite.
- **Rule:** before keeping a public helper, find a production caller; a
  test-only caller is not a reason to keep code. Don't move dead code to a
  "correct" folder — delete it. Keep an unused family only when an owner
  decision is open (text widgets, D-P43).

## L-07 — Shared navigation helpers live in `view/navigation/` (ARCH-04)

- **Scenario:** `openCurrentOrderPage` sat in the offer-sheet host file, so
  Home imported the sheet host to navigate.
- **Fix:** moved unchanged to `view/navigation/current_order_navigation.dart`.
- **Verification:** active-order recovery and offer-sheet tests.
- **Rule:** a helper used by two features gets its own file named for its
  responsibility; never import a host widget for a utility.

## L-08 — Popups return typed results; screens don't pop guessed navigators (SW-02)

- **Scenario:** two confirmations used `closesPopup: false` plus
  `Navigator.of(context, rootNavigator: true).pop(true)` from the screen,
  relying on `showDialog` using the root navigator.
- **Confidence:** contract gap; **no crash was reproduced** (recorded as a
  component-contract improvement, not a production defect).
- **Fix:** `AppPopupAction<T>.result`; the popup pops its own hosting
  navigator, ignores a second tap during the exit animation, then runs the
  callback once. Both callers migrated.
- **Verification:** `custom_widgets_test.dart` "AppPopup typed result".
- **Rule:** a dialog that answers a question completes its `Future` with a
  typed value; cancel/barrier/back = null; never reach for the root
  navigator from feature code.

## L-09 — Reuse `AppButton` for busy primary actions (SW-03)

- **Scenario:** No Internet and Splash Retry hand-built `FilledButton` with
  their own spinner, with different minimum height and semantics.
- **Fix:** `AppButton(label: retry, isLoading: …, onPressed: …)`.
- **Verification:** `startup_flow_test.dart` (busy state, repeated taps start
  one check, 320 px at text scale 2.0).
- **Rule:** loading/disabled/semantics of a primary action come from
  `AppButton`; don't reimplement them locally.

## L-10 — Sentences with label + value are one ARB key (LOC-02/03)

- **Scenario:** visible lines and screen-reader labels were composed in
  code (`'$label: $value'`, `[a, b].join('. ')`, `'$outcome · $kind'`),
  fixing Arabic word order and punctuation in Dart.
- **Fix:** semantic ICU keys per meaning (list in `DESIGN_SYSTEM.md` §5);
  the bare label keys were removed after proving non-use.
- **Not changed (layout, not wording):** a decorative bullet, the space
  between two complete sentences, amount + currency symbol.
- **Rule and checklist:** `DESIGN_SYSTEM.md` §5 "Sink checklist".

## L-11 — Classify before "fixing" (ARCH-01, SW-01)

- **Scenario:** the audit called routing under `util/routes` a layering
  violation and proposed moving it; it proposed a generic surface card for
  similar borders.
- **Resolution:** both are **not defects**. The router is the documented
  composition boundary (`ARCHITECTURE.md` §2); the cards share no behavior
  (`CUSTOM_WIDGET_CONTRACT_STANDARD.md` §2). Nothing moved or abstracted.
- **Rule:** a finding needs an approved rule it breaks or a reproducible
  failure; style similarity and folder taste are recommendations.

## L-12 — Don't over-model the client from backend wishes (API-02/03/07, REV-03)

- **Scenario:** the audit treated every backend attribute missing from a
  client model as a defect (username/status in `AppUser`, offer expiry,
  idempotency-key arguments) and grouped different fields under ranged IDs.
- **Resolution:** a client field is required only when a current consumer
  or operation needs it. Session faults are typed results, not `AppUser`
  fields; the server enforces offer expiry; request-key ownership and retry
  lifetime belong to the API contract (no signature change until then). The
  revised data report gives every field its own ID.
- **Rule:** model what a consumer needs; record the rest as a contract gap
  in the data report, never as a guessed DTO.

## L-13 — Native metadata is source evidence until a build proves it (LOC-05, PLAT-01)

- **Scenario:** the visible name was the template; the release manifest
  lacked `INTERNET` (debug/profile only); unused packages were declared.
- **Fix:** «شهم» in `android:label`, `CFBundleDisplayName`, `CFBundleName`;
  `INTERNET` in the main manifest; five proven-unneeded packages removed.
- **Not done (owner/release work):** bundle/package identifiers, location
  purpose strings and disclosures, merged-manifest/device verification,
  store assets, runtime version source (needs an approved package).
- **Rule:** distinguish source change, build evidence and device evidence;
  never claim a store-ready build from a source edit; remove a package only
  after lib/test/tool/native/plan checks (`ARCHITECTURE.md` §6).

## L-14 — Audit evidence must not break the demo-removal scanner (DOC-01)

- **Scenario:** the owner placed the audit reports in `docs/`; they quote
  demo identifiers, so `remove_demo.sh --dry-run` refused to proceed
  (reproduced 2026-11-22).
- **Fix:** a narrow classification in `tool/demo/remove_demo.dart`: the three
  baseline report paths while their SHA-256 matches, and Markdown under
  `docs/archive/audits/`; everything else is still scanned; a `docs/`
  asset registration or a Dart reference to those files stops the run.
- **Verification:** dry run green on the live checkout; on an isolated full
  copy: `--apply` succeeded with the reports preserved, an injected stray
  demo import was still rejected, and an edited baseline report was scanned
  again (see `REMEDIATION_STATUS.md` DOC-01).
- **Rule:** new quality docs describe demo symbols in words, not
  identifiers; immutable snapshots go under `docs/archive/audits/`; never
  widen the exemption to all docs or all Markdown.

## L-15 — Optional is not required: the customer phone (D-A81, CO-01)

- **Scenario:** product wording said Start Delivery comes "after the captain
  calls the customer", which read as a mandatory call even when the merchant
  gave no phone.
- **Fix:** D-A81 and PRODUCT_OVERVIEW §3.1 make the phone optional;
  `ActiveOrder.contactPhone` treats null/empty/blank as absent; the
  delivery view omits the contact card; nothing validates a phone.
- **Verification:** `current_order_workflow_test.dart` (null, "", "   "
  variants still start and complete).
- **Rule:** model "optional" end to end — nullable in the read model, absent
  section in the UI, no validator, no wording that implies it is required.

## L-16 — The server decides the stage; the app only sends commands (CO-02)

- **Rule (applied from the start, no defect shipped):** the PIN is checked
  only by the server (never returned, compared, stored or logged); a stage
  changes only from a confirmed answer — never on a tap, a timeout, opening
  Maps, GPS proximity or elapsed time; unknown statuses get no action; each
  attempt has an operation key; after an unconfirmed start/complete the
  same key is kept and the action is blocked until reconciled.
- **Verification:** cubit tests in `current_order_workflow_test.dart`
  (malformed PIN sends nothing, wrong/locked PIN typed, timeout ≠ wrong
  code, same key reused, rapid taps → one command).

## L-17 — A missing active order is not proof of delivery (CO-03)

- **Scenario (source analysis while wiring the demo):** the demo shell
  bridge re-reads the active order on every demo change. During an
  in-flight completion that read can return "none" before the command's
  answer arrives, and would have replaced the order with "no active order",
  dropping the confirmed completion.
- **Confidence:** source-confirmed race; covered by a deterministic test.
- **Fix:** while a command for the shown order is in flight, an "absent"
  read is not applied; the command's answer — or `GetOrderOutcome` after an
  unknown outcome — decides.
- **Verification:** "an absent read during an in-flight completion is not
  applied" test.
- **Rule:** never infer delivered/cancelled/reassigned from absence; use a
  receipt or the outcome lookup.

## L-18 — Put a popup form's submit in the pinned actions (CO-04)

- **Scenario (reproduced in a widget test):** at 320 × 640 and text scale
  2.0 the PIN form's own submit button, placed in the popup body, ended up
  below the visible area and could not be tapped.
- **Fix:** «تأكيد الاستلام» and «إلغاء» are `AppPopupAction`s (pinned by the
  AppPopup layout contract); the form exposes `submit()` through its state.
- **Verification:** "320 px at text scale 2.0" workflow test.
- **Rule:** in `AppPopup`, primary/cancel actions go in `actions`, never in
  scrolling `content`; test large text at 320 px.

## L-19 — Scanner guards must match paths, not file names (CO-05)

- **Scenario (reproduced by the dry run):** the historical-document guard
  matched the bare name `03_SYSTEM_DATA_REQUIREMENTS.md` inside a Dart doc
  comment that points at the **revised** report and stopped the removal.
- **Fix:** the guard matches the exact baseline paths (`docs/0X_…`) and the
  archive folder only.
- **Verification:** live dry run OK; the earlier negative checks (a Dart
  reference to the baseline path) still stop.
- **Rule:** make safety guards precise enough that ordinary documentation
  cannot trigger them, and re-run the dry run after doc comments change.

## L-20 — No fake route, no fake map (CO-06)

- **Rule (applied):** the map is built only with provisioned keys
  (`SHAHM_GOOGLE_MAPS`), the route only from a routing source; without one
  the page says "map unavailable" / "route not configured" and never draws
  a straight line or uses a sample coordinate in production. `(0, 0)` is
  invalid. External navigation opens only the Google Maps app (non-browser
  launch) and reports "app unavailable" otherwise.
- **Verification:** launcher unit tests (URIs, lat/lng order, outcomes);
  `GooglePickupMap` itself was not rendered with real tiles here.

---

## L-21 — Presentation changes must not rewrite identity or service ownership

- **Prevention rule (D-A82, implemented 2026-11-24):** shorten the
  Home greeting only, preserving full session/Profile names and whitespace
  fallback. Register the distinct Home asset before use; preserve the
  owner's main logo/Login edits. Removing a balance shortcut removes its
  exclusive inputs/read, not the Wallet feature or completion invalidation.
- Remove the actual secondary Home-card control and its dead API; do not
  hide it or confuse declining an offer with cancelling the merchant order.
  The separate offer-sheet decline path stays outside this removal.
- **Verification pending:** implementation must exercise real callers,
  absent-name input, layout and request counts. No new test result is claimed.

## L-22 — Optional delivery details need a complete historical path

- **Prevention rule (D-A83, implemented 2026-11-24):** name,
  phone and delivery notes are optional; omit blank rows. Area and fee are
  business-required; missing data stays unavailable, never invented/zero.
  Delivery notes must not be copied from pickup instructions.
- Propagate fields through model reconstruction, stage changes, mapping,
  fakes and the historical read model. A non-tappable list tile is not an
  implemented per-order detail page. Reuse the cohesive details UI across
  its actual current/history consumers, keeping commands feature-owned.
- Historical data comes from the own order record, not current profiles
  or the active-order cache. No personal details in offers, pushes or logs;
  no per-row prefetch/polling or invented retention period.
- **Verification pending:** optional/absent combinations, correct-order
  navigation, session clearing, RTL/large text, and complete data flow.

## L-23 — Remove a consumer's reads with the consumer (D-A82)

- **Scenario:** the shell created `WalletCubit` eagerly and called
  `loadBalance()` only so Home's chip had a value. Removing the chip but
  keeping that read would have fetched the wallet on every sign-in for no
  screen.
- **Fix:** the provider is lazy, `loadBalance()` was deleted (no other
  production caller), and `syncSession()` reads nothing when nothing was
  read yet. Wallet's first show, re-show and completion invalidation are
  unchanged.
- **Verification:** `wallet_test.dart` "D-A82: Home reads no wallet data…"
  (0 reads until the Wallet tab), invalidation follow-up test.
- **Rule:** when a UI consumer is removed, search for reads, eager
  providers and session hooks that existed only for it.

## L-24 — A page that never fetches must not wait forever (D-A83)

- **Scenario (caught by a widget test):** the completed-order page showed a
  spinner while the history Cubit was still `initial`. On a direct link
  before My Orders ever opened, nothing would ever load, so it would spin
  forever.
- **Fix:** only an already-running list read shows loading; "not read yet",
  not found and failure show the explicit unavailable state with Back to My
  Orders. No per-order lookup was invented (no contract).
- **Verification:** `order_details_test.dart` direct-link and
  not-configured cases.
- **Rule:** a screen that depends on another owner's read must define what
  it shows when that read never starts.

## L-25 — Run the required checks against owner work in progress honestly

- **Observed 2026-11-24:** the owner's uncommitted ARB edit lacked a comma
  (blocking `flutter gen-l10n`), the demo username changed in `auth.json`,
  and two Login tests failed after the new Login layout.
- **Handling:** only what blocked the required checks was changed (the
  comma + metadata; demo tests use the new username).
- **Correction (workflow mistake, 2026-11-24):** the two Login failures
  were then reported, in two task reports, as "the button is pushed off the
  800×600 viewport" and as "pre-existing". Both were wrong. The button was
  on screen and covered by the error toast (L-26). The HEAD comparison only
  showed the failure was new with the owner's logo, not why the tap missed.
  The tests stayed failing across two tasks instead of being fixed.
- **Rule:** never "fix" owner work silently; change the minimum that blocks
  required checks, say so, and attribute remaining failures with evidence.
  A diagnosis quotes the failing output (the hit-test warning names the
  widget that received the tap); "off-screen" or "pre-existing" is written
  only after the widget's rect, the viewport and a baseline run were
  measured. A known failure is diagnosed in the task that finds it, not
  carried as an attribution.

## L-26 — A test tap must reach its widget: toasts cover, assets decode late

- **Kind:** test defect (production behaviour was not changed).
- **Symptom:** `login_screen_test` "offline and backend failures get their
  own messages" and `demo_mode_test` "Login shows the badge…" failed in the
  full run (each passed alone). flutter_test warned that the tap at
  `Offset(400, 509)` "would not hit test" on the Login `FilledButton`; the
  second failure message, or Home, never appeared.
- **Root cause (measured):** the first failed sign-in shows the error
  toast, a floating `SnackBar` occupying y 509–600 at 800×600. The test then
  tapped the submit button again while the toast still covered it, so the
  toast received the tap. Whether the button sat under the toast depended
  on test order: the owner's new square logo (`shahm_main_logo.png`,
  1254×1254, 180 px tall at width 180; HEAD's logo was 861×498, ≈104 px)
  has a height of 0 until it is decoded. A fresh run measured the button at
  y 318–366 (clear of the toast); after earlier tests had decoded the logo
  it was centred at y 509 (under the toast).
- **Fix:** `tapLoginSubmit` in `test/test_app.dart` acts like a captain:
  closes a visible toast through its own close button, scrolls the button
  into view, asserts it is hit-testable, then taps. Both tests use it. No
  assertion, viewport or production widget was changed.
- **Verification:** both test files pass together and each target test
  passes alone; full `flutter test` (results in the task report).
- **Rule:** before tapping a control a previous step may have covered
  (toast, sheet, keyboard), close or wait for the cover and assert
  `finder.hitTestable()`; treat the "would not hit test" warning as a
  failure. Layout assertions must not depend on whether an asset happens
  to be decoded yet.
- **Open product observation (not a defect claim):** on short screens the
  4-second error toast covers the Login button until closed; whether it
  should sit above the form is an owner/design decision.

## L-27 — Format only the files you changed, and keep the output

- **Kind:** workflow mistake.
- **Symptom:** earlier tasks ran `dart format lib`, and `dart format lib test`,
  with the output discarded (`>/dev/null`). This touched files outside each
  task's scope, including ones with uncommitted owner edits.
- **Root cause:** using the whole directory as a shortcut for "the files I
  edited", and suppressing the list of changed files.
- **Correction and review (2026-11-24):** every modified Dart file was
  compared with `dart format` applied to its HEAD version. None differs from
  HEAD by formatting only, and every HEAD version was already format-clean.
  Generated localizations match a fresh `flutter gen-l10n` byte for byte.
  Because the output was discarded, it cannot be established whether
  unformatted owner edits were reformatted, so nothing was reverted.
- **Rule:** run `dart format <exact files changed in this task>` and keep
  its output in the log. Never format `lib`/`test` wholesale in a working
  tree that holds owner changes. Never format generated files.
- **Verification:** this repair formatted only `test/test_app.dart`,
  `test/login_screen_test.dart`, `test/demo_mode_test.dart` and
  `lib/view/screens/authentication/view/login_screen.dart` (results in the
  task report).

## Recommendations recorded without code change

| Item | Decision and rationale |
|---|---|
| SW-01 shared surface card | Not built: no shared behavior (L-11) |
| ARCH-05 shared lifecycle helper | Not extracted: policies differ, little duplication (L-04) |
| STATE-02 Wallet resume read | Owner decision D-P42; proposal: visible-only, coalesced |
| Text-widget family | Kept with tests; owner decision D-P43 |
| Generic dialog keys `confirm`, `alert`, `proceedQuestion` | No production use after R05 (they served the deleted `AppTools` dialogs); kept as the popup layout tests' sample copy. Remove or reuse when a feature needs a generic confirm |
| About version | Needs a real runtime source; proposal: `package_info_plus` (official Flutter Community plugin, reads the build's version on both platforms; lighter alternative: a `--dart-define` set by the release pipeline). Not installed: new packages need owner approval. Until then About keeps "unavailable" |
