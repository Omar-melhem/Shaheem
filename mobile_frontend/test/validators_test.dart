// Unit tests for the shared pure validators, including boundary cases of the
// SHAHM 10-digit phone rule and the D-A65 Login rules (username format,
// length, trimming and phone-digit normalization; password length and
// preservation).

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/util/validators/validation_error.dart';
import 'package:mobile_frontend/util/validators/validation_messages.dart';
import 'package:mobile_frontend/util/validators/validators.dart';

import 'test_app.dart';

void main() {
  group('required', () {
    test('null, empty and whitespace-only are missing', () {
      expect(Validators.required(null), ValidationError.required);
      expect(Validators.required(''), ValidationError.required);
      expect(Validators.required('   '), ValidationError.required);
    });
    test('any non-blank value passes', () {
      expect(Validators.required('a'), isNull);
    });
  });

  // D-A65 username rules plus the owner-approved phone-digit clarification.
  group('loginUsername', () {
    test('null, empty and whitespace-only → usernameRequired', () {
      expect(Validators.loginUsername(null), ValidationError.usernameRequired);
      expect(Validators.loginUsername(''), ValidationError.usernameRequired);
      expect(Validators.loginUsername('   '), ValidationError.usernameRequired);
    });

    test('length bounds: 3 invalid, 4 valid, 30 valid, 31 invalid', () {
      expect(Validators.loginUsername('abc'), ValidationError.usernameLength);
      expect(Validators.loginUsername('abcd'), isNull);
      expect(Validators.loginUsername('a' * 30), isNull);
      expect(
        Validators.loginUsername('a' * 31),
        ValidationError.usernameLength,
      );
    });

    test('allowed characters: letters, digits, underscore, dot, any case', () {
      expect(Validators.loginUsername('captain_1'), isNull);
      expect(Validators.loginUsername('captain.name'), isNull);
      expect(Validators.loginUsername('CaPtAiN01'), isNull);
      expect(Validators.loginUsername('12345'), isNull);
    });

    test('disallowed characters → usernameFormat', () {
      expect(Validators.loginUsername('كابتن'), ValidationError.usernameFormat);
      expect(
        Validators.loginUsername('captain@shahm.jo'),
        ValidationError.usernameFormat,
      );
      expect(
        Validators.loginUsername('captain one'),
        ValidationError.usernameFormat,
      );
      expect(
        Validators.loginUsername('captain-one'),
        ValidationError.usernameFormat,
      );
      // Non-ASCII letters are not a separate identity type.
      expect(Validators.loginUsername('café1'), ValidationError.usernameFormat);
    });

    test('format is checked before length (both wrong → usernameFormat)', () {
      expect(Validators.loginUsername('a@'), ValidationError.usernameFormat);
      expect(
        Validators.loginUsername('${'a' * 31}@'),
        ValidationError.usernameFormat,
      );
    });

    test('outer whitespace is ignored; length counts the trimmed value', () {
      expect(Validators.loginUsername('  captain01  '), isNull);
      expect(Validators.loginUsername(' abc '), ValidationError.usernameLength);
      expect(Validators.loginUsername('\tabcd\n'), isNull);
    });

    test('10-digit phone username in every supported digit script', () {
      expect(Validators.loginUsername('0791234567'), isNull);
      expect(Validators.loginUsername('٠٧٩١٢٣٤٥٦٧'), isNull);
      expect(Validators.loginUsername('۰۷۹۱۲۳۴۵۶۷'), isNull);
      expect(Validators.loginUsername('07٩١23۴٥6٧'), isNull);
    });

    test('phone non-goals: no country-code stripping or separators', () {
      expect(
        Validators.loginUsername('+962791234567'),
        ValidationError.usernameFormat,
      );
      expect(
        Validators.loginUsername('+٩٦٢٧٩١٢٣٤٥٦٧'),
        ValidationError.usernameFormat,
      );
      expect(
        Validators.loginUsername('079 123 4567'),
        ValidationError.usernameFormat,
      );
      expect(
        Validators.loginUsername('٠٧٩-١٢٣-٤٥٦٧'),
        ValidationError.usernameFormat,
      );
      // Arabic-Indic digits are only converted for a 10-digit phone.
      expect(Validators.loginUsername('٠١٢٣'), ValidationError.usernameFormat);
    });
  });

  group('normalizeLoginUsername', () {
    test('trims outer whitespace only; inside and case untouched', () {
      expect(
        Validators.normalizeLoginUsername('  Captain.Name  '),
        'Captain.Name',
      );
      expect(Validators.normalizeLoginUsername('a b'), 'a b');
    });

    test('converts a 10-digit phone to Latin digits, leading zero kept', () {
      expect(Validators.normalizeLoginUsername('٠٧٩١٢٣٤٥٦٧'), '0791234567');
      expect(Validators.normalizeLoginUsername('۰۷۹۱۲۳۴۵۶۷'), '0791234567');
      expect(Validators.normalizeLoginUsername('07٩١23۴٥6٧'), '0791234567');
      expect(Validators.normalizeLoginUsername(' ٠٧٩١٢٣٤٥٦٧ '), '0791234567');
      expect(Validators.normalizeLoginUsername('0791234567'), '0791234567');
    });

    test('never drops characters or rewrites ordinary usernames', () {
      expect(Validators.normalizeLoginUsername('captain.name'), 'captain.name');
      expect(Validators.normalizeLoginUsername('captain_1'), 'captain_1');
      expect(
        Validators.normalizeLoginUsername('+962791234567'),
        '+962791234567',
      );
      expect(Validators.normalizeLoginUsername('079 123 4567'), '079 123 4567');
      // 10 characters but not all digits: unchanged.
      expect(Validators.normalizeLoginUsername('٠٧٩١٢٣٤٥٦a'), '٠٧٩١٢٣٤٥٦a');
      // Digits but not 10 of them: unchanged.
      expect(Validators.normalizeLoginUsername('٠٧٩١٢٣٤٥٦'), '٠٧٩١٢٣٤٥٦');
    });
  });

  // D-A65 password rules; weak-password policy is backend-only (create/reset).
  group('loginPassword', () {
    test('null and exactly empty → passwordRequired', () {
      expect(Validators.loginPassword(null), ValidationError.passwordRequired);
      expect(Validators.loginPassword(''), ValidationError.passwordRequired);
    });

    test('length bounds: 7 invalid, 8 valid, 128 valid, 129 invalid', () {
      expect(Validators.loginPassword('a' * 7), ValidationError.passwordLength);
      expect(Validators.loginPassword('a' * 8), isNull);
      expect(Validators.loginPassword('a' * 128), isNull);
      expect(
        Validators.loginPassword('a' * 129),
        ValidationError.passwordLength,
      );
    });

    test('spaces are characters: never trimmed, whitespace-only not empty', () {
      expect(Validators.loginPassword(' '), ValidationError.passwordLength);
      expect(Validators.loginPassword(' ' * 8), isNull);
      expect(Validators.loginPassword('  abcd  '), isNull);
      // 7 visible characters plus a trailing space is 8: valid.
      expect(Validators.loginPassword('abcdefg '), isNull);
    });

    test('no composition or common-password rule at sign-in', () {
      expect(Validators.loginPassword('password'), isNull);
      expect(Validators.loginPassword('12345678'), isNull);
      expect(Validators.loginPassword('كلمةسرية'), isNull);
    });

    test('length counts code points (an emoji counts once)', () {
      expect(Validators.loginPassword('😀' * 8), isNull);
      expect(
        Validators.loginPassword('😀' * 7),
        ValidationError.passwordLength,
      );
    });
  });

  group('phone (required)', () {
    test('blank → required', () {
      expect(Validators.phone(null), ValidationError.required);
      expect(Validators.phone('  '), ValidationError.required);
    });
    test('exactly 10 digits passes, leading zero kept', () {
      expect(Validators.phone('0791234567'), isNull);
      expect(Validators.normalizePhone('0791234567'), '0791234567');
    });
    test('9 and 11 digits fail (boundaries)', () {
      expect(Validators.phone('079123456'), ValidationError.invalidPhone);
      expect(Validators.phone('07912345678'), ValidationError.invalidPhone);
    });
    test('old 7-digit minimum no longer accepted', () {
      expect(Validators.phone('1234567'), ValidationError.invalidPhone);
    });
    test('separators are dropped before counting', () {
      expect(Validators.phone('079 123-4567'), isNull);
      expect(Validators.phone('(079) 123 4567'), isNull);
    });
    test('Arabic-Indic and extended digits are normalized', () {
      expect(Validators.normalizePhone('٠٧٩١٢٣٤٥٦٧'), '0791234567');
      expect(Validators.normalizePhone('۰۷۹۱۲۳۴۵۶۷'), '0791234567');
      expect(Validators.phone('٠٧٩١٢٣٤٥٦٧'), isNull);
    });
    test('no country-code handling: +962 form is 12 digits → invalid', () {
      expect(Validators.phone('+962791234567'), ValidationError.invalidPhone);
    });
    test('letters only → invalid', () {
      expect(Validators.phone('abc'), ValidationError.invalidPhone);
    });
  });

  group('optionalPhone', () {
    test('blank is valid', () {
      expect(Validators.optionalPhone(null), isNull);
      expect(Validators.optionalPhone(' '), isNull);
    });
    test('typed value must still be 10 digits', () {
      expect(Validators.optionalPhone('079'), ValidationError.invalidPhone);
      expect(Validators.optionalPhone('0791234567'), isNull);
    });
  });

  test('every error code has an Arabic message', () {
    expect(
      validationMessage(l10n, ValidationError.required),
      l10n.fieldRequired,
    );
    expect(
      validationMessage(l10n, ValidationError.usernameRequired),
      l10n.usernameRequired,
    );
    expect(
      validationMessage(l10n, ValidationError.passwordRequired),
      l10n.passwordRequired,
    );
    expect(
      validationMessage(l10n, ValidationError.invalidPhone),
      l10n.invalidPhone,
    );
    expect(
      validationMessage(l10n, ValidationError.usernameLength),
      l10n.usernameLengthInvalid,
    );
    expect(
      validationMessage(l10n, ValidationError.usernameFormat),
      l10n.usernameFormatInvalid,
    );
    expect(
      validationMessage(l10n, ValidationError.passwordLength),
      l10n.passwordLengthInvalid,
    );
  });

  test('new Login messages use the exact owner-approved Arabic wording', () {
    expect(
      validationMessage(l10n, ValidationError.usernameLength),
      'اسم المستخدم يجب أن يكون بين 4 و30 حرفاً.',
    );
    expect(
      validationMessage(l10n, ValidationError.usernameFormat),
      'اسم المستخدم يقبل الأحرف الإنجليزية والأرقام والشرطة السفلية (_) والنقطة فقط.',
    );
    expect(
      validationMessage(l10n, ValidationError.passwordLength),
      'كلمة المرور يجب أن تكون بين 8 و128 حرفاً.',
    );
    // Existing required messages are unchanged.
    expect(l10n.usernameRequired, 'أدخل اسم المستخدم');
    expect(l10n.passwordRequired, 'أدخل كلمة المرور');
  });
}
