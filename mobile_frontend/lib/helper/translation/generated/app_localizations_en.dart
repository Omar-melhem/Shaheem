// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SHAHM';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get alert => 'Alert';

  @override
  String get proceedQuestion => 'Do you want to continue?';

  @override
  String get loading => 'Loading...';

  @override
  String get unexpectedError => 'Something went wrong. Please try again.';

  @override
  String get noInternetTitle => 'No internet connection';

  @override
  String get noInternetMessage =>
      'The app needs an internet connection. Check your connection and try again.';

  @override
  String get routeNotFoundTitle => 'Page not found';

  @override
  String get routeNotFoundMessage =>
      'The link you opened isn\'t available in the app.';

  @override
  String get routeErrorTitle => 'Couldn\'t open the page';

  @override
  String get routeErrorMessage =>
      'Something went wrong while opening this page.';

  @override
  String get routeErrorBackHome => 'Back to Home';

  @override
  String get offlineBanner => 'No internet connection';

  @override
  String get connectivityCheckFailedMessage =>
      'Couldn\'t check your internet connection. Please try again.';

  @override
  String get serviceUnavailableMessage =>
      'The SHAHM service can\'t be reached right now. Please try again shortly.';

  @override
  String get profileFailureMessage =>
      'Couldn\'t load your account details. Please try again.';

  @override
  String get accountBlockedMessage =>
      'This account can\'t sign in to the app right now. Please contact SHAHM administration.';

  @override
  String get startupFailureMessage =>
      'Something went wrong while starting the app. Please try again.';

  @override
  String get homeTitle => 'Home';

  @override
  String get currentOrderTitle => 'Current order';

  @override
  String get orderHistoryTitle => 'My orders';

  @override
  String get profileTitle => 'My account';

  @override
  String profileNameSemantics(String name) {
    return 'Name: $name';
  }

  @override
  String get profileNameUnavailable => 'Name not available';

  @override
  String profilePhoneSemantics(String phone) {
    return 'Phone number: $phone';
  }

  @override
  String get profilePhoneUnavailable => 'Phone number not available';

  @override
  String get profileRatingLoading => 'Loading rating...';

  @override
  String get profileRatingUnavailable => 'Rating not available';

  @override
  String get profileRatingOffline =>
      'No internet connection. Couldn\'t load the rating.';

  @override
  String get profileRatingFailed => 'Couldn\'t load the rating.';

  @override
  String get profileRatingNone => 'No ratings yet';

  @override
  String profileRatingValue(String value, String max) {
    return '$value / $max';
  }

  @override
  String profileRatingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ratings',
      one: '1 rating',
      zero: 'No ratings',
    );
    return '$_temp0';
  }

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileSignOutConfirm =>
      'Do you want to sign out of your account?';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsAccountSection => 'Account';

  @override
  String get accountDeletionEntry => 'Delete account';

  @override
  String get accountDeletionEntryHint =>
      'Request deletion of your account and the personal data linked to it';

  @override
  String get accountDeletionSubmitting => 'Sending the deletion request...';

  @override
  String get accountDeletionConfirmTitle => 'Delete account?';

  @override
  String get accountDeletionConfirmMessage =>
      'A request will be sent to delete your SHAHM account and the personal data linked to it. Completing the deletion may take some time, and some records may have to be kept to meet legal requirements; the details will be explained once the deletion service is enabled. Deletion can\'t be undone once it\'s complete.';

  @override
  String get accountDeletionConfirmAction => 'Confirm deletion';

  @override
  String get accountDeletionNotConfigured =>
      'The account deletion service isn\'t connected to the app yet, so no request was sent and your account wasn\'t deleted.';

  @override
  String get accountDeletionNoInternet =>
      'No internet connection, so the request wasn\'t sent. Try again.';

  @override
  String get accountDeletionFailed =>
      'Couldn\'t send the deletion request, and your account wasn\'t deleted. Try again.';

  @override
  String get accountDeletionUnconfirmed =>
      'The server didn\'t answer in time, so we don\'t know whether the deletion request was received. Your account isn\'t considered deleted.';

  @override
  String get accountDeletionReauthRequired =>
      'For your account\'s security, you need to sign in again before requesting deletion.';

  @override
  String get accountDeletionSignInAgain => 'Sign in again';

  @override
  String get accountDeletionPending =>
      'Your account deletion request was received and is being processed. The account hasn\'t been deleted yet.';

  @override
  String get aboutTitle => 'About the app';

  @override
  String get aboutDescription =>
      'The captains\' app of the SHAHM order delivery platform.';

  @override
  String get aboutVersionLabel => 'Version';

  @override
  String get aboutVersionUnavailable =>
      'The version number isn\'t available in this build of the app.';

  @override
  String get mainNavigationLabel => 'Main navigation';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get companyWordmark => 'Delivered with honor, kept with care';

  @override
  String get usernameLabel => 'Username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get loginInvalidCredentials =>
      'The username or password is incorrect.';

  @override
  String get loginNoInternet =>
      'No internet connection. Check your connection and try again.';

  @override
  String get loginBackendNotConfigured =>
      'The sign-in service isn\'t available yet. Please try again later.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Recover your password';

  @override
  String get forgotPasswordMessage =>
      'To change your password, please contact administration.';

  @override
  String get refresh => 'Refresh';

  @override
  String get currentOrderLoading => 'Loading your current order...';

  @override
  String get currentOrderEmptyTitle => 'You have no active order right now';

  @override
  String get currentOrderEmptyMessage =>
      'Your active order will appear here with its restaurant pickup location.';

  @override
  String get currentOrderNotConfiguredTitle =>
      'The order service isn\'t enabled in the app yet';

  @override
  String get currentOrderNotConfiguredMessage =>
      'The app isn\'t connected to the order service yet, so your current order can\'t be checked. This isn\'t a problem with your connection or with the service.';

  @override
  String get currentOrderLoadFailedTitle => 'Couldn\'t load your current order';

  @override
  String get currentOrderNoInternet =>
      'No internet connection. Check your connection and try again.';

  @override
  String get pickupPointLabel => 'Restaurant pickup point';

  @override
  String get pickupInstructionsLabel => 'Pickup instructions';

  @override
  String get pickupLocationInvalidTitle => 'Restaurant location not available';

  @override
  String pickupLocationInvalidMessage(String restaurant) {
    return 'Your order is active, but the location details of “$restaurant” are missing or invalid, so the map can\'t be shown.';
  }

  @override
  String get mapUnavailableTitle => 'The map isn\'t available right now';

  @override
  String get mapUnavailableMessage =>
      'The map service hasn\'t been set up in the app yet.';

  @override
  String get locationLocating => 'Finding your location...';

  @override
  String get locationPermissionDenied =>
      'The app isn\'t allowed to use your location.';

  @override
  String get locationPermissionRationale =>
      'We need your location to show where you are on the map and to calculate the route to the restaurant.';

  @override
  String get locationUnavailable =>
      'Couldn\'t find your current location. Make sure location services are on and try again.';

  @override
  String get locationNotConfigured =>
      'The location service isn\'t available yet.';

  @override
  String get pickupConfirmAction => 'Picked up';

  @override
  String get openInGoogleMaps => 'Open in Google Maps';

  @override
  String get googleMapsAppUnavailable =>
      'The Google Maps app isn\'t available on this device, so navigation wasn\'t opened.';

  @override
  String get googleMapsLaunchFailed => 'Couldn\'t open Google Maps. Try again.';

  @override
  String get pickupNavigationUnavailable =>
      'Navigation can\'t be opened because the restaurant location isn\'t available.';

  @override
  String routeDistanceAndTime(String distance, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'Distance $distance km · Estimated time $_temp0';
  }

  @override
  String get routeNotConfigured =>
      'Route calculation hasn\'t been set up yet, so no route or estimated time is shown.';

  @override
  String get routeUnavailable => 'Couldn\'t calculate the route right now.';

  @override
  String get routeNeedsCaptainLocation =>
      'The route appears once your location is found.';

  @override
  String pickupMapSemantics(String restaurant) {
    return 'Pickup map for $restaurant';
  }

  @override
  String get captainMarkerTitle => 'Your location';

  @override
  String get deliveryDestinationHeading => 'Delivery area';

  @override
  String get deliveryAreaUnavailable => 'Delivery area not available';

  @override
  String get homeLogoSemantics => 'SHAHM logo';

  @override
  String get orderDetailsHeading => 'Order details';

  @override
  String get orderDetailCustomerName => 'Customer name';

  @override
  String get orderDetailCustomerPhone => 'Customer phone number';

  @override
  String get orderDetailDeliveryNotes => 'Delivery notes';

  @override
  String get orderDetailFeeUnavailable => 'Delivery fee not available';

  @override
  String orderDetailSemantics(String label, String value) {
    return '$label: $value';
  }

  @override
  String get completedOrderTitle => 'Completed order details';

  @override
  String completedOrderIdLine(String orderId) {
    return 'Order number: $orderId';
  }

  @override
  String completedOrderMerchantLine(String merchant) {
    return 'Restaurant: $merchant';
  }

  @override
  String completedOrderDeliveredAtLine(String time) {
    return 'Delivered at: $time';
  }

  @override
  String get completedOrderUnavailableTitle =>
      'This order\'s details aren\'t available';

  @override
  String get completedOrderUnavailableMessage =>
      'Open “My orders” to refresh the history, then choose the order again.';

  @override
  String get completedOrderBack => 'Back to My orders';

  @override
  String get completedDeliveryOpenHint => 'View order details';

  @override
  String pickedUpFromLine(String merchant) {
    return 'Picked up from $merchant';
  }

  @override
  String get deliveryStatusPickedUp =>
      'The order was picked up. Tap “Start delivery” when you set off.';

  @override
  String get deliveryStatusOnTheWay =>
      'You\'re on your way to the delivery area.';

  @override
  String get startDeliveryAction => 'Start delivery';

  @override
  String get completeDeliveryAction => 'Order delivered';

  @override
  String get completeDeliveryConfirmTitle => 'Confirm order delivery?';

  @override
  String get completeDeliveryConfirmMessage =>
      'Confirm only after you\'ve handed over the order. The delivery will be recorded and the order commission will be deducted from your wallet once.';

  @override
  String get completeDeliveryConfirmAction => 'Confirm delivery';

  @override
  String get orderCommandNotConfigured =>
      'The order service isn\'t connected to the app yet, so the action wasn\'t sent and the order status didn\'t change.';

  @override
  String get orderCommandNoInternet =>
      'No internet connection, so the action wasn\'t sent. Try again.';

  @override
  String get orderCommandUnconfirmed =>
      'The server didn\'t answer in time, so we don\'t know whether the action went through. Check the order status before trying again.';

  @override
  String get orderCommandStateConflict =>
      'The order status changed on the server, so the action wasn\'t carried out. Updating its details.';

  @override
  String get orderCommandCheckStatus => 'Check order status';

  @override
  String get orderCommandCheckFailed =>
      'Couldn\'t check the order status right now. Try again.';

  @override
  String get orderCommandCheckPending =>
      'The server hasn\'t settled the result of the action yet. Check again shortly.';

  @override
  String get orderStatusUnsupportedTitle =>
      'This order status isn\'t supported in this version';

  @override
  String get orderStatusUnsupportedMessage =>
      'Refresh the page, and if the problem continues, contact administration.';

  @override
  String get deliveryCompletedTitle => 'Order delivered';

  @override
  String get deliveryCompletedMessage =>
      'Your orders and wallet are being updated now.';

  @override
  String get orderCancelledTitle => 'The order was cancelled';

  @override
  String get orderReassignedTitle =>
      'The order was assigned to another captain';

  @override
  String get orderEndedMessage => 'This order is no longer one of your tasks.';

  @override
  String get currentOrderBackHome => 'Back to Home';

  @override
  String get completedDeliveriesHeading => 'Completed orders';

  @override
  String get completedDeliveriesLoading => 'Loading completed orders…';

  @override
  String get completedDeliveriesEmpty => 'No completed orders yet.';

  @override
  String get completedDeliveriesNotConfigured =>
      'The order history service isn\'t connected yet, so completed orders can\'t be shown.';

  @override
  String get completedDeliveriesNoSession =>
      'Sign in to see your completed orders.';

  @override
  String get completedDeliveriesNoInternet =>
      'No internet connection. Couldn\'t load completed orders.';

  @override
  String get completedDeliveriesLoadFailed =>
      'Couldn\'t load completed orders right now.';

  @override
  String get completedDeliveriesLoadMore => 'Show more';

  @override
  String get completedDeliveryOutcome => 'Delivered';

  @override
  String completedDeliveryFeeLine(String amount, String currency) {
    return 'Delivery fee: $amount $currency';
  }

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get contactAdministration => 'Contact administration';

  @override
  String get createAccountTitle => 'Create an account';

  @override
  String get createAccountMessage =>
      'To create a SHAHM account, please contact administration.';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get termsUnavailableMessage =>
      'The Terms and Conditions page isn\'t available yet.';

  @override
  String get termsOpenFailedMessage =>
      'Couldn\'t open the Terms and Conditions page in the app. Try again later.';

  @override
  String get debugPreviewButton => 'App preview';

  @override
  String get debugPreviewNote =>
      'Development only — not shown in the release build';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get usernameRequired => 'Enter your username';

  @override
  String get usernameLengthInvalid =>
      'The username must be between 4 and 30 characters.';

  @override
  String get usernameFormatInvalid =>
      'The username can contain only English letters, digits, the underscore (_) and the period.';

  @override
  String get passwordRequired => 'Enter your password';

  @override
  String get passwordLengthInvalid =>
      'The password must be between 8 and 128 characters.';

  @override
  String get invalidPhone => 'The phone number must have 10 digits.';

  @override
  String get toastSuccess => 'Success';

  @override
  String get toastError => 'Error';

  @override
  String get toastWarning => 'Warning';

  @override
  String get toastInfo => 'Info';

  @override
  String toastAnnouncement(String status, String message) {
    return '$status: $message';
  }

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeGreetingNoName => 'Welcome';

  @override
  String homeActiveOrderMessage(String merchant) {
    return 'You have an order in progress from $merchant.';
  }

  @override
  String get homeActiveOrderOpen => 'View current order';

  @override
  String get homeActiveOrderCheckFailed =>
      'Couldn\'t check your current order. This doesn\'t mean you have no order.';

  @override
  String get walletCurrencySymbol => 'JOD';

  @override
  String get walletBalanceUnknownValue => '—';

  @override
  String get availabilityToggleLabel => 'Receive new order offers';

  @override
  String get availabilityStatusAvailable =>
      'You\'re available and may receive new order offers.';

  @override
  String get availabilityStatusUnavailable =>
      'You\'re unavailable and won\'t receive new order offers.';

  @override
  String get availabilityStatusUnknown => 'Availability status unknown.';

  @override
  String get availabilityChecking => 'Checking availability status...';

  @override
  String get availabilityNotConfigured =>
      'Receiving orders can\'t be turned on yet, because the app isn\'t connected to the SHAHM server.';

  @override
  String get availabilityNoSession => 'Sign in to be able to receive orders.';

  @override
  String get availabilityNoInternet =>
      'No internet connection. Check your connection and try again.';

  @override
  String get availabilityRejected =>
      'The server didn\'t confirm turning on order offers. You\'re still unavailable.';

  @override
  String get availabilityPermissionsNotConfigured =>
      'Location and notification permissions aren\'t set up in this version of the app yet.';

  @override
  String get availabilityMissingIntro =>
      'You won\'t become available until you:';

  @override
  String get availabilityNeedLocationService =>
      'Turn on the device\'s location service';

  @override
  String get availabilityNeedPreciseLocation =>
      'Allow access to your precise location';

  @override
  String get availabilityNeedBackgroundLocation =>
      'Allow location access all the time';

  @override
  String get availabilityNeedNotifications => 'Allow notifications';

  @override
  String get availabilityOpenSettings => 'Open Settings';

  @override
  String get availabilityRationaleTitle => 'Permissions needed';

  @override
  String get availabilityRationaleMessage =>
      'To receive new order offers, SHAHM needs your precise location, including while the app runs in the background, and permission to send notifications. If you don\'t allow them, you won\'t become available.';

  @override
  String get availabilityContinue => 'Continue';

  @override
  String get availabilityUnconfirmedWasAvailable =>
      'Couldn\'t confirm the change with the server. Last confirmed status: available.';

  @override
  String get availabilityUnconfirmedWasUnavailable =>
      'Couldn\'t confirm the change with the server. Last confirmed status: unavailable.';

  @override
  String get availabilityRequirementsLost =>
      'One of the required permissions is no longer allowed. You may not receive new offers until you allow it again.';

  @override
  String get offersSectionTitle => 'Orders awaiting acceptance';

  @override
  String offersSectionTitleWithCount(int count) {
    return 'Orders awaiting acceptance ($count)';
  }

  @override
  String get offersSectionSubtitle =>
      'Offers still open to you that no other captain has accepted yet.';

  @override
  String get offersLoading => 'Loading offers...';

  @override
  String get offersNotConfigured =>
      'The order service isn\'t connected yet, so available offers can\'t be shown.';

  @override
  String get offersNoSession => 'Sign in to see the offers available to you.';

  @override
  String get offersEmpty => 'No offers are available to you right now.';

  @override
  String get offersNoInternet =>
      'No internet connection. Check your connection, then refresh the list.';

  @override
  String get offersLoadFailed =>
      'Couldn\'t load offers. Try refreshing shortly.';

  @override
  String get offersAcceptedMessage =>
      'The order was accepted. Follow it in “Current order”.';

  @override
  String get offersDeclinedMessage => 'The offer was declined.';

  @override
  String get offerAccept => 'Accept';

  @override
  String offerPickupLine(String pickup) {
    return 'Restaurant location: $pickup';
  }

  @override
  String get offerPickupUnknown => 'Not available';

  @override
  String offerDeliveryAreaLine(String area) {
    return 'Delivery area: $area';
  }

  @override
  String get offerDeliveryFeeLabel => 'Delivery fee';

  @override
  String offerCardSemantics(
    String merchant,
    String pickup,
    String area,
    String fee,
  ) {
    return 'Order offer from $merchant. Restaurant location: $pickup. Delivery area: $area. Delivery fee: $fee Jordanian dinars.';
  }

  @override
  String get offerNoLongerAvailable =>
      'This offer is no longer available to you. Refresh the list.';

  @override
  String get offerRefused =>
      'The server didn\'t approve this action right now.';

  @override
  String get offerNotConfigured =>
      'The order service isn\'t connected yet; nothing was sent.';

  @override
  String get offerUnconfirmed =>
      'Couldn\'t confirm the action. Refresh the list to check the offer\'s status.';

  @override
  String get previewCaption => 'Design preview — sample data';

  @override
  String get walletTitle => 'Wallet';

  @override
  String get walletTotalBalance => 'Balance';

  @override
  String get walletValueUnknownSemantics => 'Unknown';

  @override
  String get walletDebitHistory => 'Debit history';

  @override
  String get walletHistoryWindowNote =>
      'The history shows commission debits from the last 7 days.';

  @override
  String get walletDeliveredCount => 'Delivered orders';

  @override
  String get walletEarnings => 'Earnings';

  @override
  String get walletMetricsLifetimeNote => 'Since you started';

  @override
  String get walletEarningsUnavailable => 'Not available right now';

  @override
  String get walletMetricsNotConfigured =>
      'The statistics service isn\'t connected yet.';

  @override
  String get walletMetricsLoadFailed => 'Couldn\'t load the statistics.';

  @override
  String walletDebitMerchantLine(String merchant) {
    return 'Restaurant: $merchant';
  }

  @override
  String walletDebitDateLine(String date) {
    return 'Debit date: $date';
  }

  @override
  String walletDebitAmountLine(String amount, String currency) {
    return 'Debit amount (commission): $amount $currency';
  }

  @override
  String get walletFieldUnavailable => 'Not available';

  @override
  String get walletDebitsEmpty => 'No debits in the last 7 days.';

  @override
  String get walletLoading => 'Loading wallet…';

  @override
  String get walletNotConfigured =>
      'The wallet service isn\'t connected yet, so the balance and history can\'t be shown right now.';

  @override
  String get walletNoSession => 'Sign in to see your wallet.';

  @override
  String get walletNoInternet =>
      'No internet connection. Couldn\'t load the wallet.';

  @override
  String get walletLoadFailed => 'Couldn\'t load the wallet. Try again.';

  @override
  String walletDebitSemantics(
    String amount,
    String merchant,
    String area,
    String date,
  ) {
    return 'Commission debit of $amount Jordanian dinars, restaurant: $merchant, delivery area: $area, on $date';
  }

  @override
  String get newOfferSheetTitle => 'New order offer';

  @override
  String get offerKindInstant => 'Now';

  @override
  String get offerKindScheduled => 'Scheduled';

  @override
  String offerScheduledPickupLine(String time) {
    return 'Pickup time: $time';
  }

  @override
  String walletBalanceCardSemantics(String value) {
    return 'Balance: $value';
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
    return 'Rating. $value';
  }

  @override
  String profileRatingSemanticsValue(String value, String max, String count) {
    return 'Rating $value out of $max. $count';
  }

  @override
  String declinedOfferOutcomeWithKind(String kind) {
    return 'You declined this offer · $kind';
  }

  @override
  String get offerValueUnavailable => 'Not available';

  @override
  String get offerGrossFeeLabel => 'Full delivery fee';

  @override
  String get offerEarningsMissing =>
      'Commission details aren\'t available for this offer, so it can\'t be accepted here.';

  @override
  String get offerScheduledAdminOnly =>
      'Scheduled orders are confirmed directly by a supervisor and can\'t be accepted in the app for now.';

  @override
  String get offerAcceptFull => 'Accept order';

  @override
  String get offerLater => 'Later';

  @override
  String get offerAcceptedNotOpened =>
      'The offer was accepted, but the current order couldn\'t be opened right now. You\'ll find it on Home once it\'s available.';

  @override
  String get declinedOffersHeading => 'Offers you declined';

  @override
  String get declinedOffersNote =>
      'Offers declined by you only. Declining an offer doesn\'t cancel the store\'s order.';

  @override
  String get declinedOffersLoading => 'Loading declined offers…';

  @override
  String get declinedOffersNotConfigured =>
      'The declined offers history service isn\'t connected yet.';

  @override
  String get declinedOffersNoSession => 'Sign in to see declined offers.';

  @override
  String get declinedOffersNoInternet =>
      'No internet connection. Couldn\'t load declined offers.';

  @override
  String get declinedOffersLoadFailed =>
      'Couldn\'t load declined offers right now.';

  @override
  String get declinedOffersEmpty => 'No declined offers.';

  @override
  String get declinedOfferGenericTitle => 'Order offer';

  @override
  String get declinedOfferOutcome => 'You declined this offer';

  @override
  String get demoBadge => 'Demo mode — fictional data';

  @override
  String get demoShowNewOffer => 'Show a new order';

  @override
  String get demoTools => 'Demo tools';

  @override
  String get demoToolsHide => 'Hide tools';

  @override
  String get demoScenarioNone => 'No current order';

  @override
  String get demoScenarioAssigned => 'Pre-assigned order';

  @override
  String get demoShowScheduled => 'Scheduled offer (display only)';

  @override
  String get demoReset => 'Reset demo data';

  @override
  String get demoSignOut => 'Sign out of the demo';

  @override
  String get demoFixturesError => 'Couldn\'t load the demo data.';
}
