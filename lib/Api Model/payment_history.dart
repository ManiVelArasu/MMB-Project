

class PaymentHistory {
  final bool? success;
  final Data? data;

  PaymentHistory({
    this.success,
    this.data,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];

    return PaymentHistory(
      success: json['success'] as bool? ?? false,
      data: rawData is Map<String, dynamic>
          ? Data.fromJson(rawData)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': data?.toJson(),
  };
}
class Data {
  final List<LastTransaction> items;
  final LastTransaction? lastTransaction;
  final Pagination? pagination;

  Data({
    this.items = const [],
    this.lastTransaction,
    this.pagination,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final rawLastTransaction = json['last_transaction'];
    final rawPagination = json['pagination'];

    return Data(
      items: rawItems is List
          ? rawItems
          .whereType<Map<String, dynamic>>()
          .map((item) => LastTransaction.fromJson(item))
          .toList()
          : const [],

      lastTransaction:
      rawLastTransaction is Map<String, dynamic>
          ? LastTransaction.fromJson(rawLastTransaction)
          : null,

      pagination: rawPagination is Map<String, dynamic>
          ? Pagination.fromJson(rawPagination)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'last_transaction': lastTransaction?.toJson(),
    'pagination': pagination?.toJson(),
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
    this.uid,
    this.description,
    this.purchaseType,
    this.orderType,
    this.date,
    this.amount,
    this.amountBeforeTax,
    this.gstAmount,
    this.currency,
    this.status,
    this.paymentMethod,
    this.paymentMethodDetail,
    this.invoiceNumber,
    this.razorpayPaymentId,
    this.documentsAvailable,
  });

  factory LastTransaction.fromJson(Map<String, dynamic> json) {
    return LastTransaction(
      uid: json['uid']?.toString(),
      description: json['description']?.toString(),
      purchaseType: json['purchase_type']?.toString(),
      orderType: json['order_type']?.toString(),
      date: json['date'] == null
          ? null
          : DateTime.tryParse(json['date'].toString()),
      amount: json['amount']?.toString(),
      amountBeforeTax: json['amount_before_tax']?.toString(),
      gstAmount: json['gst_amount']?.toString(),
      currency: json['currency']?.toString(),
      status: json['status']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      paymentMethodDetail: json['payment_method_detail']?.toString(),
      invoiceNumber: json['invoice_number']?.toString(),
      razorpayPaymentId: json['razorpay_payment_id']?.toString(),
      documentsAvailable: json['documents_available'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'description': description,
    'purchase_type': purchaseType,
    'order_type': orderType,
    'date': date?.toIso8601String(),
    'amount': amount,
    'amount_before_tax': amountBeforeTax,
    'gst_amount': gstAmount,
    'currency': currency,
    'status': status,
    'payment_method': paymentMethod,
    'payment_method_detail': paymentMethodDetail,
    'invoice_number': invoiceNumber,
    'razorpay_payment_id': razorpayPaymentId,
    'documents_available': documentsAvailable,
  };
}

class Pagination {
  final String? page;
  final String? limit;
  final String? total;
  final String? totalPages;

  Pagination({
    this.page,
    this.limit,
    this.total,
    this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page']?.toString(),
      limit: json['limit']?.toString(),
      total: json['total']?.toString(),
      totalPages: json['total_pages']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'page': page,
    'limit': limit,
    'total': total,
    'total_pages': totalPages,
  };
}
