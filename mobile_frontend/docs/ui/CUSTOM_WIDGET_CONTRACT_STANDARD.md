# SHAHM Flutter — Custom Widget Contract Standard

**Status:** owner-approved direction (Task 08, 2026-11-14; D-A32 supplement in
`../decisions/ARCHITECTURAL_DECISIONS.md` §1.1), made permanent and extended
by the owner-approved systematic widget cleanup (Task 12, 2026-11-15). This
is the **only** custom-widget policy; improve this file instead of adding a
second one. Applies to every shared widget under `lib/view/widget/` and to
feature widgets reused by more than one screen. Reference implementations:
`AppTextFormField` + `AppTextFieldStyle` (a widget that needs a style
object, `SHARED_UI_COMPONENTS_REFERENCE.md` §3.7) and `AppTextButton` (a
widget that does not, §3.9). The current inventory and migration order are
in §12.

Use this as a checklist when creating a widget, changing its public API, or
reviewing one. Each rule has a short "check" for review.

---

## 1. One responsibility, justified abstraction

- State in one sentence what the widget does that plain Flutter does not:
  SHAHM defaults, a reusable behavior, or a consistent composition.
- A wrapper must not just re-export another widget's constructor. If the
  only value is forwarding parameters, use the Flutter widget directly.
- Business logic, Cubits, repositories, network, navigation and logging stay
  out of shared widgets (D-A32). See §7: no API calls, no navigation, no
  `get_it` or Cubit lookups, no silent data normalization.

**Check:** the class doc comment names its responsibility and what it does
*not* own.

## 2. `required` means intrinsic

- Mark a parameter `required` only when the widget is invalid or
  inaccessible without it (e.g. `label` as a field's accessible name, a
  button's `label`).
- Do not mark callbacks, controllers, icons or cosmetic values `required`
  unless a concrete invariant needs them.
- A business rule ("this value must be filled") belongs to validators,
  use cases and Cubits, never to the Dart `required` keyword.
- **A nullable callback can be intrinsic.** When `null` deliberately means
  "disabled" (e.g. `AppTextButton.onPressed`), mark it
  `required VoidCallback? onPressed`: every caller must decide, and the
  disabled state stays available. Never replace it with a hidden non-null
  action that removes the disabled state.
- Every optional parameter has a documented default and a documented meaning
  for `null` ("inherit", "off", "none" — never undefined).

**Check:** for each `required`, the doc says why the widget cannot work
without it.

## 3. Lean API, predictable precedence

- **Minimal and useful, not a quota.** Every public parameter needs a real
  caller, an owner-approved near-term need, or a place in the widget's
  essential generic behavior (e.g. disabled state, icon position, padding).
  Remove speculative, duplicate, dead or silently ignored options and
  migrate their callers in the same change. Parameter count is not a goal by
  itself: **never delete an argument only because it has zero calls today**
  when it represents important generic behavior, and never rename one just
  to match a preference.
- Do not wrap a Flutter widget only to rename its parameters; the wrapper
  must add a SHAHM default, behavior or composition (§1).
- No two parameters may control the same thing without a documented winner.
- Real conflicts fail loudly with an `assert` and a message that names the
  fix. Never silently discard a caller's value (icons, widths, colors,
  validators).
- Prefer `assert`s in the `const` constructor; checks that need non-constant
  calls (e.g. `trim`) go in `build`.
- Keep Flutter naming where the concept is Flutter's (`enabled`, `readOnly`,
  `onChanged`); use logical names (`start`/`end`) for direction.

**Check:** every parameter appears in a real call site or test with a
stated purpose; every conflict has an assert and a test.

## 4. Theme defaults with deliberate per-call overrides

- Defaults come from `ThemeData` / central `AppColor` semantic tokens, never
  hard-coded colors in `build`. Screens never pass raw `Color(...)` values.
- Expose per-call overrides for the **actually rendered elements** where a
  real or approved need exists, and verify in tests that each override is
  visible in the rendered UI. **No styling that silently fails to apply:**
  if a value would be overridden internally (e.g. a button's foreground
  color replacing `textStyle.color`), either honor it with a documented
  precedence or assert against it.
- Separate **behavior** (named arguments) from **appearance**. Use one
  immutable, `const` style object (e.g. `AppTextFieldStyle`) when a widget
  has **several cohesive style options** across states or reused visual
  variants. **Not every widget needs a style file:** a few direct
  arguments (`color`, `textStyle`, `padding`) are enough for a small widget
  such as `AppTextButton`.
- **Precedence is always:** per-call value > theme / semantic token >
  documented Flutter fallback. A per-call `TextStyle` is **merged** over the
  default (only the properties it sets change) unless the doc says it
  replaces it.
- The style object: every property nullable; `null` means inherit; a
  `merge` where non-null values win; a `defaultsOf(ThemeData)` that states
  the source of each default.
- Do not offer a second, competing appearance API (e.g. a raw
  `InputDecoration`) alongside the style object without owner approval.
  When two inputs can set the same property (e.g. `color` and
  `textStyle.color`), document the winner and test both.
- Where a default is still a Material fallback (no approved token yet),
  make it explicit, document it as technical debt and test it. Do not choose
  new colors or tokens without owner approval (D-A63).

**Check:** the reference doc has a defaults table with sources; tests cover
each default and each override.

## 5. State ownership

- Controlled inputs (controllers, focus nodes, values) belong to the caller.
  The widget never creates an object it does not dispose of, and never
  recreates a caller's object.
- The widget may own only short-lived UI state (e.g. password visibility),
  and must keep it coherent when the parent changes the related parameter.
- Business and form state live in Cubits (`STATE_MANAGEMENT.md`).
- The widget never normalizes, trims or mutates the value it displays.
- **Command controls are controlled (Task 24).** A control that starts a
  command whose result belongs to someone else (a server, the OS), such as
  an availability switch, shows only the owner's confirmed `value`. Its
  callback is an intent, never an optimistic local flip; a busy state blocks
  repeated intents.

## 6. Direction, accessibility, input and layout

- Use logical `start`/`end` (`EdgeInsetsDirectional`, `AlignmentDirectional`)
  so Arabic RTL works by default; a text-direction option affects only the
  content it names.
- Every interactive element has an accessible name (label or localized
  tooltip); slots that accept caller widgets leave semantics to that widget
  and document it.
- Touch targets are at least 48 logical pixels.
- Keyboard, focus, autofill and disabled/read-only behavior are explicit
  and distinct (`enabled` ≠ `readOnly`).
- The widget works at 320 px width and at text scale ≥ 2.0 without overflow
  or clipped content. A widget that can appear while a field is focused
  (dialogs, sheets, toasts) is also tested with the **software keyboard
  open** (`tester.view.viewInsets`), without dismissing it.

## 7. Localization, privacy and side effects

- All visible text comes from ARB via `context.l10n` (D-A30); shared widgets
  take strings from the caller or use generic ARB keys (e.g. `showPassword`).
- Never log or expose user input, especially secrets.
- No hidden side effects: no network, storage, navigation or global state.
- Transient UI (toasts, banners, sheets) runs each action callback **at
  most once**, and never after that instance started closing or was replaced
  by a newer one; a replacement drops queued instances instead of replaying
  them later.
- Shared presentational widgets never call APIs, navigate, read `get_it`
  or a Cubit, or normalize/trim the data they display. The caller passes
  values and callbacks; the screen or Cubit owns the outcome.

## 8. Tests

For every shared widget, `test/` covers:

- each `required` argument (valid default invocation) and each `assert`;
- each exposed visual override, checked on the **rendered** result (the
  painted color, the merged text style, the laid-out size), not just the
  constructor field;
- defaults and each override, including precedence and `merge`;
- every visual and interaction state (enabled, focused, error, disabled,
  read-only, loading, as applicable);
- semantics/accessible names and RTL/LTR placement;
- narrow width and large text scale;
- regression tests for each existing consumer (e.g. Login).

Truncation and label-fit checks must load the bundled IBM Plex Sans Arabic
(`FontLoader`, as in `brand_theme_test.dart`): the default test font draws
every glyph as a square, so it both invents and hides truncation.

Report only tests that were actually run, with counts.

## 9. Migration and documentation

- A public API change updates every call site, its tests and
  `SHARED_UI_COMPONENTS_REFERENCE.md` in the same change.
- Document the actual constructor, defaults, precedence and collisions;
  never document behavior that was not verified. Update the exact API in
  the reference doc; never rewrite historical verification results.
- Record what changed and the verification in
  `../project/PROJECT_STATUS.md`.
- **One component per migration:** inventory → select one widget → propose
  its public contract → migrate its callers → test → report → stop. No
  cascading refactors of other widgets by personal preference; the next
  component is a separate task.

## 10. Approval gate

Owner approval is required **before** implementation for:

- a breaking public API change (removing, renaming or retyping a public
  argument, or changing a default that callers can see);
- a new package dependency;
- a new or changed global design token, color or typography/font;
- a visible change to product behavior or a screen's layout/copy;
- anything that touches validation, auth, routing or backend contracts.

An audit or proposal is not an approval. Record approvals in
`../decisions/ARCHITECTURAL_DECISIONS.md`.

## 11. Pre-implementation checklist and breaking-change review gate

**Before creating or changing a shared widget** (answer each in the plan or
report):

1. Responsibility: what does it add beyond the Flutter widget (§1)?
2. Reuse: does an existing shared widget already cover it? Search `lib/`
   and `test/`, not only the docs.
3. Consumers: list every real call site and each argument it uses.
4. Contract: for each argument, its type, nullability, default and meaning
   of `null`; why each `required` one is intrinsic (§2).
5. Appearance: theme/token default per rendered element; which overrides
   are justified; style object or direct arguments (§4).
6. Conflicts: which inputs overlap, the documented winner or the `assert`
   (§3).
7. States and accessibility: enabled, disabled, loading, error, focus,
   semantics name, 48 px target, RTL/LTR, 320 px and text scale ≥ 2.0 (§6).
8. Tests: the list from §8, including every real consumer.

**Breaking-change review gate.** If the change removes, renames or retypes
a public argument, changes a visible default, or alters an approved
appearance or behavior: stop **before** changing it, describe the smallest
proposed contract (before/after table and every affected caller), and get
specific owner approval (§10). Without approval, finish only the
non-breaking part, and report the blocker.

## 12. Inventory and migration order

The current inventory (Task 12, 2026-11-15) is in
`../project/PROJECT_STATUS.md` §4 ("Custom widget inventory"). Migrated so
far: `AppTextFormField` (Task 08), `AppTextButton` (Task 12), `AppPopup`
(Task 17), `AppButton` (Task 18), `AppToast` (Task 19), `AppStatusMessage` (Task 20), `UnderConstructionPlaceholder` (Task 21, audited, no change), `MainNavigationBar` (Task 22), the text widget family `AppTextWidget` + 11 wrappers (Task 23), `AppAvailabilityToggle` (Task 24, new). One component
per task (§9).
