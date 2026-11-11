// Error codes returned by the shared field validators.

/// Why a field value failed local validation.
///
/// Validators return these codes instead of text, so the rules stay
/// independent of wording. The UI turns a code into Arabic with
/// `validationMessage` (see `validation_messages.dart`).
enum ValidationError {
  /// A generic required field is empty.
  required,

  /// The Login username is empty.
  usernameRequired,

  /// The Login password is empty.
  passwordRequired,

  /// A phone number is not exactly 10 digits after normalization.
  invalidPhone,
}
