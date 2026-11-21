// Shared form text field (wrapper around Flutter's TextFormField).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/view/widget/text_field/app_text_field_style.dart';

export 'package:mobile_frontend/view/widget/text_field/app_text_field_style.dart';

/// The app's standard text input.
///
/// Contract (see SHARED_UI_COMPONENTS_REFERENCE §3.7):
/// - [label] is required and must not be blank: it is the visible label and
///   the field's accessible name. It does **not** mean the value is
///   required; that rule belongs to the feature's validator or Cubit.
/// - Behavior is configured by named arguments; appearance only through
///   [style], which overrides [AppTextFieldStyle.defaultsOf] per property.
/// - The caller owns [controller] and [focusNode]; the widget never creates,
///   normalizes or logs the value.
/// - Slots are logical: [startIcon] sits on the reading-start side (right in
///   Arabic), [endIcon] on the reading-end side. An interactive slot is the
///   caller's own widget (e.g. an `IconButton` with a localized tooltip).
/// - With [obscureText] and [showVisibilityToggle], the end slot holds the
///   built-in show/hide toggle, so [endIcon] must be null there.
/// - Error priority: a [validator] error, once the `Form` validates,
///   replaces [errorText] (Flutter `TextFormField` behavior). Use one source.
///
/// The only state it owns is the short-lived password visibility.
class AppTextFormField extends StatefulWidget {
  const AppTextFormField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.hint,
    this.helperText,
    this.errorText,
    this.validator,
    this.autovalidateMode,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.autocorrect,
    this.enableSuggestions,
    this.obscureText = false,
    this.showVisibilityToggle = true,
    this.minLines,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.onFieldSubmitted,
    this.startIcon,
    this.endIcon,
    this.style,
  }) : assert(
         controller == null || initialValue == null,
         'Use either a controller or an initialValue, not both.',
       ),
       assert(
         !obscureText || maxLines == 1,
         'Obscured fields must be single-line (maxLines: 1).',
       ),
       assert(
         !obscureText || minLines == null || minLines == 1,
         'Obscured fields must be single-line (minLines: null or 1).',
       ),
       assert(
         minLines == null || maxLines == null || minLines <= maxLines,
         'minLines must not exceed maxLines.',
       ),
       assert(
         !(obscureText && showVisibilityToggle && endIcon != null),
         'endIcon conflicts with the visibility toggle of an obscured field. '
         'Pass showVisibilityToggle: false to use endIcon instead.',
       ),
       assert(
         !obscureText || (autocorrect != true && enableSuggestions != true),
         'Obscured values must not be autocorrected or suggested.',
       );

  /// Visible label and accessible name. Localized (ARB) and not blank.
  final String label;

  /// Caller-owned controller. Mutually exclusive with [initialValue].
  final TextEditingController? controller;

  /// Starting value when no [controller] is used.
  final String? initialValue;

  /// Caller-owned focus node (e.g. to move focus between fields).
  final FocusNode? focusNode;

  /// Placeholder shown while the field is empty and focused.
  final String? hint;

  /// Supporting text under the field; hidden while an error shows.
  final String? helperText;

  /// Error supplied by the caller (e.g. a feature Cubit); null hides it.
  /// A [validator] error takes priority over it.
  final String? errorText;

  /// Optional local `Form` validator for forms without a Cubit.
  final FormFieldValidator<String>? validator;

  /// When [validator] runs automatically (Flutter default: disabled).
  final AutovalidateMode? autovalidateMode;

  /// Keyboard type, e.g. phone or visible password.
  final TextInputType? keyboardType;

  /// Keyboard action button, e.g. next or done.
  final TextInputAction? textInputAction;

  /// Platform autofill hints, e.g. username or password.
  final Iterable<String>? autofillHints;

  /// Input formatters (e.g. digits only). They change what the user can
  /// type; they never replace the feature's validation.
  final List<TextInputFormatter>? inputFormatters;

  /// Direction of the typed text only. The label, helper, error and icon
  /// slots keep following the app direction (RTL in Arabic). Null inherits.
  final TextDirection? textDirection;

  /// Alignment of the typed text; [TextAlign.start] follows the text
  /// direction.
  final TextAlign textAlign;

  /// Keyboard autocorrection. Null means on for plain fields and off for
  /// obscured ones; obscured fields cannot turn it on.
  final bool? autocorrect;

  /// Keyboard suggestions. Null means on for plain fields and off for
  /// obscured ones; obscured fields cannot turn them on.
  final bool? enableSuggestions;

  /// Hides the characters (passwords). Must be single-line.
  final bool obscureText;

  /// Shows the built-in show/hide toggle in the end slot of an obscured
  /// field. Ignored when [obscureText] is false.
  final bool showVisibilityToggle;

  /// Minimum visible lines; must not exceed [maxLines].
  final int? minLines;

  /// Maximum lines; null grows without limit. Defaults to one line.
  final int? maxLines;

  /// False disables input, focus and the visibility toggle.
  final bool enabled;

  /// True keeps the field focusable and selectable but not editable (and
  /// keeps the visibility toggle usable). Not the same as [enabled].
  final bool readOnly;

  /// Called on every edit with the current text.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard action button is pressed.
  final ValueChanged<String>? onFieldSubmitted;

  /// Widget on the reading-start side (right in Arabic).
  final Widget? startIcon;

  /// Widget on the reading-end side. Must be null when the visibility
  /// toggle is shown.
  final Widget? endIcon;

  /// Per-call appearance overrides; null properties inherit the defaults.
  final AppTextFieldStyle? style;

  @override
  State<AppTextFormField> createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends State<AppTextFormField> {
  /// Current visibility of an obscured field. Local UI state only.
  late bool _obscured = widget.obscureText;

  @override
  void didUpdateWidget(AppTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Not a const-constructor assert because String.trim isn't constant.
    assert(
      widget.label.trim().isNotEmpty,
      'AppTextFormField.label is the accessible name and must not be blank.',
    );

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final s = AppTextFieldStyle.defaultsOf(theme).merge(widget.style);
    final radius = BorderRadius.circular(s.borderRadius!);

    OutlineInputBorder border(Color? color, double? width) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color!, width: width!),
        );

    final hasToggle = widget.obscureText && widget.showVisibilityToggle;
    final Widget? endSlot = hasToggle
        ? IconButton(
            // Only flips visibility; the controller/value is untouched.
            onPressed: widget.enabled
                ? () => setState(() => _obscured = !_obscured)
                : null,
            icon: Icon(
              _obscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            tooltip: _obscured ? l10n.showPassword : l10n.hidePassword,
          )
        : widget.endIcon;

    return TextFormField(
      controller: widget.controller,
      initialValue: widget.initialValue,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      textDirection: widget.textDirection,
      textAlign: widget.textAlign,

      // Obscured values are never corrected or suggested by the keyboard.
      autocorrect: widget.autocorrect ?? !widget.obscureText,
      enableSuggestions: widget.enableSuggestions ?? !widget.obscureText,
      obscureText: widget.obscureText && _obscured,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      style: s.textStyle,
      cursorColor: s.cursorColor,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
        labelStyle: s.labelStyle,
        floatingLabelStyle: s.floatingLabelStyle,
        hintStyle: s.hintStyle,
        helperStyle: s.helperStyle,
        errorStyle: s.errorStyle,
        errorMaxLines: s.errorMaxLines,
        filled: true,
        fillColor: s.fillColor,
        contentPadding: s.contentPadding,
        // prefix/suffix are directional in Flutter: prefix = start side.
        prefixIcon: widget.startIcon,
        suffixIcon: endSlot,
        border: border(s.borderColor, s.borderWidth),
        enabledBorder: border(s.borderColor, s.borderWidth),
        focusedBorder: border(s.focusedBorderColor, s.focusedBorderWidth),
        errorBorder: border(s.errorBorderColor, s.errorBorderWidth),
        focusedErrorBorder: border(
          s.focusedErrorBorderColor,
          s.focusedErrorBorderWidth,
        ),
        disabledBorder: border(s.disabledBorderColor, s.disabledBorderWidth),
      ),
    );
  }
}
