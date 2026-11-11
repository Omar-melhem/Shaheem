// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'شهم';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get close => 'إغلاق';

  @override
  String get confirm => 'تأكيد';

  @override
  String get cancel => 'إلغاء';

  @override
  String get alert => 'تنبيه';

  @override
  String get proceedQuestion => 'هل تريد المتابعة؟';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get unexpectedError => 'حدث خطأ غير متوقع. يرجى إعادة المحاولة.';

  @override
  String get noInternetTitle => 'لا يوجد اتصال بالإنترنت';

  @override
  String get noInternetMessage =>
      'يحتاج التطبيق إلى اتصال بالإنترنت. تحقّق من اتصالك ثم أعد المحاولة.';

  @override
  String get offlineBanner => 'لا يوجد اتصال بالإنترنت';

  @override
  String get connectivityCheckFailedMessage =>
      'تعذّر التحقق من اتصالك بالإنترنت. يرجى إعادة المحاولة.';

  @override
  String get serviceUnavailableMessage =>
      'تعذّر الوصول إلى خدمة شهم حالياً. يرجى المحاولة بعد قليل.';

  @override
  String get profileFailureMessage =>
      'تعذّر تحميل بيانات حسابك. يرجى إعادة المحاولة.';

  @override
  String get accountBlockedMessage =>
      'لا يمكن الدخول إلى التطبيق بهذا الحساب حالياً. يرجى التواصل مع إدارة شهم.';

  @override
  String get startupFailureMessage =>
      'حدث خطأ أثناء تشغيل التطبيق. يرجى إعادة المحاولة.';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get usernameLabel => 'اسم المستخدم';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get loginInvalidCredentials =>
      'اسم المستخدم أو كلمة المرور غير صحيحة.';

  @override
  String get loginNoInternet =>
      'لا يوجد اتصال بالإنترنت. تحقّق من اتصالك ثم أعد المحاولة.';

  @override
  String get loginBackendNotConfigured =>
      'خدمة تسجيل الدخول غير متاحة بعد. يرجى المحاولة لاحقاً.';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get forgotPasswordTitle => 'استعادة كلمة المرور';

  @override
  String get forgotPasswordMessage =>
      'لتغيير كلمة المرور، يرجى التواصل مع الإدارة.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب';

  @override
  String get usernameRequired => 'أدخل اسم المستخدم';

  @override
  String get passwordRequired => 'أدخل كلمة المرور';

  @override
  String get invalidPhone => 'رقم الهاتف يجب أن يتكوّن من 10 أرقام.';

  @override
  String get toastSuccess => 'نجاح';

  @override
  String get toastError => 'خطأ';

  @override
  String get toastWarning => 'تحذير';

  @override
  String get toastInfo => 'معلومة';

  @override
  String toastAnnouncement(String status, String message) {
    return '$status: $message';
  }
}
