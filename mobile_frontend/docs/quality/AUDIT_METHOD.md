# SHAHM Flutter — Audit Method (repeatable counting and evidence rules)

**Owner document for:** how an audit of `mobile_frontend/` is run, counted
and reported. Findings themselves live in `REMEDIATION_STATUS.md`; enduring
lessons in `ENGINEERING_LESSONS.md`. Created 2026-11-22 (R00) after the
first audit (`cefad0a`) overstated several counts.

## 1. Snapshot provenance

Every audit report starts with:

- branch, `git rev-parse --short HEAD`, and the `git status --porcelain`
  list (untracked owner files included) at the moment of reading;
- the UTC and Amman time of the snapshot;
- whether the reports are about the committed tree or the working tree.

A report about a dirty tree names the uncommitted files it read. A later run
compares with the newest earlier run and states what changed in the source,
not only in the findings.

## 2. Counting rules (recompute; never hand-maintain)

Counts are **derived from the snapshot each time**. Never copy an earlier
total into a new report, a test or a document as a constant.

| Quantity | How to count | Exclusions (deliberate) |
|---|---|---|
| Cubits / Blocs | Class definitions matching `class X extends Cubit<` / `extends Bloc<` in `lib/` | Generated code, comments, tests |
| Stateful widgets | Definitions `extends StatefulWidget` in `lib/`, then split production / demo (`lib/demo/`) / preview (`lib/preview/`) | Same |
| ChangeNotifier owners | `extends ChangeNotifier` or `with ChangeNotifier` in `lib/` | Same |
| Combined "stateful/notifier" total | Stateful widgets + ChangeNotifier classes; Cubits/Blocs reported separately | Do not add Cubits into this total |
| Inventory paths | `git ls-files` plus untracked, non-ignored files; one row per unique existing path | Ignored build output |

Command used (zsh-safe, no `--include` globbing):

```bash
grep -rnE "class \w+(<[^>]*>)? extends (Cubit|Bloc|StatefulWidget|ChangeNotifier)\b|with ChangeNotifier" lib | grep -v /generated/
```

Each report lists the matching class names with paths so the total can be
reconciled by a reader.

**Baseline correction (`cefad0a`):** 11 production Cubits, 1 unused legacy
Bloc, 16 `StatefulWidget` classes (10 production, 3 demo, 3 preview) and 2
`ChangeNotifier` classes (router stream bridge, demo state), i.e. 18
stateful/notifier classes. The original report's "14 Cubits" and "21 state
owners" were wrong.

## 3. Reading-coverage claims

- "Inventory membership" (every path appears in the inventory) is not
  "content read". State both separately.
- Claim "fully read" only for files whose whole content was read in the run.
  For partially read files record the line ranges; for skipped content
  (long comments, JSON fixtures, generated files) say so.
- Source review is not runtime reproduction. A finding says which it is:
  `source-confirmed`, `reproduced` (test or device), or `hypothesis`.
- Test results are dated and belong to the run that executed them; a later
  report never re-quotes an older pass count as its own.

## 4. Screen and capability counting

Count separately, from the router and the approved decisions of the
snapshot:

1. **Logical production screens** reachable by a route (aliases and shell
   branches counted once each).
2. **Partial UI/workflow** screens: presentation or workflow steps missing.
3. **Integration-only gaps**: the UI is complete for its approved scope and
   needs a real adapter, content (legal text), or runtime/device
   verification. Name which; a screen backed by a real platform provider
   (No Internet uses the real connectivity monitor) does not "lack an API".
4. **Approved missing capabilities**: an approved presentation that has no
   implementation. It is **not** a screen until a design/route is
   approved (for example, future scheduled commitments must be shown
   separately from the active delivery, but no dedicated screen is
   approved).
5. **Secondary surfaces** (sheets, popups, cards): listed, not counted as
   screens.

Never add one to the screen count because a feature is described in a
separate document.

## 5. Classifying findings

| Class | Meaning |
|---|---|
| Defect | A demonstrated mismatch with an approved rule, a reproducible failure or a source-confirmed path that produces wrong behavior |
| Contract gap | Behavior blocked by a missing backend/API contract; truthful placeholders are **not** a defect |
| Owner decision | An open product choice (D-P…); never presented as a bug |
| Recommendation | Optional improvement (duplication, style); no defect shown |
| Not a defect | The audit's assumption contradicted the documented architecture |

Rules learned from the first audit:

- Routing in `lib/util/routes/` is the project's documented organization
  (`ARCHITECTURE.md`). The router importing screens at the composition
  boundary is expected; only real domain/data layering violations count.
- Similar borders/radii, or a punctuation-only string in code, are
  recommendations unless a defect (wrong translation order, wrong
  accessibility sentence) is shown.
- A field absent from a client model is a defect only when a current
  consumer or operation needs it. Not every backend attribute belongs in
  `AppUser` or an offer; session faults can be typed results.
- A missing `Idempotency-Key` argument on a domain method does not prove
  the future adapter cannot own the request key. Key ownership and retry
  lifetime belong in the API contract.

## 6. Historical audit documents and the demo-removal scanner

`tool/demo/remove_demo.dart` scans `docs/` for leftover demo identifiers.
Audit reports quote such identifiers as evidence, which made the dry run
fail (reproduced 2026-11-22: `docs/01_…` and `docs/02_…` matched the
demo flag pattern). The scanner therefore classifies, narrowly:

- the three baseline report paths in `docs/` (`01_APPLICATION_AUDIT_REPORT.md`,
  `02_FILE_BY_FILE_INVENTORY.md`, `03_SYSTEM_DATA_REQUIREMENTS.md`), **only
  while their SHA-256 matches** the recorded snapshot;
- Markdown under `docs/archive/audits/`.

Everything else (code, config, ARB, tests, assets, all other docs,
including `docs/quality/`) is still scanned, and the scanner rejects a
`docs/` asset registration or a Dart file naming these documents.

When writing new reports or quality docs, **describe demo symbols in words**
(for example "the debug demo flag", "the demo app widget") instead of
quoting their identifiers, so active docs remain scannable. A new immutable
snapshot goes under `docs/archive/audits/<date>-<rev>/`.

## 7. Report set per run

1. Application audit (status, findings, screens, API readiness,
   localization, platform, verification).
2. File-by-file inventory (with reading-coverage column).
3. System data requirements (atomic field dictionary; see
   `REMEDIATION_STATUS.md` R10 for the rules).

Explanations may be in Arabic for the owner; maintained engineering docs
stay English (`CLAUDE.md` §12).
