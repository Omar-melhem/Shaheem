# SHAHM Flutter — Documentation Index

**Reconciled against the client revision of 2026-11-20 (D-A69–D-A79).** For current business rules use `project/PRODUCT_OVERVIEW.md`, and for decision resolution use `decisions/ARCHITECTURAL_DECISIONS.md` §1.2, §1.1 and §3. Older implementation snapshots are not production approvals. `project/PROJECT_STATUS.md` §0 records the current target versus what the code actually contains.

This is the central documentation for the SHAHM Flutter app
(`mobile_frontend/`). The permanent working rules for Claude Code are in
`../CLAUDE.md`.

All documents are in English. Each topic has **one** canonical document;
other documents link to it instead of repeating it.

## Canonical documents

| Document | Purpose |
|---|---|
| [`project/PRODUCT_OVERVIEW.md`](project/PRODUCT_OVERVIEW.md) | What SHAHM is, its roles, and the current owner-approved business rules |
| [`project/PROJECT_STATUS.md`](project/PROJECT_STATUS.md) | What is implemented, planned, or pending, plus the latest verification results |
| [`architecture/ARCHITECTURE.md`](architecture/ARCHITECTURE.md) | Layers, folder responsibilities, dependency rules, composition and DI, widget separation |
| [`architecture/STATE_MANAGEMENT.md`](architecture/STATE_MANAGEMENT.md) | Cubit vs Bloc, app-level vs feature state, form validation flow |
| [`architecture/ROUTING_AND_STARTUP.md`](architecture/ROUTING_AND_STARTUP.md) | Routes, the redirect policy, the startup sequence, error routing, the main navigation shell, the temporary debug preview |
| [`architecture/GLOBAL_SERVICES.md`](architecture/GLOBAL_SERVICES.md) | Connectivity monitor, global banner, lifecycle, session and current user, auth use cases |
| [`ui/DESIGN_SYSTEM.md`](ui/DESIGN_SYSTEM.md) | Colors, typography, fonts, RTL, strings, assets, icons, the main navigation bar's visual rules |
| [`ui/SHARED_UI_COMPONENTS_REFERENCE.md`](ui/SHARED_UI_COMPONENTS_REFERENCE.md) | APIs of the shared text widgets, `AppTools`, loading widgets, validators, form/button/popup/toast components, `MainNavigationBar`, `AppStatusMessage`, the Splash widget |
| [`ui/CUSTOM_WIDGET_CONTRACT_STANDARD.md`](ui/CUSTOM_WIDGET_CONTRACT_STANDARD.md) | The single custom-widget policy: when to create a widget at all, composition over abstraction, `required` vs business validation, theme-first appearance, dumb UI / smart feature layer, sizing/RTL/accessibility, performance without myths, proportional tests, examples, approval gate and a 60-second checklist (Task 08, rewritten Task 32) |
| [`release/STORE_SUBMISSION_COMPLIANCE.md`](release/STORE_SUBMISSION_COMPLIANCE.md) | Apple App Store and Google Play submission checklist: applicable requirements, current repository evidence, blockers, owner inputs and the pre-submission audit (Task 14; policy baseline 2026-11-15; not store approval or legal advice) |
| [`decisions/ARCHITECTURAL_DECISIONS.md`](decisions/ARCHITECTURAL_DECISIONS.md) | Registry of every decision: Approved, Pending or Rejected |
| [`CLAUDE_PROJECT_INSTRUCTIONS.md`](CLAUDE_PROJECT_INSTRUCTIONS.md) | Text for the Claude Project "Instructions" field, plus the knowledge-file list |

## Archive (historical, not authoritative)

> **Unresolved documentation gap (verified 2026-11-14):** `docs/archive/` is
> referenced below and elsewhere for historical traceability, but it is
> **not present in this checkout** and was not found in the Git history of any
> local or remote branch. The links below are therefore unverified. The
> canonical documents and owner approvals still suffice for current work; do
> not recreate archive files from memory.

| Path | Contents |
|---|---|
| [`archive/OLD_REQUIREMENTS/`](archive/OLD_REQUIREMENTS/README.md) | Index and summaries of the requirement documents that drove the work on 2026-11-10 and 11 |
| [`archive/SUPERSEDED/APP_STATE_AND_STARTUP_ARCHITECTURE.md`](archive/SUPERSEDED/APP_STATE_AND_STARTUP_ARCHITECTURE.md) | Replaced by `architecture/ROUTING_AND_STARTUP.md` and `architecture/GLOBAL_SERVICES.md` |
| [`archive/SUPERSEDED/SESSION_REVIEW_2026-11-11.md`](archive/SUPERSEDED/SESSION_REVIEW_2026-11-11.md) | Session retrospective, written in Arabic. Kept as history; its open items are tracked in `PROJECT_STATUS.md` and the decisions registry |

When the archive and a canonical document disagree, **the canonical
owner-approved rules win for future implementation**. Source code reveals
what is **currently implemented**, not a veto over a newer approved rule.

## Related documentation outside this folder

These belong to the React web prototype and are **not** Flutter documents.
They are useful as product references:

- `../../web_frontend/docs/SHAHM-PROJECT.md`: full prototype overview (Arabic).
- `../../web_frontend/docs/wallet-commission-backend-contract.md`: historical external proposed wallet contract that still describes commission holds (superseded by D-A74). The file exists in the repository, but it was **not included in the 2026-11-14 reconciliation bundle and has not been reviewed or certified** line by line. Its contents are not automatically approved; new implementation must follow the currently approved wallet rules in this package.
- `../../web_frontend/CLAUDE.md`: web prototype rules, including approved product rules (CR v1.3 and v1.4).

## Canonical contract policy

- **Backend**: ASP.NET Core Identity + PostgreSQL, REST `/api/v1` with OpenAPI;
  RFC 9457 Problem Details, typed generated clients, POST task commands,
  typed SignalR events, FCM/APNs hints, transactional outbox and idempotent
  PostgreSQL business effects. Concrete DTOs/events must still be written.
- **Operational source of truth**: `project/PRODUCT_OVERVIEW.md` takes
  precedence over archived prototype prompts for broadcast/GPS/wallet/order
  behavior. Follow approved D-A53–D-A79 decisions (latest first) when
  historic tables contradict them.
- **Product vs implementation**: approved target ≠ code already implemented.
  Never turn a historic screenshot/simulator run into a claimed new test.
- **Project Knowledge synchronization**: replacing local Markdown bytes does
  not automatically replace the existing SHAHM Project attachments. Upload
  the updated canonical files through the Project interface to synchronize.

## Maintenance

- **Update together:** update the canonical document in the same task as the
  code change.
- **Decisions:** add or change them in the decisions registry first, then
  reference the decision ID elsewhere.
- **Status:** keep `PROJECT_STATUS.md` current after each feature.
- **Superseded docs:** move them to `archive/`. Never delete documentation.
