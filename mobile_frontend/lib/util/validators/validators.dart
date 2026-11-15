// Shared, pure field validators for SHAHM forms.
//
// Rules here are only the ones SHAHM has confirmed: the phone format and the
// Login rules approved in D-A65 (plus the owner clarifications recorded with
// it). Every validator is synchronous and deterministic: no widgets,
// navigation, network or state. Form Cubits/Blocs call them; widgets never
// re-implement them. They are a convenience for the user, not a security
// boundary — the backend enforces the authoritative rules.

import 'package:mobile_frontend/util/validators/validation_error.dart';

/// Field validators. Each returns `null` when the value is valid, otherwise
/// the [ValidationError] describing the problem.
abstract final class Validators {
  /// SHAHM phone numbers have exactly this many digits (leading zero kept).
  static const int phoneDigits = 10;

  /// Login username length bounds, inclusive (D-A65).
  static const int usernameMinLength = 4;
  static const int usernameMaxLength = 30;

  /// Login password length bounds, inclusive (D-A65). Counted in Unicode
  /// code points, so a character outside the Basic Multilingual Plane
  /// counts once.
  static const int passwordMinLength = 8;
  static const int passwordMaxLength = 128;

  /// The only characters a Login username may contain (D-A65): ASCII
  /// letters, ASCII digits, underscore and dot.
  static final RegExp _usernameCharacters = RegExp(r'^[A-Za-z0-9_.]+$');

  /// A value that is not blank. Whitespace-only counts as empty.
  static ValidationError? required(String? value) =>
      (value == null || value.trim().isEmpty) ? ValidationError.required : null;

  /// The exact username to validate and send to sign-in.
  ///
  /// 1. Leading and trailing whitespace is removed; nothing inside is
  ///    touched and case is preserved (the backend matches
  ///    case-insensitively, the client never rewrites case).
  /// 2. If what remains is a phone-username candidate — exactly
  ///    [phoneDigits] characters, every one a Latin, Arabic-Indic (٠-٩) or
  ///    Extended Arabic-Indic (۰-۹) digit, in any mix — each digit becomes
  ///    its Latin equivalent, keeping the leading zero.
  ///
  /// Anything else is returned trimmed but otherwise unchanged. In
  /// particular, unlike [normalizePhone], no character is ever dropped: a
  /// value with `+`, spaces, dashes or letters is not a phone candidate, so
  /// `+962…` is not shortened into a local number and `captain.name` stays
  /// exactly as typed.
  static String normalizeLoginUsername(String raw) {
    final trimmed = raw.trim();
    final runes = trimmed.runes.toList();
    if (runes.length != phoneDigits) return trimmed;

    final buffer = StringBuffer();
    for (final rune in runes) {
      final latin = _latinDigit(rune);
      if (latin == null) return trimmed; // Not all digits: leave it alone.
      buffer.writeCharCode(latin);
    }
    return buffer.toString();
  }

  /// Login username (D-A65), checked on [normalizeLoginUsername]'s result so
  /// that what is validated is exactly what is submitted.
  ///
  /// Order, first failure wins:
  /// 1. Blank or whitespace-only → [ValidationError.usernameRequired].
  /// 2. Any character outside `[A-Za-z0-9_.]` →
  ///    [ValidationError.usernameFormat]. Checked before length because the
  ///    character rule is what the user must fix first, and because after
  ///    it passes every character is one ASCII unit, so the length check
  ///    below is unambiguous.
  /// 3. Fewer than [usernameMinLength] or more than [usernameMaxLength]
  ///    characters → [ValidationError.usernameLength].
  ///
  /// A 10-digit phone number (in any supported digit script) passes because
  /// it normalizes to 10 ASCII digits. It is a username, not an email: an
  /// `@` is simply a disallowed character.
  static ValidationError? loginUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationError.usernameRequired;
    }
    final username = normalizeLoginUsername(value);
    if (!_usernameCharacters.hasMatch(username)) {
      return ValidationError.usernameFormat;
    }
    if (username.length < usernameMinLength ||
        username.length > usernameMaxLength) {
      return ValidationError.usernameLength;
    }
    return null;
  }

  /// Login password (D-A65).
  ///
  /// - Exactly empty → [ValidationError.passwordRequired]. Spaces are valid
  ///   password characters, so a whitespace-only value is not "empty" and is
  ///   never trimmed.
  /// - Otherwise it must be [passwordMinLength]–[passwordMaxLength]
  ///   characters → else [ValidationError.passwordLength].
  ///
  /// No composition rule and no common/weak-password check: by owner
  /// decision that policy belongs to the backend when an Admin creates or
  /// resets a password, never to sign-in, so an existing password is not
  /// rejected here for being weak.
  static ValidationError? loginPassword(String? value) {
    if (value == null || value.isEmpty) return ValidationError.passwordRequired;
    final length = value.runes.length;
    if (length < passwordMinLength || length > passwordMaxLength) {
      return ValidationError.passwordLength;
    }
    return null;
  }

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
  ///
  /// For phone fields only. Login uses [normalizeLoginUsername], which never
  /// drops characters.
  static String normalizePhone(String raw) {
    final buffer = StringBuffer();
    for (final rune in raw.runes) {
      final latin = _latinDigit(rune);
      if (latin != null) buffer.writeCharCode(latin);
      // Any other character is dropped.
    }
    return buffer.toString();
  }

  /// The Latin digit code unit (`0`-`9`) for a Latin, Arabic-Indic (٠-٩) or
  /// Extended Arabic-Indic (۰-۹) digit [rune], or null for anything else.
  static int? _latinDigit(int rune) {
    if (rune >= 0x30 && rune <= 0x39) return rune; // 0-9
    if (rune >= 0x0660 && rune <= 0x0669) return rune - 0x0660 + 0x30; // ٠-٩
    if (rune >= 0x06F0 && rune <= 0x06F9) return rune - 0x06F0 + 0x30; // ۰-۹
    return null;
  }
}
