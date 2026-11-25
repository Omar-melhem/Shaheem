// STANDALONE DESIGN PREVIEW (Task 36) — not part of the app.
//
// Run it on its own:
//   flutter run -t lib/preview/new_offer_sheet_preview.dart
//   flutter run -t lib/preview/new_offer_sheet_preview.dart \
//     --dart-define=PREVIEW_OFFER_KIND=scheduled
//
// Nothing in the app imports this file, so it never ships in the app's
// builds. It opens the REAL `NewOrderOfferSheet` over a sample page with
// FICTIONAL offers (an instant one and a scheduled one); the accept-gating
// rules are the app's own (`offerAcceptBlock`). No repository, Cubit,
// session or navigation of the app is involved: «قبول الطلب» and «رفض
// الطلب» only close the sheet, and nothing is sent anywhere.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/theme/app_theme.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/view/navigation/new_offer_sheet_host.dart';
import 'package:mobile_frontend/view/navigation/new_order_offer_sheet.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() => runApp(
  NewOfferSheetPreviewApp(
    autoOpen: const String.fromEnvironment('PREVIEW_OFFER_KIND') == 'scheduled'
        ? OrderOfferKind.scheduled
        : OrderOfferKind.instant,
  ),
);

/// FICTIONAL sample offers, for this preview only (never fetched data).
CaptainOrderOffer previewSampleOffer(OrderOfferKind kind, DateTime now) =>
    switch (kind) {
      OrderOfferKind.instant => const CaptainOrderOffer(
        id: 'preview-instant-1',
        orderId: 'preview-order-1',
        merchantName: 'مثال: مطعم تجريبي',
        pickupLabel: 'منطقة استلام تجريبية',
        deliveryAreaName: 'منطقة تسليم تجريبية',
        deliveryFeeFils: 2500,
        commission: OfferCommissionSnapshot(
          amountFils: 500,
          rateBasisPoints: 2000,
        ),
      ),
      OrderOfferKind.scheduled => CaptainOrderOffer(
        id: 'preview-scheduled-1',
        orderId: 'preview-order-2',
        kind: OrderOfferKind.scheduled,
        merchantName: 'مثال: مقهى تجريبي',
        pickupLabel: 'منطقة استلام تجريبية',
        deliveryAreaName: 'منطقة تسليم تجريبية',
        deliveryFeeFils: 3000,
        scheduledPickupAt: DateTime(now.year, now.month, now.day + 1, 13, 30),
        commission: const OfferCommissionSnapshot(
          amountFils: 600,
          rateBasisPoints: 2000,
        ),
      ),
    };

/// The preview app: the real theme, localization and breakpoints, a
/// caption, and a sample page that opens the sheet.
class NewOfferSheetPreviewApp extends StatelessWidget {
  const NewOfferSheetPreviewApp({super.key, this.autoOpen});

  /// Opens this kind's sample sheet after the first frame (for
  /// screenshots); null opens nothing.
  final OrderOfferKind? autoOpen;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: _SamplePage(autoOpen: autoOpen),
    );
  }
}

/// Opens the real sheet for a sample offer, with the app's gating rules.
Future<void> showPreviewOfferSheet(BuildContext context, OrderOfferKind kind) {
  final offer = previewSampleOffer(kind, DateTime.now());
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: false,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) {
      final block = offerAcceptBlock(offer);
      void close() => Navigator.of(sheetContext).pop();
      return NewOrderOfferSheet(
        offer: offer,
        notice: offerAcceptBlockText(sheetContext.l10n, block),
        onAccept: block == OfferAcceptBlock.none ? close : null,
        onLater: close,
      );
    },
  );
}

/// A plain sample page behind the sheet, with one button per offer kind.
class _SamplePage extends StatefulWidget {
  const _SamplePage({this.autoOpen});

  final OrderOfferKind? autoOpen;

  @override
  State<_SamplePage> createState() => _SamplePageState();
}

class _SamplePageState extends State<_SamplePage> {
  @override
  void initState() {
    super.initState();
    final kind = widget.autoOpen;
    if (kind != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showPreviewOfferSheet(context, kind);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newOfferSheetTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final kind in OrderOfferKind.values) ...[
              AppButton(
                label: kind == OrderOfferKind.instant
                    ? l10n.offerKindInstant
                    : l10n.offerKindScheduled,
                onPressed: () => showPreviewOfferSheet(context, kind),
              ),
              const SizedBox(height: 12),
            ],
          ],
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
