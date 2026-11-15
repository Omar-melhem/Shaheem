# SHAHM Flutter — Shared UI Components Reference

**Important scope:** this file documents the previously verified public widget API. Approved 2026-11-14 replacements are described below as **migration targets**, not as changes already made to Flutter source. Do not perpetuate obsolete colors, font or Profile tab in new code.

Reference for the shared typography, text widgets, UI tools, loading
components, and field validators of the SHAHM Flutter app
(`mobile_frontend/`). Attach it to future prompts so these components can be
used without re-reading the code.

Last verified against the source on 2026-11-11. Update this file whenever a
public API or responsibility below changes.

**Approved target change (D-A50, 2026-11-12):** Wallet replaces Profile as
the fifth navigation destination and the total balance appears in the AppBar.
The enum/API below still documents the old implementation until the Flutter
source is updated; do not assume the Wallet branch or screen already exists.

---

## 1. Purpose and scope

Covers:

- Typography: `TextThemeStyle` and `AppFonts`.
- Eleven shared text widgets plus their base class `AppTextWidget`.
- `AppTools` (`tools.dart`): loading, dialogs, toasts, bottom sheet, keyboard
  unfocus, and two small formatting helpers.
- Loading widgets: `AndroidLoading` and `IosLoading`.
- Shared pure field validators (`util/validators/`), which replace the
  validators that used to live in `tools.dart`.
- The widget extracted from the Splash screen, and the rule for future screens.
- **Custom components (added 2026-11-11, D-A32):** `AppTextFormField`,
  `AppButton`, `AppTextButton`, `AppPopup`/`showAppPopup`,
  `AppToast`/`showAppToast` (§3.7–3.11).
- **Main navigation (added 2026-11-11, D-A36):** `MainNavigationBar`,
  `MainNavDestination`, `UnderConstructionPlaceholder` and `AppStatusMessage`
  (§3.12–3.14).

Not covered here:
- Colors, fonts, RTL, localization and responsive breakpoints: see
  `DESIGN_SYSTEM.md`.
- Startup, connectivity, session and routing: see
  `../architecture/ROUTING_AND_STARTUP.md` and
  `../architecture/GLOBAL_SERVICES.md`.

These files were copied from an older GetX-based project and repaired for
SHAHM. Before the repair, `flutter analyze` reported 120 issues (95 errors)
in them.

---

## 2. Verified file inventory

All paths are relative to `mobile_frontend/`.

| Path | Responsibility | Scope |
|---|---|---|
| `lib/theme/text_themes.dart` | `TextThemeStyle`: static text style constants | Shared |
| `lib/util/fonts.dart` | `AppFonts`: font name constants (not modified) | Shared |
| `lib/view/widget/text/app_text_widget.dart` | `AppTextWidget`: base class with the shared parameters and rendering | Shared (new) |
| `lib/view/widget/text/headline1.dart` … `headline6.dart` | `Headline1`–`Headline6` | Shared |
| `lib/view/widget/text/body_text1.dart`, `body_text2.dart` | `BodyText1`, `BodyText2` | Shared |
| `lib/view/widget/text/subtitle1.dart`, `subtitle2.dart` | `Subtitle1`, `Subtitle2` | Shared |
| `lib/view/widget/text/caption.dart` | `Caption` | Shared |
| `lib/view/widget/padding/padding.dart` | `CustomePadding`, used by `AndroidLoading` (not modified) | Shared |
| `lib/util/tools/tools.dart` | `AppTools` UI helpers and the global `appTools` | Shared |
| `lib/util/tools/android_loading.dart` | `AndroidLoading` | Shared |
| `lib/util/tools/ios_loading.dart` | `IosLoading` | Shared |
| `lib/util/validators/validators.dart` | `Validators`: pure field validators | Shared (new) |
| `lib/util/validators/validation_error.dart` | `ValidationError` enum of error codes | Shared (new) |
| `lib/util/validators/validation_messages.dart` | `validationMessage(l10n, error)`: error code → localized text | Shared |
| `lib/view/widget/text_field/app_text_form_field.dart` | `AppTextFormField` | Shared (new) |
| `lib/view/widget/text_field/app_text_field_style.dart` | `AppTextFieldStyle`: per-call appearance overrides and theme defaults | Shared (new, Task 08) |
| `lib/view/widget/buttons/app_button.dart` | `AppButton` | Shared (new) |
| `lib/view/widget/buttons/app_text_button.dart` | `AppTextButton` | Shared (new) |
| `lib/view/widget/buttons/app_icon_position.dart` | `AppIconPosition { start, end }` | Shared (new) |
| `lib/view/widget/pop_up_screen/app_popup.dart` | `AppPopup`, `AppPopupAction`, `showAppPopup` | Shared (new) |
| `lib/view/widget/toast/app_toast.dart` | `AppToast`, `AppToastType`, `showAppToast` | Shared (new) |
| `lib/view/widget/navigation/main_navigation_bar.dart` | `MainNavigationBar`: the visual five-destination bar | Shared (new, R8) |
| `lib/view/widget/navigation/main_nav_destination.dart` | `MainNavDestination`: destination order, icons and labels | Shared (new, R8) |
| `lib/view/widget/placeholder/under_construction_placeholder.dart` | `UnderConstructionPlaceholder` | Shared (new, R8) |
| `lib/view/widget/status/app_status_message.dart` | `AppStatusMessage`: empty, error, loading and unavailable states | Shared (new, R9) |
| `lib/view/screens/splash_screen/view/splash_screen.dart` | `SplashScreen`: composition only | Splash feature |
| `lib/view/screens/splash_screen/widget/splash_startup_status.dart` | `SplashStartupStatus` | Splash feature (new) |

---

## 3. Public API reference

**Approved migration targets (D-A63–D-A66):** all shared text styles must
use bundled **IBM Plex Sans Arabic** and default Ink `#242424` (including
Headline4); choose semantic `AppColor` tokens from the central reusable
palette. Relocate `AndroidLoading`/`IosLoading` to `view/widget/loading/`
after imports audit. In `MainNavigationBar`, use **Wallet** as destination 5,
Profile via AppBar/menu, and server-backed unread/current-order state. New
widgets use these approved targets; the signatures below are a **historical
2026-11-11 verified snapshot** until the source migration occurs.


### 3.1 `TextThemeStyle` (`lib/theme/text_themes.dart`)

`abstract final class TextThemeStyle` holds only `static const TextStyle`
fields. It can't be instantiated, so use it as `TextThemeStyle.bodyText1`.

At the old code snapshot, each style uses `fontFamily: AppFonts.tajawalReg`, `color: AppColor.black`
(`#000000`) and `height: 1.2`.

| Style | Size | Weight |
|---|---|---|
| `headline0` | 38 | w600 |
| `headline1` | 36 | w600 |
| `headline2` | 26 | w600 |
| `headline3` | 24 | w600 |
| `headline4` | 20 | w400 |
| `headline5` | 16 | w400 |
| `headline6` | 14 | w400 |
| `bodyText1` | 15 | w400 |
| `bodyText2` | 13 | w400 |
| `subtitle2` | 12 | w400 |
| `subtitle1` | 10 | w400 |
| `caption` | 9 | w300 |

`headline0` has no matching widget.

### 3.2 `AppTextWidget` and the text widgets (`lib/view/widget/text/`)

`abstract class AppTextWidget extends StatelessWidget` defines the parameters
shared by all eleven widgets. The constructors are unchanged from the old
project.

| Parameter | Type | Default / null meaning |
|---|---|---|
| `title` | `String` (required) | The text. Empty is allowed (renders nothing). |
| `style` | `TextStyle?` | **Merged** over the default (Task 23): only its non-null properties apply. |
| `color` | `Color?` | null keeps `style.color`, else Ink. |
| `fontSize` | `double?` | null keeps `style.fontSize`, else the widget's size. |
| `fontWeight` | `FontWeight?` | Only on `Headline4`, `Headline5`, `BodyText1`, `BodyText2`. null keeps `style.fontWeight`, else the widget's weight. |
| `textDecoration` | `TextDecoration?` | null keeps `style.decoration`, else none. |
| `maxLines` | `int?` | `1` (null also means 1: pass a number to wrap) |
| `overflow` | `TextOverflow?` | `TextOverflow.ellipsis` |
| `textAlign` | `TextAlign?` | `TextAlign.start` (right-aligned in RTL) |

**Style precedence, per property:**
1. the dedicated parameter (`color`, `fontSize`, `fontWeight`,
   `textDecoration`);
2. then `style`;
3. then the widget default: IBM Plex Sans Arabic, the size and weight below,
   Ink, and the `TextThemeStyle` line height 1.2.

So a partial style such as `TextStyle(fontSize: 22)` keeps the font, weight
and color. A style with `inherit: false` follows Flutter's `TextStyle.merge`
rule and replaces the default entirely; dedicated parameters still apply on
top. Before Task 23, any `style` replaced the default (dropping the font
weight, size and Ink color) and silently ignored the dedicated parameters.

Subclasses implement `TextStyle buildDefaultStyle()`. The four with
`fontWeight` also override `fontWeightOverride`. Current defaults, verified
by rendered tests with the real font:

| Widget | Base style | Size | Weight | Color | `fontWeight` param |
|---|---|---|---|---|---|
| `Headline1` | headline1 | 36 | bold | Ink | no |
| `Headline2` | headline2 | 26 | bold | Ink | no |
| `Headline3` | headline3 | 24 | bold | Ink | no |
| `Headline4` | headline4 | 20 | bold | Ink | yes |
| `Headline5` | headline5 | 16 | w400 (from the style) | Ink | yes |
| `Headline6` | headline6 | 14 | normal | Ink | no |
| `BodyText1` | bodyText1 | 15 | bold | Ink | yes |
| `BodyText2` | bodyText2 | 13 | bold | Ink | yes |
| `Subtitle1` | subtitle1 | 10 | bold | Ink | no |
| `Subtitle2` | subtitle2 | 12 | bold | Ink | no |
| `Caption` | caption | 9 | bold | Ink | no |

**Consumers:** none in `lib/` (tests only).

**Tests:** `test/text_widgets_test.dart` covers all eleven wrappers with the
real font:
- defaults and the precedence;
- RTL and LTR start alignment with mixed Arabic, Latin and digits;
- forwarding of `textAlign`, `maxLines` and `overflow`;
- semantics and empty text;
- 320, 375 and 450 px × text scale 1, 2 and 3.

`test/shared_widgets_test.dart` and `test/brand_theme_test.dart` cover them
too.

### 3.3 `AppTools` (`lib/util/tools/tools.dart`)

There's a global `final AppTools appTools = AppTools();`, and
`AppTools.loadingRouteName == 'loading'`.

| Method | Behavior |
|---|---|
| `void unFocusKeyboard(BuildContext context)` | Removes focus from the current field, which hides the keyboard. |
| `int createRandom()` | Random int (about 2,000,000–2,001,100,000). Not unique and not secure, so never use it for IDs or tokens. |
| `Future<void> showCustomBottomSheet(BuildContext context, Widget child, bool isDismissible)` | Modal bottom sheet: scrollable, not draggable, transparent background. |
| `void showLoading(BuildContext context)` | Blocking, non-dismissible loading dialog. See §7.3. |
| `void hideLoading(BuildContext context)` | **New.** Pops the loading dialog from the root navigator. Call it exactly once per `showLoading`. |
| `String timeFormatter(double time)` | Seconds → `mm:ss` (minutes wrap at 60). |
| `void showAlertDialogTwoFun(BuildContext context, {VoidCallback? yes, VoidCallback? no, String? title, String? content})` | **Delegates to `showAppPopup`** (not dismissible by tapping outside): Cancel (destructive text button) and Confirm (primary). An omitted callback just closes the popup; a callback you pass must close it itself. Defaults: localized «تنبيه» / «هل تريد المتابعة؟». |
| `void showAlertDialogOneFun(BuildContext context, {VoidCallback? onTap, String? title, String? content})` | **Delegates to `showAppPopup`** with a red warning icon and a single Confirm. Same callback rule and defaults. |
| `void showSuccessMessage(String message, BuildContext context)` | **Delegates to `showAppToast`** (success). |
| `void showWarningMessage(String message, BuildContext context)` | Warning toast via `showAppToast`. |
| `void showErrorMessage(String message, BuildContext context)` | Error toast via `showAppToast`. |
| `void showInfoMessage(String message, BuildContext context)` | **New.** Info toast via `showAppToast`. |

The method signatures are unchanged from before, so existing callers keep
working. The visuals changed from Cupertino dialogs and `toasty_box`
toasts to the shared components.

### 3.4 Loading widgets (historical `lib/util/tools/`; approved target `lib/view/widget/loading/`)

- `const AndroidLoading({Key? key})`: a `CircularProgressIndicator` in
  `AppColor.primary`, with the localized caption (`l10n.loading`,
  «جارٍ التحميل...») 10 px below it and
  20 px vertical padding. Meant to sit inside a `Dialog`.
- `const IosLoading({Key? key})`: a centered 100×100 box in
  `AppColor.black` at 80% opacity with 16 px corner radius, holding a
  `CupertinoActivityIndicator` (radius 17, color `AppColor.secondary300`).

### 3.5 Validators (`lib/util/validators/`)

```dart
enum ValidationError {
  required, usernameRequired, usernameLength, usernameFormat,
  passwordRequired, passwordLength, invalidPhone,
}

abstract final class Validators {
  static const int phoneDigits = 10;
  static const int usernameMinLength = 4, usernameMaxLength = 30;   // D-A65
  static const int passwordMinLength = 8, passwordMaxLength = 128;  // D-A65
  static ValidationError? required(String? value);
  static String normalizeLoginUsername(String raw);     // trim + phone digits
  static ValidationError? loginUsername(String? value); // checks the normalized value
  static ValidationError? loginPassword(String? value); // never trimmed
  static ValidationError? phone(String? value);         // required phone
  static ValidationError? optionalPhone(String? value); // blank allowed
  static bool isValidPhone(String raw);
  static String normalizePhone(String raw);
}

String validationMessage(AppLocalizations l10n, ValidationError error); // localized text
```

A validator returns `null` when the value is valid, otherwise an error code.

### 3.6 Splash widget

- `const SplashStartupStatus({Key? key})`: reads `SplashCubit` from the
  widget tree. Messages are localized; width follows
  `AppBreakpoints.formMaxWidth`.

### 3.7 `AppTextFormField` and `AppTextFieldStyle` (`lib/view/widget/text_field/`)

**Verified 2026-11-14 (Task 08, owner-approved contract).** A wrapper around
`TextFormField` that adds SHAHM defaults, logical slots and the password
visibility toggle. Behavior is set by named arguments; appearance only
through `style`. `app_text_form_field.dart` re-exports
`app_text_field_style.dart`, so one import gives both.

```dart
const AppTextFormField({
  Key? key,
  required String label,               // visible label + accessible name; not blank
  TextEditingController? controller,   // caller-owned; not with initialValue
  String? initialValue,
  FocusNode? focusNode,                // caller-owned
  String? hint,
  String? helperText,
  String? errorText,                   // e.g. from a feature Cubit
  FormFieldValidator<String>? validator,
  AutovalidateMode? autovalidateMode,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  Iterable<String>? autofillHints,
  List<TextInputFormatter>? inputFormatters,
  TextDirection? textDirection,        // typed text only; null inherits
  TextAlign textAlign = TextAlign.start,
  bool? autocorrect,                   // null → !obscureText
  bool? enableSuggestions,             // null → !obscureText
  bool obscureText = false,
  bool showVisibilityToggle = true,
  int? minLines,
  int? maxLines = 1,
  bool enabled = true,
  bool readOnly = false,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onFieldSubmitted,
  Widget? startIcon,                   // reading-start side (right in Arabic)
  Widget? endIcon,                     // reading-end side
  AppTextFieldStyle? style,
})
```

**`required` is intrinsic, not business.** `label` is required because a
field without a name is inaccessible. Whether the *value* must be filled is
decided by the feature's validator/Cubit (e.g. `Validators.loginUsername`).

**Invalid combinations (debug asserts):**

| Rule | Where |
|---|---|
| `label` not empty or whitespace-only | `build` (uses `trim`, not constant) |
| `controller` and `initialValue` not both | constructor |
| `obscureText` requires `maxLines: 1` and `minLines` null or 1 | constructor |
| `minLines <= maxLines` when both set | constructor |
| `obscureText && showVisibilityToggle` forbids `endIcon` (pass `showVisibilityToggle: false` to use it) | constructor |
| `obscureText` forbids `autocorrect: true` / `enableSuggestions: true` | constructor |

**Behavior:**
- **Slots:** `startIcon` → `prefixIcon`, `endIcon` → `suffixIcon` (both
  directional in Flutter). An interactive slot is the caller's own widget,
  e.g. `IconButton(tooltip: l10n.…, onPressed: …)`; the field adds no tap
  or semantics wrapper.
- **Visibility toggle:** in the end slot of an obscured field; localized
  `showPassword`/`hidePassword` tooltips; disabled when `enabled` is false,
  usable when `readOnly`; flips visibility only, never the value; resets to
  obscured when the parent changes `obscureText`.
- **Keyboard assistance:** `autocorrect` and `enableSuggestions` default on
  for plain fields and off for obscured ones; each can be turned off
  independently.
- **Direction:** `textDirection` affects the typed text only (Flutter passes
  it to `EditableText`); label, helper, error and slots follow the app's
  `Directionality` (RTL). Null inherits.
- **`enabled` vs `readOnly`:** disabled is not focusable and disables the
  toggle; read-only is focusable and selectable but not editable. Neither
  has its own fill color (no approved token).
- **Error priority:** after the parent `Form` validates, a `validator` error
  replaces `errorText` (Flutter `TextFormField` behavior). Use one source;
  Login uses `errorText` from `LoginCubit`.
- **Login call sites (Task 11, 2026-11-15):** both fields pass **no**
  `style`, so they share the `defaultsOf` borders, fill and text style in
  every state. Username only: `textDirection: TextDirection.ltr` (typed text
  only; label, error and the start icon stay RTL; default `textAlign.start`
  then places the text and caret on the left), `autocorrect: false`,
  `enableSuggestions: false`, no input formatters. Password unchanged
  (obscured, toggle, inherited RTL direction, assistance off by default).
  Tested in `login_screen_test.dart` (group "field consistency and username
  input").
- **No business rules,** no Cubit dependency, no normalization or logging
  of the value; the only state owned is password visibility.

**`AppTextFieldStyle`** (immutable, `const`): `textStyle`, `labelStyle`,
`floatingLabelStyle`, `hintStyle`, `helperStyle`, `errorStyle`,
`errorMaxLines`, `fillColor`, `cursorColor`, `borderRadius`,
`contentPadding`, and a color + width for each border state: `borderColor`/
`borderWidth` (resting), `focusedBorderColor`/`focusedBorderWidth`,
`errorBorderColor`/`errorBorderWidth`, `focusedErrorBorderColor`/
`focusedErrorBorderWidth`, `disabledBorderColor`/`disabledBorderWidth`.

**Precedence:** `AppTextFieldStyle.defaultsOf(Theme.of(context)).merge(style)`.
1. Non-null per-call `style` values.
2. `defaultsOf(theme)` (table below).
3. Text styles left null by both use Flutter's Material defaults.

`merge`: non-null values of the argument win; null (or a null argument)
never erases. Border states are **independent**: `borderWidth` changes only
the resting border. While an error shows, Flutter colors the cursor with
`errorStyle.color` (or the theme error color), not `cursorColor`.

| Default (`defaultsOf`) | Value | Source |
|---|---|---|
| Fill | `colorScheme.surface` (white) | `AppColor.surface` |
| Resting border | `AppColor.inputBorder` (`inkMuted`), 1 | Input-specific token (Task 10): 5.37:1 on white, 4.74:1 on cream |
| Focused border | `colorScheme.primary`, 1.5 | `AppColor.primary` |
| Error / focused-error border | `colorScheme.error`, 1 / 1.5 | **Material default** (`AppTheme` sets no error color) |
| Disabled border | `onSurface` alpha 97 (≈38%), 1 | **Material 3 filled-field fallback**, now explicit |
| Radius / padding / error lines | 12 / directional 16×14 / 3 | Unchanged |

The two **bold** sources are pre-existing fallbacks kept to preserve the
current look; they are open technical debt, not approved branding. The
resting border was moved from `sandLight` (≈1.25–1.42:1) to the existing
neutral `inkMuted` in Task 10 to meet WCAG 1.4.11.

**Not offered (removed in Task 08, no callers):** `width` (wrap in layout),
`obscuringCharacter`, `onTap`, `autofocus`, `maxLength` (it would count
grapheme clusters, not the D-A65 code points), `textCapitalization`,
`onStartIconTap`/`onEndIconTap`, `startIconSemanticLabel`/
`endIconSemanticLabel`, and top-level `style`/`cursorColor`/`fillColor`/
`borderRadius`/`borderWidth`/`contentPadding` (now in `AppTextFieldStyle`).
`showObscureToggle` was renamed `showVisibilityToggle`. Re-add an option only
with a real caller (see `CUSTOM_WIDGET_CONTRACT_STANDARD.md`).

### 3.8 `AppButton` (`lib/view/widget/buttons/`)

Verified against the source on 2026-11-15 (Task 18). **No public API
change**; behavior fixes and debug asserts only.

```dart
const AppButton({
  Key? key,
  String? label,                    // exactly one of label / child (asserts)
  Widget? child,
  required VoidCallback? onPressed,  // null → disabled
  Widget? icon,                      // decorative, beside the content
  AppIconPosition iconPosition = AppIconPosition.start,
  bool isLoading = false,
  bool expand = false,               // exclusive with width (assert)
  double? width,                     // > 0
  double height = 48,                // a minimum, >= 0
  EdgeInsetsGeometry? padding,       // null → 24 px start/end
  double borderRadius = 12,          // >= 0
  BorderSide? border,                // null → none
  Color? backgroundColor,            // null → colorScheme.primary
  Color? foregroundColor,            // null → textStyle.color → onPrimary
  TextStyle? textStyle,              // merged over the default
  String? loadingSemanticLabel,      // null → l10n.loading
});
```

| Element | Default | Override | Precedence / rule |
|---|---|---|---|
| Content | — | `label` (non-blank build assert) **or** `child` | Exactly one (const asserts). `child` must carry its own accessible name |
| Label/icon/spinner color (enabled, loading) | `colorScheme.onPrimary` | `foregroundColor`, or `textStyle.color` | `foregroundColor` > `textStyle.color` > onPrimary. An `Icon` with its own color keeps it |
| Background (enabled, loading) | `colorScheme.primary` | `backgroundColor` | Loading keeps the enabled colors |
| Disabled colors | Material: background `onSurface` alpha 31, content `onSurface` alpha 97 | none | Always the Material fallback (no approved disabled token), even with custom colors |
| Label text | bold 16, theme family (IBM Plex Sans Arabic) | `textStyle` | **Merged** (only set properties change; a style with `inherit: false` replaces it, Flutter `merge` rule) |
| Shape | radius 12, no border | `borderRadius`, `border` | Border follows the radius |
| Size | content width, 48 px minimum height, 24 px horizontal padding | `width`, `expand`, `height`, `padding` | `height` is a minimum; `expand` fills the parent's width |

- **Disabled:** `onPressed: null` (no tap, disabled semantics).
- **Loading:** a spinner (22 px) over the invisible content, so the size is
  identical at every text scale; taps and the semantics tap action are
  blocked even when `onPressed` is non-null; screen readers hear only
  `loadingSemanticLabel` / «جارٍ التحميل...» as a live region (the hidden
  label is excluded), so loading is distinguishable from disabled.
- **Long labels (Task 18 fix):** labels wrap, centered; they are never
  truncated (the old `TextOverflow.ellipsis` cut long labels to one line at
  320–450 px). The button grows taller instead.
- **Height (Task 10):** a minimum, not a fixed size (Login at text scale
  3.0 needed 72 px; `brand_theme_test.dart`).
- **Task 18 fixes, verified by tests that fail on the previous code:** a
  per-call `textStyle` no longer drops the bold weight; `textStyle.color`
  is no longer silently replaced by onPrimary; long labels are no longer
  truncated; asserts for blank labels, label + child, expand + width, and
  negative width/height/radius. No caller used any of these, so no screen's
  default appearance changed (only labels that were being truncated now
  wrap).
- **Open (owner decision, not implemented):** `child` has no current caller
  and an icon-only child has no accessible name unless the caller adds
  `Semantics`; options are to keep it as is (documented), add an optional
  semantic label, or remove `child` (breaking).
- **Callers:** Login submit (`login_form.dart`), debug preview
  (`debug_preview_button.dart`), primary `AppPopup` actions,
  `AppStatusMessage` action.
- **Tests:** `custom_widgets_test.dart` group `AppButton` (29, incl.
  "rendered contract": defaults, every override, precedence, asserts,
  disabled/loading semantics, RTL/LTR icon positions, 320/375/450 px ×
  text scale 1/2/3).

### 3.9 `AppTextButton`

Verified against the source on 2026-11-15 (Task 12, the first widget
migrated under `CUSTOM_WIDGET_CONTRACT_STANDARD.md`).

```dart
const AppTextButton({
  Key? key,
  required String label,               // non-blank (build assert)
  required VoidCallback? onPressed,    // null → disabled
  Widget? icon,                        // null → label only
  AppIconPosition iconPosition = AppIconPosition.start,
  Color? color,                        // null → textStyle.color → primary
  TextStyle? textStyle,                // merged over the default
  EdgeInsetsGeometry? padding,         // null → 12 px start/end
});
```

| Element | Default | Override | Precedence |
|---|---|---|---|
| Label/icon color (enabled) | `colorScheme.primary` | `color`, or `textStyle.color` | `color` > `textStyle.color` > primary |
| Label/icon color (disabled) | Material disabled (`onSurface` alpha 97) | none | Always the Material fallback (no approved disabled token) |
| Label text | semi-bold (w600), theme family (IBM Plex Sans Arabic); no size set, so Flutter's 14 px text default | `textStyle` | merged: only the properties it sets change |
| Icon | none; 18 px, label color | `icon`, `iconPosition` | logical start/end |
| Padding | `EdgeInsetsDirectional.symmetric(horizontal: 12)` | `padding` | the 48×48 minimum still applies |

- **Low emphasis:** no background, border or loading state (use
  `AppButton` for those).
- **`required` decisions:** `label` is the visible text and accessible
  name; `onPressed` is required but nullable so every caller decides the
  enabled state explicitly.
- **Task 12 fixes (non-breaking, no constructor change):** a color set
  only in `textStyle` used to be silently replaced by the primary color;
  a `textStyle` used to drop the default semi-bold weight; a blank label
  now asserts. No caller passed `textStyle`, so no screen changed.
- **Semantics:** one button node named by the label; disabled has no tap
  action. The icon is decorative.
- **Layout:** grows to wrap long labels at large text sizes (tested at
  320 px, text scale 2.0 and 3.0).
- **Callers:** Login forgot password (`login_form.dart`), Login contact
  administration (`login_screen.dart`), Login Terms & Conditions
  (`login_terms_action.dart`, Task 13), non-primary `AppPopup` actions
  (`color: colorScheme.error` when destructive), Current Order location
  Retry (`active_order_pickup_view.dart`).
- **Tests:** `test/custom_widgets_test.dart` group `AppTextButton` (14) and
  the `AppPopup` destructive-action test; callers in `login_screen_test.dart`
  and `current_order_test.dart`.

#### 3.9.1 Login Terms & Conditions action (Task 13, feature widget)

`LoginTermsAction({required LegalPageLauncher legalPageLauncher})` in
`lib/view/screens/authentication/widget/login_terms_action.dart`: an
`AppTextButton` labelled `l10n.termsAndConditions` («الشروط والأحكام»),
centered under the no-account action and above the debug preview. Always
enabled. A tap hides the keyboard, ignores repeated taps while opening, and
asks `LegalPageLauncher.openTermsAndConditions()`:

| Result | What the user sees |
|---|---|
| `opened` | The page in the in-app view; closing it returns to Login |
| `notConfigured` (**today**: no URL provided) | `AppPopup`: title «الشروط والأحكام», `termsUnavailableMessage`, Close |
| `invalidUrl`, `unsupported`, `failed` | `AppPopup`: `termsOpenFailedMessage`, Close. Nothing opens outside the app |

`LegalPageLauncher` (`lib/helper/legal/legal_page_launcher.dart`) reads the
single source of truth `LegalLinks.termsAndConditions`
(`lib/helper/legal/legal_links.dart`, **empty: not yet provided**). It
accepts only absolute `https` URLs with a host and no credentials, only on
Android and iOS, only after `supportsLaunchMode(LaunchMode.inAppWebView)`,
and requests only `LaunchMode.inAppWebView` with JavaScript and DOM storage
off. Every failure is returned as a result; no other mode is ever tried.
Not a consent control: Login has no checkbox or acceptance step.

### 3.10 `AppPopup` and `showAppPopup` (`lib/view/widget/pop_up_screen/`)

```dart
Future<T?> showAppPopup<T>(BuildContext context, {String? title,
  String? message, Widget? content, Widget? icon,
  List<AppPopupAction> actions = const [], bool showCloseButton = false,
  bool barrierDismissible = true});

AppPopupAction({required label, onPressed, isPrimary = false,
  isDestructive = false, closesPopup = true});
```

`AppPopup({title, message, content, icon, actions = const [],
showCloseButton = false, maxWidth = 480})` is the widget `showAppPopup`
builds. **No public API change in Task 17** (2026-11-15); only debug
asserts were added (below).

- **Structure:** icon, title (a semantic header), then a body. The body is
  either `message` (centered text) or `content`. Content-only popups are
  valid.
- **Actions:**
  - Primary actions render as `AppButton`; others as `AppTextButton`;
    `isDestructive` uses `colorScheme.error` (unchanged; no approved
    semantic error token yet).
  - An action closes the popup and then runs its callback, unless
    `closesPopup` is false. Actions close with a `null` result.
- **Asserts (debug, Task 17):** `message` xor `content`; at least one of
  `title`/`message`/`content`; an action with `closesPopup: false` needs
  `onPressed` (otherwise it does nothing); `showAppPopup` with
  `barrierDismissible: false` needs an action or `showCloseButton` (else the
  popup cannot be closed). No production caller violated any of them.
- **Layout (Task 17):**
  - Width is capped at `maxWidth` (480 px); the inset is 20 px horizontal,
    24 px vertical.
  - Height fits the usable screen. Flutter's `Dialog` already adds the
    keyboard (`MediaQuery.viewInsets`) to its inset and removes it for the
    child, and `showDialog` applies `SafeArea`; the popup adds no inset of
    its own (no double counting).
  - Icon, title and body scroll together; the actions stay **pinned** below
    them (Flutter `AlertDialog(scrollable: true)` pattern).
  - When even the actions do not fit with half the height left for the
    upper part (e.g. landscape with the keyboard open at text scale 2–3),
    the upper part keeps `min(natural, half)` and the actions scroll in the
    rest. Implemented by the private `_PopupLayout` in `app_popup.dart`.
  - When everything fits, the dialog hugs its content as before. Text is
    never shrunk or truncated; no fixed height.
- **Close button:** an optional localized close (X) at the top end (left in
  RTL), 48 px target.
- It's a modal dialog, never a route. The keyboard is **not** dismissed by
  the popup; callers may still dismiss it (the Terms action does).
- **Tests:** `custom_widgets_test.dart` groups `AppPopup` (incl. contract
  asserts) and "AppPopup layout with the keyboard open" (320 px at scale
  1/2/3, long title/message, scrolling content, landscape, long labels at
  320/1024 px, RTL/LTR close position, `AppTools` wrappers);
  `login_screen_test.dart` "popups with the keyboard open" (Forgot Password,
  Create Account).

### 3.11 `AppToast` and `showAppToast` (`lib/view/widget/toast/`)

```dart
enum AppToastType { success, error, warning, info }

void showAppToast(
  BuildContext context, {
  required String message,
  AppToastType type = AppToastType.info,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
  bool showCloseButton = true,
});

const AppToast({Key? key, required String message, required AppToastType type,
  IconData? icon, String? actionLabel, VoidCallback? onAction,
  VoidCallback? onClose});
static Color AppToast.backgroundFor(BuildContext context, AppToastType type);
```

Callers use `showAppToast` (directly, as Login does, or through the
`AppTools` `showSuccessMessage` / `showWarningMessage` / `showErrorMessage` /
`showInfoMessage` wrappers). `AppToast` is the content widget it builds.

**Contract (debug asserts, Task 19):**

| Rule | Why |
|---|---|
| `message` is required and not blank | A toast without text has nothing to show or announce. Displayed exactly as given (never trimmed). |
| `actionLabel` and `onAction` come as a pair: both or neither | A label without a callback is a dead button; a callback without a label is inaccessible. Both used to be dropped silently. Also asserted in the `AppToast` constructor. |
| `actionLabel` is not blank | It is the action's accessible name. |
| `duration > Duration.zero` | A zero or negative duration hides the toast before it can be read. |
| `context` is mounted | After an `await`, check `context.mounted` first. Without a `ScaffoldMessenger`, Flutter throws its own "No ScaffoldMessenger widget found" error. |

**Rendering:**

- **Mechanism:** a floating `SnackBar` (12 px radius, Flutter's default floating
  margins) through `ScaffoldMessenger`; no toast package.
- **Types:** each has its own icon (`check_circle_outline`, `error_outline`,
  `warning_amber_rounded`, `info_outline`), background color and localized
  status label («نجاح» / «خطأ» / «تحذير» / «معلومة»), so color is never the
  only signal. The icon, message and controls are white.
- **Colors:** existing tokens only (decision C-13): success `AppColor.secondary`,
  error the theme error color, warning `AppColor.sandDark`, info `AppColor.ink`.
  These are not the final semantic status colors (owner decision pending).
- **Order:** the icon sits at the start and the close button at the end; the
  action follows the message. Arabic RTL mirrors this (tested in both
  directions).
- **Action layout:** the action stays beside the message when both fit on one
  line. Otherwise it moves under the message, aligned to the end, so the
  message is never squeezed and nothing overflows. Labels wrap; they are never
  truncated.
- **Height:** the whole toast stays between the status bar and the keyboard.
  When its content is taller (very large text on a short screen), the message
  area scrolls and the close button stays on screen.
- **Targets:** the action is at least 48 px tall and wide, and the close button
  is 48 × 48 with the localized «إغلاق» tooltip.

**Semantics:** the toast is a live region announced once as `toastAnnouncement`
(`{status}: {message}`). The visible message and icon are excluded, so the text
is not read twice. The action button is labelled by `actionLabel`, and the
close button by its tooltip. With no action and `showCloseButton: false`, the
toast has no tap actions at all.

**Lifecycle:**

- **Replacement:** a new toast replaces the visible one and drops any queued
  one (`clearSnackBars`), so a quick burst shows only the latest message.
- **Action:** tapping it closes the toast and runs `onAction` **exactly once**.
  A double tap, a toast that is closing, or a toast that was replaced (while it
  is still animating out) never runs it. The close button is inert in the same
  way. This uses a file-private weak association per `ScaffoldMessenger`; there
  is no global toast service.
- **Timeout:** the toast hides after `duration`, **including when it has an
  action**. A screen reader does not extend it, because the action is not a
  `SnackBar.action`, so Flutter's `persist` stays false. A swipe also
  dismisses it.
- **Navigation:** the messenger belongs to `MaterialApp`, so a toast stays
  visible across route changes until it times out or is closed.
- **Popups:** a popup opened over a toast covers it with its modal barrier, so
  the toast's controls cannot be tapped until the popup closes; the timer keeps
  running.

**Limits:** at 320 px and text scale 3 with the keyboard open, a long message
and the wrapped action can be taller than the visible area. They scroll inside
the toast and stay reachable, but they are not visible all at once. Native
screen-reader announcement order (`SnackBar`'s own live region around the
toast's live region) is not verifiable in widget tests and needs a device
check.

**Tests:** in `test/custom_widgets_test.dart`, the "AppToast" group has 43
tests: 6 original and 37 in "rendered contract". Login's error toast is covered
in `test/login_screen_test.dart`.

### 3.12 `MainNavigationBar` and `MainNavDestination` (`lib/view/widget/navigation/`)

```dart
enum MainNavDestination { home, notifications, currentOrder, orderHistory, profile }
//   .icon  .selectedIcon  .label(l10n)

MainNavigationBar({required int selectedIndex,
  required ValueChanged<int> onDestinationSelected,
  int unreadCount = 0, bool hasActiveOrder = false,
  bool isCheckingActiveOrder = false});
```

| Member | Meaning |
|---|---|
| `selectedIndex` | Index into `MainNavDestination.values` of the open destination. The shell passes GoRouter's branch index |
| `onDestinationSelected(index)` | Called on every tap, including on the current destination |
| `unreadCount` | Shows the dot on Notifications when greater than zero. The number itself isn't displayed |
| `hasActiveOrder` | Changes the central button's background and adds a badge. Independent of selection. Pass true only when the server reported an active order |
| `isCheckingActiveOrder` | Shows a small spinner instead of the central icon; the button keeps its size |
| `barHeight` (64, the minimum), `centerButtonSize` (56), `centerButtonRise` (20), `maxContentWidth` (640), `maxTextScale` (2) | Layout constants |
| `itemKey(destination)`, `centerButtonKey`, `centerProgressKey`, `notificationDotKey`, `activeOrderBadgeKey`, `surfaceKey` | Keys for tests |

- **Presentation only.** No routes, no GoRouter, no Cubits, no fetching.
  Inject the indicator values; leave the defaults when there is no real
  data.
- **Enum order is the branch order** of the shell route. Change them
  together (`ROUTING_AND_STARTUP.md` §7).
- **Placement:** used by `AppNavBar` as the `Scaffold.bottomNavigationBar`.
  It sizes itself (bar + raised strip + bottom safe area) and grows when
  labels need two lines. Don't wrap it in a `SafeArea` or add bottom
  padding: it applies the inset itself.
- Visual rules, states and accessibility: `DESIGN_SYSTEM.md` §9–10.
- **Debug asserts (Task 22):**
  - `selectedIndex` must be within `0..MainNavDestination.values.length - 1`
    (it used to show nothing selected, silently);
  - `unreadCount` must not be negative.
  The shell always passes a valid `currentIndex` and no `unreadCount`, so the
  dot stays off until real data exists.
- **Taps:** every tap, including a repeated tap on the current destination,
  is reported. What it means belongs to the shell: `AppNavBar` calls
  `goBranch`, plus `CurrentOrderCubit.load()` for Current Order.
- **Fifth destination:** still **Profile** in code. The approved Wallet
  migration (D-A66) is not implemented.
- **Text scale cap (`maxTextScale = 2`):** the system text scale is clamped
  to 2 inside the bar only, so a fixed bottom bar can't take over the screen;
  scale 3 renders like scale 2. Screen-reader labels always carry the full
  destination name.
- **Known limitation, real font (owner decision):** at text scale 2 or more,
  some labels end in "…" even on two lines:
  - at 320 px: «الطلب الحالي», «سجل الطلبات» and «الملف الشخصي»;
  - at 375 px: «الملف الشخصي».

  All labels fit at text scale 1 on every tested width, and at 450 px up to
  the cap.

### 3.13 `UnderConstructionPlaceholder` (`lib/view/widget/placeholder/`)

```dart
const UnderConstructionPlaceholder({
  Key? key,
  required IconData icon,
  required String message,
});
```

- **What it shows:**
  - the shared ARB heading `underConstructionTitle` («قيد التطوير»);
  - the caller's localized sentence, shown exactly as given;
  - the caller's icon.

  All three go through `AppStatusMessage` (§3.14), with no action and no
  loading state. It is presentation only: no state, navigation or data.
- **Why both arguments are required:**
  - `message` is the screen-specific sentence, the only thing that tells the
    three screens apart;
  - `icon` identifies the feature (each caller passes its
    `MainNavDestination` icon).
- **Blank messages:** rejected in debug by `AppStatusMessage`'s blank-message
  assert (Task 20). There is no separate assert here.
- **Used by:** the bodies of the Notifications, Order History and Profile
  placeholder screens.
- **Verified (Task 21):**
  - each screen at 320×300 and text scale 3: no overflow, heading and message
    not truncated, one status announcement;
  - the shell tests cover every tab at all widths.
- **Known limitation, outside this widget:** at text scale 3 the screens'
  `AppBar` titles («سجل الطلبات», «الملف الشخصي») are cut off with an
  ellipsis, as Material app-bar titles are single-line.
- **Release:** these placeholders are temporary and still block store
  submission (see `docs/release/STORE_SUBMISSION_COMPLIANCE.md`).

### 3.14 `AppStatusMessage` (`lib/view/widget/status/`)

```dart
const AppStatusMessage({
  Key? key,
  required IconData icon,
  required String title,
  String? message,
  String? actionLabel,
  VoidCallback? onAction,
  bool isLoading = false,
});
```

A centered block for empty, error, loading and "not available" states.
**Callers:**
- Current Order: loading, empty with Refresh, not configured, and failure
  with Retry;
- the active-order map area: invalid pickup with Retry, and map unavailable;
- `UnderConstructionPlaceholder`, used by Notifications, Order History and
  Profile.

**Contract (debug asserts, Task 20):**

| Argument | Rule |
|---|---|
| `title` (required) | Not blank: it is what the status says and announces. Shown as given (never trimmed). |
| `icon` (required) | Decorative, 64 px, `AppColor.primary`, excluded from semantics. Replaced by the spinner while loading (it stays required; making it optional would be an API change, which is an owner decision). |
| `message` | null shows nothing and leaves no gap. An empty or blank string asserts: pass null. |
| `actionLabel` + `onAction` | Both or neither (asserted). Both used to be dropped silently. A blank label is rejected by `AppButton`. |
| `isLoading` (false) | Shows a 40 px spinner instead of the icon, with the same 16 px gap. A provided action stays interactive. |

**Rendering:**
- The title uses the theme `titleLarge` (IBM Plex Sans Arabic, bold,
  `textPrimary`); the message uses `bodyLarge` (`textSecondary`); both are
  centered.
- The action is an `AppButton`, at least 48 px tall. Its label wraps, and a
  Retry runs on every tap.
- The block centers within the area its parent gives (not the screen),
  scrolls when that area is short, is capped by `formMaxWidth` with the
  shared screen padding, and adds no `SafeArea`.
- Verified at 320, 375 and 450 px × text scale 1, 2 and 3, at full and 300 px
  height, with the keyboard open, and in RTL and LTR. Nothing overflows or is
  truncated, and the action stays reachable.

**Semantics:**
- One live-region node is labelled "title, newline, message", and is reused
  (and announced again) when the state changes.
- The icon and spinner are silent; the action is a separate, named button.
- Loading has no separate semantic flag: its meaning comes from the title
  wording.
- Native screen-reader output has not been verified on a device.

**Tests:** in `test/custom_widgets_test.dart`, the "AppStatusMessage" group
(36). Callers are covered by `current_order_test.dart` and
`main_navigation_test.dart`.

### 3.15 `AppAvailabilityToggle` (`lib/view/widget/toggle/`, Task 24)

```dart
const AppAvailabilityToggle({
  Key? key,
  required bool value,
  required ValueChanged<bool>? onChanged,
  required String label,
  String? supportingText,
  bool isBusy = false,
});
```

A **controlled** labelled switch row for an on/off command (first caller:
the Home availability card). Presentation only: no permissions, Cubits,
repositories, routing or remembered state.

| Argument | Rule |
|---|---|
| `value` (required) | What the owner says is true (for availability, the server-confirmed status). Never changed by the widget. |
| `onChanged` (required, nullable) | A tap sends `!value` as an **intent**; the switch moves only when the owner passes a new `value`. Null means disabled. |
| `label` (required) | The visible title and accessible name. Must not be blank (asserted). |
| `supportingText` | Status line under the label, also the switch's semantic value. null shows nothing; blank asserts. |
| `isBusy` (false) | Taps are ignored, a small spinner shows and the current value stays visible. Describe what is running in `supportingText`. |

- **Rendering:**
  - the label is `titleMedium`, bold, `textPrimary`; the status is
    `bodyMedium`, `textSecondary`; both use IBM Plex Sans Arabic and wrap;
  - the `Switch` uses the theme's colours (no per-call colours);
  - the whole row is the tap target, at least 56 px tall;
  - text sits at the start and the switch at the end (RTL and LTR).
- **Semantics:** one node with the toggled state, enabled state (false when
  null or busy), `label` and `supportingText` value, and a tap action only
  when enabled.
- **Tests:** `test/app_availability_toggle_test.dart` (18), including
  320/375/450 px × text scale 1, 2 and 3 with the real font.

---

## 4. Dependency map

```text
text_themes.dart ──► app_color.dart, fonts.dart
app_text_widget.dart ──► flutter/material
headlineN / bodyTextN / subtitleN / caption ──► app_text_widget, text_themes, app_color
android_loading.dart ──► app_color, l10n_extension, view/widget/padding/padding.dart
ios_loading.dart ──► flutter/cupertino, app_color
tools.dart ──► app_color, l10n_extension, android_loading, ios_loading,
               pop_up_screen/app_popup, toast/app_toast
app_popup.dart ──► buttons/app_button, buttons/app_text_button, text_themes, app_color, l10n
app_toast.dart / app_text_form_field.dart / app_button.dart ──► l10n_extension, theme
validators.dart ──► validation_error.dart
validation_messages.dart ──► validation_error.dart, generated AppLocalizations
splash_screen.dart ──► widget/splash_startup_status.dart ──► splash_cubit, l10n, app_breakpoints
```

**Packages:** the Flutter SDK, plus `responsive_framework` (through
`AppBreakpoints`). `toasty_box` is no longer imported (see D-P12; it hasn't
been removed from `pubspec.yaml`).

**GetX:**
- `get` is **not** in `pubspec.yaml` or `pubspec.lock`. The copied files
  imported it anyway, which is why they didn't compile.
- A full search of `lib/` and `test/` finds no remaining GetX code; it only
  appears in comments explaining the migration.
- Removed from this subsystem:
  - `package:get/get.dart` imports in `text_themes.dart` and `tools.dart`.
  - `Get.locale` (12 uses in `text_themes.dart`).
  - `Get.context` (2 uses, in `showLoading`).
  - `Get.back()` (4 uses, in the dialogs).
  - About 20 `.tr` translation lookups.
- There were no `GetxController`, `Obx`, `GetBuilder`, `Get.put` or
  `Get.find` uses.

**Other old-project references removed:**
- `package:hirfi_home/...` imports (all text widgets and `tools.dart`).
- `AppColors` (old class name; SHAHM's is `AppColor`).
- `AppColors.almostBlack`.
- `TranslationData`.
- `RegExption` / `util/exptions.dart`.
- `dart:io` `Platform`.

**Layering note (observation, not changed):** `util/tools/` imports
widgets from `view/widget/`. That's a `util → view` dependency. Revisit if
`util/` must stay free of view code.

---

## 5. Typography architecture

Moved to `DESIGN_SYSTEM.md` §3, which covers where the styles live, why they
are static (no Cubit), the font status and the relation to `AppTheme`. The
style scale itself is listed in §3.1 above.

---

## 6. Shared text widgets

**When to use them:** any plain, non-interactive text that fits one of the
sizes. Don't force them onto text with different semantics, such as
`TextField` content, `RichText` with mixed spans, or text that must wrap
without a line limit when you'd forget to pass `maxLines`.

**Watch out for:**
- The default `maxLines: 1` with ellipsis. Pass `maxLines` for paragraphs.
- Most widgets default to **bold**, even though the base style is w400.

```dart
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/widget/text/headline4.dart';
import 'package:mobile_frontend/view/widget/text/body_text2.dart';

const Headline4(title: 'الطلبات النشطة');
const BodyText2(
  title: 'تفاصيل الطلب',
  color: AppColor.inkMuted,
  fontWeight: FontWeight.w400,
  maxLines: 3,
);
```

A partial `style` changes only what it sets; dedicated parameters win:

```dart
// 15, bold, IBM Plex Sans Arabic (kept), underlined (style), primary
// (color beats style.color).
const BodyText1(
  title: 'الإجمالي',
  style: TextStyle(color: AppColor.inkMuted, decoration: TextDecoration.underline),
  color: AppColor.primary,
);
```

**Adding a new shared text widget:**
1. Create `lib/view/widget/text/<name>.dart`.
2. Extend `AppTextWidget` and forward the `super.` parameters.
3. Implement `buildDefaultStyle()` from a `TextThemeStyle` constant.
4. Add an English `///` comment.
5. Add it to this document.

Don't duplicate an existing size or weight combination.

---

## 7. Tools, validators, and loading components

### 7.1 What `tools.dart` provides now

It contains UI helpers only (§3.3).

**Changes from the old project:**
- Every helper that shows UI now takes a `BuildContext` instead of using
  `Get.context`.
- Dialogs close with `Navigator.of(dialogContext).pop()`.
- Text defaults come from the localization resources (`context.l10n`).
- Dialogs and toasts delegate to `AppPopup` and `AppToast` (2026-11-11).
- `hideLoading` was added.
- The three toast helpers previously **ignored `message`** and always showed
  "This is a warning toast!". They now show `message`.
- `withOpacity` was replaced with `withValues`.
- All validators moved out (§7.2).

### 7.2 Legacy validators: what happened to each

The old `tools.dart` had **16** validator functions; the task brief said 15.

| # | Legacy function | Outcome | Reason |
|---|---|---|---|
| 1 | `passwordValidate` | **Adapted** → `Validators.loginPassword` | Required only (2026-11-11 rationale: the old minimum of 8 wasn't confirmed then). *Since Task 03, D-A65 sets 8–128; see below.* |
| 2 | `passwordSetValidate` | Removed | Depended on the missing `RegExption.passwordPattern`. No SHAHM set-password form or policy yet. |
| 3 | `confirmPasswordValidate` | Removed | No SHAHM form with password confirmation. Pending. |
| 4 | `passwordChecker` | Removed | Helper for #3, using #5 and #6. |
| 5 | `samePass` | Removed | Pending a confirm-password requirement. |
| 6 | `passwordRole` | Removed | Old strength rules (8 characters, mixed case, digit and symbol) aren't confirmed for SHAHM. |
| 7 | `emailValidate` | Removed | SHAHM login uses a username; no SHAHM email field is specified. |
| 8 | `emailValidateHelp` | Removed | Same as #7. |
| 9 | `emailOrPhoneValidate` | Removed | Email-only check despite its name; same as #7. |
| 10 | `nameValidate` | Removed | No mobile name field is specified. Use `Validators.required` if one appears. |
| 11 | `phoneNumberValidate` | **Adapted** → `Validators.phone` | The old 7-character minimum is replaced by exactly 10 digits. |
| 12 | `phoneNumberValidate2` | **Merged** into `Validators.phone` | The old regex and 9-character minimum are replaced. |
| 13 | `phoneNumberValidateHelp` | **Merged** → `Validators.isValidPhone` | Boolean helper. |
| 14 | `expiryDateValidate` | Removed | No card or expiry field in SHAHM. |
| 15 | `requiredFieldValidate` | **Retained / adapted** → `Validators.required` | Generic. It now also treats whitespace-only values as empty. |
| 16 | `phoneOrEmailFieldValidate` | Removed | Duplicate of #15. |

**New:** `Validators.loginUsername` (required; extended with the D-A65 rules
in Task 03, see below), `Validators.optionalPhone`, and
`Validators.normalizePhone`. **Added in Task 03:**
`Validators.normalizeLoginUsername`.

**Validation API change:** the old validators took a
`TextEditingController`; the new ones take `String?`. This matches Flutter's
`FormFieldValidator` and Cubit state. No callers existed.

**Confirmed SHAHM rules applied:**
- **Phone (FU §1.3, as in the web prototype's `domain/phone.ts`):** exactly 10
  digits after normalization.
  - Normalization: Arabic-Indic digits (٠-٩, ۰-۹) become 0-9, and every
    other character (spaces, dashes, brackets, `+`) is dropped.
  - The leading zero is kept.
  - No country-code handling, so `+962…` (12 digits) is invalid.
  - Message: «رقم الهاتف يجب أن يتكوّن من 10 أرقام.»
- **Login (D-A65 and its owner-approved supplement; implemented in Task 03):**
  - **Username normalization** (`normalizeLoginUsername`): leading and
    trailing whitespace is trimmed; inner characters and case are never
    changed. If the trimmed value is exactly 10 characters and every one is
    a Latin, Arabic-Indic (٠-٩) or Extended Arabic-Indic (۰-۹) digit (any
    mix), each digit becomes Latin, keeping the leading zero. Nothing is
    ever dropped (unlike `normalizePhone`), so `+962…`, spaced or dashed
    numbers and ordinary usernames stay as typed.
  - **Username validation** (`loginUsername`) runs on that normalized value,
    first failure wins:
    1. Blank or whitespace-only → `usernameRequired` «أدخل اسم المستخدم».
    2. A character outside `[A-Za-z0-9_.]` → `usernameFormat`
       «اسم المستخدم يقبل الأحرف الإنجليزية والأرقام والشرطة السفلية (_) والنقطة فقط.».
       Checked before length, so a value that is both too long/short and
       malformed shows the character message.
    3. Fewer than 4 or more than 30 characters → `usernameLength`
       «اسم المستخدم يجب أن يكون بين 4 و30 حرفاً.».
  - **Password validation** (`loginPassword`): exactly empty →
    `passwordRequired` «أدخل كلمة المرور»; otherwise fewer than 8 or more
    than 128 characters (counted in Unicode code points) → `passwordLength`
    «كلمة المرور يجب أن تكون بين 8 و128 حرفاً.». Never trimmed;
    whitespace-only is a password, not an empty field. No composition rule.
  - **No weak-password check at sign-in:** that policy belongs to the
    backend when an Admin creates or resets a password (still to be
    specified).
  - No email check: `@` is simply a disallowed username character.
- Admin creates/resets accounts; no self-registration, no public password
  reset or profile onboarding. An incomplete captain profile is ineligible
  for offers until Admin completes it (backend, not implemented).
- Other future fields require an explicit feature contract.

### 7.3 Loading: platform behavior

`showLoading` decides by `Theme.of(context).platform`:

| Platform | Shows | Barrier |
|---|---|---|
| iOS, macOS | `Center(IosLoading())` | Transparent, not dismissible |
| Android, web, Windows, Linux, Fuchsia | `Dialog(white, child: AndroidLoading())` | Default dim, not dismissible |

**Changes from the old project:**
- It used `dart:io` `Platform`, which throws on web.
- It showed nothing on platforms other than Android and iOS. Non-Apple
  platforms now get the Android variant.

Both widgets use only Material or Cupertino widgets, so each renders on every
platform; the platform choice is purely visual.

**Limitations:**
- No timeout and no counting of nested calls. Every `showLoading` needs
  exactly one `hideLoading`.
- `hideLoading` pops the top route of the root navigator. If another dialog
  was opened above the loader, that dialog closes instead.
- Prefer showing loading from Cubit state where the screen allows, and keep
  this overlay for short blocking actions.

```dart
import 'package:mobile_frontend/util/tools/tools.dart';

appTools.showLoading(context);
try {
  await doSomething();
} finally {
  if (context.mounted) appTools.hideLoading(context);
}
```

### 7.4 How forms use validators

The form-state pattern (a feature Cubit calls `Validators.*`, emits field
errors and the submit status, and ignores overlapping submits) is described
in `../architecture/STATE_MANAGEMENT.md` §3. **`LoginCubit` is the first
implementation:** it calls `Validators.loginUsername` and
`Validators.loginPassword`, submits `Validators.normalizeLoginUsername` of
the typed username and the password exactly as typed, and `LoginForm` shows
`validationMessage(context.l10n, error)` inline.

**Validator audit (2026-11-11, brief R7 §7):** this was re-checked against
the brief. The retained validators and rules are unchanged (table §7.2), no
new rules were added, and no legacy dependency was restored.

**Rule:** never put validators back into `tools.dart`. New rules go in
`util/validators/`, each with a `ValidationError` code, a message key in
`app_ar.arb` mapped in `validation_messages.dart`, and unit tests. Add only
confirmed SHAHM rules; mark anything else as pending in
`../decisions/ARCHITECTURAL_DECISIONS.md`.

---

## 8. Splash extraction

**Extracted:** `_StartupStatus` (private, inside `splash_screen.dart`) became
`SplashStartupStatus` in
`lib/view/screens/splash_screen/widget/splash_startup_status.dart`.

- **Behavior and appearance are unchanged:**
  - A 28×28 spinner while startup runs.
  - For a recoverable error, the Arabic message plus a Retry `FilledButton`.
- **What remains in `splash_screen.dart`:** composition only. That's the
  `Scaffold` with the cream background, the logo (at 60% of screen width, up
  to 360 px), spacing, and `SplashStartupStatus`. The logo block stays inline
  because it's a few lines with no reuse.
- **No changes** to routing, startup, session, or connectivity logic.

The permanent widget-separation rule for every screen is in
`../architecture/ARCHITECTURE.md` §3.

---

## 9. Usage examples

```dart
import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/util/tools/tools.dart';
import 'package:mobile_frontend/util/validators/validation_messages.dart';
import 'package:mobile_frontend/util/validators/validators.dart';
import 'package:mobile_frontend/view/widget/text/headline3.dart';

// Text
const Headline3(title: 'مرحباً');
Text('…', style: TextThemeStyle.bodyText2.copyWith(height: 1.5));

// Validation result → message
final error = Validators.phone('079 123 4567'); // null (valid)
final text = error == null ? null : validationMessage(context.l10n, error);

// Store the normalized phone value
final phone = Validators.normalizePhone('٠٧٩١٢٣٤٥٦٧'); // '0791234567'

// Dialog and toast
appTools.showAlertDialogTwoFun(
  context,
  yes: () {
    Navigator.of(context).pop();
    // …
  },
);
appTools.showErrorMessage(context.l10n.serviceUnavailableMessage, context);
appTools.unFocusKeyboard(context);

// Shared components (imports from lib/view/widget/…)
AppTextFormField(
  label: context.l10n.usernameLabel,   // required, not blank
  errorText: usernameErrorText,        // from the feature Cubit
  textInputAction: TextInputAction.next,
  onChanged: cubit.usernameChanged,
);
AppTextFormField(                      // appearance via AppTextFieldStyle
  label: context.l10n.passwordLabel,
  obscureText: true,                   // built-in visibility toggle
  style: const AppTextFieldStyle(borderRadius: 8, borderWidth: 2),
);
AppButton(label: context.l10n.loginButton, expand: true,
    isLoading: state.isSubmitting, onPressed: cubit.submit);
showAppPopup<void>(context, title: '…', message: '…',
    actions: [AppPopupAction(label: context.l10n.close, isPrimary: true)]);
showAppToast(context, message: '…', type: AppToastType.success);
```

---

## 10. Maintenance rules

**Owner-approved supersession:** do not reproduce black/Tajawal as final
branding, old Profile as the fifth tab, or util/tools loading components
in newly migrated code. Convert the feature and remove the old implementation
once callers/tests have been audited. The older public API reference tables
record historical state only. Extend them with the **verified** new API after
implementation; never pretend the migration was already tested.


Project-wide rules (no GetX, English comments, ARB localization/`AppColor`, no
duplicates, package policy) are in `../../CLAUDE.md`. Specific to these
components:

- **Text widgets:**
  - Extend `AppTextWidget` and forward the `super.` parameters.
  - Keep constructor parameters stable, or update every caller and this
    document.
- **`tools.dart`:** UI helpers only. No validation or business rules.
- **Validators:** pure and synchronous, with unit tests, and confirmed
  SHAHM rules only.
- **Updates:** update this reference whenever a public API here changes.

---

## 11. Verification

Current results are in `../project/PROJECT_STATUS.md` §5.

**Historical (2026-11-11, at the end of the refactor):**
- `flutter analyze`: 120 issues before, 1 after (the existing `SplashBloc`
  info).
- `flutter test`: 70 passed.

Covering tests:
- `test/validators_test.dart`: every validator and boundary.
- `test/shared_widgets_test.dart`: text widget defaults and overrides,
  Android and iOS loading, dialogs, `timeFormatter`.

- `test/custom_widgets_test.dart`: `AppTextFormField` contract asserts,
  slots, toggle, keyboard flags, direction, error priority, every border
  state and style override, `AppTextFieldStyle.merge`, 320 px at text scale
  2.0 and 3.0 (Task 08), plus the button, popup and toast components.
- `test/main_navigation_bar_test.dart`: `MainNavigationBar` order, RTL and
  LTR, selected state, the central button, both indicators, semantics, safe
  area and widths (added with R8).

Not performed: platform builds and device runs.

---

## 12. Change summary (historical, 2026-11-11 refactor)

**Created:**
- `lib/view/widget/text/app_text_widget.dart`
- `lib/util/validators/validators.dart`
- `lib/util/validators/validation_error.dart`
- `lib/util/validators/validation_messages.dart`
- `lib/view/screens/splash_screen/widget/splash_startup_status.dart`
- `test/validators_test.dart`
- `test/shared_widgets_test.dart`
- `docs/ui/SHARED_UI_COMPONENTS_REFERENCE.md` (this file; moved from `docs/` during the documentation reorganization)

**Modified:**
- `lib/theme/text_themes.dart`
- All 11 files in `lib/view/widget/text/`
- `lib/util/tools/tools.dart`
- `lib/util/tools/android_loading.dart`
- `lib/util/tools/ios_loading.dart`
- `lib/view/screens/splash_screen/view/splash_screen.dart`
- `lib/util/app_strings.dart` (validation and dialog strings added)
- `lib/theme/app_color.dart`: whitespace only, from `dart format`

**Deleted or moved:** none. Validator logic moved from `tools.dart` into
`util/validators/` as described in §7.2.

**API changes:**

| Old | New |
|---|---|
| `TextThemeStyle().x` (instance) | `TextThemeStyle.x` (static const) |
| `appTools.showLoading()` | `appTools.showLoading(context)` |
| — | `appTools.hideLoading(context)` (new) |
| Validators taking a `TextEditingController` | Removed from `AppTools`; see §7.2 |

No callers existed outside these files; `tools.dart` was updated internally.

**Open decisions:**
- **Font files (historical question, now resolved):** IBM Plex Sans Arabic
  is approved; bundled assets and migration remain unimplemented. The old
  question asked where the Tajawal (and Inter?) files are and what
  `pubspec.yaml` family names should be used?
- **`Headline4` color (historical question, now resolved):** D-A63 approves
  Ink `#242424`, which `Headline4` already uses in the verified snapshot.
- **Text color (historical question, now resolved):** D-A63 approves Ink
  `#242424` as the default for all text styles. Source migration pending:
  the other styles and widgets still default to `AppColor.black` (§3.1–3.2).
- **Login rules (historical question, now resolved):** D-A65 and its
  owner-approved supplement define the username and password rules, the
  phone-digit normalization and the Arabic messages; implemented in Task 03
  (§7.2). The backend weak-password policy for Admin create/reset is still
  to be specified.
