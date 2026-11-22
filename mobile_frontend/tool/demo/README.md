# SHAHM debug demonstration mode (Tasks 37–38) — temporary

The real captain app with **fictional** data, for showing the product. Not a
backend, not a test environment, never a release feature.

## Start

```bash
cd mobile_frontend
flutter run --debug --dart-define=SHAHM_DEMO=true
```

- Sign in with `demo_captain` / `Demo1234!` (any other pair is refused as
  invalid credentials).
- Without the define, or in a profile/release build, the app is the normal
  app (Login reports the backend is not configured).
- **Packaging:** `pubspec.yaml` declares `assets/demo/fixtures/` while the
  demo is installed, so those JSON files are packaged in **every** build,
  release included, even though the demo UI cannot start there. Remove the
  demo before any store or release build.

## What is shown

| Screen | Source |
|---|---|
| Login | the real form and validation; a demo auth repository answers |
| Home | the real Home: greeting, availability switch and wallet chip in the Home AppBar (D-A71; availability in demo memory only, no permission prompt), the real offer cards. The chip shows the demo **balance** (4.000 د.أ, the same in-memory wallet the Wallet tab reads; «—» when signed out; tap → Wallet) |
| New-offer sheet | the real shared sheet and host, fed by «إظهار طلب جديد»; since Task 38 it shows only the full delivery fee (e.g. 3.000 د.أ for the template offer), never commission or net |
| Current Order | the real standalone page (D-A73), opened after a confirmed acceptance, on foreground return with an unfinished order, or first after sign-in when the pre-assigned scenario is chosen; the map stays "unavailable" (no maps, no GPS) |
| My Orders («طلباتي») | the real «العروض التي رفضتها» section (fixture decline + your declines). A decline in the sheet opened over this tab appears first at once, without leaving the tab; a reset restores the fixture row in place |
| Wallet | the real screen: one balance (4.000 د.أ, no holds, within the 5,000-fils ceiling), the lifetime delivered count (3, including a delivery older than 7 days) with earnings "unavailable" (formula pending, D-P36), and the commission debits of the last 7 days. No recharge action or credit list |
| My Account («حسابي») | the real Profile tab: fictional name, phone «غير متوفر», rating «غير متوفر» (no rating backend), Settings (account deletion reports "not configured": nothing is sent), Terms, About |

There is no Notifications screen (removed, D-A72). A dark strip
«وضع تجريبي — بيانات وهمية» stays above every screen, including sheets and
popups.

## Demo controls (in the strip, signed in only)

- **«إظهار طلب جديد»** — adds a new instant offer from
  `offers.json → incoming_offer_template` (ids `demo-new-offer-1`, `-2`, …,
  expiry 120 s). The real shell host shows it in the real sheet over any tab
  or page. At most three can wait unanswered.
- **«أدوات العرض»** — opens the tools:
  - «بدون طلب حالي» / «طلب مسند مسبقاً»: the active-order scenario. With a
    pre-assigned order, a new instant offer is refused (one active order).
    The chosen scenario survives the demo sign-out, so the next sign-in
    shows the startup routing to Current Order (a fresh demo session; the
    demo itself still resets when the process exits).
  - «عرض مؤجل (للعرض فقط)»: lists the scheduled sample; Accept stays off.
  - «إعادة ضبط بيانات العرض»: back to the original fixtures.
  - «تسجيل الخروج من العرض»: the real sign-out; all demo changes except the
    chosen active-order scenario are wiped.

Simulated, in memory only: accept (eligible, unexpired, instant, no active
order; once), decline (this captain only, recorded in declined offers; no
wallet change: there are no holds), availability. Nothing is sent over the network, written to
disk or kept after a restart. The token `DEMO_ONLY_NOT_A_JWT_DO_NOT_SEND`
lives in memory only and is never used.

**Current Order workflow (D-A81, 2026-11-22).** `DemoOrderWorkflowRepository`
lets the real Current Order page run its whole flow against the in-memory
demo server: accept an offer → pickup leg (the map stays "unavailable"
unless Google Maps keys are provisioned; «فتح في خرائط Google» uses the
fictional merchant point) → «تم الاستلام» with the fixture's demo PIN
(`current_order.json` → `pickup_pin`, checked **only** by `DemoState`;
three wrong attempts lock it until a reset) → delivery view → «بدء التوصيل»
→ «تم تسليم الطلب». Completion appends one completed delivery and exactly
one commission debit (the offer's fixture commission) and lowers the
balance; a repeat with the same operation key returns the same receipt.
Offers `demo-offer-101` and the injected template carry a fictional,
non-assignable `070…` customer phone; `demo-offer-102` and the
pre-assigned scenario have none, to show the optional-phone path. Removing
the demo leaves the real stage UI and ports with production "not
configured" behavior.

**Not shown (no screen exists):** future scheduled commitments, recharge
credits (ledger evidence in `wallet.json`, not listed in the captain UI).
The demo has no real GPS, routing, backend PIN check or settlement.

**How the Task 38 behaviour is wired:**

- Home balance (since R02, 2026-11-22): no demo hook. The app's own
  shell-scoped `WalletCubit` feeds both Home's chip and the Wallet tab and
  reads `DemoWalletRepository` here, exactly like the production placeholder
  in a normal run. The former demo Home connector, its router/main hooks
  and the `router-home` region were removed as redundant; removing the demo
  therefore leaves the shared source with truthful "not configured" data.
- History after a decline: the app's own (permanent, non-demo) path —
  `PendingOffersCubit.onDeclineConfirmed` → shell-scoped
  `DeclinedOffersCubit.refresh()` once the demo repository has answered.
- History after a reset: `DemoShellBridge` calls the same `refresh()` when
  `DemoState.resetCount` changes (sign-in, reset, sign-out), nothing else.

**Verified (2026-11-16):** `flutter test` 1,015 passed; interactive run on
the iPhone 17 simulator (iOS 26.5, 402×874 pt, normal and accessibility-XL
text) driven by pointer events injected through the Dart VM service — see
`docs/project/PROJECT_STATUS.md` (Task 38). No physical device was used.

## Files

| Kind | Path |
|---|---|
| Demo code | `lib/demo/` (`demo_mode.dart`, `demo_app.dart`, `demo_state.dart`, `model/demo_fixtures.dart`, `repo/demo_auth_repository.dart`, `repo/demo_repositories.dart`, `widget/demo_strip.dart`, `widget/demo_shell_bridge.dart`) |
| Fixtures (owner-supplied pack; updated for the 2026-11-20 client revision: no `notifications.json`, one balance of 4,000 fils without hold fields, an older completed delivery) | `assets/demo/fixtures/*.json` (7 files) |
| Tests | `test/demo_mode_test.dart` |
| Tooling | `tool/demo/` (this file, `install_manifest.json`, `remove_demo.sh`, `remove_demo.dart`) |
| Marked edits | `lib/main.dart`, `lib/util/routes/go_router.dart`, `pubspec.yaml`, `CLAUDE.md`, `docs/project/PROJECT_STATUS.md` (`SHAHM_DEMO_START/END <id>` regions) |
| Exact edit | `lib/helper/translation/app_ar.arb` (10 `demo*` keys at the end; generated localizations are regenerated) |

## Remove

```bash
bash tool/demo/remove_demo.sh --dry-run   # checks + plan, changes nothing
bash tool/demo/remove_demo.sh --apply     # removes, gen-l10n, analyze, test
```

The tool only touches what `install_manifest.json` lists. It stops before any
change if a demo region was edited, a path is unexpected, or a demo
reference would remain elsewhere. `--apply` backs up every touched file to a
temporary folder first and restores it if `flutter gen-l10n`, `flutter
analyze` or `flutter test` fails. It never runs git. Afterwards
`remove_demo.sh` and `remove_demo.dart` remain and report "demo absent".

**Historical audit documents (R00, 2026-11-22).** Audit reports quote demo
identifiers as evidence. The leftover scan skips only the three baseline
reports in `docs/` while their SHA-256 still matches, and Markdown under
`docs/archive/audits/`; every other file is scanned as before, and a
`docs/` asset registration or a Dart reference to those documents stops the
run. See `docs/quality/AUDIT_METHOD.md` §6.
