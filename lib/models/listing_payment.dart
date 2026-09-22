/// Hali ya malipo ya ada ya kutangaza nyumba (TZS 5,000) kupitia
/// ClickPesa (USSD-PUSH) - kama ilivyorudishwa na backend
/// (`/payments/listing-fee/...`).
class ListingPayment {
  const ListingPayment({
    required this.txRef,
    required this.status,
    required this.amount,
    required this.currency,
    this.channel,
    this.used = false,
  });

  final String txRef;

  /// 'pending' | 'successful' | 'failed'
  final String status;
  final int amount;
  final String currency;

  /// Mtandao wa simu ulioombwa kutuma ombi la USSD-PUSH, mfano
  /// "M-PESA", "TIGO-PESA", "AIRTEL-MONEY", "HALOPESA" - hutumika
  /// kumwambia muuzaji aangalie simu yake ya mtandao gani.
  final String? channel;

  /// True endapo malipo haya tayari yametumika kutuma tangazo (tx_ref
  /// haiwezi kutumika mara ya pili).
  final bool used;

  bool get isSuccessful => status == 'successful';
  bool get isFailed => status == 'failed';
  bool get isPending => status == 'pending';

  factory ListingPayment.fromJson(Map<String, dynamic> json) => ListingPayment(
        txRef: json['tx_ref'] as String,
        status: json['status'] as String,
        amount: json['amount'] as int,
        currency: json['currency'] as String,
        channel: json['channel'] as String?,
        used: json['used'] as bool? ?? false,
      );
}
