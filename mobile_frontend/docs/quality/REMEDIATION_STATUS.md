# SHAHM Flutter — Audit Remediation Status (single tracker)

**Scope:** every finding of the 2026-11-22 audit of `cefad0a`
(baseline reports kept unchanged at `docs/01_APPLICATION_AUDIT_REPORT.md`,
`docs/02_FILE_BY_FILE_INVENTORY.md`, `docs/03_SYSTEM_DATA_REQUIREMENTS.md`;
SHA-256 pinned in `tool/demo/remove_demo.dart`; an out-of-repo copy is the
audit run folder), plus review corrections. Authority: D-A80. Revised
reports: [`reports/2026-11-22-post-fix/`](reports/2026-11-22-post-fix/).
Lessons: [`ENGINEERING_LESSONS.md`](ENGINEERING_LESSONS.md). Counting rules:
[`AUDIT_METHOD.md`](AUDIT_METHOD.md).

**Statuses:** `verified-open`, `in-progress`, `fixed-verified` (code changed
and the named check ran green), `fixed-unverified`, `recommendation`,
`not-a-defect`, `blocked-contract`, `blocked-owner`, `superseded`,
`not-reproduced`. "Verified" means repository tests/analysis in this
working tree on 2026-11-22 (V1 below), never a live backend, device or
store result. Completion levels in the revised report 01 §4.

**V1 (2026-11-22T12:30Z, working tree on `cefad0a`):** `flutter analyze` no
issues; `flutter test` 1,034 passed / 0 failed; demo dry run OK; isolated
`--apply` rehearsal OK (1,006 tests after removal). No simulator/device run.

| ID | Problem and evidence | Classification | Priority | Authorized scope | Owner canonical doc | Affected files | Repair / backlog task | Status | Actual verification | Open input | Lesson |
|---|---|---|---|---|---|---|---|---|---|---|---|
| ARCH-01 | Router files in `util/routes` import screens | Not a defect: documented composition boundary | — | None (no move) | `architecture/ARCHITECTURE.md` §2 | — | Composition responsibility documented | not-a-defect | Doc review | — | L-11 |
| ARCH-02 | Orphan `AppTools` members and loading widgets (only one unfocus call used) | Defect (dead public API) | Medium | D-A80 | `ui/SHARED_UI_COMPONENTS_REFERENCE.md` | `lib/util/tools/*` (deleted), `login_screen.dart`, tests | R05: deleted; unfocus inlined with the same check | fixed-verified | V1 (login, shared/custom widget tests) | — | L-06 |
| ARCH-03 | Unused `splash_screen/bloc/` redefines `SplashState`; sole `bloc` importer; analyzer info | Defect (dead code) | Low | D-A80, D-P13 | `architecture/ARCHITECTURE.md` §6, decisions D-P13 | `splash_screen/bloc/*` (deleted), `pubspec.yaml/.lock` | R05 + R09 | fixed-verified | V1 (analyze clean; `splash_cubit_test`, startup tests) | — | L-06 |
| ARCH-04 | `openCurrentOrderPage` lived in the offer-sheet host, imported by Home | Defect (misplaced shared helper) | Low | D-A80 | `architecture/ARCHITECTURE.md` §2 | `view/navigation/current_order_navigation.dart` (new), host, Home card | R05: moved unchanged | fixed-verified | V1 (`active_order_recovery_test`, `new_offer_sheet_test`) | — | L-07 |
| ARCH-05 | Visibility/resume loading repeated in Home, My Orders, Wallet | Recommendation (policies differ) | — | Compare only | `architecture/ROUTING_AND_STARTUP.md` §7 trigger table | — | Decided: no helper | recommendation | Comparison documented | — | L-04 |
| ARCH-06 | Timeout mapped inconsistently; deletion timeout claimed "not sent / not deleted" | Defect (deletion copy untrue) + undocumented policy | Medium | D-A80 | `architecture/GLOBAL_SERVICES.md` §3.4 | 5 use cases, deletion Cubit/Settings, ARB | R04: explicit `on TimeoutException`; `AccountDeletionUnconfirmed` | fixed-verified | V1 (`timeout_policy_test` 9 cases) | — | L-05 |
| ARCH-07 | No real data layer / HTTP / DTOs / secure storage / `get_it` | Contract gap | Medium (integration) | None until contracts exist | `project/PROJECT_STATUS.md` §0.1 | `lib/data/` | B-01…B-09 | blocked-contract | — | OpenAPI (D-P02) | — |
| ARCH-08 = LOC-01 | Unknown/removed route showed go_router's English page with the URI | Defect | Medium | D-A80 | `architecture/ROUTING_AND_STARTUP.md` §2.1 | `go_router.dart`, `route_error_screen.dart` (new), ARB | R01 | fixed-verified | V1 (`main_navigation_test` "route errors", 6 cases) | — | L-01 |
| SW-01 | Similar white bordered cards in ~10 widgets | Recommendation (no shared behavior) | — | None | `ui/CUSTOM_WIDGET_CONTRACT_STANDARD.md` §2 | — | Decided: no `AppSurfaceCard` | recommendation | Doc review | — | L-11 |
| SW-02 | Confirmations used `closesPopup:false` + root-navigator `pop(true)` | Component-contract gap (no crash reproduced) | Low | D-A80 | `ui/SHARED_UI_COMPONENTS_REFERENCE.md` §3.10 | `app_popup.dart`, Profile, deletion confirmation | R06: `AppPopupAction<T>.result` | fixed-verified | V1 ("AppPopup typed result", 7 cases; profile/settings tests) | — | L-08 |
| SW-03 | No Internet / Splash Retry hand-built `FilledButton` + spinner | Defect (duplicate behavior) | Low | D-A80 | `ui/SHARED_UI_COMPONENTS_REFERENCE.md` §3.8 | two Retry widgets | R07 | fixed-verified | V1 (`startup_flow_test`: busy, one check, 320 px × 2.0) | — | L-09 |
| SW-04 | Dead chip sizing helpers; `CustomePadding` only used by dead loading widget; text-widget family unused | Defect (dead code) / owner decision (text family) | Low | D-A80 (not the text family) | `ui/SHARED_UI_COMPONENTS_REFERENCE.md` | `wallet_balance_chip.dart`, `padding.dart` (deleted) | R05 | fixed-verified (helpers) / blocked-owner (family) | V1 | D-P43 | L-06 |
| STATE-01 | Profile rating loaded once per session | Defect (stale read model) | Low | D-A80 | `architecture/STATE_MANAGEMENT.md` §2 | Profile screen, `ProfileRatingCubit` | R03 | fixed-verified | V1 (`profile_settings_test` "refresh", 4 cases) | D-P37 (scale only) | L-04 |
| STATE-02 | Wallet does not re-read on resume | Owner decision, not a defect | — | Proposal only | decisions D-P42 | — | proposal recorded | blocked-owner | — | D-P42 | — |
| API-01 | Active order lacks stage, PIN, actions, area, customer contact | Contract gap | High (feature) | None | data report §9 | — | B-03 | blocked-contract | — | D-P25, OpenAPI | — |
| API-02 | Offer expiry/round absent; request-key ownership undefined | Contract gap (server enforces expiry; key ownership is an API-contract detail) | Medium | None | data report §7 | — | B-02 | blocked-contract | — | OpenAPI | L-12 |
| API-03 | `AppUser` lacks username / profile-complete / status | Contract gap; status is a typed result, not a client field | Low | None | data report | — | B-01 | blocked-contract | — | OpenAPI | L-12 |
| API-04 | No location-report / push-registration contract | Contract gap | Medium | None | data report | — | B-07 | blocked-contract | — | D-A57/D-A58 contracts | — |
| API-05 | Home balance chip had no production source (router passed null; only the demo hook fed it) | Defect (D-A71 "same single source") | Medium | D-A80 | `architecture/STATE_MANAGEMENT.md` §2 | router, Home route, `WalletCubit/State`, `WalletScreen`, demo files and manifest | R02 | fixed-verified (code-ready; real data needs B-05) | V1 (`wallet_test` R02 groups; demo dry run + rehearsal) | — | L-02 |
| API-06 | Earnings formula and rating scale undecided | Owner decision | — | None | decisions | — | B-05/B-06 | blocked-owner | — | D-P36, D-P37 | — |
| API-07 | Declined record lacks order ref/area; no paging | Contract gap (not required by the current screen) | Low | None | data report | — | B-04 | blocked-contract | — | OpenAPI | L-12 |
| LOC-02 | `label + ': ' + value` composed in code | Defect (word order fixed in code) | Low | D-A80 | `ui/DESIGN_SYSTEM.md` §5 | offer card, sheet, debit/balance cards, profile identity, ARB, tests | R08 | fixed-verified | V1 | — | L-10 |
| LOC-03 | Literal separators/joins in visible or semantic text | Defect (semantic `join`, declined kind) / recommendation (decorative bullet, sentence space) | Low | D-A80 | same | metric card, rating card, declined tile | R08 | fixed-verified / recommendation | V1 | — | L-10 |
| LOC-05 | Visible app name was the template value | Defect (D-A66/D-P23) | Medium | D-A80 | `release/STORE_SUBMISSION_COMPLIANCE.md` | `Info.plist`, `AndroidManifest.xml` | R09 | fixed-unverified (source only; no device build) | `plutil -lint`, `xmllint` | bundle/package IDs (owner) | L-13 |
| PLAT-01 | Unused packages; no main-manifest `INTERNET`; no location purpose strings; template IDs | Mixed | Medium | D-A80 (`INTERNET`, proven-unneeded deps) | same + `architecture/ARCHITECTURE.md` §6 | manifest, `pubspec.yaml/.lock` | R09: 5 packages removed, `INTERNET` added | fixed-verified (deps; `INTERNET` confirmed in the merged **release** manifest 2026-11-22) / blocked-owner (IDs, purpose strings, legal copy); APK build blocked by compileSdk 37 requirement of `permission_handler_android` (pre-existing toolchain gap) | V1 + audit evidence in §6 | owner IDs, legal copy | L-13 |
| TEST-01 | All tests use fakes/placeholders | Contract gap; labels are honest | Low | Labels only | `project/PROJECT_STATUS.md` | — | B-01… | blocked-contract | — | OpenAPI | — |
| REV-01 | Report overstated counts (14 Cubits, 21 owners) and "full read" coverage | Audit defect | Medium | R00 | `quality/AUDIT_METHOD.md` | revised reports 01/02 | Recounted with the documented command | fixed-verified | grep recount on final source | — | L-03 |
| REV-02 | Screen counting mixed capability with screens; No Internet called API-blocked | Audit defect | Low | R00 | same | revised report 01 §3 | Recounted | fixed-verified | router recheck | — | L-03 |
| REV-03 | Data report grouped different fields under ranged IDs | Audit defect | Medium | R10 | `quality/AUDIT_METHOD.md` §7 | revised report 03 | 125 atomic IDs, one row per table each | fixed-verified | script check: 125/125, no duplicates | owner decisions listed there | L-12 |
| DOC-01 | Audit reports in `docs/` made the demo-removal dry run fail | Defect (tooling interaction), reproduced | Medium | D-A80 | `quality/AUDIT_METHOD.md` §6, `tool/demo/README.md` | `tool/demo/remove_demo.dart` | Narrow sha-pinned classification + runtime-use guard | fixed-verified | live dry run OK; copy: apply OK, 4 negative checks rejected, archive snapshot allowed | — | L-14 |
| LOC-06 (new) | `confirm`, `alert`, `proceedQuestion` unused in production after R05 | Recommendation | — | — | lessons (recommendations) | ARB, popup tests | keep as test sample copy; remove or reuse later | recommendation | key-usage scan | — | — |

## Current Order workflow (D-A81, 2026-11-22)

| ID | Problem and evidence | Classification | Status | Actual verification | Open input | Lesson |
|---|---|---|---|---|---|---|
| CO-01 | Docs implied a mandatory customer call before Start Delivery | Product wording defect | fixed-verified | D-A81, PRODUCT_OVERVIEW; phone-variant tests | — | L-15 |
| CO-02 | Workflow commands need server authority, keys, no local stage advance | Design rule (applied) | fixed-verified | cubit workflow tests | API contract | L-16 |
| CO-03 | An "absent" read during an in-flight completion could drop the confirmed result | Defect (source-confirmed race) | fixed-verified | deterministic cubit test | — | L-17 |
| CO-04 | PIN submit unreachable at 320 px × text 2.0 when placed in the popup body | Defect (reproduced in test) | fixed-verified | large-text widget test | — | L-18 |
| CO-05 | Scanner guard false positive on a doc comment naming the revised report | Defect (reproduced by dry run) | fixed-verified | live dry run OK | — | L-19 |
| CO-06 | Map/route must never be faked | Design rule (applied) | fixed-unverified (no keyed build, no tiles) | launcher tests; iOS debug simulator build compiles | Maps keys/billing, Routes access design | L-20 |

**V2 (2026-11-22, working tree on `cefad0a`):** see `../project/PROJECT_STATUS.md` §0.2.

## Backlog (contract- or owner-blocked work)

B-01 auth/session · B-02 offers · B-03 active-order workflow and maps ·
B-04 completed deliveries · B-05 wallet/statistics · B-06 rating · B-07
availability, GPS, push · B-08 deletion · B-09 legal, version, release
identity · B-10 future commitments. Inputs, current boundary, proposed
files, acceptance checks and blockers: revised data report §9.
