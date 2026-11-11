// Unit tests for the shared pure validators, including boundary cases of the
// SHAHM 10-digit phone rule and the Login required-field rules.

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

  group('loginUsername', () {
    test('blank → usernameRequired', () {
      expect(Validators.loginUsername(null), ValidationError.usernameRequired);
      expect(Validators.loginUsername(' '), ValidationError.usernameRequired);
    });
    test('is not an email field: plain usernames pass', () {
      expect(Validators.loginUsername('captain01'), isNull);
      expect(Validators.loginUsername('اسم'), isNull);
    });
  });

  group('loginPassword', () {
    test('empty → passwordRequired', () {
      expect(Validators.loginPassword(null), ValidationError.passwordRequired);
      expect(Validators.loginPassword(''), ValidationError.passwordRequired);
    });
    test('not trimmed and no length/strength rule', () {
      expect(Validators.loginPassword(' '), isNull);
      expect(Validators.loginPassword('a'), isNull);
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
  });
}
