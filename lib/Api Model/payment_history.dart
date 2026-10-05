

class PaymentHistory {
  final bool? success;
  final Data? data;

  PaymentHistory({
    required this.success,
    required this.data,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) => PaymentHistory(
    success: json["success"]??false,
    data:json["data"]==null?null: Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data?.toJson(),
  };
}

class Data {
  final List<LastTransaction> items;
  final LastTransaction? lastTransaction;
  final Pagination? pagination;

  Data({
    required this.items,
    required this.lastTransaction,
    required this.pagination,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    items: List<LastTransaction>.from(json["items"].map((x) => LastTransaction.fromJson(x))),
    lastTransaction: LastTransaction.fromJson(json["last_transaction"]),
    pagination: Pagination.fromJson(json["pagination"]),
  );

  Map<String, dynamic> toJson() => {
    "items": List<dynamic>.from(items.map((x) => x.toJson())),
    "last_transaction": lastTransaction?.toJson(),
    "pagination": pagination?.toJson(),
  };
}

class LastTransaction {
  final String? uid;
  final String? description;
  final String? purchaseType;
  final String? orderType;
  final DateTime? date;
  final String? amount;
  final String? amountBeforeTax;
  final String? gstAmount;
  final String? currency;
  final String? status;
  final String? paymentMethod;
  final String? paymentMethodDetail;
  final String? invoiceNumber;
  final String? razorpayPaymentId;
  final bool? documentsAvailable;

  LastTransaction({
    required this.uid,
    required this.description,
    required this.purchaseType,
    required this.orderType,
    required this.date,
    required this.amount,
    required this.amountBeforeTax,
    required this.gstAmount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.paymentMethodDetail,
    required this.invoiceNumber,
    required this.razorpayPaymentId,
    required this.documentsAvailable,
  });

  factory LastTransaction.fromJson(Map<String, dynamic> json) => LastTransaction(
    uid: json["uid"]?.toString(),
    description: json["description"]?.toString(),
    purchaseType: json["purchase_type"]?.toString(),
    orderType: json["order_type"]?.toString(),
    date:json["date"]==null?null: DateTime.parse(json["date"]),
    amount: json["amount"]?.toString(),
    amountBeforeTax: json["amount_before_tax"]?.toString(),
    gstAmount: json["gst_amount"]?.toString(),
    currency: json["currency"]?.toString(),
    status: json["status"]?.toString(),
    paymentMethod: json["payment_method"]?.toString(),
    paymentMethodDetail: json["payment_method_detail"]?.toString(),
    invoiceNumber: json["invoice_number"]?.toString(),
    razorpayPaymentId: json["razorpay_payment_id"]?.toString(),
    documentsAvailable: json["documents_available"]??false,
  );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "description": description,
    "purchase_type": purchaseType,
    "order_type": orderType,
    "date": date?.toIso8601String(),
    "amount": amount,
    "amount_before_tax": amountBeforeTax,
    "gst_amount": gstAmount,
    "currency": currency,
    "status": status,
    "payment_method": paymentMethod,
    "payment_method_detail": paymentMethodDetail,
    "invoice_number": invoiceNumber,
    "razorpay_payment_id": razorpayPaymentId,
    "documents_available": documentsAvailable,
  };
}

class Pagination {
  final String? page;
  final String? limit;
  final String? total;
  final String? totalPages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    page: json["page"]?.toString(),
    limit: json["limit"]?.toString(),
    total: json["total"]?.toString(),
    totalPages: json["total_pages"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "page": page,
    "limit": limit,
    "total": total,
    "total_pages": totalPages,
  };
}
