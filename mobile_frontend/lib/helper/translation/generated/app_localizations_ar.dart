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
  String get notificationsTitle => 'الإشعارات';

  @override
  String get currentOrderTitle => 'الطلب الحالي';

  @override
  String get orderHistoryTitle => 'سجل الطلبات';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get mainNavigationLabel => 'التنقل الرئيسي';

  @override
  String get navUnreadNotifications => 'توجد إشعارات غير مقروءة';

  @override
  String get navActiveOrder => 'لديك طلب فعال';

  @override
  String get navCheckingActiveOrder => 'جارٍ التحقق من طلبك الحالي';

  @override
  String get navCurrentOrderHint => 'عرض طلبك الفعال وموقع استلامه على الخريطة';

  @override
  String get underConstructionTitle => 'قيد التطوير';

  @override
  String get notificationsPlaceholderMessage =>
      'صفحة الإشعارات قيد التطوير وستتوفر قريباً.';

  @override
  String get orderHistoryPlaceholderMessage =>
      'صفحة سجل الطلبات قيد التطوير وستتوفر قريباً.';

  @override
  String get profilePlaceholderMessage =>
      'صفحة الملف الشخصي قيد التطوير وستتوفر قريباً.';

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
  String get refresh => 'تحديث';

  @override
  String get currentOrderLoading => 'جارٍ تحميل طلبك الحالي...';

  @override
  String get currentOrderEmptyTitle => 'لا يوجد لديك طلب فعال حالياً';

  @override
  String get currentOrderEmptyMessage =>
      'سيظهر طلبك الفعال هنا مع موقع استلامه من المطعم.';

  @override
  String get currentOrderNotConfiguredTitle =>
      'خدمة الطلبات غير مفعّلة في التطبيق بعد';

  @override
  String get currentOrderNotConfiguredMessage =>
      'لم يتم ربط التطبيق بخدمة الطلبات حتى الآن، لذلك لا يمكن التحقق من طلبك الحالي. هذا ليس عطلاً في اتصالك أو في الخدمة.';

  @override
  String get currentOrderLoadFailedTitle => 'تعذّر تحميل طلبك الحالي';

  @override
  String get currentOrderNoInternet =>
      'لا يوجد اتصال بالإنترنت. تحقّق من اتصالك ثم أعد المحاولة.';

  @override
  String get pickupPointLabel => 'نقطة الاستلام من المطعم';

  @override
  String get pickupInstructionsLabel => 'تعليمات الاستلام';

  @override
  String get pickupLocationInvalidTitle => 'موقع المطعم غير متوفر';

  @override
  String pickupLocationInvalidMessage(String restaurant) {
    return 'طلبك فعال، لكن بيانات موقع «$restaurant» ناقصة أو غير صحيحة، لذلك لا يمكن عرض الخريطة.';
  }

  @override
  String get mapUnavailableTitle => 'الخريطة غير متاحة حالياً';

  @override
  String get mapUnavailableMessage =>
      'لم يتم إعداد خدمة الخرائط في التطبيق بعد.';

  @override
  String get locationLocating => 'جارٍ تحديد موقعك...';

  @override
  String get locationPermissionDenied => 'لم يُسمح للتطبيق باستخدام الموقع.';

  @override
  String get locationPermissionRationale =>
      'نحتاج إلى موقعك لعرض مكانك على الخريطة وحساب المسار إلى المطعم.';

  @override
  String get locationUnavailable =>
      'تعذّر تحديد موقعك الحالي. تأكّد من تفعيل خدمة الموقع ثم أعد المحاولة.';

  @override
  String get locationNotConfigured => 'خدمة تحديد الموقع غير متاحة بعد.';

  @override
  String get noAccountPrompt => 'ليس لديك حساب؟';

  @override
  String get contactAdministration => 'تواصل مع الإدارة';

  @override
  String get createAccountTitle => 'إنشاء حساب';

  @override
  String get createAccountMessage =>
      'لإنشاء حساب في شهم، يرجى التواصل مع الإدارة.';

  @override
  String get termsAndConditions => 'الشروط والأحكام';

  @override
  String get termsUnavailableMessage => 'صفحة الشروط والأحكام غير متاحة بعد.';

  @override
  String get termsOpenFailedMessage =>
      'تعذّر فتح صفحة الشروط والأحكام داخل التطبيق. حاول مرة أخرى لاحقاً.';

  @override
  String get debugPreviewButton => 'معاينة التطبيق';

  @override
  String get debugPreviewNote => 'للتطوير فقط — لا يظهر في نسخة الإصدار';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب';

  @override
  String get usernameRequired => 'أدخل اسم المستخدم';

  @override
  String get usernameLengthInvalid =>
      'اسم المستخدم يجب أن يكون بين 4 و30 حرفاً.';

  @override
  String get usernameFormatInvalid =>
      'اسم المستخدم يقبل الأحرف الإنجليزية والأرقام والشرطة السفلية (_) والنقطة فقط.';

  @override
  String get passwordRequired => 'أدخل كلمة المرور';

  @override
  String get passwordLengthInvalid =>
      'كلمة المرور يجب أن تكون بين 8 و128 حرفاً.';

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

  @override
  String homeGreeting(String name) {
    return 'مرحباً، $name';
  }

  @override
  String get homeGreetingNoName => 'مرحباً بك';

  @override
  String get walletCurrencySymbol => 'د.أ';

  @override
  String get walletBalanceUnknownValue => '—';

  @override
  String walletBalanceSemantics(String amount) {
    return 'إجمالي رصيد المحفظة: $amount دينار أردني';
  }

  @override
  String get walletBalanceUnavailableSemantics =>
      'إجمالي رصيد المحفظة غير متوفر حالياً';

  @override
  String get availabilityCardTitle => 'استقبال الطلبات';

  @override
  String get availabilityToggleLabel => 'استقبال عروض الطلبات الجديدة';

  @override
  String get availabilityStatusAvailable =>
      'أنت متاح، وقد تصلك عروض طلبات جديدة.';

  @override
  String get availabilityStatusUnavailable =>
      'أنت غير متاح، ولن تصلك عروض طلبات جديدة.';

  @override
  String get availabilityStatusUnknown => 'حالة التوفر غير معروفة.';

  @override
  String get availabilityChecking => 'جارٍ التحقق من حالة التوفر...';

  @override
  String get availabilityNotConfigured =>
      'تفعيل استقبال الطلبات غير متاح بعد، لأن التطبيق لم يُربط بخادم شهم.';

  @override
  String get availabilityNoSession => 'سجّل الدخول لتتمكن من استقبال الطلبات.';

  @override
  String get availabilityNoInternet =>
      'لا يوجد اتصال بالإنترنت. تحقق من الاتصال ثم أعد المحاولة.';

  @override
  String get availabilityRejected =>
      'لم يؤكد الخادم تفعيل استقبال الطلبات. ما زلت غير متاح.';

  @override
  String get availabilityPermissionsNotConfigured =>
      'أذونات الموقع والإشعارات غير مهيأة في هذا الإصدار من التطبيق بعد.';

  @override
  String get availabilityMissingIntro => 'لن تصبح متاحاً قبل:';

  @override
  String get availabilityNeedLocationService => 'تشغيل خدمة الموقع في الجهاز';

  @override
  String get availabilityNeedPreciseLocation =>
      'السماح بالوصول إلى الموقع الدقيق';

  @override
  String get availabilityNeedBackgroundLocation =>
      'السماح بالوصول إلى الموقع طوال الوقت';

  @override
  String get availabilityNeedNotifications => 'السماح بالإشعارات';

  @override
  String get availabilityOpenSettings => 'فتح الإعدادات';

  @override
  String get availabilityRationaleTitle => 'أذونات مطلوبة';

  @override
  String get availabilityRationaleMessage =>
      'لاستقبال عروض الطلبات الجديدة يحتاج شهم إلى موقعك الدقيق، بما في ذلك أثناء عمل التطبيق في الخلفية، وإلى إذن الإشعارات. إن لم تسمح بها فلن تصبح متاحاً.';

  @override
  String get availabilityContinue => 'متابعة';

  @override
  String get availabilityUnconfirmedWasAvailable =>
      'تعذّر تأكيد التغيير مع الخادم. آخر حالة مؤكدة: متاح.';

  @override
  String get availabilityUnconfirmedWasUnavailable =>
      'تعذّر تأكيد التغيير مع الخادم. آخر حالة مؤكدة: غير متاح.';

  @override
  String get availabilityRequirementsLost =>
      'لم يعد أحد الأذونات المطلوبة مسموحاً. قد لا تصلك عروض جديدة حتى تسمح به مجدداً.';
}
