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

  /// The Login username (after outer trimming and phone-digit
  /// normalization) is shorter than 4 or longer than 30 characters.
  usernameLength,

  /// The Login username contains a character other than ASCII letters,
  /// digits, underscore or dot.
  usernameFormat,

  /// The Login password is empty.
  passwordRequired,

  /// The Login password is shorter than 8 or longer than 128 characters.
  passwordLength,

  /// A phone number is not exactly 10 digits after normalization.
  invalidPhone,
}
