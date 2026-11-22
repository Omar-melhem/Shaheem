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

---

## Recommendations recorded without code change

| Item | Decision and rationale |
|---|---|
| SW-01 shared surface card | Not built: no shared behavior (L-11) |
| ARCH-05 shared lifecycle helper | Not extracted: policies differ, little duplication (L-04) |
| STATE-02 Wallet resume read | Owner decision D-P42; proposal: visible-only, coalesced |
| Text-widget family | Kept with tests; owner decision D-P43 |
| Generic dialog keys `confirm`, `alert`, `proceedQuestion` | No production use after R05 (they served the deleted `AppTools` dialogs); kept as the popup layout tests' sample copy. Remove or reuse when a feature needs a generic confirm |
| About version | Needs a real runtime source; proposal: `package_info_plus` (official Flutter Community plugin, reads the build's version on both platforms; lighter alternative: a `--dart-define` set by the release pipeline). Not installed: new packages need owner approval. Until then About keeps "unavailable" |
