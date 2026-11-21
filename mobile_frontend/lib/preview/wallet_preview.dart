// STANDALONE DESIGN PREVIEW (Task 34) — not part of the app.
//
// Run it on its own:
//   flutter run -t lib/preview/wallet_preview.dart
//
// Nothing in the app imports this file, so it never ships in the app's
// builds. It shows the real Wallet screen and cards with FICTIONAL sample
// data (D-A74–D-A76: one balance, two lifetime metric cards, commission
// debits) so the layout can be reviewed without a backend. Nothing here is
// a real balance, debit or statistic; the earnings card stays "unavailable"
// because its formula is an open owner decision (D-P36).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/domain/entities/wallet.dart';
import 'package:mobile_frontend/domain/repositories/wallet_repository.dart';
import 'package:mobile_frontend/domain/use_cases/get_wallet.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/app_theme.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/cubit/wallet_cubit.dart';
import 'package:mobile_frontend/view/screens/wallet_screen/view/wallet_screen.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() => runApp(const WalletPreviewApp());

/// FICTIONAL sample wallet, for this preview only (never fetched data).
/// A negative balance shows how a debt is displayed.
WalletOverview previewSampleWallet(DateTime now) => WalletOverview(
  summary: const WalletSummary(balanceFils: -500),
  debits: [
    WalletCommissionDebit(
      id: 'preview-debit-1',
      debitedAt: now.subtract(const Duration(hours: 5)),
      commissionFils: 500,
      merchantName: 'مطعم السنابل',
      deliveryAreaName: 'تلاع العلي',
    ),
    WalletCommissionDebit(
      id: 'preview-debit-2',
      debitedAt: now.subtract(const Duration(days: 1, hours: 2)),
      commissionFils: 600,
      merchantName: 'مخبز وحلويات الياسمين الشرقية للمناسبات والأفراح',
      deliveryAreaName: 'دابوق — الحي الغربي قرب المدارس الخاصة',
    ),
    WalletCommissionDebit(
      id: 'preview-debit-3',
      debitedAt: now.subtract(const Duration(days: 3)),
      commissionFils: 400,
      merchantName: 'كافيه الزاوية',
    ),
  ],
);

/// In-memory source for the preview: returns [previewSampleWallet].
class _PreviewWalletRepository implements WalletRepository {
  const _PreviewWalletRepository();

  @override
  Future<WalletOverview> getWallet({required DateTime historySinceUtc}) async =>
      previewSampleWallet(DateTime.now().toUtc());

  /// FICTIONAL lifetime count; earnings stay unavailable (D-P36).
  @override
  Future<CaptainDeliveryStatistics> getDeliveryStatistics() async =>
      const CaptainDeliveryStatistics(deliveredCount: 128);
}

/// The preview app: the real theme, Arabic localization, breakpoints and
/// Wallet screen, with a caption.
class WalletPreviewApp extends StatefulWidget {
  const WalletPreviewApp({super.key});

  @override
  State<WalletPreviewApp> createState() => _WalletPreviewAppState();
}

class _WalletPreviewAppState extends State<WalletPreviewApp> {
  // The preview's own sandbox gate (not a captain session).
  final _wallet = WalletCubit(
    const GetWallet(_PreviewWalletRepository()),
    const GetDeliveryStatistics(_PreviewWalletRepository()),
    () => true,
  );

  late final _router = GoRouter(
    initialLocation: RoutesString.wallet,
    routes: [
      GoRoute(
        path: RoutesString.wallet,
        builder: (context, state) => const WalletScreen(),
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    _wallet.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _wallet,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: _router,
        builder: (context, child) => ResponsiveBreakpoints.builder(
          breakpoints: AppBreakpoints.all,
          child: Column(
            children: [
              const _PreviewCaption(),
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
      ),
    );
  }
}

/// Always-visible caption: this is a design preview with sample data.
class _PreviewCaption extends StatelessWidget {
  const _PreviewCaption();

  @override
  Widget build(BuildContext context) {
    return Material(
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
