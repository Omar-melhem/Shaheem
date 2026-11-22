// R04 (ARCH-06): the per-operation timeout policy documented in
// docs/architecture/GLOBAL_SERVICES.md ("Timeout classification").
//
// Reads: a timeout is the service not answering — the read's "service
// unavailable" outcome where its contract has one, otherwise its retryable
// failure; never "offline", never "not configured", never empty/zero.
// Commands: a timeout is an unknown outcome — never success, never
// rejection. Each case is compared with known offline, a server rejection,
// no backend and a real success, using test-only repositories.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/domain/entities/captain_account.dart';
import 'package:mobile_frontend/domain/entities/declined_offer.dart';
import 'package:mobile_frontend/domain/entities/order_offer.dart';
import 'package:mobile_frontend/domain/entities/wallet.dart';
import 'package:mobile_frontend/domain/errors/captain_account_exceptions.dart';
import 'package:mobile_frontend/domain/errors/order_history_exceptions.dart';
import 'package:mobile_frontend/domain/errors/order_offer_exceptions.dart';
import 'package:mobile_frontend/domain/errors/wallet_exceptions.dart';
import 'package:mobile_frontend/domain/repositories/captain_account_repository.dart';
import 'package:mobile_frontend/domain/repositories/order_history_repository.dart';
import 'package:mobile_frontend/domain/repositories/order_offer_repository.dart';
import 'package:mobile_frontend/domain/repositories/wallet_repository.dart';
import 'package:mobile_frontend/domain/use_cases/captain_account.dart';
import 'package:mobile_frontend/domain/use_cases/get_declined_offers.dart';
import 'package:mobile_frontend/domain/use_cases/get_wallet.dart';
import 'package:mobile_frontend/domain/use_cases/order_offers.dart';
import 'package:mobile_frontend/view/screens/settings_screen/cubit/account_deletion_cubit.dart';

/// How the next repository call behaves.
sealed class _Mode {
  const _Mode();
}

/// Never answers (the use case's timeout fires).
final class _Hang extends _Mode {
  const _Hang();
}

/// Throws [error].
final class _Throw extends _Mode {
  const _Throw(this.error);
  final Object error;
}

/// Answers normally.
final class _Answer extends _Mode {
  const _Answer();
}

/// One test-only source for every repository whose timeout is classified.
class _Repo
    implements
        WalletRepository,
        OrderOfferRepository,
        OrderHistoryRepository,
        CaptainAccountRepository {
  _Mode mode = const _Answer();

  Future<T> _run<T>(T Function() value) {
    switch (mode) {
      case _Hang():
        return Completer<T>().future;
      case _Throw(:final error):
        return Future<T>.error(error);
      case _Answer():
        return Future.value(value());
    }
  }

  @override
  Future<WalletOverview> getWallet({required DateTime historySinceUtc}) => _run(
    () => const WalletOverview(
      summary: WalletSummary(balanceFils: 0),
      debits: [],
    ),
  );

  @override
  Future<CaptainDeliveryStatistics> getDeliveryStatistics() =>
      _run(() => const CaptainDeliveryStatistics(deliveredCount: 0));

  @override
  Future<List<CaptainOrderOffer>> getEligibleOffers() => _run(() => []);

  @override
  Future<void> acceptOffer(String offerId) => _run(() {});

  @override
  Future<void> declineOffer(String offerId) => _run(() {});

  @override
  Future<List<DeclinedOfferRecord>> getDeclinedOffers() => _run(() => []);

  @override
  Future<CaptainRating> getRating() =>
      _run(() => const CaptainRating(ratingsCount: 0));

  @override
  Future<AccountDeletionStatus> requestAccountDeletion() =>
      _run(() => AccountDeletionStatus.pending);
}

const _short = Duration(milliseconds: 1);

void main() {
  late _Repo repo;
  setUp(() => repo = _Repo());

  group('reads: timeout = retryable failure, distinct from offline', () {
    test('wallet', () async {
      final read = GetWallet(repo, timeout: _short);
      repo.mode = const _Hang();
      expect(await read(), isA<WalletFailure>());
      repo.mode = const _Throw(WalletNetworkUnavailableException());
      expect(await read(), isA<WalletNoInternet>());
      repo.mode = const _Throw(WalletBackendNotConfiguredException());
      expect(await read(), isA<WalletNotConfigured>());
      repo.mode = const _Answer();
      final loaded = await read();
      expect(loaded, isA<WalletLoaded>());
      expect((loaded as WalletLoaded).overview.summary.balanceFils, 0);
    });

    test('lifetime statistics', () async {
      final read = GetDeliveryStatistics(repo, timeout: _short);
      repo.mode = const _Hang();
      expect(await read(), isA<DeliveryStatisticsFailure>());
      repo.mode = const _Throw(WalletNetworkUnavailableException());
      expect(await read(), isA<DeliveryStatisticsNoInternet>());
      repo.mode = const _Answer();
      expect(await read(), isA<DeliveryStatisticsLoaded>());
    });

    test('eligible offers (timeout is never "no offers")', () async {
      final read = GetEligibleOffers(repo, timeout: _short);
      repo.mode = const _Hang();
      expect(await read(), isA<EligibleOffersFailure>());
      repo.mode = const _Throw(OrderOfferNetworkUnavailableException());
      expect(await read(), isA<EligibleOffersNoInternet>());
      repo.mode = const _Answer();
      expect(await read(), isA<EligibleOffersLoaded>());
    });

    test('declined offers (timeout is never "empty")', () async {
      final read = GetDeclinedOffers(repo, timeout: _short);
      repo.mode = const _Hang();
      expect(await read(), isA<DeclinedOffersFailure>());
      repo.mode = const _Throw(OrderHistoryNetworkUnavailableException());
      expect(await read(), isA<DeclinedOffersNoInternet>());
      repo.mode = const _Answer();
      expect(await read(), isA<DeclinedOffersLoaded>());
    });

    test('rating', () async {
      final read = GetCaptainRating(repo, timeout: _short);
      repo.mode = const _Hang();
      expect(await read(), isA<RatingFailure>());
      repo.mode = const _Throw(CaptainAccountNetworkUnavailableException());
      expect(await read(), isA<RatingNoInternet>());
      repo.mode = const _Answer();
      expect(await read(), isA<RatingLoaded>());
    });
  });

  group('commands: timeout = unknown outcome', () {
    for (final (name, send) in [
      ('accept', (_Repo r) => AcceptOrderOffer(r, timeout: _short)('o1')),
      ('decline', (_Repo r) => DeclineOrderOffer(r, timeout: _short)('o1')),
    ]) {
      test('$name: timeout is unconfirmed, not success or rejection', () async {
        repo.mode = const _Hang();
        expect(await send(repo), isA<OfferCommandUnconfirmed>());
        repo.mode = const _Throw(OrderOfferRefusedException());
        expect(await send(repo), isA<OfferCommandRefused>());
        repo.mode = const _Throw(OrderOfferNoLongerAvailableException());
        expect(await send(repo), isA<OfferCommandNoLongerAvailable>());
        repo.mode = const _Throw(OrderOfferBackendNotConfiguredException());
        expect(await send(repo), isA<OfferCommandNotConfigured>());
        repo.mode = const _Answer();
        expect(await send(repo), isA<OfferCommandConfirmed>());
      });
    }

    test('account deletion: timeout is unconfirmed — neither deleted nor '
        '"not sent"; offline stays "not sent"', () async {
      final send = RequestAccountDeletion(repo, timeout: _short);
      repo.mode = const _Hang();
      expect(await send(), isA<AccountDeletionUnconfirmed>());
      repo.mode = const _Throw(CaptainAccountNetworkUnavailableException());
      expect(await send(), isA<AccountDeletionNoInternet>());
      repo.mode = const _Throw(
        CaptainAccountReauthenticationRequiredException(),
      );
      expect(await send(), isA<AccountDeletionReauthenticationRequired>());
      repo.mode = const _Answer();
      expect(await send(), isA<AccountDeletionPending>());
    });

    test('deletion flow: unconfirmed keeps the session and blocks a '
        'second submission from the same screen', () async {
      var sessionEnded = false;
      final cubit = AccountDeletionCubit(
        RequestAccountDeletion(repo, timeout: _short),
        onCompleted: () async => sessionEnded = true,
        onReauthenticate: () async => sessionEnded = true,
      );
      addTearDown(cubit.close);
      repo.mode = const _Hang();
      await cubit.submitConfirmed();
      expect(cubit.state, AccountDeletionFlow.unconfirmed);
      expect(cubit.canSubmit, isFalse);
      expect(sessionEnded, isFalse);
    });
  });
}
