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
  String get routeNotFoundTitle => 'الصفحة غير موجودة';

  @override
  String get routeNotFoundMessage => 'الرابط الذي فتحته غير متاح في التطبيق.';

  @override
  String get routeErrorTitle => 'تعذّر فتح الصفحة';

  @override
  String get routeErrorMessage => 'حدث خطأ أثناء فتح هذه الصفحة.';

  @override
  String get routeErrorBackHome => 'العودة إلى الرئيسية';

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
  String get currentOrderTitle => 'الطلب الحالي';

  @override
  String get orderHistoryTitle => 'طلباتي';

  @override
  String get profileTitle => 'حسابي';

  @override
  String profileNameSemantics(String name) {
    return 'الاسم: $name';
  }

  @override
  String get profileNameUnavailable => 'الاسم غير متوفر';

  @override
  String profilePhoneSemantics(String phone) {
    return 'رقم الهاتف: $phone';
  }

  @override
  String get profilePhoneUnavailable => 'رقم الهاتف غير متوفر';

  @override
  String get profileRatingLoading => 'جارٍ تحميل التقييم...';

  @override
  String get profileRatingUnavailable => 'التقييم غير متوفر';

  @override
  String get profileRatingOffline =>
      'لا يوجد اتصال بالإنترنت. تعذّر تحميل التقييم.';

  @override
  String get profileRatingFailed => 'تعذّر تحميل التقييم.';

  @override
  String get profileRatingNone => 'لا توجد تقييمات بعد';

  @override
  String profileRatingValue(String value, String max) {
    return '$value / $max';
  }

  @override
  String profileRatingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تقييم',
      many: '$count تقييماً',
      few: '$count تقييمات',
      two: 'تقييمان',
      one: 'تقييم واحد',
      zero: 'لا توجد تقييمات',
    );
    return '$_temp0';
  }

  @override
  String get profileSignOut => 'تسجيل الخروج';

  @override
  String get profileSignOutConfirm => 'هل تريد تسجيل الخروج من حسابك؟';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsLanguageSection => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsAccountSection => 'الحساب';

  @override
  String get accountDeletionEntry => 'حذف الحساب';

  @override
  String get accountDeletionEntryHint =>
      'طلب حذف حسابك وبياناتك الشخصية المرتبطة به';

  @override
  String get accountDeletionSubmitting => 'جارٍ إرسال طلب الحذف...';

  @override
  String get accountDeletionConfirmTitle => 'حذف الحساب؟';

  @override
  String get accountDeletionConfirmMessage =>
      'سيُرسل طلب لحذف حسابك في شهم وبياناتك الشخصية المرتبطة به. قد يستغرق إكمال الحذف بعض الوقت، وقد يلزم الاحتفاظ ببعض السجلات وفق المتطلبات القانونية؛ ستُوضَّح التفاصيل عند تفعيل خدمة الحذف. لا يمكن التراجع عن الحذف بعد اكتماله.';

  @override
  String get accountDeletionConfirmAction => 'تأكيد الحذف';

  @override
  String get accountDeletionNotConfigured =>
      'خدمة حذف الحساب غير متصلة بالتطبيق بعد، لذلك لم يُرسل أي طلب ولم يُحذف حسابك.';

  @override
  String get accountDeletionNoInternet =>
      'لا يوجد اتصال بالإنترنت، ولم يُرسل الطلب. حاول مرة أخرى.';

  @override
  String get accountDeletionFailed =>
      'تعذّر إرسال طلب الحذف، ولم يُحذف حسابك. حاول مرة أخرى.';

  @override
  String get accountDeletionUnconfirmed =>
      'لم يصل ردّ من الخادم في الوقت المحدد، لذلك لا نعرف إن كان طلب الحذف قد استُلم. لا يُعدّ حسابك محذوفاً.';

  @override
  String get accountDeletionReauthRequired =>
      'لأمان حسابك، يجب تسجيل الدخول مجدداً قبل طلب الحذف.';

  @override
  String get accountDeletionSignInAgain => 'تسجيل الدخول مجدداً';

  @override
  String get accountDeletionPending =>
      'تم استلام طلب حذف حسابك وهو قيد المعالجة. لم يُحذف الحساب بعد.';

  @override
  String get aboutTitle => 'حول التطبيق';

  @override
  String get aboutDescription => 'تطبيق الكباتن في منصة شهم لتوصيل الطلبات.';

  @override
  String get aboutVersionLabel => 'الإصدار';

  @override
  String get aboutVersionUnavailable =>
      'رقم الإصدار غير متوفر في هذه النسخة من التطبيق.';

  @override
  String get mainNavigationLabel => 'التنقل الرئيسي';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get companyWordmark => 'نوصلها بشهامة، ونحفظها بأمانة';

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
  String get pickupConfirmAction => 'تم الاستلام';

  @override
  String get openInGoogleMaps => 'فتح في خرائط Google';

  @override
  String get googleMapsAppUnavailable =>
      'تطبيق خرائط Google غير متاح على هذا الجهاز، لذلك لم تُفتح الملاحة.';

  @override
  String get googleMapsLaunchFailed => 'تعذّر فتح خرائط Google. حاول مرة أخرى.';

  @override
  String get pickupNavigationUnavailable =>
      'لا يمكن فتح الملاحة لأن موقع المطعم غير متوفر.';

  @override
  String routeDistanceAndTime(String distance, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
    );
    return 'المسافة $distance كم · الوقت المتوقع $_temp0';
  }

  @override
  String get routeNotConfigured =>
      'لم يتم إعداد حساب المسار بعد، لذلك لا يظهر مسار أو وقت متوقع.';

  @override
  String get routeUnavailable => 'تعذّر حساب المسار حالياً.';

  @override
  String get routeNeedsCaptainLocation => 'يظهر المسار بعد تحديد موقعك.';

  @override
  String pickupMapSemantics(String restaurant) {
    return 'خريطة الاستلام من $restaurant';
  }

  @override
  String get captainMarkerTitle => 'موقعك';

  @override
  String get deliveryDestinationHeading => 'منطقة التسليم';

  @override
  String get deliveryAreaUnavailable => 'منطقة التسليم غير متوفرة';

  @override
  String get homeLogoSemantics => 'شعار شهم';

  @override
  String get orderDetailsHeading => 'تفاصيل الطلب';

  @override
  String get orderDetailCustomerName => 'اسم العميل';

  @override
  String get orderDetailCustomerPhone => 'رقم هاتف العميل';

  @override
  String get orderDetailDeliveryNotes => 'ملاحظات التوصيل';

  @override
  String get orderDetailFeeUnavailable => 'أجرة التوصيل غير متوفرة';

  @override
  String orderDetailSemantics(String label, String value) {
    return '$label: $value';
  }

  @override
  String get completedOrderTitle => 'تفاصيل الطلب المكتمل';

  @override
  String completedOrderIdLine(String orderId) {
    return 'رقم الطلب: $orderId';
  }

  @override
  String completedOrderMerchantLine(String merchant) {
    return 'المطعم: $merchant';
  }

  @override
  String completedOrderDeliveredAtLine(String time) {
    return 'وقت التسليم: $time';
  }

  @override
  String get completedOrderUnavailableTitle => 'تفاصيل هذا الطلب غير متاحة';

  @override
  String get completedOrderUnavailableMessage =>
      'افتح «طلباتي» لتحديث السجل ثم اختر الطلب مرة أخرى.';

  @override
  String get completedOrderBack => 'العودة إلى طلباتي';

  @override
  String get completedDeliveryOpenHint => 'عرض تفاصيل الطلب';

  @override
  String pickedUpFromLine(String merchant) {
    return 'تم الاستلام من $merchant';
  }

  @override
  String get deliveryStatusPickedUp =>
      'تم استلام الطلب. اضغط «بدء التوصيل» عند انطلاقك.';

  @override
  String get deliveryStatusOnTheWay => 'أنت في الطريق إلى منطقة التسليم.';

  @override
  String get startDeliveryAction => 'بدء التوصيل';

  @override
  String get completeDeliveryAction => 'تم تسليم الطلب';

  @override
  String get completeDeliveryConfirmTitle => 'تأكيد تسليم الطلب؟';

  @override
  String get completeDeliveryConfirmMessage =>
      'أكّد فقط بعد تسليم الطلب. سيُسجَّل التسليم وتُخصم عمولة الطلب من محفظتك مرة واحدة.';

  @override
  String get completeDeliveryConfirmAction => 'تأكيد التسليم';

  @override
  String get orderCommandNotConfigured =>
      'خدمة الطلبات غير متصلة بالتطبيق بعد، لذلك لم يُرسل الإجراء ولم تتغيّر حالة الطلب.';

  @override
  String get orderCommandNoInternet =>
      'لا يوجد اتصال بالإنترنت، ولم يُرسل الإجراء. حاول مرة أخرى.';

  @override
  String get orderCommandUnconfirmed =>
      'لم يصل ردّ من الخادم في الوقت المحدد، لذلك لا نعرف إن تم تنفيذ الإجراء. تحقّق من حالة الطلب قبل المحاولة مجدداً.';

  @override
  String get orderCommandStateConflict =>
      'تغيّرت حالة الطلب على الخادم، لذلك لم يُنفَّذ الإجراء. جارٍ تحديث بياناته.';

  @override
  String get orderCommandCheckStatus => 'تحقّق من حالة الطلب';

  @override
  String get orderCommandCheckFailed =>
      'تعذّر التحقق من حالة الطلب الآن. حاول مرة أخرى.';

  @override
  String get orderCommandCheckPending =>
      'لم يحسم الخادم نتيجة الإجراء بعد. تحقّق مرة أخرى بعد قليل.';

  @override
  String get orderStatusUnsupportedTitle =>
      'حالة الطلب غير مدعومة في هذا الإصدار';

  @override
  String get orderStatusUnsupportedMessage =>
      'حدّث الصفحة، وإن استمرت المشكلة تواصل مع الإدارة.';

  @override
  String get deliveryCompletedTitle => 'تم تسليم الطلب';

  @override
  String get deliveryCompletedMessage => 'يتم الآن تحديث طلباتك ومحفظتك.';

  @override
  String get orderCancelledTitle => 'تم إلغاء الطلب';

  @override
  String get orderReassignedTitle => 'أُسند الطلب إلى كابتن آخر';

  @override
  String get orderEndedMessage => 'لم يعد هذا الطلب ضمن مهامك.';

  @override
  String get currentOrderBackHome => 'العودة إلى الرئيسية';

  @override
  String get completedDeliveriesHeading => 'الطلبات المكتملة';

  @override
  String get completedDeliveriesLoading => 'جارٍ تحميل الطلبات المكتملة…';

  @override
  String get completedDeliveriesEmpty => 'لا توجد طلبات مكتملة بعد.';

  @override
  String get completedDeliveriesNotConfigured =>
      'خدمة سجل الطلبات غير متصلة بعد، لذلك لا يمكن عرض الطلبات المكتملة.';

  @override
  String get completedDeliveriesNoSession =>
      'سجّل الدخول لعرض طلباتك المكتملة.';

  @override
  String get completedDeliveriesNoInternet =>
      'لا يوجد اتصال بالإنترنت. تعذّر تحميل الطلبات المكتملة.';

  @override
  String get completedDeliveriesLoadFailed =>
      'تعذّر تحميل الطلبات المكتملة الآن.';

  @override
  String get completedDeliveriesLoadMore => 'عرض المزيد';

  @override
  String get completedDeliveryOutcome => 'تم التسليم';

  @override
  String completedDeliveryFeeLine(String amount, String currency) {
    return 'أجرة التوصيل: $amount $currency';
  }

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
  String homeActiveOrderMessage(String merchant) {
    return 'لديك طلب قيد التنفيذ من $merchant.';
  }

  @override
  String get homeActiveOrderOpen => 'عرض الطلب الحالي';

  @override
  String get homeActiveOrderCheckFailed =>
      'تعذّر التحقق من طلبك الحالي. هذا لا يعني عدم وجود طلب.';

  @override
  String get walletCurrencySymbol => 'د.أ';

  @override
  String get walletBalanceUnknownValue => '—';

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

  @override
  String get offersSectionTitle => 'طلبات بانتظار القبول';

  @override
  String offersSectionTitleWithCount(int count) {
    return 'طلبات بانتظار القبول ($count)';
  }

  @override
  String get offersSectionSubtitle =>
      'عروض ما زالت متاحة لك ولم يقبلها كابتن آخر بعد.';

  @override
  String get offersLoading => 'جارٍ تحميل العروض...';

  @override
  String get offersNotConfigured =>
      'خدمة الطلبات غير متصلة بعد، لذلك لا يمكن عرض العروض المتاحة.';

  @override
  String get offersNoSession => 'سجّل الدخول لعرض العروض المتاحة لك.';

  @override
  String get offersEmpty => 'لا توجد عروض متاحة لك الآن.';

  @override
  String get offersNoInternet =>
      'لا يوجد اتصال بالإنترنت. تحقق من الاتصال ثم حدّث القائمة.';

  @override
  String get offersLoadFailed => 'تعذّر تحميل العروض. حاول التحديث بعد قليل.';

  @override
  String get offersAcceptedMessage => 'تم قبول الطلب. تابعه من «الطلب الحالي».';

  @override
  String get offersDeclinedMessage => 'تم رفض العرض.';

  @override
  String get offerAccept => 'قبول';

  @override
  String offerPickupLine(String pickup) {
    return 'موقع المطعم: $pickup';
  }

  @override
  String get offerPickupUnknown => 'غير متوفر';

  @override
  String offerDeliveryAreaLine(String area) {
    return 'منطقة التسليم: $area';
  }

  @override
  String get offerDeliveryFeeLabel => 'أجرة التوصيل';

  @override
  String offerCardSemantics(
    String merchant,
    String pickup,
    String area,
    String fee,
  ) {
    return 'عرض طلب من $merchant. موقع المطعم: $pickup. منطقة التسليم: $area. قيمة التوصيل: $fee دينار أردني.';
  }

  @override
  String get offerNoLongerAvailable =>
      'لم يعد هذا العرض متاحاً لك. حدّث القائمة.';

  @override
  String get offerRefused => 'لم يوافق الخادم على هذه العملية حالياً.';

  @override
  String get offerNotConfigured =>
      'خدمة الطلبات غير متصلة بعد، لم يُرسل أي طلب.';

  @override
  String get offerUnconfirmed =>
      'تعذّر تأكيد العملية. حدّث القائمة للتحقق من حالة العرض.';

  @override
  String get previewCaption => 'معاينة تصميم — بيانات افتراضية';

  @override
  String get walletTitle => 'المحفظة';

  @override
  String get walletTotalBalance => 'الرصيد';

  @override
  String get walletValueUnknownSemantics => 'غير معروف';

  @override
  String get walletDebitHistory => 'سجل الخصم';

  @override
  String get walletHistoryWindowNote =>
      'يعرض السجل عمليات خصم العمولة خلال آخر 7 أيام.';

  @override
  String get walletDeliveredCount => 'الطلبات المسلّمة';

  @override
  String get walletEarnings => 'الأرباح';

  @override
  String get walletMetricsLifetimeNote => 'منذ بدء العمل';

  @override
  String get walletEarningsUnavailable => 'غير متوفر حالياً';

  @override
  String get walletMetricsNotConfigured => 'خدمة الإحصائيات غير متصلة بعد.';

  @override
  String get walletMetricsLoadFailed => 'تعذّر تحميل الإحصائيات.';

  @override
  String walletDebitMerchantLine(String merchant) {
    return 'المطعم: $merchant';
  }

  @override
  String walletDebitDateLine(String date) {
    return 'تاريخ الخصم: $date';
  }

  @override
  String walletDebitAmountLine(String amount, String currency) {
    return 'قيمة الخصم (العمولة): $amount $currency';
  }

  @override
  String get walletFieldUnavailable => 'غير متوفر';

  @override
  String get walletDebitsEmpty => 'لا توجد عمليات خصم خلال آخر 7 أيام.';

  @override
  String get walletLoading => 'جارٍ تحميل المحفظة…';

  @override
  String get walletNotConfigured =>
      'خدمة المحفظة غير متصلة بعد، لذلك لا يمكن عرض الرصيد أو السجل حالياً.';

  @override
  String get walletNoSession => 'سجّل الدخول لعرض محفظتك.';

  @override
  String get walletNoInternet =>
      'لا يوجد اتصال بالإنترنت. تعذّر تحميل المحفظة.';

  @override
  String get walletLoadFailed => 'تعذّر تحميل المحفظة. حاول مرة أخرى.';

  @override
  String walletDebitSemantics(
    String amount,
    String merchant,
    String area,
    String date,
  ) {
    return 'خصم عمولة بقيمة $amount دينار أردني، المطعم: $merchant، منطقة التسليم: $area، بتاريخ $date';
  }

  @override
  String get newOfferSheetTitle => 'عرض طلب جديد';

  @override
  String get offerKindInstant => 'حالي';

  @override
  String get offerKindScheduled => 'مؤجل';

  @override
  String offerScheduledPickupLine(String time) {
    return 'موعد الاستلام: $time';
  }

  @override
  String walletBalanceCardSemantics(String value) {
    return 'الرصيد: $value';
  }

  @override
  String walletMetricSemantics(String metric, String value) {
    return '$metric. $value';
  }

  @override
  String walletMetricSemanticsWithNote(
    String metric,
    String value,
    String note,
  ) {
    return '$metric. $value. $note';
  }

  @override
  String profileRatingSemantics(String value) {
    return 'التقييم. $value';
  }

  @override
  String profileRatingSemanticsValue(String value, String max, String count) {
    return 'التقييم $value من $max. $count';
  }

  @override
  String declinedOfferOutcomeWithKind(String kind) {
    return 'رفضتَ هذا العرض · $kind';
  }

  @override
  String get offerValueUnavailable => 'غير متوفر';

  @override
  String get offerGrossFeeLabel => 'أجرة التوصيل كاملة';

  @override
  String get offerEarningsMissing =>
      'تفاصيل العمولة غير متوفرة لهذا العرض، لذلك لا يمكن قبوله من هنا.';

  @override
  String get offerScheduledAdminOnly =>
      'الطلبات المؤجلة يؤكدها المشرف مباشرة، ولا يمكن قبولها من التطبيق حالياً.';

  @override
  String get offerAcceptFull => 'قبول الطلب';

  @override
  String get offerLater => 'لاحقاً';

  @override
  String get offerAcceptedNotOpened =>
      'تم قبول العرض، لكن تعذّر فتح الطلب الحالي الآن. ستجده في الصفحة الرئيسية عند توفّره.';

  @override
  String get declinedOffersHeading => 'العروض التي رفضتها';

  @override
  String get declinedOffersNote =>
      'عروض رفضتها أنت فقط. رفض العرض لا يلغي طلب المتجر.';

  @override
  String get declinedOffersLoading => 'جارٍ تحميل العروض المرفوضة…';

  @override
  String get declinedOffersNotConfigured =>
      'خدمة سجل العروض المرفوضة غير متصلة بعد.';

  @override
  String get declinedOffersNoSession => 'سجّل الدخول لعرض العروض المرفوضة.';

  @override
  String get declinedOffersNoInternet =>
      'لا يوجد اتصال بالإنترنت. تعذّر تحميل العروض المرفوضة.';

  @override
  String get declinedOffersLoadFailed => 'تعذّر تحميل العروض المرفوضة الآن.';

  @override
  String get declinedOffersEmpty => 'لا توجد عروض مرفوضة.';

  @override
  String get declinedOfferGenericTitle => 'عرض طلب';

  @override
  String get declinedOfferOutcome => 'رفضتَ هذا العرض';

  @override
  String get demoBadge => 'وضع تجريبي — بيانات وهمية';

  @override
  String get demoShowNewOffer => 'إظهار طلب جديد';

  @override
  String get demoTools => 'أدوات العرض';

  @override
  String get demoToolsHide => 'إخفاء الأدوات';

  @override
  String get demoScenarioNone => 'بدون طلب حالي';

  @override
  String get demoScenarioAssigned => 'طلب مسند مسبقاً';

  @override
  String get demoShowScheduled => 'عرض مؤجل (للعرض فقط)';

  @override
  String get demoReset => 'إعادة ضبط بيانات العرض';

  @override
  String get demoSignOut => 'تسجيل الخروج من العرض';

  @override
  String get demoFixturesError => 'تعذّر تحميل بيانات العرض التجريبي.';
}
