# 01 — Application Audit (revised, post-remediation)

**Provenance.** Revised 2026-11-22 (R11) against the final remediation
working tree on branch `Yousef-Hamdan`, HEAD `cefad0a`, **uncommitted**
(nothing staged or committed). Baseline: [`../../../01_APPLICATION_AUDIT_REPORT.md`](../../../01_APPLICATION_AUDIT_REPORT.md)
(Arabic, kept byte-identical, SHA-256 `557182f7…`). Companion reports:
[`02_FILE_BY_FILE_INVENTORY.md`](02_FILE_BY_FILE_INVENTORY.md),
[`03_SYSTEM_DATA_REQUIREMENTS.md`](03_SYSTEM_DATA_REQUIREMENTS.md). Per-finding
detail: [`../../REMEDIATION_STATUS.md`](../../REMEDIATION_STATUS.md); lessons:
[`../../ENGINEERING_LESSONS.md`](../../ENGINEERING_LESSONS.md); method:
[`../../AUDIT_METHOD.md`](../../AUDIT_METHOD.md).

## 1. Verification actually run (2026-11-22, this working tree)

| Check | Result |
|---|---|
| `flutter gen-l10n` | generated, no warnings (226 ARB keys, each with metadata; 3 generic dialog keys now unused in production, see lessons) |
| `dart format --set-exit-if-changed` on every changed/new Dart file | 0 changed |
| `flutter analyze` | **No issues** (the baseline's one info, from the dead `SplashBloc`, is gone) |
| `flutter test` | **1,034 passed, 0 failed** (new run; the baseline's 1,001 is a different, older run) |
| `bash tool/demo/remove_demo.sh --dry-run` (live) | OK, no file changed |
| `--apply` rehearsal on a full isolated copy (scratchpad, not the repo) | Removed the demo; gen-l10n, analyze and tests passed inside the tool; afterwards 1,006 tests passed, "demo absent", baseline reports byte-identical, shared wallet source intact |
| Scanner negative checks on the copy | stray demo import → stopped; edited baseline report → scanned and stopped; `docs/` asset registration → stopped; Dart reference to a baseline report → stopped; archived Markdown snapshot → allowed |
| Simulator / device run | **Not performed in this pass.** No device, store or release build was made |
| Live backend / financial / deletion operations | None (no backend exists) |

## 2. Recomputed counts (final source)

Command and exclusions: `AUDIT_METHOD.md` §2.

| Kind | Count | Classes |
|---|---|---|
| Cubits | **11** | `AppConnectivityCubit`, `AppSessionCubit`, `SplashCubit`, `LoginCubit`, `CurrentOrderCubit`, `HomeAvailabilityCubit`, `PendingOffersCubit`, `DeclinedOffersCubit`, `WalletCubit` (shell-scoped since R02), `ProfileRatingCubit`, `AccountDeletionCubit` |
| Blocs | **0** (baseline: 1 dead `SplashBloc`, deleted) | — |
| `StatefulWidget` | **16**: 10 production, 3 demo, 3 preview | production: `MainApp`, `NewOfferSheetHost`, `LoginForm`, `LoginTermsAction`, `CurrentOrderScreen`, `HomeLifecycleBridge`, `OrderHistoryScreen`, `ProfileScreen`, `WalletScreen`, `AppTextFormField`; demo: the demo app, strip and shell bridge; preview: `HomeOffersPreviewApp`, `_SamplePage`, `WalletPreviewApp` |
| `ChangeNotifier` | **2** | `StreamRefreshListenable` (router refresh bridge), the demo state |
| Stateful/notifier total | **18** | (baseline report said 21 owners and 14 Cubits: wrong) |
| Business state outside Cubits | **0** | every `StatefulWidget` holds lifecycle, controller or presentation state only |
| Paths | **344** (baseline 340) | report 02 |
| Runtime Dart files (`lib/`, excl. demo/preview/generated) | **153** | report 02 §3 |

## 3. Screen inventory (rechecked from the router)

| # | Screen | Route | UI / workflow | Integration status |
|---|---|---|---|---|
| S01 | Splash | `/` | complete for its scope | needs the real session adapter (B-01) |
| S02 | No Internet | `/no-internet` | complete | **real** platform provider; only runtime/device verification is missing (not an API gap) |
| S03 | Login | `/login` | complete | auth adapter (B-01); Terms content D-P40 |
| S04 | Home | `/home` (tab 0) | complete | availability, offers, wallet adapters (B-02, B-05, B-07) |
| S05 | My Orders «طلباتي» | `/order-history` (tab 1) | **partial**: only declined offers; completed-delivery list missing | read model missing (B-04) |
| S06 | Wallet | `/wallet` (tab 2) | complete | wallet adapter (B-05); earnings D-P36 |
| S07 | My Account «حسابي» | `/profile` (tab 3) | complete | rating adapter (B-06), D-P37 |
| S08 | Current Order | `/current-order` | **partial**: no map provider, PIN, Start Delivery, completion, external navigation, customer contact | B-03 |
| S09 | Settings | `/settings` | complete | deletion adapter (B-08), D-P39 |
| S10 | About | `/about` | complete | version source (B-09; package approval) |

- **Logical production screens:** 10 (unchanged).
- **Partial UI/workflow:** 2 — My Orders, Current Order.
- **Complete UI, integration/content/verification pending:** 8 — Splash,
  Login, Home, Wallet, My Account, Settings, About (adapter or content), No
  Internet (runtime/device verification only).
- **Approved missing capability (not a screen):** 1 — future scheduled
  commitments (no read model, no approved design or route, D-P25).
- **Secondary surfaces (not counted):** new-offer sheet, the route-error
  surface (new, R01), connectivity banner, toasts, and the popups (create
  account, forgot password, Terms unavailable, sign-out confirmation,
  account-deletion confirmation).

## 4. Findings — final status

| ID | Final status | What changed / why not |
|---|---|---|
| ARCH-01 | not-a-defect | Router = documented composition boundary; no move |
| ARCH-02 | fixed-verified | `AppTools`, loading widgets deleted; unfocus inlined |
| ARCH-03 | fixed-verified | `SplashBloc` deleted; direct `bloc` dependency removed |
| ARCH-04 | fixed-verified | `current_order_navigation.dart` |
| ARCH-05 | recommendation (decided: no helper) | policies differ; trigger table documented |
| ARCH-06 | fixed-verified | explicit timeout policy; deletion timeout now "unconfirmed" |
| ARCH-07 | blocked-contract | needs OpenAPI (B-01..B-09) |
| ARCH-08 = LOC-01 | fixed-verified | `RouteErrorScreen` via `errorBuilder` |
| SW-01 | recommendation (decided: no shared card) | no shared behavior |
| SW-02 | fixed-verified | `AppPopupAction<T>.result`; two callers migrated |
| SW-03 | fixed-verified | `AppButton` on both Retry surfaces |
| SW-04 | fixed-verified (dead helpers) / blocked-owner (text family D-P43) | chip helpers and `CustomePadding` deleted |
| STATE-01 | fixed-verified | Profile rating refresh |
| STATE-02 | blocked-owner | D-P42 |
| API-01, API-02, API-03, API-04, API-07 | blocked-contract | data report §7, backlog §9; API-03/07 partly not needed by current consumers |
| API-05 | fixed-verified (code-ready) | one shell `WalletCubit` for Home and Wallet; real data still needs B-05 |
| API-06 | blocked-owner | D-P36, D-P37 |
| LOC-02 | fixed-verified | ICU line/sentence keys |
| LOC-03 | fixed-verified (semantic joins, declined kind) / recommendation (bullet, sentence space) | layout separators kept |
| LOC-05 | fixed-unverified | «شهم» set in source; no device build |
| PLAT-01 | fixed-verified (deps, source `INTERNET`) / fixed-unverified (merged manifest) / blocked-owner (IDs, purpose strings, legal copy) | — |
| TEST-01 | blocked-contract | tests are fake-backed by design until contracts exist |
| REV-01..03 | fixed-verified | this report, report 03, `AUDIT_METHOD.md` |
| DOC-01 | fixed-verified | narrow sha-pinned scanner classification |

Completion levels: **code-ready** (all `fixed-*` rows), **integration-ready**
(none: no contract exists), **live-verified** (none).

## 5. Remaining work and what unblocks it

| Item | Next bounded task | Unblocked by |
|---|---|---|
| Real data for every screen | B-01 … B-09 (data report §9) | OpenAPI + Problem Details + event schemas (D-P02) |
| My Orders completed deliveries | B-04 | completed-delivery read model |
| Current Order workflow and maps | B-03 | active-order contract, D-P25, maps keys/config (D-A62) |
| Earnings, rating | B-05, B-06 | D-P36, D-P37 |
| Deletion | B-08 | D-P39 |
| Legal, version, identifiers | B-09 | D-P40; approval of a version package; owner bundle/package IDs |
| Wallet resume read | small change in `WalletScreen` | D-P42 |
| Text-widget family | keep / replace / reduce | D-P43 |
| Future commitments | B-10 | D-P25, D-P35 |
| Device verification | simulator/device walkthrough | a run session (not done here) |
