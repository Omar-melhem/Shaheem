import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar')];

  /// App name; also the logo's semantic label and the window title.
  ///
  /// In ar, this message translates to:
  /// **'شهم'**
  String get appName;

  /// Generic retry action.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// Generic close action (popups, toasts).
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// Generic confirm action in dialogs.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// Generic cancel action in dialogs.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// Default title of generic alert dialogs.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه'**
  String get alert;

  /// Default content of generic confirm dialogs.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد المتابعة؟'**
  String get proceedQuestion;

  /// Loading caption and screen-reader label for loading states.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل...'**
  String get loading;

  /// Fallback for unexpected recoverable errors outside startup.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع. يرجى إعادة المحاولة.'**
  String get unexpectedError;

  /// Title of the No Internet startup screen.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get noInternetTitle;

  /// Explanation on the No Internet startup screen.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج التطبيق إلى اتصال بالإنترنت. تحقّق من اتصالك ثم أعد المحاولة.'**
  String get noInternetMessage;

  /// Global offline banner shown on any screen after startup.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get offlineBanner;

  /// Startup: the internet check itself failed (not confirmed offline).
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحقق من اتصالك بالإنترنت. يرجى إعادة المحاولة.'**
  String get connectivityCheckFailedMessage;

  /// Internet works but the SHAHM backend did not respond.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الوصول إلى خدمة شهم حالياً. يرجى المحاولة بعد قليل.'**
  String get serviceUnavailableMessage;

  /// Session is valid but the account profile failed to load.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل بيانات حسابك. يرجى إعادة المحاولة.'**
  String get profileFailureMessage;

  /// Account disabled, suspended or not allowed in this app.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن الدخول إلى التطبيق بهذا الحساب حالياً. يرجى التواصل مع إدارة شهم.'**
  String get accountBlockedMessage;

  /// Fallback for unexpected startup errors.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تشغيل التطبيق. يرجى إعادة المحاولة.'**
  String get startupFailureMessage;

  /// Home screen title.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get homeTitle;

  /// Login screen heading.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// Login username field label.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم'**
  String get usernameLabel;

  /// Login password field label.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// Login submit button.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginButton;

  /// Screen-reader label of the password visibility toggle (currently hidden).
  ///
  /// In ar, this message translates to:
  /// **'إظهار كلمة المرور'**
  String get showPassword;

  /// Screen-reader label of the password visibility toggle (currently shown).
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة المرور'**
  String get hidePassword;

  /// Server rejected the credentials. Generic on purpose: never reveal whether the account exists.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم أو كلمة المرور غير صحيحة.'**
  String get loginInvalidCredentials;

  /// Login failed because the device is offline.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت. تحقّق من اتصالك ثم أعد المحاولة.'**
  String get loginNoInternet;

  /// No authentication backend is connected yet (development placeholder).
  ///
  /// In ar, this message translates to:
  /// **'خدمة تسجيل الدخول غير متاحة بعد. يرجى المحاولة لاحقاً.'**
  String get loginBackendNotConfigured;

  /// Login text action that opens the password-reset information popup.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPassword;

  /// Title of the forgot-password popup.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get forgotPasswordTitle;

  /// Forgot-password popup body. No automated reset exists.
  ///
  /// In ar, this message translates to:
  /// **'لتغيير كلمة المرور، يرجى التواصل مع الإدارة.'**
  String get forgotPasswordMessage;

  /// Validation: a generic required field is empty.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get fieldRequired;

  /// Validation: Login username is empty.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسم المستخدم'**
  String get usernameRequired;

  /// Validation: Login password is empty.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور'**
  String get passwordRequired;

  /// Validation: phone number is not exactly 10 digits.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف يجب أن يتكوّن من 10 أرقام.'**
  String get invalidPhone;

  /// Screen-reader prefix for success toasts (status is not conveyed by color alone).
  ///
  /// In ar, this message translates to:
  /// **'نجاح'**
  String get toastSuccess;

  /// Screen-reader prefix for error toasts.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get toastError;

  /// Screen-reader prefix for warning toasts.
  ///
  /// In ar, this message translates to:
  /// **'تحذير'**
  String get toastWarning;

  /// Screen-reader prefix for info toasts.
  ///
  /// In ar, this message translates to:
  /// **'معلومة'**
  String get toastInfo;

  /// What screen readers announce for a toast: its status label, then the message. Kept as a pattern so other languages can reorder it.
  ///
  /// In ar, this message translates to:
  /// **'{status}: {message}'**
  String toastAnnouncement(String status, String message);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
