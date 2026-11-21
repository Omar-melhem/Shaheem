// The captain's wallet and delivery statistics as reported by the SHAHM
// backend (client revision D-A74–D-A76).

/// The captain's single wallet balance in integer fils (D-A25, D-A74),
/// exactly as the server reports it. There are no commission holds, so
/// there is no held or "available" part. Nothing is calculated or clamped
/// on the phone: the value may be negative, and an existing balance above
/// the 5,000-fils recharge ceiling (D-A75, enforced by the server on new
/// credits) is shown as reported.
class WalletSummary {
  const WalletSummary({required this.balanceFils});

  /// Confirmed recharge credits minus commission debits and audited
  /// adjustments (server-owned).
  final int balanceFils;
}

/// A final commission debit for a delivered order (`commission_debit`):
/// the one debit the server posts on confirmed delivery completion, never
/// an estimate and never the delivery fee.
class WalletCommissionDebit {
  const WalletCommissionDebit({
    required this.id,
    required this.debitedAt,
    required this.commissionFils,
    this.merchantName,
    this.deliveryAreaName,
    this.orderId,
  });

  /// Stable ledger transaction id.
  final String id;

  /// Server timestamp of the debit.
  final DateTime debitedAt;

  /// The commission debited, in fils (not the delivery fee).
  final int commissionFils;

  /// The order's merchant, if the server provides it.
  final String? merchantName;

  /// The order's delivery **area** (never a customer address or position),
  /// if the server provides it.
  final String? deliveryAreaName;

  /// The linked order, if the server provides it.
  final String? orderId;
}

/// What the Wallet screen shows from the wallet read model: the balance
/// and the commission-debit history (D-A76). Recharge credits stay in the
/// server's immutable ledger; the captain UI does not list them, so this
/// client read model does not carry them.
class WalletOverview {
  const WalletOverview({required this.summary, required this.debits});

  final WalletSummary summary;

  /// Commission debits inside the display window, newest first.
  final List<WalletCommissionDebit> debits;
}

/// The captain's **lifetime** delivery statistics since they started work
/// (D-A76): every successfully completed delivery in their history, not a
/// display window, a page, pending offers or declined offers.
///
/// Read from an explicit server read model (API contract: TO SPECIFY);
/// widgets never derive it from the debit list.
class CaptainDeliveryStatistics {
  const CaptainDeliveryStatistics({
    required this.deliveredCount,
    this.earningsFils,
  }) : assert(deliveredCount >= 0, 'deliveredCount cannot be negative');

  /// Successfully completed deliveries since the captain started work.
  final int deliveredCount;

  /// Lifetime earnings in fils, or null while unavailable. The formula
  /// (gross delivered fees or net after commission) is an open owner
  /// decision (D-P36), so no source fills this yet and the UI shows
  /// "unavailable"; it is never a computed or zero stand-in. Distinct from
  /// the wallet balance and from recharge credits.
  final int? earningsFils;
}
