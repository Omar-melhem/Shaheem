# SHAHM Flutter — Design System

**2026-11-24 target amendment (D-A82/D-A83):** §6/§10 now describe the approved Home emblem/first-name/accept-only revision and the new shared delivery-details presentation. Implemented in Flutter 2026-11-24 (widget tests; no device check yet); older dated verification is historical.

**Current target: red/white/neutral theme (D-A69, client revision 2026-11-20).** Check `PROJECT_STATUS.md` §0 before claiming a component has been migrated in Flutter.

Colors, typography, fonts, RTL, localization, responsive breakpoints and
assets. Component APIs (text
widgets, tools, loading widgets, validators) are in
`SHARED_UI_COMPONENTS_REFERENCE.md`.

Decisions referenced: D-A19, D-A24, D-A26, D-A30, D-A31, D-A32, D-A33,
D-A36, D-A37, D-A38, D-A41, D-P08, D-P11, D-P18, D-P21, C-11, C-12, C-13,
C-20, C-21, C-22, C-36.

---

## 1. Colors (`lib/theme/app_color.dart`, class `AppColor`)

**Semantic palette (D-A69).** The exact shades are an implementation
selection for the owner's red/white direction, centralized so they can be
revised in one place. There is one brand palette; the former
maroon/forest/cream/sand tokens (D-A63) are superseded.

| Semantic role | Hex | Use |
|---|---|---|
| `primary` | `#C62828` | Prominent primary actions, including Accept |
| `onPrimary` | `#FFFFFF` | Content on red |
| `primaryPressed` | `#A61B1B` | Pressed red state |
| `primaryContainer` | `#FDECEC` | Low-emphasis red status/highlight background |
| `onPrimaryContainer` | `#8F1D1D` | Text on the red tint |
| `background` / `surface` | `#FFFFFF` | Screens, Home AppBar, navigation, cards, sheets |
| `surfaceContainer` | `#F5F5F5` | Neutral inset surfaces |
| `textPrimary` / `navSelected` | `#171717` | Main text, selected tab icon/label |
| `textSecondary` / `navUnselected` | `#616161` | Secondary text, unselected tabs |
| `inputOutline` | `#737373` | Visible control boundary |
| `divider` / `outlineVariant` | `#E5E5E5` | Decorative separators, card outlines |
| `selectedTabContainer` | `#EEEEEE` | Neutral selection cue behind the selected tab |
| `disabledBackground` | `#F0F0F0` | Disabled controls |
| `disabledForeground` | `#767676` | Disabled content |
| `success` | `#166534` | Semantic available/success state only |
| `error` | `#B91C1C` | Validation, failure, destructive account deletion |
| `warning` | `#92400E` | Semantic warning |
| `focus` | `#171717` | Focused outline (plus width/shape cue) |

Approximate contrast on white: primary 5.62:1, text primary 17.93:1, text
secondary 6.19:1, input outline 4.74:1 (body text ≥ 4.5:1; meaningful
non-text boundaries ≥ 3:1; a decorative divider never replaces an input
boundary). Brand red and destructive red are close in hue: actions are
distinguished by label, icon, placement and filled vs outlined style.

**Rules:**
- Colors come from `AppColor` through `ColorScheme` and component themes; no
  `Color(...)` literals in screen widgets; no decorative gradients.
- `secondary` maps to **neutral emphasis**, not success. Use the explicit
  `success` token for "available/success" (e.g. the availability switch).
- Selected tabs are dark, never red.
- Material surface tint and scrolled-under tint are disabled deliberately
  so no beige or red tint returns on white surfaces.

## 2. Theme (`lib/theme/app_theme.dart`)

`AppTheme.light` builds a `ColorScheme.light` from the table above:
primary/onPrimary, primaryContainer/onPrimaryContainer, secondary =
neutral (`textPrimary`), surface/onSurface = white/`textPrimary`,
`surfaceContainer*`, outline = `inputOutline`, outlineVariant = `divider`,
error = `error`, `surfaceTint` transparent. Component themes: white Scaffold
and AppBar (no scrolled-under tint, dark status-bar icons), filled buttons
red with pressed/disabled states, outlined buttons neutral, input borders
`inputOutline` / focus `focus` / error `error`, switch thumb/track using
`success` when on, bottom sheet and dialog white, `fontFamily`
IBM Plex Sans Arabic. No dark theme, no runtime switching (no Cubit).

**Reference image (`reference_home_client.jpeg`):** layout guidance only —
greeting at the start of the AppBar with the availability switch/status
below it, readable white cards, four destinations. Not adopted: its maroon,
its reference-image logo artwork, patterned header, red selected tab, sample names/amounts, «الربح»
(the full fee is labelled «أجرة التوصيل») and «تجاهل» (dismiss ≠ decline).

## 3. Typography

| Item | Approved target / current snapshot |
|---|---|
| Official Arabic font | **IBM Plex Sans Arabic**, bundled in project assets and declared in `pubspec.yaml`; use a valid Flutter font **family name**, not an asset path in `fontFamily` |
| Text-color default | `AppColor.ink` **`#242424`** for all text styles, including `Headline4`; semantic variants only where required |
| Typography source | Central `TextThemeStyle`/`ThemeData` aligned to shared widgets; no duplicate theme definitions across screens |
| Localization | `gen_l10n` with Arabic ARB, RTL driven by Flutter locale; no reactive locale Cubit for the single-language MVP |
| Current source status | **Implemented (Task 10, 2026-11-15).** Family name `IBMPlexSansArabic` (`AppFonts.ibmPlexSansArabic`), registered in `pubspec.yaml` with weights 300 Light, 400 Regular, 500 Medium, 600 SemiBold, 700 Bold. Files in `assets/fonts/ibm_plex_sans_arabic/` from the official IBM release `@ibm/plex-sans-arabic@1.1.0` (github.com/IBM/plex, font version 1.005), SIL Open Font License 1.1 kept as `OFL.txt`. Other weights (100, 200, 450 Text) are not bundled. The family covers Latin and digits too. The obsolete Tajawal/Inter path constants were removed |

Use semantic text styles; avoid raw font/color declarations in individual
widgets. Do not share proprietary font files or promise runtime font changes.

## 4. RTL and language

- **RTL:** comes from the locale. `MaterialApp.router` runs with
  `locale: ar` and Flutter's localization delegates, so the whole app is RTL
  and Material's built-in strings (tooltips, buttons) are Arabic. There's
  no manual `Directionality` wrapper.
- **Logical alignment:** use start and end (`TextAlign.start`,
  `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`)
  rather than left and right. That keeps every layout correct for a future
  LTR language. Don't manually reverse rows or icons.
- **Mixed text:** check that Arabic mixed with numbers or Latin text renders
  correctly. Phone numbers are stored normalized to Latin digits.

## 5. Localization (D-A30)

| Item | Value |
|---|---|
| Workflow | Flutter's official `gen_l10n` with ARB files (`flutter_localizations` SDK package, `generate: true` in `pubspec.yaml`) |
| Config | `l10n.yaml`: `arb-dir: lib/helper/translation`, template `app_ar.arb`, class `AppLocalizations`, output `app_localizations.dart`, `output-dir: lib/helper/translation/generated`, `nullable-getter: false` |
| Resources | `lib/helper/translation/app_ar.arb`, with every key described (`@key.description`) |
| Generated | `lib/helper/translation/generated/app_localizations.dart` (+ `_ar.dart`). **Never edit by hand**; regenerate with `flutter gen-l10n` (or `flutter pub get`) |
| Active locales | Arabic (`ar`) only, which is also the default. No language picker and no locale Cubit |
| Access | `context.l10n.someKey` (`lib/helper/translation/l10n_extension.dart`) |

**Rules:**
- **Every user-facing string comes from ARB:** labels, hints, validation,
  toasts, dialogs, loading, offline, errors and titles. Never hard-code UI
  text in widgets, Cubits or validators.
- **Validation:** validators return codes, and `validationMessage(l10n,
  code)` resolves the text.
- **Adding a key:**
  1. Add it to `app_ar.arb` with a description.
  2. Use ARB placeholders for interpolation and plurals.
  3. Regenerate.
- **Adding a language:** add `app_<locale>.arb` with **all** keys. Don't ship
  a partial translation.
- **Replaced:** `AppStrings` (`lib/util/app_strings.dart`) was removed when
  ARB localization was introduced, on 2026-11-11.

**Copy notes:**
- **Same text, two places:** the Login heading and the Login button both
  read «تسجيل الدخول». The offline banner and the No Internet title share
  their text too.
- **Rejected credentials:** incorrect username/password always receive the
  generic «اسم المستخدم أو كلمة المرور غير صحيحة.» (D-A33). **Approved D-A53:**
  if the backend determines the account is suspended, invalidate its session
  immediately and return to Login. The old UI's generic blocked handling is
  an implementation snapshot, not a still-pending policy.
- **Composed text** uses ARB placeholders, never string concatenation. For
  example, a toast's screen-reader announcement is `toastAnnouncement
  ({status}: {message})`, so other languages can reorder it.
  - **Applied in R08 (2026-11-22, LOC-02/03):** the "label: value" lines of
    the offer card and new-offer sheet (`offerPickupLine`,
    `offerDeliveryAreaLine`, `offerScheduledPickupLine`), the debit card
    (`walletDebitMerchantLine`, `walletDebitDateLine`,
    `walletDebitAmountLine`; the area line reuses `offerDeliveryAreaLine`,
    same meaning), the balance/profile screen-reader sentences
    (`walletBalanceCardSemantics`, `profileNameSemantics`,
    `profilePhoneSemantics`), the metric/rating sentences formerly joined
    with `'. '` in code (`walletMetricSemantics[WithNote]`,
    `profileRatingSemantics[WithCount]`) and the declined-record outcome
    with its kind (`declinedOfferOutcomeWithKind`). The former bare label
    keys were removed after proving they had no other use.
  - **Intentionally left as layout (not defects):** the decorative bullet
    before each missing availability requirement (a list marker, not
    wording); the space joining two complete sentences on the Current Order
    location notice; the amount-plus-currency pair, which uses the shared
    JOD formatter and the `walletCurrencySymbol` key everywhere.
  - **Sink checklist for new text:** (1) any sentence that combines a label
    and a value, two facts, or punctuation between parts is one ARB key with
    named placeholders; (2) server data (merchant, area names) is a
    placeholder value, never ARB text; (3) amounts, dates and phone numbers
    stay LTR-isolated before insertion; (4) counts use ICU plurals; (5) a
    screen-reader label is a sentence key too, not a `join`; (6) run
    `flutter gen-l10n` and never edit generated files.
- **Platform app names (D-A66):** Android/iOS **«شهم»** is set since R09
  (2026-11-22): `android:label` in the main manifest, `CFBundleDisplayName`
  and `CFBundleName` in `Info.plist`. Web **«SHAHM | شهم»** belongs to the
  web portals. These are platform metadata, not ARB strings.

## 6. Assets

| Constant | Path | Notes |
|---|---|---|
| `AppImages.logo` | `assets/images/png/shahm_main_logo.png` | Current owner-edited main logo used by existing consumers; preserve it and verify against source before changing |
| `AppImages.homeLogo` | `assets/images/png/shahm_logo_2.png` | **Implemented 2026-11-24 (D-A82):** constant in `lib/util/images.dart`, used by `HomeAppBar` (height 44, `BoxFit.contain`). Asset exists; preserve full artwork and aspect ratio |

**Registration:** `pubspec.yaml` registers `assets/images/png/`. Add
format-specific folders (`svg/`, `webp/`…) only when needed.

**Usage:** always reference images through `AppImages` constants.

## 7. Layout conventions

- **Touch targets:** at least 48 px (`AppButton`, `AppTextButton` and the
  field toggles enforce this).
- **Screen edges:** respect `SafeArea`.
- **Short screens and the keyboard:** screens with forms scroll
  (`SingleChildScrollView`), so content never overflows when the screen is
  short or the keyboard is open. Avoid fixed heights.
- **Loading UI:** use `AppButton(isLoading:)`, the shared loading widgets or
  `AppTools.showLoading`. Don't duplicate spinners with new styles.
- **Popups and toasts:** use `showAppPopup` and `showAppToast` (or the
  `AppTools` helpers that delegate to them). Toast colors come from existing
  tokens (decision C-13) and every type has an icon, so color is never the
  only signal.

## 8. Responsive breakpoints (D-A31)

**Package:** `responsive_framework` 1.5.1.

**Single definition:** `AppBreakpoints.all` in
`lib/util/responsive/app_breakpoints.dart`, registered once by
`ResponsiveBreakpoints.builder` in `MainApp`'s `MaterialApp.router` builder.
**Never define breakpoints anywhere else.**

| Name | Logical width |
|---|---|
| `MOBILE` | 0–450 |
| `TABLET` | 451–800 |
| `DESKTOP` | 801–1920 |
| `AppBreakpoints.fourK` (`'4K'`) | 1921 and above |

**Boundaries:**
- The package matches `start ≤ width ≤ end` and the first match wins.
- Each range is therefore defined to start at the previous range's end (450,
  800, 1920). An exact boundary belongs to the smaller range, and fractional
  widths have no gap (decision C-11).

**Helpers** (decision C-12):

| Helper | Mobile | Tablet | Desktop and above |
|---|---|---|---|
| `AppBreakpoints.formMaxWidth(context)` | full width | 480 | 520 |
| `AppBreakpoints.screenPadding(context)` | 20 | 32 | 32 |

Used by Login, No Internet and the Splash status.

**Querying:** for anything else, use `ResponsiveBreakpoints.of(context)`
(`isMobile`, `isTablet`, `isDesktop`, `largerThan(...)`).

**Approach:** adapt the layout, don't scale everything.
- Phones use vertical flow and the full width.
- Larger screens cap the form or content width instead of stretching it.
- Don't shrink text to make content fit.

**Known package behavior:** the screen is measured after the first frame.
On that frame no breakpoint is active, so `formMaxWidth` returns the
desktop cap. That's harmless and corrected one frame later.

**Tests:** the Login screen, the main shell and the navigation bar are
tested at widths 320, 375, 450.5, 600, 800.5, 840, 1024, 1440 and 1920.5,
and in landscape on a short screen; Login also with the keyboard open
(`test/login_screen_test.dart`, `test/main_navigation_test.dart`,
`test/main_navigation_bar_test.dart`). Breakpoint mapping is tested in
`test/localization_responsive_test.dart`, including the exact boundaries
(450, 800, 1920) and the fractional widths just past them (450.5, 800.5,
1920.5). It found no uncovered ranges (verified 2026-11-11).

## 9. Icons (D-A37)

| Use | Icon set |
|---|---|
| The five main navigation destinations, their screens (placeholders and Current Order) and the active-order badge | **Phosphor** (`phosphor_icons` 3.0.1). Use the style classes (`PhosphorIconsRegular`, `PhosphorIconsFill`, `PhosphorIconsBold`), which keep icon tree-shaking working; avoid `PhosphorIcons.x(style)` |
| Everything built earlier (form field icons, popups, toasts, No Internet, the debug preview button) | Material `Icons.*`, unchanged |

- **Navigation destinations never use Material `Icons.*`**, downloaded SVGs
  or a second icon family.
- **Weights:** Regular when not selected, Fill when selected.
- **Current Order never uses a plus icon** (D-A41): a plus means "create",
  and this action opens the active order. It uses a map pin.
- **RTL:** the package marks its icons `matchTextDirection`, so they mirror
  with the text direction by themselves. Don't flip icons by hand.
- Moving the older Material icons to Phosphor is **not decided**; don't do it
  as a side effect.

Final mapping (C-22):

| Destination | Not selected | Selected |
|---|---|---|
| Home | `PhosphorIconsRegular.house` | `PhosphorIconsFill.house` |
| Notifications | `PhosphorIconsRegular.bell` | `PhosphorIconsFill.bell` |
| Current Order | `PhosphorIconsRegular.mapPin` | `PhosphorIconsFill.mapPin` |
| Order History | `PhosphorIconsRegular.clockCounterClockwise` | `PhosphorIconsFill.clockCounterClockwise` |
| Profile (current implementation only) | `PhosphorIconsRegular.userCircle` | `PhosphorIconsFill.userCircle` |
| Active-order badge | `PhosphorIconsFill.package` | — |

**Approved target change (D-A50, not implemented in the current code
snapshot):** Wallet replaces Profile as the fifth destination. Keep the
Phosphor icon family, but select the exact Wallet glyph and final visual
mapping during the Wallet navigation implementation; do not treat the old
Profile mapping as the target design.

## 10. Main navigation bar (D-A69, D-A70)

Component API: `SHARED_UI_COMPONENTS_REFERENCE.md` §3.12. Routing:
`../architecture/ROUTING_AND_STARTUP.md` §7.

- **Four** equal items in reading order (Arabic: Home on the right, My
  Account on the left): «الرئيسية», «طلباتي», «المحفظة», «حسابي». No raised
  center button, unread dot or active-order badge.
- Each item: icon above label; the whole item (≥ 48×48) is the target.
  White surface with a top `divider` line plus the bottom safe-area inset
  (added once, inside the bar). Content width capped at 640 px.
- **Selected:** Fill icon, bold label, `navSelected` (`#171717`), and a
  `selectedTabContainer` pill behind the icon (second cue beyond color).
  **Unselected:** Regular icon, regular label, `navUnselected` (`#616161`).
- Labels are never shrunk; if one does not fit, all labels get two lines and
  the bar grows. Text scaling honored up to 2.0 inside the bar.
- Each item is a labelled button exposing its selected state; the bar is
  named `mainNavigationLabel`.
- Hidden while the keyboard is open; visible only inside the main shell.

### 10.1 Home AppBar (D-A82, superseding D-A71)

White, no patterned header. Row 1: first-name greeting at logical start and
the owner-provided Home emblem at logical end, replacing the removed wallet
shortcut. Use `AppImages.homeLogo`, bounded size and `BoxFit.contain`;
never crop/stretch the artwork or attach a wallet action. Preserve the
existing main logo constant/consumers. Row 2 keeps availability/status,
controlled switch and notices. AppBar height adapts to content, 320 px and
text scale up to 3. Full session/Profile name is unchanged; a blank name
keeps the localized generic greeting. Logo semantics come from localization.

### 10.2 Home offer card (D-A82)

White card, divider outline, restrained shadow; merchant, pickup, delivery
area and full delivery fee. One full-width filled-red Accept `AppButton`
with its busy/disabled states; remove the secondary rejection column and
its spacer, then rebalance vertical rhythm. Content-driven height, wrapping
Arabic text and 3-decimal JOD remain. Separate new-offer-sheet actions are
unchanged. This is a target until implementation; earlier two-button card
screenshots/tests are not evidence of this revision.

### 10.3 Delivery details, current and historical (D-A83)

Use a cohesive stateless details presentation for both the active delivery
leg and each own completed-order page. Localized heading/rows: optional
customer name, optional phone, required area, optional delivery notes and
full fee. Omit blank optional rows; unavailable required data gets honest
localized copy. No customer map. Reuse existing theme, money formatting and
selectable/LTR phone behavior; long notes wrap without a fixed card height.
The historical page is read-only and preserves the appropriate merchant,
order identity and completion time. Commands remain in the active feature.

## 11. Status, empty and placeholder states

All of these use `AppStatusMessage` (`lib/view/widget/status/`): an icon (or
a spinner while loading), a title, an optional sentence and an optional
action button, spaced 16 / 8 / 24 px.

- **Centering:** the block is centered in the area it's given, which for a
  screen is the body between the app bar and the navigation bar, not the
  physical screen. It scrolls if that area is too short.
- **Insets:** it uses the shared horizontal padding and width helpers and
  adds no `SafeArea`; the surrounding `Scaffold`s already consumed the
  insets. Don't add fixed vertical offsets to position it.
- **Current-code placeholders (historical):** Notifications, Order History and Profile
  use `UnderConstructionPlaceholder` («قيد التطوير» plus one sentence), which
  delegates to `AppStatusMessage`. They show no data and call nothing. Under
  D-A66, **Wallet is the approved fifth tab** and Profile moves to AppBar/menu.
  Old Profile implementation remains pending a code migration.
- **Current Order** uses it for loading, no active order, backend not
  connected (no action button), lookup failure (Retry), and inside the map
  area for "restaurant location unavailable" and "map unavailable".
- **Measured on the iPhone 17 simulator screenshot (2026-11-11, R10):** in
  the error state the body runs from y ≈ 118 to ≈ 757 logical px (app bar
  bottom to navigation-bar top), so its middle is ≈ 437. The content group
  (icon top ≈ 336 to button bottom ≈ 544) is centered at ≈ 440, about 2–3 px
  low, which is within the icon glyph's internal padding. On this device the
  body's middle and the screen's middle (437) coincide. No measurable layout
  issue, so no layout change was made. A widget test pins the group to the
  body's center at iPhone 17 size.

## 12. Current Order pickup view (D-A41)

- A surface card with the label «نقطة الاستلام من المطعم», the restaurant
  name and, when the order has them, the pickup instructions. Always shown
  for an active order, even without coordinates.
- One line for the captain's own location while it's being read or when it
  failed (with Retry where that helps); nothing once it is known.
- The map area: rounded, at least 240 px and 55% of the body height; the
  page scrolls on short screens. Without usable restaurant coordinates it
  shows «موقع المطعم غير متوفر» with Retry; with no map configured it shows
  «الخريطة غير متاحة حالياً». Never a blank area or a default location.
- Content is capped at 840 px on wide screens.

## 13. Simulator check (2026-11-11)

The shell, the bar and the Current Order states were run on an iPhone 17
simulator (iOS 26.5, portrait) with temporary fake data. Checked there: the
status-bar and home-indicator insets, the raised circle and its shadow, the
selected ring, the active-order badge and the loading spinner. Not checked
on a device: Android, landscape, small and large physical screens, and the
keyboard (covered by widget tests only).
