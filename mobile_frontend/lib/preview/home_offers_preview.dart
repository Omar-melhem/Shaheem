// STANDALONE DESIGN PREVIEW (Task 26) — not part of the app.
//
// Run it on its own:
//   flutter run -t lib/preview/home_offers_preview.dart
//
// Nothing in the app imports this file (not `main.dart`, the router or any
// feature), so it never ships in the app's builds. It shows the real Home
// screen with FICTIONAL sample offers so the layout of «طلبات بانتظار
// القبول» and `AppOrderOfferCard` can be reviewed and edited without a
// backend. Accept/decline only show the busy state and then the honest
// "service not connected, nothing was sent" message: nothing is accepted
// or declined anywhere.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/domain/use_cases/get_active_order.dart';
import 'package:mobile_frontend/domain/use_cases/get_captain_location.dart';
import 'package:mobile_frontend/data/repositories/active_order_repository_placeholder.dart';
import 'package:mobile_frontend/data/repositories/captain_location_repository_placeholder.dart';
import 'package:mobile_frontend/data/repositories/auth_repository_placeholder.dart';
import 'package:mobile_frontend/data/repositories/availability_permission_gateway_placeholder.dart';
import 'package:mobile_frontend/data/repositories/captain_availability_repository_placeholder.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/domain/errors/order_offer_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/order_offer_repository.dart';
import 'package:mobile_frontend/domain/use_cases/captain_availability.dart';
import 'package:mobile_frontend/domain/use_cases/order_offers.dart';
import 'package:mobile_frontend/domain/use_cases/sign_out.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/app_theme.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/home_availability_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/pending_offers_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/view/home_screen.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() => runApp(const HomeOffersPreviewApp());

/// FICTIONAL sample offers, for this preview only (never fetched data).
const previewSampleOffers = [
  CaptainOrderOffer(
    id: 'preview-1',
    merchantName: 'مطعم السنابل',
    pickupLabel: 'الشميساني',
    deliveryAreaName: 'تلاع العلي',
    deliveryFeeFils: 2500,
  ),
  CaptainOrderOffer(
    id: 'preview-2',
    merchantName: 'مخبز وحلويات الياسمين الشرقية للمناسبات',
    pickupLabel: 'جبل عمّان، الدوار الثالث، بجانب المكتبة العامة',
    deliveryAreaName: 'دابوق — الحي الغربي قرب المدارس الخاصة',
    deliveryFeeFils: 3000,
  ),
  CaptainOrderOffer(
    id: 'preview-3',
    merchantName: 'كافيه الزاوية',
    deliveryAreaName: 'الجبيهة',
    deliveryFeeFils: 1500,
  ),
  CaptainOrderOffer(
    id: 'preview-4',
    merchantName: 'مطبخ البيت',
    pickupLabel: 'خلدا',
    deliveryAreaName: 'أم السماق',
    deliveryFeeFils: 2000,
  ),
];

/// In-memory source for the preview: returns [previewSampleOffers]; every
/// command waits briefly and then reports "not configured" (nothing sent).
class _PreviewOfferRepository implements OrderOfferRepository {
  const _PreviewOfferRepository();

  @override
  Future<List<CaptainOrderOffer>> getEligibleOffers() async =>
      previewSampleOffers;

  @override
  Future<void> acceptOffer(String offerId) => _notSent();

  @override
  Future<void> declineOffer(String offerId) => _notSent();

  static Future<void> _notSent() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    throw const OrderOfferBackendNotConfiguredException();
  }
}

/// The preview app: the real theme, Arabic localization, breakpoints and
/// Home screen, with a persistent caption above it.
class HomeOffersPreviewApp extends StatefulWidget {
  const HomeOffersPreviewApp({super.key});

  @override
  State<HomeOffersPreviewApp> createState() => _HomeOffersPreviewAppState();
}

class _HomeOffersPreviewAppState extends State<HomeOffersPreviewApp> {
  // No user is invented: the session stays unknown (no greeting name).
  final _session = AppSessionCubit(SignOut(const AuthRepositoryPlaceholder()));
  late final _availability = HomeAvailabilityCubit(
    const GetCaptainAvailability(CaptainAvailabilityRepositoryPlaceholder()),
    const ChangeCaptainAvailability(CaptainAvailabilityRepositoryPlaceholder()),
    const AvailabilityPermissionGatewayPlaceholder(),
    () => false,
  );
  // The preview's own sandbox gate (not a captain session).
  late final _offers = PendingOffersCubit(
    const GetEligibleOffers(_PreviewOfferRepository()),
    const AcceptOrderOffer(_PreviewOfferRepository()),
    const DeclineOrderOffer(_PreviewOfferRepository()),
    () => true,
  );

  // The real active-order owner over the "not configured" placeholder, so
  // Home shows no invented order (D-A73).
  late final _currentOrder = CurrentOrderCubit(
    const GetActiveOrder(ActiveOrderRepositoryPlaceholder()),
    const GetCaptainLocation(CaptainLocationRepositoryPlaceholder()),
  );

  @override
  void dispose() {
    _currentOrder.close();
    _offers.close();
    _availability.close();
    _session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _session),
        BlocProvider.value(value: _availability),
        BlocProvider.value(value: _offers),
        BlocProvider.value(value: _currentOrder),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => ResponsiveBreakpoints.builder(
          breakpoints: AppBreakpoints.all,
          child: Column(
            children: [
              const _PreviewCaption(),
              // The caption already covers the status bar; without this
              // the Home app bar would add the top inset a second time.
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: child!,
                ),
              ),
            ],
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

/// Always-visible caption: this is a design preview with sample data.
class _PreviewCaption extends StatelessWidget {
  const _PreviewCaption();

  static const Key captionKey = Key('home-offers-preview-caption');

  @override
  Widget build(BuildContext context) {
    return Material(
      key: captionKey,
      color: AppColor.secondary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              context.l10n.previewCaption,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColor.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
