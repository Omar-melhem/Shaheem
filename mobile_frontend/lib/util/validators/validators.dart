// Shared, pure field validators for SHAHM forms.
//
// Rules here are only the ones SHAHM has confirmed (phone format, Login
// required fields — matching the approved web prototype). Every validator is
// synchronous and deterministic: no widgets, navigation, network or state.
// Form Cubits/Blocs call them; widgets never re-implement them. They are a
// convenience for the user, not a security boundary — the backend enforces
// the authoritative rules.

import 'package:mobile_frontend/util/validators/validation_error.dart';

/// Field validators. Each returns `null` when the value is valid, otherwise
/// the [ValidationError] describing the problem.
abstract final class Validators {
  /// SHAHM phone numbers have exactly this many digits (leading zero kept).
  static const int phoneDigits = 10;

  /// A value that is not blank. Whitespace-only counts as empty.
  static ValidationError? required(String? value) =>
      (value == null || value.trim().isEmpty) ? ValidationError.required : null;

  /// Login username: required (whitespace-only counts as empty).
  ///
  /// It is a username, not an email, so no email format is checked. Its
  /// allowed characters and length limits are not specified yet.
  static ValidationError? loginUsername(String? value) =>
      (value == null || value.trim().isEmpty)
      ? ValidationError.usernameRequired
      : null;

  /// Login password: required. Not trimmed, because spaces can be part of a
  /// password. No length or strength rule: none is specified for SHAHM yet.
  static ValidationError? loginPassword(String? value) =>
      (value == null || value.isEmpty)
      ? ValidationError.passwordRequired
      : null;

  /// A required phone number: must be exactly [phoneDigits] digits after
  /// [normalizePhone]. Empty → [ValidationError.required].
  static ValidationError? phone(String? value) {
    if (value == null || value.trim().isEmpty) return ValidationError.required;
    return isValidPhone(value) ? null : ValidationError.invalidPhone;
  }

  /// An optional phone number: blank is valid; anything typed must be a
  /// valid phone number.
  static ValidationError? optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return isValidPhone(value) ? null : ValidationError.invalidPhone;
  }

  /// Whether [raw] is exactly [phoneDigits] digits after [normalizePhone].
  static bool isValidPhone(String raw) {
    final digits = normalizePhone(raw);
    return digits.length == phoneDigits;
  }

  /// SHAHM phone normalization (same rule as the web prototype, FU §1.3):
  /// Arabic-Indic digits (٠-٩ and ۰-۹) become Latin digits, and every other
  /// character (spaces, dashes, brackets, "+") is dropped. No country code is
  /// added or removed. Store and send the normalized value.
  static String normalizePhone(String raw) {
    final buffer = StringBuffer();
    for (final rune in raw.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        buffer.writeCharCode(rune); // 0-9
      } else if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(rune - 0x0660 + 0x30); // Arabic-Indic ٠-٩
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(rune - 0x06F0 + 0x30); // Extended ۰-۹
      }
      // Any other character is dropped.
    }
    return buffer.toString();
  }
}
