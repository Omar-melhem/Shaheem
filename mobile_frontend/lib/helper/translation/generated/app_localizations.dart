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

  /// Route error surface (R01): an opened link or path matches no page of the app (e.g. the removed notifications path). Never shows the path itself.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة غير موجودة'**
  String get routeNotFoundTitle;

  /// Route error surface (R01): explanation for an unknown path.
  ///
  /// In ar, this message translates to:
  /// **'الرابط الذي فتحته غير متاح في التطبيق.'**
  String get routeNotFoundMessage;

  /// Route error surface (R01): navigation failed for a reason other than an unknown path. No technical details are shown.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الصفحة'**
  String get routeErrorTitle;

  /// Route error surface (R01): explanation for a navigation failure other than an unknown path.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء فتح هذه الصفحة.'**
  String get routeErrorMessage;

  /// Route error surface (R01): the only action; goes to Home, where the normal routing policy applies.
  ///
  /// In ar, this message translates to:
  /// **'العودة إلى الرئيسية'**
  String get routeErrorBackHome;

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

  /// Current Order screen title; also the label of the central main-navigation button. It opens the captain's active order; it never creates an order.
  ///
  /// In ar, this message translates to:
  /// **'الطلب الحالي'**
  String get currentOrderTitle;

  /// Order History screen title; also its label in the main navigation bar.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get orderHistoryTitle;

  /// Profile screen title; also its label in the main navigation bar.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get profileTitle;

  /// Profile (D-A77, R08): screen-reader sentence for the captain name (or its honest fallback).
  ///
  /// In ar, this message translates to:
  /// **'الاسم: {name}'**
  String profileNameSemantics(String name);

  /// Profile (D-A77): the session has no name; nothing is invented.
  ///
  /// In ar, this message translates to:
  /// **'الاسم غير متوفر'**
  String get profileNameUnavailable;

  /// Profile (D-A77, R08): screen-reader sentence for the captain phone (or its honest fallback).
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف: {phone}'**
  String profilePhoneSemantics(String phone);

  /// Profile (D-A77): the session has no phone; nothing is invented.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف غير متوفر'**
  String get profilePhoneUnavailable;

  /// Profile (D-A77): rating card heading.
  ///
  /// In ar, this message translates to:
  /// **'التقييم'**
  String get profileRatingTitle;

  /// Profile (D-A77): rating is loading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل التقييم...'**
  String get profileRatingLoading;

  /// Profile (D-A77): rating unknown (not configured, offline or failed); never a fabricated value.
  ///
  /// In ar, this message translates to:
  /// **'التقييم غير متوفر'**
  String get profileRatingUnavailable;

  /// Profile (D-A77): the server confirmed there are no ratings yet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تقييمات بعد'**
  String get profileRatingNone;

  /// Profile (D-A77): rating value with the scale the server states (no assumed 5-star scale).
  ///
  /// In ar, this message translates to:
  /// **'{value} من {max}'**
  String profileRatingOutOf(String value, String max);

  /// Profile (D-A77): how many ratings the server aggregated.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا توجد تقييمات} =1{تقييم واحد} =2{تقييمان} few{{count} تقييمات} many{{count} تقييماً} other{{count} تقييم}}'**
  String profileRatingCount(int count);

  /// Profile: sign-out entry and its confirmation action.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get profileSignOut;

  /// Profile: sign-out confirmation message.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد تسجيل الخروج من حسابك؟'**
  String get profileSignOutConfirm;

  /// Settings page title and the Profile entry (D-A77).
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// Settings section heading above account deletion.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get settingsAccountSection;

  /// Settings (D-A78): destructive account-deletion entry.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get accountDeletionEntry;

  /// Settings (D-A78): what the deletion entry does.
  ///
  /// In ar, this message translates to:
  /// **'طلب حذف حسابك وبياناتك الشخصية المرتبطة به'**
  String get accountDeletionEntryHint;

  /// Settings (D-A78): the confirmed request is being sent.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ إرسال طلب الحذف...'**
  String get accountDeletionSubmitting;

  /// Settings (D-A78): confirmation title.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب؟'**
  String get accountDeletionConfirmTitle;

  /// Settings (D-A78): plain explanation before confirming; invents no retention period (D-P39).
  ///
  /// In ar, this message translates to:
  /// **'سيُرسل طلب لحذف حسابك في شهم وبياناتك الشخصية المرتبطة به. قد يستغرق إكمال الحذف بعض الوقت، وقد يلزم الاحتفاظ ببعض السجلات وفق المتطلبات القانونية؛ ستُوضَّح التفاصيل عند تفعيل خدمة الحذف. لا يمكن التراجع عن الحذف بعد اكتماله.'**
  String get accountDeletionConfirmMessage;

  /// Settings (D-A78): the only control that sends the request.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحذف'**
  String get accountDeletionConfirmAction;

  /// Settings (D-A78): no deletion backend exists; nothing was sent or deleted.
  ///
  /// In ar, this message translates to:
  /// **'خدمة حذف الحساب غير متصلة بالتطبيق بعد، لذلك لم يُرسل أي طلب ولم يُحذف حسابك.'**
  String get accountDeletionNotConfigured;

  /// Settings (D-A78): offline; nothing was sent.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت، ولم يُرسل الطلب. حاول مرة أخرى.'**
  String get accountDeletionNoInternet;

  /// Settings (D-A78): failure; nothing is assumed deleted.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إرسال طلب الحذف، ولم يُحذف حسابك. حاول مرة أخرى.'**
  String get accountDeletionFailed;

  /// Settings (R04): the confirmed request timed out; whether the server received it is unknown. Claims neither deletion nor 'not sent'; no automatic resend.
  ///
  /// In ar, this message translates to:
  /// **'لم يصل ردّ من الخادم في الوقت المحدد، لذلك لا نعرف إن كان طلب الحذف قد استُلم. لا يُعدّ حسابك محذوفاً.'**
  String get accountDeletionUnconfirmed;

  /// Settings (D-A78): the server requires a fresh sign-in.
  ///
  /// In ar, this message translates to:
  /// **'لأمان حسابك، يجب تسجيل الدخول مجدداً قبل طلب الحذف.'**
  String get accountDeletionReauthRequired;

  /// Settings (D-A78): starts the real sign-in flow again.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول مجدداً'**
  String get accountDeletionSignInAgain;

  /// Settings (D-A78): accepted but not yet deleted.
  ///
  /// In ar, this message translates to:
  /// **'تم استلام طلب حذف حسابك وهو قيد المعالجة. لم يُحذف الحساب بعد.'**
  String get accountDeletionPending;

  /// About page title and the Profile entry (D-A77).
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get aboutTitle;

  /// About (D-A77): factual one-line identity (captains-only app); no invented company details.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق الكباتن في منصة شهم لتوصيل الطلبات.'**
  String get aboutDescription;

  /// About (D-A77): version row label.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get aboutVersionLabel;

  /// About (D-A77): no version source is configured; nothing is guessed.
  ///
  /// In ar, this message translates to:
  /// **'رقم الإصدار غير متوفر في هذه النسخة من التطبيق.'**
  String get aboutVersionUnavailable;

  /// Screen-reader name of the main bottom navigation bar.
  ///
  /// In ar, this message translates to:
  /// **'التنقل الرئيسي'**
  String get mainNavigationLabel;

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

  /// Current Order pickup leg (D-A81): opens the pickup-verification form. Typing or confirming alone never marks pickup.
  ///
  /// In ar, this message translates to:
  /// **'تم الاستلام'**
  String get pickupConfirmAction;

  /// Current Order pickup leg: opens the Google Maps app with driving directions to the merchant only.
  ///
  /// In ar, this message translates to:
  /// **'فتح في خرائط Google'**
  String get openInGoogleMaps;

  /// The Google Maps app is not installed or cannot be opened; no other map app was chosen.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق خرائط Google غير متاح على هذا الجهاز، لذلك لم تُفتح الملاحة.'**
  String get googleMapsAppUnavailable;

  /// Launching the Google Maps app failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح خرائط Google. حاول مرة أخرى.'**
  String get googleMapsLaunchFailed;

  /// The merchant coordinates are missing or invalid, so no navigation destination exists.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن فتح الملاحة لأن موقع المطعم غير متوفر.'**
  String get pickupNavigationUnavailable;

  /// Pickup route (Google Routes DRIVE, no live traffic): road distance in km (LTR-isolated) and duration in minutes from the routing source.
  ///
  /// In ar, this message translates to:
  /// **'المسافة {distance} كم · الوقت المتوقع {minutes, plural, =1{دقيقة واحدة} =2{دقيقتان} few{{minutes} دقائق} many{{minutes} دقيقة} other{{minutes} دقيقة}}'**
  String routeDistanceAndTime(String distance, int minutes);

  /// No routing source is configured; no straight line is drawn instead.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم إعداد حساب المسار بعد، لذلك لا يظهر مسار أو وقت متوقع.'**
  String get routeNotConfigured;

  /// The routing source returned no route.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حساب المسار حالياً.'**
  String get routeUnavailable;

  /// A route needs the captain position, which is not available.
  ///
  /// In ar, this message translates to:
  /// **'يظهر المسار بعد تحديد موقعك.'**
  String get routeNeedsCaptainLocation;

  /// Screen-reader label of the Google pickup map; {restaurant} is the merchant name (server data).
  ///
  /// In ar, this message translates to:
  /// **'خريطة الاستلام من {restaurant}'**
  String pickupMapSemantics(String restaurant);

  /// Title of the captain's own marker on the pickup map.
  ///
  /// In ar, this message translates to:
  /// **'موقعك'**
  String get captainMarkerTitle;

  /// Pickup-verification form title (D-A81).
  ///
  /// In ar, this message translates to:
  /// **'تأكيد استلام الطلب'**
  String get pickupVerificationTitle;

  /// Pickup-verification form: the merchant gives the order-specific four-digit PIN after handover (D-A67).
  ///
  /// In ar, this message translates to:
  /// **'اطلب من المطعم رمز الاستلام المكوّن من 4 أرقام وأدخله هنا.'**
  String get pickupVerificationMessage;

  /// Pickup PIN field label.
  ///
  /// In ar, this message translates to:
  /// **'رمز الاستلام'**
  String get pickupPinLabel;

  /// Pickup PIN validation: empty.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز الاستلام.'**
  String get pickupPinRequired;

  /// Pickup PIN validation: not exactly four digits (syntax only; correctness is checked by the server).
  ///
  /// In ar, this message translates to:
  /// **'رمز الاستلام يتكوّن من 4 أرقام.'**
  String get pickupPinFormat;

  /// Pickup-verification form submit action.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الاستلام'**
  String get pickupVerificationSubmit;

  /// Pickup-verification form: the PIN was sent and the server answer is awaited.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق من الرمز…'**
  String get pickupVerificationSending;

  /// The server rejected the PIN and did not say how many attempts remain.
  ///
  /// In ar, this message translates to:
  /// **'رمز الاستلام غير صحيح.'**
  String get pickupPinIncorrect;

  /// The server rejected the PIN and supplied the remaining attempts (never counted on the phone).
  ///
  /// In ar, this message translates to:
  /// **'رمز الاستلام غير صحيح. {count, plural, =0{لم تتبقَّ محاولات} =1{تبقّت محاولة واحدة} =2{تبقّت محاولتان} few{تبقّت {count} محاولات} many{تبقّت {count} محاولة} other{تبقّت {count} محاولة}}.'**
  String pickupPinIncorrectRemaining(int count);

  /// No PIN attempts remain (server-enforced, three) — Admin intervention (D-A67).
  ///
  /// In ar, this message translates to:
  /// **'استُنفدت محاولات إدخال الرمز. تواصل مع الإدارة لإكمال الاستلام.'**
  String get pickupPinLocked;

  /// Delivery view (D-A81): heading above the destination area (an area, never an address).
  ///
  /// In ar, this message translates to:
  /// **'منطقة التسليم'**
  String get deliveryDestinationHeading;

  /// Delivery view: the server sent no destination area.
  ///
  /// In ar, this message translates to:
  /// **'منطقة التسليم غير متوفرة'**
  String get deliveryAreaUnavailable;

  /// Delivery view: shown only when the merchant supplied a phone (optional, D-A81).
  ///
  /// In ar, this message translates to:
  /// **'رقم هاتف العميل'**
  String get customerPhoneHeading;

  /// Screen-reader sentence for the optional customer phone.
  ///
  /// In ar, this message translates to:
  /// **'رقم هاتف العميل: {phone}'**
  String customerPhoneSemantics(String phone);

  /// Delivery view: where the order was collected; {merchant} is server data.
  ///
  /// In ar, this message translates to:
  /// **'تم الاستلام من {merchant}'**
  String pickedUpFromLine(String merchant);

  /// Delivery view, status picked_up.
  ///
  /// In ar, this message translates to:
  /// **'تم استلام الطلب. اضغط «بدء التوصيل» عند انطلاقك.'**
  String get deliveryStatusPickedUp;

  /// Delivery view, status on_the_way.
  ///
  /// In ar, this message translates to:
  /// **'أنت في الطريق إلى منطقة التسليم.'**
  String get deliveryStatusOnTheWay;

  /// Separate Start Delivery action (picked_up → on_the_way), explicitly retained (D-A81).
  ///
  /// In ar, this message translates to:
  /// **'بدء التوصيل'**
  String get startDeliveryAction;

  /// Completion action, only after a confirmed start (on_the_way).
  ///
  /// In ar, this message translates to:
  /// **'تم تسليم الطلب'**
  String get completeDeliveryAction;

  /// Completion confirmation title.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد تسليم الطلب؟'**
  String get completeDeliveryConfirmTitle;

  /// Completion confirmation: the server records the delivery and debits the commission once (D-A74).
  ///
  /// In ar, this message translates to:
  /// **'أكّد فقط بعد تسليم الطلب. سيُسجَّل التسليم وتُخصم عمولة الطلب من محفظتك مرة واحدة.'**
  String get completeDeliveryConfirmMessage;

  /// Completion confirmation: the only control that sends the command.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد التسليم'**
  String get completeDeliveryConfirmAction;

  /// A workflow command found no backend: nothing was sent.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الطلبات غير متصلة بالتطبيق بعد، لذلك لم يُرسل الإجراء ولم تتغيّر حالة الطلب.'**
  String get orderCommandNotConfigured;

  /// A workflow command was not sent because the device is offline.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت، ولم يُرسل الإجراء. حاول مرة أخرى.'**
  String get orderCommandNoInternet;

  /// A workflow command timed out or its answer was lost: the outcome is unknown (R04).
  ///
  /// In ar, this message translates to:
  /// **'لم يصل ردّ من الخادم في الوقت المحدد، لذلك لا نعرف إن تم تنفيذ الإجراء. تحقّق من حالة الطلب قبل المحاولة مجدداً.'**
  String get orderCommandUnconfirmed;

  /// The server refused the command because the order changed (already advanced, cancelled or reassigned).
  ///
  /// In ar, this message translates to:
  /// **'تغيّرت حالة الطلب على الخادم، لذلك لم يُنفَّذ الإجراء. جارٍ تحديث بياناته.'**
  String get orderCommandStateConflict;

  /// Reads the authoritative order/outcome after an unconfirmed command; never resends with a new key.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق من حالة الطلب'**
  String get orderCommandCheckStatus;

  /// The outcome lookup itself failed; the outcome stays unknown.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحقق من حالة الطلب الآن. حاول مرة أخرى.'**
  String get orderCommandCheckFailed;

  /// The outcome lookup says the operation is not resolved yet.
  ///
  /// In ar, this message translates to:
  /// **'لم يحسم الخادم نتيجة الإجراء بعد. تحقّق مرة أخرى بعد قليل.'**
  String get orderCommandCheckPending;

  /// The server reported a status this app version does not know; no action is offered.
  ///
  /// In ar, this message translates to:
  /// **'حالة الطلب غير مدعومة في هذا الإصدار'**
  String get orderStatusUnsupportedTitle;

  /// Advice for an unsupported status.
  ///
  /// In ar, this message translates to:
  /// **'حدّث الصفحة، وإن استمرت المشكلة تواصل مع الإدارة.'**
  String get orderStatusUnsupportedMessage;

  /// Server-confirmed completion.
  ///
  /// In ar, this message translates to:
  /// **'تم تسليم الطلب'**
  String get deliveryCompletedTitle;

  /// After a confirmed completion the history and wallet are re-read; they may lag briefly.
  ///
  /// In ar, this message translates to:
  /// **'يتم الآن تحديث طلباتك ومحفظتك.'**
  String get deliveryCompletedMessage;

  /// Outcome lookup: the order was cancelled (no completion debit).
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الطلب'**
  String get orderCancelledTitle;

  /// Outcome lookup: the order was reassigned.
  ///
  /// In ar, this message translates to:
  /// **'أُسند الطلب إلى كابتن آخر'**
  String get orderReassignedTitle;

  /// The order is no longer this captain's work.
  ///
  /// In ar, this message translates to:
  /// **'لم يعد هذا الطلب ضمن مهامك.'**
  String get orderEndedMessage;

  /// Current Order: back to Home after the order ended.
  ///
  /// In ar, this message translates to:
  /// **'العودة إلى الرئيسية'**
  String get currentOrderBackHome;

  /// My Orders (D-A81): completed deliveries section, as the server records them.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات المكتملة'**
  String get completedDeliveriesHeading;

  /// Completed deliveries: loading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل الطلبات المكتملة…'**
  String get completedDeliveriesLoading;

  /// Completed deliveries: the server confirmed none.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات مكتملة بعد.'**
  String get completedDeliveriesEmpty;

  /// Completed deliveries: no history backend; nothing was checked.
  ///
  /// In ar, this message translates to:
  /// **'خدمة سجل الطلبات غير متصلة بعد، لذلك لا يمكن عرض الطلبات المكتملة.'**
  String get completedDeliveriesNotConfigured;

  /// Completed deliveries: no session (debug preview).
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لعرض طلباتك المكتملة.'**
  String get completedDeliveriesNoSession;

  /// Completed deliveries: offline.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت. تعذّر تحميل الطلبات المكتملة.'**
  String get completedDeliveriesNoInternet;

  /// Completed deliveries: failure or timeout.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الطلبات المكتملة الآن.'**
  String get completedDeliveriesLoadFailed;

  /// Completed deliveries: reads the next page from the server's cursor.
  ///
  /// In ar, this message translates to:
  /// **'عرض المزيد'**
  String get completedDeliveriesLoadMore;

  /// Completed delivery record outcome line.
  ///
  /// In ar, this message translates to:
  /// **'تم التسليم'**
  String get completedDeliveryOutcome;

  /// Completed delivery: the full delivery fee; {amount} LTR-isolated JOD, {currency} the symbol.
  ///
  /// In ar, this message translates to:
  /// **'أجرة التوصيل: {amount} {currency}'**
  String completedDeliveryFeeLine(String amount, String currency);

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

  /// Home (D-A73): the authoritative active order exists; shown with the way back to the Current Order page.
  ///
  /// In ar, this message translates to:
  /// **'لديك طلب قيد التنفيذ من {merchant}.'**
  String homeActiveOrderMessage(String merchant);

  /// Home (D-A73): opens the Current Order page.
  ///
  /// In ar, this message translates to:
  /// **'عرض الطلب الحالي'**
  String get homeActiveOrderOpen;

  /// Home (D-A73): the active-order lookup failed; never shown as "no order".
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحقق من طلبك الحالي. هذا لا يعني عدم وجود طلب.'**
  String get homeActiveOrderCheckFailed;

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

  /// Heading of the Home section listing order offers this captain can still accept (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'طلبات بانتظار القبول'**
  String get offersSectionTitle;

  /// Heading with the number of offers the server returned (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'طلبات بانتظار القبول ({count})'**
  String offersSectionTitleWithCount(int count);

  /// Explains which offers the section shows (server-confirmed, still actionable for this captain) (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'عروض ما زالت متاحة لك ولم يقبلها كابتن آخر بعد.'**
  String get offersSectionSubtitle;

  /// Shown while the offers are loading (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل العروض...'**
  String get offersLoading;

  /// No offers backend is connected; nothing was checked (never shown as 'no offers') (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'خدمة الطلبات غير متصلة بعد، لذلك لا يمكن عرض العروض المتاحة.'**
  String get offersNotConfigured;

  /// No signed-in captain (e.g. the debug preview); offers are not loaded (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لعرض العروض المتاحة لك.'**
  String get offersNoSession;

  /// The server confirmed there are no actionable offers (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عروض متاحة لك الآن.'**
  String get offersEmpty;

  /// Offers could not be loaded because the device is offline (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت. تحقق من الاتصال ثم حدّث القائمة.'**
  String get offersNoInternet;

  /// Offers could not be loaded because the server failed (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل العروض. حاول التحديث بعد قليل.'**
  String get offersLoadFailed;

  /// Shown after the server confirmed this captain's acceptance; no automatic navigation (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'تم قبول الطلب. تابعه من «الطلب الحالي».'**
  String get offersAcceptedMessage;

  /// Shown after the server confirmed the decline (for this captain only) (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'تم رفض العرض.'**
  String get offersDeclinedMessage;

  /// Primary action of an order offer card: accept the offer (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get offerAccept;

  /// Red action of an order offer card: decline the offer for this captain only (never cancels the merchant's order) (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get offerDecline;

  /// Offer card and new-offer sheet (Task 26, R08): the merchant pickup line; {pickup} is server data or the unavailable text.
  ///
  /// In ar, this message translates to:
  /// **'موقع المطعم: {pickup}'**
  String offerPickupLine(String pickup);

  /// Neutral value when the server gave no verified pickup information (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'غير متوفر'**
  String get offerPickupUnknown;

  /// Offer card, new-offer sheet and debit card (R08): the customer delivery area line (an area, never a coordinate).
  ///
  /// In ar, this message translates to:
  /// **'منطقة التسليم: {area}'**
  String offerDeliveryAreaLine(String area);

  /// Label of the delivery fee snapshot (not the captain's profit or commission) (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'أجرة التوصيل'**
  String get offerDeliveryFeeLabel;

  /// Screen-reader summary of an offer card (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'عرض طلب من {merchant}. موقع المطعم: {pickup}. منطقة التسليم: {area}. قيمة التوصيل: {fee} دينار أردني.'**
  String offerCardSemantics(
    String merchant,
    String pickup,
    String area,
    String fee,
  );

  /// The server says the offer expired, was withdrawn or was taken (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'لم يعد هذا العرض متاحاً لك. حدّث القائمة.'**
  String get offerNoLongerAvailable;

  /// The server refused the accept/decline command (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'لم يوافق الخادم على هذه العملية حالياً.'**
  String get offerRefused;

  /// No offers backend is connected; the command was not sent (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'خدمة الطلبات غير متصلة بعد، لم يُرسل أي طلب.'**
  String get offerNotConfigured;

  /// The command's outcome is unknown; actions stay off until the list is refreshed (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تأكيد العملية. حدّث القائمة للتحقق من حالة العرض.'**
  String get offerUnconfirmed;

  /// Caption of the standalone design preview entrypoint (sample data only; not part of the app) (Task 26).
  ///
  /// In ar, this message translates to:
  /// **'معاينة تصميم — بيانات افتراضية'**
  String get previewCaption;

  /// Title of the Wallet tab and screen; also the Profile entry that opens it (Task 34).
  ///
  /// In ar, this message translates to:
  /// **'المحفظة'**
  String get walletTitle;

  /// Screen-reader hint of the Home app-bar balance chip, which opens Wallet (Task 34).
  ///
  /// In ar, this message translates to:
  /// **'فتح المحفظة'**
  String get walletOpenHint;

  /// Wallet balance card: total balance label (server value) (Task 34).
  ///
  /// In ar, this message translates to:
  /// **'الرصيد'**
  String get walletTotalBalance;

  /// Screen-reader text for a balance shown as «—» because it is not known (Task 34).
  ///
  /// In ar, this message translates to:
  /// **'غير معروف'**
  String get walletValueUnknownSemantics;

  /// History selector: final commission debits of the last 7 days (Task 34).
  ///
  /// In ar, this message translates to:
  /// **'سجل الخصم'**
  String get walletDebitHistory;

  /// Note under the history selectors: the visible window, not the full ledger (Task 34).
  ///
  /// In ar, this message translates to:
  /// **'يعرض السجل عمليات خصم العمولة خلال آخر 7 أيام.'**
  String get walletHistoryWindowNote;

  /// Wallet metric card (D-A76): lifetime count of successfully completed deliveries.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات المسلّمة'**
  String get walletDeliveredCount;

  /// Wallet metric card (D-A76): lifetime earnings; formula pending owner decision D-P36.
  ///
  /// In ar, this message translates to:
  /// **'الأرباح'**
  String get walletEarnings;

  /// Wallet metric cards (D-A76): the period is lifetime since the captain started work.
  ///
  /// In ar, this message translates to:
  /// **'منذ بدء العمل'**
  String get walletMetricsLifetimeNote;

  /// Wallet earnings card (D-A76): no approved formula/source yet (D-P36); never shown as zero.
  ///
  /// In ar, this message translates to:
  /// **'غير متوفر حالياً'**
  String get walletEarningsUnavailable;

  /// Wallet metric cards (D-A76): no statistics backend is connected; nothing was read.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الإحصائيات غير متصلة بعد.'**
  String get walletMetricsNotConfigured;

  /// Wallet metric cards (D-A76): the statistics read failed; the balance is unaffected.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الإحصائيات.'**
  String get walletMetricsLoadFailed;

  /// Debit card (Task 34, R08): the order merchant line.
  ///
  /// In ar, this message translates to:
  /// **'المطعم: {merchant}'**
  String walletDebitMerchantLine(String merchant);

  /// Debit card (Task 34, R08): the debit date line; {date} is the LTR-isolated local date and time.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الخصم: {date}'**
  String walletDebitDateLine(String date);

  /// Debit card (Task 34, R08): the commission debited (never the delivery fee); {amount} is LTR-isolated fils formatted as JOD, {currency} the currency symbol.
  ///
  /// In ar, this message translates to:
  /// **'قيمة الخصم (العمولة): {amount} {currency}'**
  String walletDebitAmountLine(String amount, String currency);

  /// A value the server did not provide (e.g. merchant or area of a debit); never invented (Task 34).
  ///
  /// In ar, this message translates to:
  /// **'غير متوفر'**
  String get walletFieldUnavailable;

  /// Confirmed by the server: no commission debits in the 7-day window (Task 34).
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عمليات خصم خلال آخر 7 أيام.'**
  String get walletDebitsEmpty;

  /// Wallet is loading (Task 34).
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل المحفظة…'**
  String get walletLoading;

  /// No wallet backend is connected; nothing was checked. Never shown as zero or empty (Task 34).
  ///
  /// In ar, this message translates to:
  /// **'خدمة المحفظة غير متصلة بعد، لذلك لا يمكن عرض الرصيد أو السجل حالياً.'**
  String get walletNotConfigured;

  /// No signed-in captain (e.g. the debug preview) (Task 34).
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لعرض محفظتك.'**
  String get walletNoSession;

  /// Offline while loading the wallet (Task 34).
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت. تعذّر تحميل المحفظة.'**
  String get walletNoInternet;

  /// The wallet server failed while loading (Task 34).
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل المحفظة. حاول مرة أخرى.'**
  String get walletLoadFailed;

  /// Screen-reader summary of a commission-debit card (Task 34).
  ///
  /// In ar, this message translates to:
  /// **'خصم عمولة بقيمة {amount} دينار أردني، المطعم: {merchant}، منطقة التسليم: {area}، بتاريخ {date}'**
  String walletDebitSemantics(
    String amount,
    String merchant,
    String area,
    String date,
  );

  /// Title of the new-order offer bottom sheet (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'عرض طلب جديد'**
  String get newOfferSheetTitle;

  /// Badge of an instant (current) offer (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'حالي'**
  String get offerKindInstant;

  /// Badge of a scheduled (future pickup) offer (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'مؤجل'**
  String get offerKindScheduled;

  /// New-offer sheet (Task 36, R08): the authoritative scheduled pickup line; {time} is the LTR-isolated local date/time or the unavailable text.
  ///
  /// In ar, this message translates to:
  /// **'موعد الاستلام: {time}'**
  String offerScheduledPickupLine(String time);

  /// Wallet balance card (R08): screen-reader sentence; {value} is the spoken amount with currency or the unknown text.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد: {value}'**
  String walletBalanceCardSemantics(String value);

  /// Wallet metric card (R08): screen-reader sentence of a lifetime metric without a note.
  ///
  /// In ar, this message translates to:
  /// **'{metric}. {value}'**
  String walletMetricSemantics(String metric, String value);

  /// Wallet metric card (R08): screen-reader sentence of a lifetime metric with its period/unavailability note.
  ///
  /// In ar, this message translates to:
  /// **'{metric}. {value}. {note}'**
  String walletMetricSemanticsWithNote(
    String metric,
    String value,
    String note,
  );

  /// Profile rating card (R08): screen-reader sentence without a count.
  ///
  /// In ar, this message translates to:
  /// **'التقييم. {value}'**
  String profileRatingSemantics(String value);

  /// Profile rating card (R08): screen-reader sentence with the localized ratings count.
  ///
  /// In ar, this message translates to:
  /// **'التقييم. {value}. {count}'**
  String profileRatingSemanticsWithCount(String value, String count);

  /// My Orders declined record (R08): outcome with the offer kind; {kind} is the localized instant/scheduled label.
  ///
  /// In ar, this message translates to:
  /// **'رفضتَ هذا العرض · {kind}'**
  String declinedOfferOutcomeWithKind(String kind);

  /// Neutral value when the server did not send a value needed by the offer sheet (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'غير متوفر'**
  String get offerValueUnavailable;

  /// The offer sheet's only money row: the full delivery fee, never net of commission (Task 36; single row since Task 38).
  ///
  /// In ar, this message translates to:
  /// **'أجرة التوصيل كاملة'**
  String get offerGrossFeeLabel;

  /// Accept is off because the commission snapshot is missing or inconsistent (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل العمولة غير متوفرة لهذا العرض، لذلك لا يمكن قبوله من هنا.'**
  String get offerEarningsMissing;

  /// Accept is off for a scheduled offer: the approved process is Admin-confirmed assignment (D-A47 / D-A61) (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'الطلبات المؤجلة يؤكدها المشرف مباشرة، ولا يمكن قبولها من التطبيق حالياً.'**
  String get offerScheduledAdminOnly;

  /// Accept action of the offer sheet (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'قبول الطلب'**
  String get offerAcceptFull;

  /// Decline action of the offer sheet: this captain only, never cancels the merchant's order (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'رفض الطلب'**
  String get offerDeclineFull;

  /// Closes the offer sheet without answering; the offer stays on Home (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'لاحقاً'**
  String get offerLater;

  /// Acceptance was confirmed but the matching current order could not be shown; nothing is accepted twice (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'تم قبول العرض، لكن تعذّر فتح الطلب الحالي الآن. ستجده في الصفحة الرئيسية عند توفّره.'**
  String get offerAcceptedNotOpened;

  /// Order History section of offers this captain declined (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'العروض التي رفضتها'**
  String get declinedOffersHeading;

  /// Explains declined offers are not cancelled orders (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'عروض رفضتها أنت فقط. رفض العرض لا يلغي طلب المتجر.'**
  String get declinedOffersNote;

  /// Declined offers are loading (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل العروض المرفوضة…'**
  String get declinedOffersLoading;

  /// No history backend is connected; nothing was checked (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'خدمة سجل العروض المرفوضة غير متصلة بعد.'**
  String get declinedOffersNotConfigured;

  /// No signed-in captain (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لعرض العروض المرفوضة.'**
  String get declinedOffersNoSession;

  /// Offline while loading declined offers (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت. تعذّر تحميل العروض المرفوضة.'**
  String get declinedOffersNoInternet;

  /// Server failure while loading declined offers (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل العروض المرفوضة الآن.'**
  String get declinedOffersLoadFailed;

  /// The server confirmed there are no declined offers (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عروض مرفوضة.'**
  String get declinedOffersEmpty;

  /// Title of a declined-offer record without a merchant name (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'عرض طلب'**
  String get declinedOfferGenericTitle;

  /// Outcome line of a declined-offer record (Task 36).
  ///
  /// In ar, this message translates to:
  /// **'رفضتَ هذا العرض'**
  String get declinedOfferOutcome;

  /// Debug demo (Task 37) badge shown on every screen.
  ///
  /// In ar, this message translates to:
  /// **'وضع تجريبي — بيانات وهمية'**
  String get demoBadge;

  /// Debug demo (Task 37): adds a fictional new instant offer.
  ///
  /// In ar, this message translates to:
  /// **'إظهار طلب جديد'**
  String get demoShowNewOffer;

  /// Debug demo (Task 37): shows the demo tools.
  ///
  /// In ar, this message translates to:
  /// **'أدوات العرض'**
  String get demoTools;

  /// Debug demo (Task 37): hides the demo tools.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء الأدوات'**
  String get demoToolsHide;

  /// Debug demo (Task 37): no active order scenario.
  ///
  /// In ar, this message translates to:
  /// **'بدون طلب حالي'**
  String get demoScenarioNone;

  /// Debug demo (Task 37): fictional pre-assigned active order scenario.
  ///
  /// In ar, this message translates to:
  /// **'طلب مسند مسبقاً'**
  String get demoScenarioAssigned;

  /// Debug demo (Task 37): lists the visual-only scheduled sample offer.
  ///
  /// In ar, this message translates to:
  /// **'عرض مؤجل (للعرض فقط)'**
  String get demoShowScheduled;

  /// Debug demo (Task 37): restores the original fixtures.
  ///
  /// In ar, this message translates to:
  /// **'إعادة ضبط بيانات العرض'**
  String get demoReset;

  /// Debug demo (Task 37): signs the demo captain out and clears demo data.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج من العرض'**
  String get demoSignOut;

  /// Debug demo (Task 37): the fixture files could not be read.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل بيانات العرض التجريبي.'**
  String get demoFixturesError;
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
