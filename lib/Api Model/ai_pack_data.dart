class AiPackPaymentData {
  final String? type;
  final String? orderId;
  final int? amount;
  final String? currency;
  final String? paymentUid;
  final String? packUid;

  AiPackPaymentData({
    this.type,
    this.orderId,
    this.amount,
    this.currency,
    this.paymentUid,
    this.packUid,
  });

  factory AiPackPaymentData.fromJson(Map<String, dynamic> json) {
    return AiPackPaymentData(
      type: json["type"]?.toString(),
      orderId: json["order_id"]?.toString(),
      amount: json["amount"] is int
          ? json["amount"]
          : int.tryParse(json["amount"]?.toString() ?? ""),
      currency: json["currency"]?.toString(),
      paymentUid: json["payment_uid"]?.toString(),
      packUid: json["pack_uid"]?.toString(),
    );
  }
}