# SHAHM Flutter — Custom Widget Standard

**Focused owner approval (2026-11-24, D-A82/D-A83):** removal of Home
wallet inputs/component when exclusive, removal of the offer card's
secondary rejection input/control, and migration of their callers/tests
are authorized for this revision. The separate offer sheet's rejection
flow remains. A shared delivery-details section has actual active/history
consumers; keep it presentation-only. This does not authorize unrelated
widget redesigns, dependencies or mass migrations. Examples below using
the old card `onDecline` signature are pre-migration examples; update them
to the actual new signature with the implementation.

**Status:** the **only** custom-widget policy for `mobile_frontend` (created
Task 08, 2026-11-14; rewritten Task 32, 2026-11-15). Improve this file;
don't add a second one.

**Principle: simple by default.** Compose Flutter widgets, style them with
`ThemeData` and `AppColor`, and add an abstraction only for a need you can
point to.

> **Compatibility note.** Task 32 replaces the earlier checklist-style
> wording (Tasks 08, 12, 23, 27), not their results. Approved contracts stay
> as they are: D-A32, `AppTextFormField` + `AppTextFieldStyle`, the text
> widget family, `AppButton`, `AppTextButton`, `AppPopup`, `AppToast`,
> `AppStatusMessage`, `MainNavigationBar`, `AppAvailabilityToggle`,
> `AppOrderOfferCard`, and the tested fixes made in those tasks. This guide
> does not authorize reworking them.

---

> **Owner-approved exception (D-A79, 2026-11-20):** the breaking API changes
> needed to remove obsolete navigation inputs (`MainNavigationBar`,
> `MainNavDestination`), Home AppBar inputs and wallet hold fields are
> pre-approved for Tasks 39–44. The approval gate in §11 still applies to
> every other change.

## 1. Do we need a custom widget?

Decide in this order:

1. **Use Flutter directly** (`Text`, `Row`, `Padding`, `Card`,
   `FilledButton`, `TextButton`, `ListTile`, `Switch` …) when the code is
   simple, readable and doesn't duplicate branded design or feature
   behavior.
2. **Extract a private, feature-local widget** when a cohesive section needs
   clearer structure, its own rebuild scope, or is repeated **within the
   feature**. A meaningful one-off section can justify it; a single `Row`,
   `Padding`, `Icon` or `SizedBox` does not.
3. **Create a shared `App*` widget** only when several features actually use
   it, or an approved reusable design/behavior contract justifies one place.

A wrapper that only renames a Flutter widget's parameters is not a widget;
use the Flutter widget. Check first whether the theme plus a standard
Material widget already solves it.

## 2. Compose, don't build frameworks

- `const Foo({super.key, ...})`, `final` fields, a small `build` that
  composes existing widgets.
- **`StatelessWidget` by default** for presentation.
- **`StatefulWidget` is normal Flutter.** Use it for local, short-lived UI
  state or a resource the widget must own and dispose (an animation or focus
  controller, an `AppLifecycleListener` — e.g. `HomeLifecycleBridge`). Keep
  business state in Cubits; never create a Cubit just to avoid a
  `StatefulWidget`.
- **Business stays out of presentational widgets:** no repositories, server
  commands, persistence, eligibility rules, navigation, `get_it`, and no
  Cubit reads/creation inside a shared widget. A **feature** callback such as
  `() => cubit.accept(offer.id)` is fine (see Example B).
- **Files:** one public shared widget per file is a useful convention.
  Private helpers (`_Foo`, a private method) may live in the same file when
  they clarify a real section. Move a section to its own file when it grows
  or is used elsewhere. Don't create a file per two-line helper.
- No `Manager`, `Factory`, `BaseWidget`, `Utils`, `Service` or inheritance
  layer created only "for organization".
- **Visual similarity is not a contract (SW-01 decision, 2026-11-22).** The
  2026-11-22 audit proposed an `AppSurfaceCard` because about ten widgets
  draw a white, divider-bordered, 16-radius `DecoratedBox`. They share no
  behavior, semantics or state: each has its own content, semantics
  container and padding, the active-order prompt is deliberately red and
  the balance chip deliberately 20-radius. So the built-in composition
  stays. Extract a shared surface only when repeated **behavior** (tap
  target, semantics, loading/error slots) or an approved visual contract
  must change in one place; the surface itself comes from `ThemeData`
  (`colorScheme.surface`, `AppColor.divider`).

## 3. Constructors and `required`

- **`required` = the widget can't express its contract unless the caller
  supplies it** (`required CaptainOrderOffer offer`, an intrinsic `label`).
  Never for cosmetic styling.
- **Required constructor data ≠ business validation.** `required` is a Dart
  rule about the call site. "This field must be filled" belongs to
  validators, use cases and Cubits.
- Callbacks: `required VoidCallback? onPressed` makes every caller choose
  enabled (`() {…}`) or disabled (`null`); plain optional `VoidCallback?`
  is right when "disabled by default" is meaningful. Choose per component;
  there is no global rule. Existing approved names stay unless superseded by a focused owner
  change (D-A82 removes Home card `onDecline`, not the sheet command); otherwise prefer Flutter names (`onPressed`,
  `onChanged`, `onTap`).
- Optional arguments have a useful default or a documented meaning for
  `null`. One argument must not silently cancel another: document the
  winner, or `assert` with a message that names the fix.
- **Asserts are debug-only programmer checks.** They don't validate data in
  release builds; external data is checked in its own layer.
- No speculative width/height/style/behavior knobs. Equally, don't delete a
  useful existing argument only because it has no caller today: removing or
  renaming a public argument needs owner approval (§11).
- A `child` slot is fine when flexibility is real. Don't offer `child` plus
  several competing content parameters, and don't require both `label` and
  `child` when only one can apply.

## 4. Appearance: theme first

- Start from `Theme.of(context).colorScheme`, `textTheme`, component themes
  and approved `AppColor` tokens. Keep IBM Plex Sans Arabic and the SHAHM
  palette (D-A63). Local tweaks: `textTheme.titleMedium?.copyWith(...)`.
- Use Flutter's own styling (`Card`, `DecoratedBox`, `Border`,
  `ButtonStyle`, `OutlinedButton.styleFrom`). Centralize a default only
  where it is truly shared.
- Expose only the **few overrides the real design needs** (e.g. one
  `Color? backgroundColor` or `EdgeInsetsGeometry? padding`). Width belongs
  to the parent; height follows content.
- **Style objects are the exception.** Use one only for a substantial,
  cohesive, reused set of appearance options or several approved variants.
  `AppTextFieldStyle` qualifies (many field states); it is **not** a
  template every widget must copy.
- A `ThemeExtension` or custom component theme is a later option for
  repeated shared variants or dynamic theming, never for a single widget.
- If a style object and direct arguments overlap, document precedence
  (per-call value > theme/token > Flutter fallback; a per-call `TextStyle`
  is merged, not replaced, unless documented). **Every override must
  visibly work**: check it on the rendered widget.
- No new hex colors, no hard-coded production Arabic strings, no invented
  status/disabled/error tokens. `ColorScheme.error` is a Material fallback
  in use today, **not** an approved SHAHM semantic token.

## 5. Data and callbacks: dumb UI, smart feature layer

- Shared presentational widgets take typed input plus callbacks. They never
  fetch, normalize, trim, cache, persist or mutate authoritative data.
- Prefer one typed object (`offer`) over parallel fields (name, pickup,
  area, fee).
- The widget may show caller-supplied busy, disabled or notice states.
  Outcomes, race protection and server confirmation belong to the Cubit and
  repository. Never simulate success in production.
- **Command controls are controlled:** a control whose result belongs to
  someone else (the server, the OS) shows only the owner's confirmed value;
  its callback is an intent, and a busy state blocks repeats.
- **Transient UI** (toasts, banners, sheets) runs each action at most once,
  never after it started closing or was replaced.
- **Sample data** lives in test fixtures or an explicitly labeled,
  debug-only design preview, never in the real Home data. A preview renders
  the **real** widget with typed sample input (Example C), not a second card.

## 6. Sizing, responsiveness, accessibility, RTL

- A reusable card fills the **available** width (the parent sets padding and
  constraints) and grows with its content. Don't read the screen size
  inside it, and don't fix a height that can cut Arabic text.
- `Expanded`/`Flexible` only where constraints need them; `Wrap` when items
  can flow; a lazy scrollable parent for long lists.
- `EdgeInsetsDirectional` / `AlignmentDirectional` and logical start/end;
  RTL comes from the Arabic locale.
- Text from ARB via `context.l10n`; money via `formatJodFils` inside an LTR
  isolate.
- Action controls are at least 48 px; non-text icon controls need a
  semantic label; decorative icons add no semantics. Prefer native widgets'
  built-in semantics over manual `Semantics` trees unless needed (e.g. one
  summary for a card).
- Works at 320 px and text scale 2–3 without overflow. Overlays that can
  appear over a focused field are also tested with the keyboard open.
- Widget tests don't prove screen-reader behavior on a device; say so.

## 7. Performance — no myths

- No limits on lines, parameters, classes or files as a "performance" rule.
  Long files are a readability concern, not proof of slow frames.
- `const` where possible. Nothing expensive in `build`: no `TextPainter`
  allocation per frame, I/O, subscriptions or side effects.
- Long lists stay lazy (`SliverList.separated` / builders) with stable keys
  where items can move. Never `shrinkWrap: true` with an eager nested
  `ListView` for long content.
- Subscribe narrowly (`BlocBuilder`, `BlocSelector`, `context.select`), but
  add selectors, caches, keep-alives, memoization, timers, streams or
  wrapper providers only for a demonstrated need.
- A performance claim needs a measurement or a before/after rebuild or
  work-count test.

## 8. Tests: proportional and concrete

For a new widget or a focused change, test the real risks:

1. Required data and the main UI render.
2. A callback fires; disabled and busy states don't.
3. Each **exposed** customization changes the rendered result.
4. Long Arabic text at 320 px and text scale 2–3 doesn't overflow; RTL and
   semantics where relevant.
5. Existing callers still behave the same.

Prefer widget tests of rendered behavior over source-string checks. Overflow
and truncation tests load the bundled IBM Plex Sans Arabic (`FontLoader`);
the default test font draws squares and both invents and hides overflow.
Don't write 30 tests for a three-line wrapper. Run `dart format` on touched
Dart files, `flutter analyze`, focused tests and the full suite for
production changes; report only what actually ran.

## 9. Naming and placement

- PascalCase classes, snake_case files, `_private` helpers in the same
  library.
- `App*` only for genuinely shared components in `lib/view/widget/<area>/`.
  Feature sections use feature names (`HomeGreeting`,
  `PendingOffersSliver`) under `lib/view/screens/<feature>/widget/` (public
  only so the screen can import them).
- One folder spelling: `widget/`, never `widgets/` beside it.
- Keep the `domain` / `data` / `view` / Cubit boundaries; no "common
  helpers" dumping ground.

## 10. Examples

**A — small presentational piece (no style object, no Bloc).** Inside the
card's file it stays private:

```dart
class _OfferDetailRow extends StatelessWidget {
  const _OfferDetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
```

**B — essential input, feature-supplied callbacks** (the real
`PendingOffersSliver` call, shortened):

```dart
AppOrderOfferCard(
  key: ValueKey(offer.id),
  offer: offer,
  busyAction: busy,
  onAccept: enabled ? () => unawaited(cubit.accept(offer.id)) : null,
  onDecline: enabled ? () => unawaited(cubit.decline(offer.id)) : null,
)
```

The **feature** reads the Cubit; `AppOrderOfferCard` never does. `null`
disables an action; pending state comes from the Cubit, not from the card.

**C — previews reuse the production widget** (fixture data only):

```dart
const sampleOffer = CaptainOrderOffer(
  id: 'preview-1',
  merchantName: 'مطعم السنابل',
  pickupLabel: 'الشميساني',
  deliveryAreaName: 'تلاع العلي',
  deliveryFeeFils: 2500,
);

AppOrderOfferCard(offer: sampleOffer, onAccept: () {}, onDecline: () {})
```

`lib/preview/home_offers_preview.dart` does this through the real
`HomeScreen`, with a visible "design preview" caption.

**Why not something bigger:** one approved card look needs no
`AppOrderOfferCardStyle`, base class or `ThemeExtension`; card state already
lives in `PendingOffersCubit`, so no per-card Cubit or local cache; and a
separate preview card would drift from the real one (padding, icons,
divider, fee format, buttons).

## 11. Approval gate and migration

You may fix demonstrated non-breaking bugs, broken overrides, misleading
docs and small local maintainability issues, with a regression test.

**Stop and get owner approval first** for: deleting a public component;
removing, renaming or retyping a public argument or a visible default;
visual changes beyond an approved design; new semantic colors, tokens or
fonts; new dependencies; changes to validation, auth, routing, navigation,
business logic or backend contracts; a mass migration. Describe the
smallest proposal (before/after and every affected caller) and finish only
the non-breaking part meanwhile. A proposal or audit is not an approval;
record approvals in `../decisions/ARCHITECTURAL_DECISIONS.md`.

When a public API changes, update every caller, its tests and
`SHARED_UI_COMPONENTS_REFERENCE.md` in the same change, and note the
verification in `../project/PROJECT_STATUS.md`. **One component per task**;
this guide does not retroactively authorize reworking other widgets.

## 12. 60-second pre-build checklist

1. What repeated pattern or meaningful section justifies this instead of a
   Flutter widget?
2. What is the smallest constructor, and which inputs are truly `required`?
3. Can it be stateless? If not, which local resource does it own and
   dispose?
4. Can `ThemeData` and existing tokens handle the look without a style
   class?
5. Are layout ownership, labels, RTL, accessibility and callbacks clear?
6. Is it free of business I/O, Cubits, navigation and duplicate preview
   implementations?
7. Which few tests catch real regressions, and does any caller break?

**If the widget is harder to use or maintain than the Flutter code it
replaces, simplify it or don't create it.**

---

Further reading (guidance, not requirements): Flutter UI
(docs.flutter.dev/ui), themes (docs.flutter.dev/cookbook/design/themes),
performance best practices (docs.flutter.dev/perf/best-practices). The
inventory of shared widgets is in `../project/PROJECT_STATUS.md` §4 and the
APIs in `SHARED_UI_COMPONENTS_REFERENCE.md`.
