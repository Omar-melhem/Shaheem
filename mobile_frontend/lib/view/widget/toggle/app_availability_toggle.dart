// Shared controlled switch row for an on/off intent (e.g. captain availability).

import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';

/// A labelled switch row whose state belongs entirely to its owner.
///
/// Presentation only: it requests no permission, reads no Cubit, calls no
/// repository and remembers nothing. [value] is what the owner says is
/// true (for availability: the server-confirmed status). A tap calls
/// [onChanged] with the opposite value as an **intent**; the switch only
/// moves when the owner passes a new [value].
///
/// - [onChanged] null: disabled (announced as disabled, not tappable).
/// - [isBusy]: taps are ignored and a small spinner shows next to the
///   switch; describe what is running in [supportingText].
///
/// The whole row is the tap target (at least 48 logical pixels tall) and is
/// one screen-reader node: a switch with [label] as its name,
/// [supportingText] as its value and the toggled state.
class AppAvailabilityToggle extends StatelessWidget {
  /// Creates the row. [label] must not be blank (asserted).
  const AppAvailabilityToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.supportingText,
    this.isBusy = false,
  });

  /// Whether the switch shows "on". Supplied by the owner; never changed
  /// here.
  final bool value;

  /// Receives the requested new value. Null disables the row (required so
  /// every caller decides; the disabled state stays available).
  final ValueChanged<bool>? onChanged;

  /// Visible title and accessible name. Localized (ARB) and not blank.
  final String label;

  /// Optional status line under the label (e.g. "You are Available"), also
  /// read as the switch's value. Null shows nothing; blank asserts.
  final String? supportingText;

  /// Work for this control is running: taps are ignored and a spinner
  /// shows. Defaults to false.
  final bool isBusy;

  /// Smallest height of the row (the tap target).
  static const double minHeight = 56;

  @override
  Widget build(BuildContext context) {
    assert(
      label.trim().isNotEmpty,
      'AppAvailabilityToggle: label must not be blank; it is the switch\'s '
      'accessible name. Pass a localized label.',
    );
    assert(
      supportingText == null || supportingText!.trim().isNotEmpty,
      'AppAvailabilityToggle: supportingText must not be blank; pass null to '
      'show no status line.',
    );
    final theme = Theme.of(context);
    final enabled = onChanged != null && !isBusy;
    void toggle() => onChanged!(!value);

    return Semantics(
      container: true,
      toggled: value,
      enabled: enabled,
      label: label,
      value: supportingText,
      onTap: enabled ? toggle : null,
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? toggle : null,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColor.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (supportingText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          supportingText!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isBusy) ...[
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 8),
                ],
                // The row handles taps and semantics; the switch only shows
                // the owner's value (and the disabled look when not enabled).
                IgnorePointer(
                  child: Switch(
                    value: value,
                    onChanged: enabled ? onChanged : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
