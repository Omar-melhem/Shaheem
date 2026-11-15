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

  /// Home screen title; also the Home label in the main navigation bar.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get homeTitle;

  /// Notifications screen title; also its label in the main navigation bar.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsTitle;

  /// Current Order screen title; also the label of the central main-navigation button. It opens the captain's active order; it never creates an order.
  ///
  /// In ar, this message translates to:
  /// **'الطلب الحالي'**
  String get currentOrderTitle;

  /// Order History screen title; also its label in the main navigation bar.
  ///
  /// In ar, this message translates to:
  /// **'سجل الطلبات'**
  String get orderHistoryTitle;

  /// Profile screen title; also its label in the main navigation bar.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profileTitle;

  /// Screen-reader name of the main bottom navigation bar.
  ///
  /// In ar, this message translates to:
  /// **'التنقل الرئيسي'**
  String get mainNavigationLabel;

  /// Screen-reader description added to the Notifications destination while the unread dot is shown.
  ///
  /// In ar, this message translates to:
  /// **'توجد إشعارات غير مقروءة'**
  String get navUnreadNotifications;

  /// Screen-reader description added to the Current Order destination while the server reports an active order.
  ///
  /// In ar, this message translates to:
  /// **'لديك طلب فعال'**
  String get navActiveOrder;

  /// Screen-reader description added to the Current Order destination while the active order is being looked up.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق من طلبك الحالي'**
  String get navCheckingActiveOrder;

  /// Screen-reader hint of the Current Order destination: what tapping it does (it does not create an order).
  ///
  /// In ar, this message translates to:
  /// **'عرض طلبك الفعال وموقع استلامه على الخريطة'**
  String get navCurrentOrderHint;

  /// Heading of the placeholder shown on screens whose feature is not built yet.
  ///
  /// In ar, this message translates to:
  /// **'قيد التطوير'**
  String get underConstructionTitle;

  /// Placeholder body of the Notifications screen (feature not built yet).
  ///
  /// In ar, this message translates to:
  /// **'صفحة الإشعارات قيد التطوير وستتوفر قريباً.'**
  String get notificationsPlaceholderMessage;

  /// Placeholder body of the Order History screen (feature not built yet).
  ///
  /// In ar, this message translates to:
  /// **'صفحة سجل الطلبات قيد التطوير وستتوفر قريباً.'**
  String get orderHistoryPlaceholderMessage;

  /// Placeholder body of the Profile screen (feature not built yet).
  ///
  /// In ar, this message translates to:
  /// **'صفحة الملف الشخصي قيد التطوير وستتوفر قريباً.'**
  String get profilePlaceholderMessage;

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

  /// Generic refresh action (asks the server again).
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get refresh;

  /// Current Order: the active order is being looked up.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل طلبك الحالي...'**
  String get currentOrderLoading;

  /// Current Order: the server reports no active order.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد لديك طلب فعال حالياً'**
  String get currentOrderEmptyTitle;

  /// Current Order: supporting text of the no-active-order state.
  ///
  /// In ar, this message translates to:
  /// **'سيظهر طلبك الفعال هنا مع موقع استلامه من المطعم.'**
  String get currentOrderEmptyMessage;

  /// Current Order: no orders backend is connected yet (development placeholder). NOT a temporary outage: do not word it as "try again later".
  ///
  /// In ar, this message translates to:
  /// **'خدمة الطلبات غير مفعّلة في التطبيق بعد'**
  String get currentOrderNotConfiguredTitle;

  /// Current Order: supporting text of the backend-not-connected state.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم ربط التطبيق بخدمة الطلبات حتى الآن، لذلك لا يمكن التحقق من طلبك الحالي. هذا ليس عطلاً في اتصالك أو في الخدمة.'**
  String get currentOrderNotConfiguredMessage;

  /// Current Order: the lookup failed (shown with a Retry action).
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل طلبك الحالي'**
  String get currentOrderLoadFailedTitle;

  /// Current Order: the lookup failed because the device is offline.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت. تحقّق من اتصالك ثم أعد المحاولة.'**
  String get currentOrderNoInternet;

  /// Label above the restaurant name: this is where the order is collected (not the customer's address).
  ///
  /// In ar, this message translates to:
  /// **'نقطة الاستلام من المطعم'**
  String get pickupPointLabel;

  /// Label above the pickup instructions of the active order.
  ///
  /// In ar, this message translates to:
  /// **'تعليمات الاستلام'**
  String get pickupInstructionsLabel;

  /// Pickup view map area: the active order has missing or malformed restaurant coordinates, so no map is shown.
  ///
  /// In ar, this message translates to:
  /// **'موقع المطعم غير متوفر'**
  String get pickupLocationInvalidTitle;

  /// Pickup view map area: the order is active but its restaurant coordinates are missing or malformed.
  ///
  /// In ar, this message translates to:
  /// **'طلبك فعال، لكن بيانات موقع «{restaurant}» ناقصة أو غير صحيحة، لذلك لا يمكن عرض الخريطة.'**
  String pickupLocationInvalidMessage(String restaurant);

  /// Shown in the map area when no map service is configured or it cannot load.
  ///
  /// In ar, this message translates to:
  /// **'الخريطة غير متاحة حالياً'**
  String get mapUnavailableTitle;

  /// Supporting text of the map-unavailable state.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم إعداد خدمة الخرائط في التطبيق بعد.'**
  String get mapUnavailableMessage;

  /// Pickup view: the captain's position is being read.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحديد موقعك...'**
  String get locationLocating;

  /// Pickup view: the location permission was denied.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسمح للتطبيق باستخدام الموقع.'**
  String get locationPermissionDenied;

  /// Pickup view: why the location permission is needed.
  ///
  /// In ar, this message translates to:
  /// **'نحتاج إلى موقعك لعرض مكانك على الخريطة وحساب المسار إلى المطعم.'**
  String get locationPermissionRationale;

  /// Pickup view: permission is fine but no position could be obtained.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد موقعك الحالي. تأكّد من تفعيل خدمة الموقع ثم أعد المحاولة.'**
  String get locationUnavailable;

  /// Pickup view: no location provider is integrated yet (development placeholder).
  ///
  /// In ar, this message translates to:
  /// **'خدمة تحديد الموقع غير متاحة بعد.'**
  String get locationNotConfigured;

  /// Static text below the Login form, before the contact-administration action.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get noAccountPrompt;

  /// Login text action that opens the create-account information popup.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الإدارة'**
  String get contactAdministration;

  /// Title of the create-account information popup.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get createAccountTitle;

  /// Create-account popup body. There is no public registration.
  ///
  /// In ar, this message translates to:
  /// **'لإنشاء حساب في شهم، يرجى التواصل مع الإدارة.'**
  String get createAccountMessage;

  /// Login text action that opens the Terms & Conditions page in the app; also the title of its popup. Not a consent control.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والأحكام'**
  String get termsAndConditions;

  /// Popup body while no Terms & Conditions URL has been published/configured. Truthful temporary state, not legal text.
  ///
  /// In ar, this message translates to:
  /// **'صفحة الشروط والأحكام غير متاحة بعد.'**
  String get termsUnavailableMessage;

  /// Popup body when the Terms page could not be opened inside the app (unsupported device, invalid configuration or load failure). Nothing is opened outside the app.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح صفحة الشروط والأحكام داخل التطبيق. حاول مرة أخرى لاحقاً.'**
  String get termsOpenFailedMessage;

  /// TEMPORARY, debug builds only: Login button that opens the main navigation shell without signing in.
  ///
  /// In ar, this message translates to:
  /// **'معاينة التطبيق'**
  String get debugPreviewButton;

  /// TEMPORARY, debug builds only: caption marking the preview button as a development tool.
  ///
  /// In ar, this message translates to:
  /// **'للتطوير فقط — لا يظهر في نسخة الإصدار'**
  String get debugPreviewNote;

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

  /// Validation: Login username is shorter than 4 or longer than 30 characters (D-A65). Owner-approved wording.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم يجب أن يكون بين 4 و30 حرفاً.'**
  String get usernameLengthInvalid;

  /// Validation: Login username contains a character other than ASCII letters, digits, underscore or dot (D-A65). Owner-approved wording.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم يقبل الأحرف الإنجليزية والأرقام والشرطة السفلية (_) والنقطة فقط.'**
  String get usernameFormatInvalid;

  /// Validation: Login password is empty.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور'**
  String get passwordRequired;

  /// Validation: Login password is shorter than 8 or longer than 128 characters (D-A65). Owner-approved wording.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور يجب أن تكون بين 8 و128 حرفاً.'**
  String get passwordLengthInvalid;

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

  /// Home greeting with the signed-in captain's display name from the backend session. Copy pending owner review (Task 24).
  ///
  /// In ar, this message translates to:
  /// **'مرحباً، {name}'**
  String homeGreeting(String name);

  /// Home greeting when no display name is known (no name from the backend, or the debug preview without a session). Copy pending owner review (Task 24).
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك'**
  String get homeGreetingNoName;

  /// Jordanian Dinar symbol shown after a wallet amount (PRODUCT_OVERVIEW: JOD, د.أ).
  ///
  /// In ar, this message translates to:
  /// **'د.أ'**
  String get walletCurrencySymbol;

  /// Visible placeholder in the Home app bar when the total wallet balance is not known. Never a zero amount.
  ///
  /// In ar, this message translates to:
  /// **'—'**
  String get walletBalanceUnknownValue;

  /// Screen-reader text for the read-only total wallet balance in the Home app bar.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي رصيد المحفظة: {amount} دينار أردني'**
  String walletBalanceSemantics(String amount);

  /// Screen-reader text when the total wallet balance is not known (no wallet backend or session yet).
  ///
  /// In ar, this message translates to:
  /// **'إجمالي رصيد المحفظة غير متوفر حالياً'**
  String get walletBalanceUnavailableSemantics;

  /// Heading of the Home card that controls the captain's own availability for new order offers (not the Admin broadcast switch). Copy pending owner review (Task 24).
  ///
  /// In ar, this message translates to:
  /// **'استقبال الطلبات'**
  String get availabilityCardTitle;

  /// Accessible name and label of the captain availability switch. Copy pending owner review (Task 24).
  ///
  /// In ar, this message translates to:
  /// **'استقبال عروض الطلبات الجديدة'**
  String get availabilityToggleLabel;

  /// Shown only when the backend confirmed the captain is Available. Copy pending owner review (Task 24).
  ///
  /// In ar, this message translates to:
  /// **'أنت متاح، وقد تصلك عروض طلبات جديدة.'**
  String get availabilityStatusAvailable;

  /// Shown when the backend confirmed the captain is not Available.
  ///
  /// In ar, this message translates to:
  /// **'أنت غير متاح، ولن تصلك عروض طلبات جديدة.'**
  String get availabilityStatusUnavailable;

  /// Shown when no availability has been confirmed by the backend.
  ///
  /// In ar, this message translates to:
  /// **'حالة التوفر غير معروفة.'**
  String get availabilityStatusUnknown;

  /// Shown while the availability status or a change is being checked.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق من حالة التوفر...'**
  String get availabilityChecking;

  /// No availability backend is connected yet; nothing can be enabled. Copy pending owner review (Task 24).
  ///
  /// In ar, this message translates to:
  /// **'تفعيل استقبال الطلبات غير متاح بعد، لأن التطبيق لم يُربط بخادم شهم.'**
  String get availabilityNotConfigured;

  /// No signed-in captain (e.g. the debug preview); availability cannot be changed.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لتتمكن من استقبال الطلبات.'**
  String get availabilityNoSession;

  /// Availability could not be checked because the device is offline.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت. تحقق من الاتصال ثم أعد المحاولة.'**
  String get availabilityNoInternet;

  /// The backend refused to make the captain Available. Copy pending owner review (Task 24).
  ///
  /// In ar, this message translates to:
  /// **'لم يؤكد الخادم تفعيل استقبال الطلبات. ما زلت غير متاح.'**
  String get availabilityRejected;

  /// The app build cannot check or request location/notification permissions yet (native configuration pending).
  ///
  /// In ar, this message translates to:
  /// **'أذونات الموقع والإشعارات غير مهيأة في هذا الإصدار من التطبيق بعد.'**
  String get availabilityPermissionsNotConfigured;

  /// Introduces the list of missing requirements for being Available.
  ///
  /// In ar, this message translates to:
  /// **'لن تصبح متاحاً قبل:'**
  String get availabilityMissingIntro;

  /// Missing requirement: the device location service (GPS) is off.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل خدمة الموقع في الجهاز'**
  String get availabilityNeedLocationService;

  /// Missing requirement: precise location permission. Copy pending owner/legal review (Task 24).
  ///
  /// In ar, this message translates to:
  /// **'السماح بالوصول إلى الموقع الدقيق'**
  String get availabilityNeedPreciseLocation;

  /// Missing requirement: background (always) location permission. Copy pending owner/legal review (Task 24).
  ///
  /// In ar, this message translates to:
  /// **'السماح بالوصول إلى الموقع طوال الوقت'**
  String get availabilityNeedBackgroundLocation;

  /// Missing requirement: notification permission. Copy pending owner/legal review (Task 24).
  ///
  /// In ar, this message translates to:
  /// **'السماح بالإشعارات'**
  String get availabilityNeedNotifications;

  /// Opens the system settings for the app, only when the captain taps it.
  ///
  /// In ar, this message translates to:
  /// **'فتح الإعدادات'**
  String get availabilityOpenSettings;

  /// Title of the explanation shown before requesting location and notification permissions. Copy pending owner/legal review (Task 24).
  ///
  /// In ar, this message translates to:
  /// **'أذونات مطلوبة'**
  String get availabilityRationaleTitle;

  /// Explanation before the OS permission prompts (D-A48, D-A57, D-A58). Not legally approved: pending owner/legal review (Task 24).
  ///
  /// In ar, this message translates to:
  /// **'لاستقبال عروض الطلبات الجديدة يحتاج شهم إلى موقعك الدقيق، بما في ذلك أثناء عمل التطبيق في الخلفية، وإلى إذن الإشعارات. إن لم تسمح بها فلن تصبح متاحاً.'**
  String get availabilityRationaleMessage;

  /// Continues from the permission explanation to the system prompts.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get availabilityContinue;

  /// An availability change could not be confirmed; the last confirmed status was Available.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تأكيد التغيير مع الخادم. آخر حالة مؤكدة: متاح.'**
  String get availabilityUnconfirmedWasAvailable;

  /// An availability change could not be confirmed; the last confirmed status was not Available.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تأكيد التغيير مع الخادم. آخر حالة مؤكدة: غير متاح.'**
  String get availabilityUnconfirmedWasUnavailable;

  /// While confirmed Available, a required permission or the location service is no longer granted. Copy pending owner review (Task 24).
  ///
  /// In ar, this message translates to:
  /// **'لم يعد أحد الأذونات المطلوبة مسموحاً. قد لا تصلك عروض جديدة حتى تسمح به مجدداً.'**
  String get availabilityRequirementsLost;
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
