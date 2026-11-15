# SHAHM Flutter — Design System

**Approved target (owner confirmation through 2026-11-14).** Descriptions of 2026-11-11 code below must not be mistaken for completed migration. Check `PROJECT_STATUS.md` before claiming colors/fonts/components are changed in Flutter.

Colors, typography, fonts, RTL, localization, responsive breakpoints and
assets. Component APIs (text
widgets, tools, loading widgets, validators) are in
`SHARED_UI_COMPONENTS_REFERENCE.md`.

Decisions referenced: D-A19, D-A24, D-A26, D-A30, D-A31, D-A32, D-A33,
D-A36, D-A37, D-A38, D-A41, D-P08, D-P11, D-P18, D-P21, C-11, C-12, C-13,
C-20, C-21, C-22, C-36.

---

## 1. Colors (`lib/theme/app_color.dart`, class `AppColor`)

**Final SHAHM brand palette (D-A63):**

| Role | Base value |
|---|---|
| Primary maroon | `#8C2335` |
| Secondary forest green | `#263D34` |
| Cream background | `#F5F0E8` |
| Sand accent | `#C8A98A` |
| Ink — default text, including Headline4 | `#242424` |

**Permanent design-system rule:** all client-side branding must use central,
coordinated design tokens, never literal colors in screen widgets. A future
brand-color change should require edits to central Flutter tokens and the
web design-token source(s), not a search-and-replace across components.
Runtime server-delivered theme switching is **not** implicitly approved.

`AppColor` must provide coherent **Brand**, **Basic**, **Neutral**, **Semantic**,
**Text**, **Background**, **Border**, and **Extended** palettes/scales (including
appropriate states for success, warning, error, disabled and focus). Preserve
intentional reusable shades even when currently unused. Remove verified
obsolete aliases/duplicates in the same migration, and update every caller.
Do **not** indiscriminately delete every "unused" color or retain shadow
implementations of the same token. Names/scales may be refined centrally
without changing the owner's five brand hex values.

| Semantic family | Use |
|---|---|
| `background`, `splashBackground` | Cream |
| `surface` | White/default surface |
| `textPrimary` | Ink |
| `textSecondary` | Approved muted Ink/neutral scale |
| `border`, `outline` | Sand/neutral border |
| `success`, `warning`, `error` | Semantic statuses, not arbitrary brand accents |

**Implemented in Flutter (Task 10, 2026-11-15):**
- The five base values above are exact in `AppColor` (`primary`, `secondary`,
  `cream`/`background`, `sand`, `ink`/`textPrimary`) and mapped in
  `AppTheme.light` (tested in `test/brand_theme_test.dart`). The 50–900
  maroon/forest scales and the cream/sand/ink shades are
  **implementation-derived tonal shades**, not owner-specified values.
- `TextThemeStyle` and the shared text widgets default to Ink (no longer
  black).
- **Input border:** new semantic alias `AppColor.inputBorder = inkMuted`
  (`#6E6A64`, an existing neutral; no new hex). It is used only for the
  resting border of `AppTextFormField` and measures **5.37:1** on the white
  fill and **4.74:1** on the cream background (WCAG 1.4.11 ≥ 3:1). No sand
  shade passes on both (`sandDark`: 3.29:1 / 2.90:1). `border`/`outline`
  stay `sandLight`, so the navigation bar and other outlined elements are
  unchanged.
- **Still unresolved (owner decision):** exact semantic `error`, `warning`,
  `success` and `disabled` colors. Inputs and toasts still use Material's
  default error (`#B00020`, 6.46:1 on cream) and the Material 3 disabled
  border (`onSurface` at alpha 97). The older miscellaneous `AppColor` block
  (`red`, `success`, `failed`, …) was not audited or removed in this task.
- Web token sources were **not** changed; web synchronization is pending.

**Rules:** no raw `Color(...)` literals in widgets; no unapproved decorative
gradients; maintain contrast and accessible status communication.

## 2. Theme (`lib/theme/app_theme.dart`)

`AppTheme.light` builds a `ColorScheme.light` with these colors:
- primary: maroon, with white on primary.
- secondary: forest green, with white on secondary.
- surface: white; on-surface: ink.
- outline: `sandLight` (inputs use `AppColor.inputBorder` instead).

It also sets:
- `fontFamily: AppFonts.ibmPlexSansArabic` (every Material text style;
  Material 3 colors default text with `onSurface` = Ink).
- Scaffold background: cream.
- `AppBarTheme`: cream background, ink foreground, centered, no elevation.
- `FilledButtonTheme`: minimum size 160×48, bold IBM Plex Sans Arabic text.
- Button labels: a Flutter button's text style replaces the inherited one,
  so `AppButton`/`AppTextButton` fill in the theme family when their style
  names none.

There's no dark theme, and no runtime theme switching (so no Cubit).

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
- **Platform app names:** the historical source still has framework defaults,
  but the approved target is Android/iOS **«شهم»** and web **«SHAHM | شهم»**
  (D-A66). These are platform metadata, not ARB strings.

## 6. Assets

| Constant | Path | Notes |
|---|---|---|
| `AppImages.logo` | `assets/images/png/shahm_logo.png` | Official SHAHM logo with real transparency (copied from `web_frontend/public/brand/shahm-logo-transparent.png`). Don't alter the artwork |

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

## 10. Main navigation bar (D-A36, D-A38, D-A50)

Component API: `SHARED_UI_COMPONENTS_REFERENCE.md` §3.12. Routing:
`../architecture/ROUTING_AND_STARTUP.md` §7.

**Layout** (C-20):
- Five items in reading order, equal widths. In Arabic, Home is on the
  right and the fifth destination is on the left; Current Order is always the middle item, so
  it is centered in RTL and LTR alike.
- Each item is an icon with its label below, and the whole item (at least
  48×48) is the touch target. All five share one vertical rhythm: 8 px, the
  icon (28 px box), 4 px, the label, 8 px.
- Bar surface: at least 64 px high, `surface` color, a top border in
  `outline`, plus the bottom safe-area inset. The inset is added once,
  inside the bar; the shell `Scaffold` adds none.
- Central button: a 56 px circle with elevation, raised 20 px above the bar
  surface, with its label «الطلب الحالي» below it. The raised strip is part
  of the bar's own height, so it never overlaps page content or other items.
- On wide screens the items are capped at 640 px and centered; the surface
  still spans the full width. The bar stays at the bottom at every
  breakpoint (no NavigationRail).
- **Labels are never shrunk.** They are 12 px. When any label doesn't fit on
  one line (a narrow phone or larger accessibility text), all labels get two
  lines and the bar grows taller. Text scaling is honored up to 2.0 inside
  the bar.

**States** (approved tokens, D-A63; old component look remains a code snapshot):

| State | Shown by |
|---|---|
| Destination not selected | Regular icon, regular-weight label, `textSecondary` |
| Destination selected | Fill icon, bold label, `colorScheme.primary` |
| Central button, normal | `colorScheme.primary` background, white Regular map pin, surface-colored ring |
| Central button, selected | The same background with an `AppColor.sand` ring, a Fill map pin and a bold label |
| Central button, active order | `colorScheme.secondary` background **and** a small package badge above the circle. Independent of "selected": all four combinations exist. Shown only when the server reported an active order, never after an error |
| Central button, checking | A small spinner replaces the icon inside the same circle; the size doesn't change |
| Unread notifications | A 10 px dot in `colorScheme.error` at the icon's top-end corner. It is overlaid, so the icon and label don't move |

**Accessibility:**
- Each item is a labelled button that exposes its selected state.
- The unread dot, the active order and the lookup in progress are announced
  in words (`navUnreadNotifications`, `navActiveOrder`,
  `navCheckingActiveOrder`), and none relies on color alone.
- The central button has the hint `navCurrentOrderHint` («عرض طلبك الفعال
  وموقع استلامه على الخريطة»), so it's announced as opening the current
  order, not creating one.
- The bar is named `mainNavigationLabel` for screen readers.
- The central button's color change is not animated when the system asks
  for reduced motion.

**Behavior:** hidden while the keyboard is open; visible only inside the
main shell.

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
