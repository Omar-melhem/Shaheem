// Shared form text field (wrapper around Flutter's TextFormField).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';

/// The app's standard text input.
///
/// - Adornments are logical: [startIcon] sits on the reading-start side
///   (right in Arabic), [endIcon] on the reading-end side.
/// - With [obscureText] and [showObscureToggle], an accessible show/hide
///   control occupies the end side (replacing [endIcon]). Toggling only
///   changes visibility; the typed value is never touched.
/// - [errorText] lets a feature Cubit show its own field errors. The widget
///   owns no business rules and doesn't know about any Cubit.
class AppTextFormField extends StatefulWidget {
  const AppTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.showObscureToggle = true,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.autofillHints,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.autovalidateMode,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.style,
    this.cursorColor,
    this.fillColor,
    this.borderRadius = 12,
    this.contentPadding,
    this.width,
    this.startIcon,
    this.endIcon,
    this.onStartIconTap,
    this.onEndIconTap,
    this.startIconSemanticLabel,
    this.endIconSemanticLabel,
  }) : assert(
         controller == null || initialValue == null,
         'Use either a controller or an initialValue, not both.',
       ),
       assert(
         !obscureText || maxLines == 1,
         'Obscured fields must be single-line.',
       );

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialValue;

  /// Field label (also its accessible name).
  final String? label;
  final String? hint;
  final String? helperText;

  /// Error supplied by the caller (e.g. a feature Cubit). Shown under the
  /// field; null hides it.
  final String? errorText;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// Hides the characters (passwords).
  final bool obscureText;
  final String obscuringCharacter;

  /// Shows a visibility toggle when [obscureText] is true.
  final bool showObscureToggle;

  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final Iterable<String>? autofillHints;

  /// Defaults to [TextAlign.start] so text follows the reading direction.
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final TextCapitalization textCapitalization;

  /// Optional local `Form` validator. Feature forms usually pass
  /// [errorText] from their Cubit instead.
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;

  final TextStyle? style;
  final Color? cursorColor;

  /// Background fill. Defaults to the theme surface (white).
  final Color? fillColor;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  /// Fixed width; by default the field takes the available width.
  final double? width;

  /// Adornment on the reading-start side (right in Arabic).
  final Widget? startIcon;

  /// Adornment on the reading-end side. Replaced by the visibility toggle
  /// for obscured fields.
  final Widget? endIcon;

  /// Makes [startIcon] / [endIcon] tappable.
  final VoidCallback? onStartIconTap;
  final VoidCallback? onEndIconTap;

  /// Screen-reader labels for tappable adornments.
  final String? startIconSemanticLabel;
  final String? endIconSemanticLabel;

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

  /// Wraps an adornment in a tappable, labelled button when it has a tap
  /// callback; otherwise returns it as decoration.
  Widget? _adornment(Widget? icon, VoidCallback? onTap, String? label) {
    if (icon == null) return null;
    if (onTap == null) return icon;
    return IconButton(
      onPressed: widget.enabled ? onTap : null,
      icon: icon,
      tooltip: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final radius = BorderRadius.circular(widget.borderRadius);

    final Widget? endAdornment = widget.obscureText && widget.showObscureToggle
        ? IconButton(
            // Only flips visibility; the controller/value is untouched.
            onPressed: () => setState(() => _obscured = !_obscured),
            icon: Icon(
              _obscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            tooltip: _obscured ? l10n.showPassword : l10n.hidePassword,
          )
        : _adornment(
            widget.endIcon,
            widget.onEndIconTap,
            widget.endIconSemanticLabel,
          );

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    final field = TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      initialValue: widget.initialValue,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: widget.obscureText && _obscured,
      obscuringCharacter: widget.obscuringCharacter,
      // Obscured values must not be suggested or corrected by the keyboard.
      enableSuggestions: !widget.obscureText,
      autocorrect: !widget.obscureText,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      autofillHints: widget.autofillHints,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      textCapitalization: widget.textCapitalization,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      onTap: widget.onTap,
      style: widget.style,
      cursorColor: widget.cursorColor,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
        errorMaxLines: 3,
        filled: true,
        fillColor: widget.fillColor ?? theme.colorScheme.surface,
        contentPadding:
            widget.contentPadding ??
            const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 14),
        // prefix/suffix are directional in Flutter: prefix = start side.
        prefixIcon: _adornment(
          widget.startIcon,
          widget.onStartIconTap,
          widget.startIconSemanticLabel,
        ),
        suffixIcon: endAdornment,
        border: border(theme.colorScheme.outline),
        enabledBorder: border(theme.colorScheme.outline),
        focusedBorder: border(theme.colorScheme.primary, 1.5),
        errorBorder: border(theme.colorScheme.error),
        focusedErrorBorder: border(theme.colorScheme.error, 1.5),
      ),
    );

    return widget.width == null
        ? field
        : SizedBox(width: widget.width, child: field);
  }
}
