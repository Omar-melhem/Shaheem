// Shell-level presenter of newly arrived order offers (Task 36).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/helper/translation/generated/app_localizations.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/view/navigation/current_order_navigation.dart';
import 'package:mobile_frontend/view/navigation/new_order_offer_sheet.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/home_screen/cubit/pending_offers_cubit.dart';
import 'package:mobile_frontend/view/widget/order/app_order_offer_card.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';

/// Why an offer cannot be accepted from the app even though it is shown.
enum OfferAcceptBlock {
  /// Nothing blocks an informed acceptance.
  none,

  /// A scheduled offer: the approved process is a direct Admin-confirmed
  /// assignment with no in-app acceptance (D-A47 / D-A61). A different
  /// process needs an owner decision and a server contract first.
  scheduledAdminOnly,

  /// The commission snapshot is missing or inconsistent, so the captain
  /// could not see what they would earn.
  earningsMissing,
}

/// Whether (and why not) [offer] may be accepted from the new-offer sheet.
/// Declining is never blocked by these reasons.
OfferAcceptBlock offerAcceptBlock(CaptainOrderOffer offer) {
  if (offer.kind == OrderOfferKind.scheduled) {
    return OfferAcceptBlock.scheduledAdminOnly;
  }
  if (!offer.hasEarningsDisclosure) return OfferAcceptBlock.earningsMissing;
  return OfferAcceptBlock.none;
}

/// The localized explanation for [block]; null for [OfferAcceptBlock.none].
String? offerAcceptBlockText(AppLocalizations l10n, OfferAcceptBlock block) =>
    switch (block) {
      OfferAcceptBlock.none => null,
      OfferAcceptBlock.scheduledAdminOnly => l10n.offerScheduledAdminOnly,
      OfferAcceptBlock.earningsMissing => l10n.offerEarningsMissing,
    };

/// Shows a [NewOrderOfferSheet] above whatever authenticated screen is open
/// (any tab, or a page above the shell) when the server's offer list gains
/// an offer this captain has not seen yet, and turns a confirmed instant
/// acceptance — from the sheet **or** a Home card — into the Current Order
/// page (D-A73).
///
/// Mounted once, in the main shell (`go_router.dart`), under the shell's
/// `PendingOffersCubit`, which stays the only owner of offer data and of
/// the accept/decline commands. This widget keeps only presentation
/// bookkeeping (offer ids), never offer data of its own:
///
/// - **What is new:** the first list the server returns after the shell
///   opens is what Home already shows, so it is only remembered. A later
///   list's ids that were never seen are queued. Ids no longer in the
///   server's list are forgotten, so memory stays bounded by that list.
/// - **When:** one sheet at a time, after the frame, only with a signed-in
///   captain ([hasSession]), only while the app is in the foreground, and
///   only for an offer still in the server's list without a blocking
///   notice. Rebuilds and tab switches never show it again. A sheet that
///   could not be shown while the app was in the background triggers one
///   server read on resume, so the decision uses a fresh list.
/// - **Triggers:** whatever makes the Cubit load (Home opening, returning
///   to Home, resume, refresh). No push or realtime transport exists yet
///   (TO SPECIFY); when one does, an event should only call
///   `PendingOffersCubit.load()`. Nothing here polls or invents offers.
/// - **Closing:** «لاحقاً», the barrier or system back close the sheet
///   without answering (never a decline); the offer stays on Home and is
///   not shown again. While a command runs, the sheet cannot be closed.
/// - **After a confirmed acceptance** of an instant offer (card or sheet):
///   the app-level `CurrentOrderCubit` re-reads the active order (a fresh
///   read, never an older in-flight answer) and the Current Order page is
///   pushed only when the server's active order is this offer's order
///   ([CaptainOrderOffer.orderId]); otherwise a popup says it was accepted
///   but cannot be shown yet. Nothing is accepted twice, and no new sheet
///   opens while this runs. A confirmed decline just closes the sheet.
/// - **An active order supersedes offers:** whenever the authoritative
///   active order is reported (acceptance or foreground recovery), an open
///   sheet is closed without an answer before navigation, so it never stays
///   above the recovered order and nothing is declined.
/// - **Sign-out:** the shell (and this widget) leave the tree; an open sheet
///   is removed. A lost session reported by the Cubit does the same.
class NewOfferSheetHost extends StatefulWidget {
  const NewOfferSheetHost({
    super.key,
    required this.hasSession,
    required this.child,
  });

  /// Whether a real captain session exists right now.
  final bool Function() hasSession;

  /// The shell's content (the navigation bar and its branches).
  final Widget child;

  @override
  State<NewOfferSheetHost> createState() => _NewOfferSheetHostState();
}

/// How a sheet ended; null when it was closed without an answer.
enum _SheetOutcome { accepted, declined }

class _NewOfferSheetHostState extends State<NewOfferSheetHost> {
  late final AppLifecycleListener _lifecycle;

  /// Ids in the server's latest list that need no sheet (already shown,
  /// already on Home when the shell opened, or queued).
  final Set<String> _known = {};

  /// Whether the first server list was received.
  bool _baselined = false;

  /// New offer ids waiting for a sheet, oldest first.
  final List<String> _queue = [];

  /// The sheet that is open, if any.
  ModalBottomSheetRoute<_SheetOutcome>? _open;

  bool _presentScheduled = false;

  /// While a confirmed acceptance is being turned into Current Order, no
  /// new sheet is presented.
  bool _handlingAcceptance = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    final route = _open;
    _open = null;
    if (route != null) {
      // The navigator may be mid-update (sign-out redirect); remove the
      // sheet after the frame unless the redirect already did.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.isActive) route.navigator?.removeRoute(route);
      });
    }
    super.dispose();
  }

  void _onResume() {
    if (_queue.isEmpty || _open != null || !widget.hasSession()) return;
    // Re-read before deciding: the queued offers may be gone by now.
    unawaited(context.read<PendingOffersCubit>().load());
  }

  void _onOffers(BuildContext context, PendingOffersState state) {
    if (state.status == PendingOffersStatus.noSession) {
      _reset();
      return;
    }
    if (state.status != PendingOffersStatus.loaded) return;
    final ids = {for (final o in state.offers) o.id};
    if (!_baselined) {
      _baselined = true;
      _known.addAll(ids);
      return;
    }
    for (final id in ids) {
      if (_known.add(id)) _queue.add(id);
    }
    _known.retainAll(ids);
    _queue.retainWhere(ids.contains);
    _schedulePresent();
  }

  /// Forgets everything and closes an open sheet (no session any more).
  void _reset() {
    _known.clear();
    _queue.clear();
    _baselined = false;
    final route = _open;
    _open = null;
    if (route != null && route.isActive) route.navigator?.removeRoute(route);
  }

  void _schedulePresent() {
    if (_presentScheduled) return;
    _presentScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _presentScheduled = false;
      unawaited(_presentNext());
    });
  }

  Future<void> _presentNext() async {
    if (!mounted || _open != null || _queue.isEmpty || _handlingAcceptance) {
      return;
    }
    if (!widget.hasSession()) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    final cubit = context.read<PendingOffersCubit>();
    final state = cubit.state;
    if (state.status != PendingOffersStatus.loaded) return;

    CaptainOrderOffer? offer;
    while (offer == null && _queue.isNotEmpty) {
      final id = _queue.removeAt(0);
      final match = state.offers.where((o) => o.id == id).firstOrNull;
      if (match != null && !(state.notices[id]?.blocksActions ?? false)) {
        offer = match;
      }
    }
    if (offer == null) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final route = ModalBottomSheetRoute<_SheetOutcome>(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _LiveOfferSheet(initialOffer: offer!),
      ),
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      barrierLabel: MaterialLocalizations.of(context).scrimLabel,
      isScrollControlled: true,
      useSafeArea: true,
      // No drag-to-close: a drag bypasses the "not while a command runs"
      // rule. The barrier, system back and «لاحقاً» close it instead.
      enableDrag: false,
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
    _open = route;
    await navigator.push(route);
    if (_open == route) _open = null;
    if (!mounted) return;
    // A confirmed acceptance is handled by [_onAcceptConfirmed] (for the
    // sheet and the Home cards alike).
    _schedulePresent();
  }

  /// Whether [previous] → [current] is the end of a server-confirmed
  /// acceptance (the offer left the list with the "accepted" message).
  static bool _acceptConfirmed(
    PendingOffersState previous,
    PendingOffersState current,
  ) {
    final pending = previous.pending;
    return pending != null &&
        pending.action == OfferAction.accept &&
        current.pending == null &&
        current.message == PendingOffersMessage.accepted &&
        !current.offers.any((o) => o.id == pending.offerId);
  }

  /// The accepted offer, as it was listed before the acceptance.
  CaptainOrderOffer? _acceptedOffer;

  void _rememberAccepted(BuildContext context, PendingOffersState previous) {
    final id = previous.pending?.offerId;
    _acceptedOffer = previous.offers.where((o) => o.id == id).firstOrNull;
  }

  /// After a confirmed instant acceptance (card or sheet): pushes Current
  /// Order only for the matching authoritative active order, otherwise says
  /// why it is not shown. Scheduled offers are never accepted in the app.
  Future<void> _onAcceptConfirmed() async {
    final offer = _acceptedOffer;
    _acceptedOffer = null;
    if (offer == null || offer.kind != OrderOfferKind.instant) return;
    _handlingAcceptance = true;
    try {
      final l10n = context.l10n;
      final current = await context.read<CurrentOrderCubit>().refreshed();
      if (!mounted || current == null || !widget.hasSession()) return;
      final orderId = offer.orderId;
      if (current is CurrentOrderActive &&
          orderId != null &&
          current.order.orderId == orderId) {
        openCurrentOrderPage(context);
        return;
      }
      await showAppPopup<void>(
        context,
        message: l10n.offerAcceptedNotOpened,
        actions: [AppPopupAction(label: l10n.close)],
      );
    } finally {
      _handlingAcceptance = false;
      if (mounted) _schedulePresent();
    }
  }

  /// Closes an open sheet without an answer (never a decline): an
  /// authoritative active order supersedes it.
  void _onActiveOrder(BuildContext context, CurrentOrderState state) {
    final route = _open;
    if (route == null) return;
    _open = null;
    if (route.isActive) route.navigator?.removeRoute(route);
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<PendingOffersCubit, PendingOffersState>(listener: _onOffers),
      BlocListener<PendingOffersCubit, PendingOffersState>(
        listenWhen: (previous, current) {
          final confirmed = _acceptConfirmed(previous, current);
          if (confirmed) _rememberAccepted(context, previous);
          return confirmed;
        },
        listener: (context, state) => unawaited(_onAcceptConfirmed()),
      ),
      BlocListener<CurrentOrderCubit, CurrentOrderState>(
        listenWhen: (previous, current) => current is CurrentOrderActive,
        listener: _onActiveOrder,
      ),
    ],
    child: widget.child,
  );
}

/// The sheet's content, kept in step with the shell's `PendingOffersCubit`:
/// busy state, notices and availability come from the server's answers.
class _LiveOfferSheet extends StatelessWidget {
  const _LiveOfferSheet({required this.initialOffer});

  /// The offer as it was when the sheet opened; shown if it leaves the
  /// server's list meanwhile (with its actions off).
  final CaptainOrderOffer initialOffer;

  String get _id => initialOffer.id;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<PendingOffersCubit>();
    return BlocConsumer<PendingOffersCubit, PendingOffersState>(
      // A command for this offer just ended.
      listenWhen: (previous, current) =>
          previous.pending?.offerId == _id && current.pending == null,
      listener: (context, state) {
        if (state.offers.any((o) => o.id == _id)) return; // Not confirmed.
        final outcome = switch (state.message) {
          PendingOffersMessage.accepted => _SheetOutcome.accepted,
          PendingOffersMessage.declined => _SheetOutcome.declined,
          null => null,
        };
        // Only while this sheet is still the top route: the host may have
        // closed it already because an active order superseded it.
        if (outcome != null && (ModalRoute.of(context)?.isCurrent ?? false)) {
          Navigator.of(context).pop(outcome);
        }
      },
      builder: (context, state) {
        final live = state.offers.where((o) => o.id == _id).firstOrNull;
        final offer = live ?? initialOffer;
        final pending = state.pending;
        final busy = pending != null && pending.offerId == _id
            ? switch (pending.action) {
                OfferAction.accept => AppOfferCardAction.accept,
                OfferAction.decline => AppOfferCardAction.decline,
              }
            : null;
        final cardNotice = state.notices[_id];
        final loaded = state.status == PendingOffersStatus.loaded;
        final gone = loaded && live == null;
        // Another command (e.g. from Home), a refresh or a blocking notice
        // keeps both answers off.
        final ready =
            loaded &&
            live != null &&
            pending == null &&
            !(cardNotice?.blocksActions ?? false);
        final block = offerAcceptBlock(offer);
        final notice =
            switch (cardNotice) {
              OfferCardNotice.noLongerAvailable => l10n.offerNoLongerAvailable,
              OfferCardNotice.refused => l10n.offerRefused,
              OfferCardNotice.notConfigured => l10n.offerNotConfigured,
              OfferCardNotice.unconfirmed => l10n.offerUnconfirmed,
              null => null,
            } ??
            (gone ? l10n.offerNoLongerAvailable : null) ??
            offerAcceptBlockText(l10n, block);
        return PopScope(
          canPop: pending == null,
          child: NewOrderOfferSheet(
            offer: offer,
            busyAction: busy,
            notice: notice,
            onAccept: ready && block == OfferAcceptBlock.none
                ? () => unawaited(cubit.accept(_id))
                : null,
            onDecline: ready ? () => unawaited(cubit.decline(_id)) : null,
            onLater: () => Navigator.of(context).maybePop(),
          ),
        );
      },
    );
  }
}
