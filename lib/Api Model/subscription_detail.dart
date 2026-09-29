import 'dart:convert';

SubscriptionDetail subscriptionDetailFromJson(String str) =>
    SubscriptionDetail.fromJson(json.decode(str));

String subscriptionDetailToJson(SubscriptionDetail data) =>
    json.encode(data.toJson());

class SubscriptionDetail {
  final bool? success;
  final AccessDetails? data;

  SubscriptionDetail({required this.success, required this.data});

  factory SubscriptionDetail.fromJson(Map<String, dynamic> json) =>
      SubscriptionDetail(
        success: json["success"] ?? false,
        data: json["data"] == null
            ? null
            : AccessDetails.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {"success": success, "data": data?.toJson()};
}

class AccessDetails {
  final bool? hasActiveSubscription;
  final bool? isOnTrial;
  final Period? period;
  final Subscription? subscription;
  final Plan? plan;
  final Billing? billing;
  final List<Feature> features;

  AccessDetails({
    required this.hasActiveSubscription,
    required this.isOnTrial,
    required this.period,
    required this.subscription,
    required this.plan,
    required this.billing,
    required this.features,
  });

  factory AccessDetails.fromJson(Map<String, dynamic> json) => AccessDetails(
    hasActiveSubscription: json["has_active_subscription"] ?? false,
    isOnTrial: json["is_on_trial"] ?? false,
    period: json["period"] == null ? null : Period.fromJson(json["period"]),
    subscription: json["subscription"] == null
        ? null
        : Subscription.fromJson(json["subscription"]),
    plan: json["plan"] == null ? null : Plan.fromJson(json["plan"]),
    billing: json["billing"] == null ? null : Billing.fromJson(json["billing"]),
    features: json["features"] == null
        ? []
        : List<Feature>.from(json["features"].map((x) => Feature.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "has_active_subscription": hasActiveSubscription,
    "is_on_trial": isOnTrial,
    "period": period?.toJson(),
    "subscription": subscription?.toJson(),
    "plan": plan?.toJson(),
    "billing": billing?.toJson(),
    "features": List<dynamic>.from(features.map((x) => x.toJson())),
  };
}

class Billing {
  final String? cycle;
  final String? price;
  final String? currency;

  Billing({required this.cycle, required this.price, required this.currency});

  factory Billing.fromJson(Map<String, dynamic> json) => Billing(
    cycle: json["cycle"]?.toString(),
    price: json["price"]?.toString(),
    currency: json["currency"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "cycle": cycle,
    "price": price,
    "currency": currency,
  };
}

class Feature {
  final String? key;
  final String? label;
  final String? resetPeriod;
  final String? dataType;
  final bool? topupable;
  final String? unit;
  final String? limit;
  final bool? unlimited;
  final String? used;
  final String? topupGranted;
  final String? topupRemaining;
  final String? effectiveLimit;
  final String? remaining;
  final bool? enabled;

  Feature({
    required this.key,
    required this.label,
    required this.resetPeriod,
    required this.dataType,
    required this.topupable,
    this.unit,
    this.limit,
    this.unlimited,
    this.used,
    this.topupGranted,
    this.topupRemaining,
    this.effectiveLimit,
    this.remaining,
    this.enabled,
  });

  factory Feature.fromJson(Map<String, dynamic> json) => Feature(
    key: json["key"]?.toString(),
    label: json["label"]?.toString(),
    resetPeriod: json["reset_period"]?.toString(),
    dataType: json["data_type"]?.toString(),
    topupable: json["topupable"] ?? false,
    unit: json["unit"]?.toString(),
    limit: json["limit"]?.toString(),
    unlimited: json["unlimited"] ?? false,
    used: json["used"]?.toString(),
    topupGranted: json["topup_granted"]?.toString(),
    topupRemaining: json["topup_remaining"]?.toString(),
    effectiveLimit: json["effective_limit"]?.toString(),
    remaining: json["remaining"]?.toString(),
    enabled: json["enabled"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "key": key,
    "label": label,
    "reset_period": resetPeriod,
    "data_type": dataType,
    "topupable": topupable,
    "unit": unit,
    "limit": limit,
    "unlimited": unlimited,
    "used": used,
    "topup_granted": topupGranted,
    "topup_remaining": topupRemaining,
    "effective_limit": effectiveLimit,
    "remaining": remaining,
    "enabled": enabled,
  };
}

class Period {
  final DateTime? start;
  final DateTime? end;

  Period({required this.start, required this.end});

  factory Period.fromJson(Map<String, dynamic> json) => Period(
    start: json["start"] == null ? null : DateTime.parse(json["start"]),
    end: json["end"] == null ? null : DateTime.parse(json["end"]),
  );

  Map<String, dynamic> toJson() => {
    "start":
        "${start?.year.toString().padLeft(4, '0')}-${start?.month.toString().padLeft(2, '0')}-${start?.day.toString().padLeft(2, '0')}",
    "end":
        "${end?.year.toString().padLeft(4, '0')}-${end?.month.toString().padLeft(2, '0')}-${end?.day.toString().padLeft(2, '0')}",
  };
}

class Plan {
  final String? uid;
  final String? name;
  final String? description;
  final String? planType;

  Plan({
    required this.uid,
    required this.name,
    required this.description,
    required this.planType,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    uid: json["uid"]?.toString(),
    name: json["name"]?.toString(),
    description: json["description"]?.toString(),
    planType: json["plan_type"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "name": name,
    "description": description,
    "plan_type": planType,
  };
}

class Subscription {
  final String? uid;
  final String? status;
  final String? subType;
  final bool? autoRenew;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? renewsOn;
  final String? renewalCancelledAt;
  final bool? cancelRenewalAllowed;
  final String? amountPaid;
  final String? paymentGateway;
  final String? paymentMethod;
  final String? paymentMethodDetail;

  Subscription({
    required this.uid,
    required this.status,
    required this.subType,
    required this.autoRenew,
    required this.startsAt,
    required this.endsAt,
    required this.renewsOn,
    required this.renewalCancelledAt,
    required this.cancelRenewalAllowed,
    required this.amountPaid,
    required this.paymentGateway,
    required this.paymentMethod,
    required this.paymentMethodDetail,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    uid: json["uid"]?.toString(),
    status: json["status"]?.toString(),
    subType: json["sub_type"]?.toString(),
    autoRenew: json["auto_renew"] ?? false,
    startsAt: json["starts_at"] == null
        ? null
        : DateTime.parse(json["starts_at"]),
    endsAt: json["ends_at"] == null ? null : DateTime.parse(json["ends_at"]),
    renewsOn: json["renews_on"] == null
        ? null
        : DateTime.parse(json["renews_on"]),
    renewalCancelledAt: json["renewal_cancelled_at"]?.toString(),
    cancelRenewalAllowed: json["cancel_renewal_allowed"] ?? false,
    amountPaid: json["amount_paid"]?.toString(),
    paymentGateway: json["payment_gateway"]?.toString(),
    paymentMethod: json["payment_method"]?.toString(),
    paymentMethodDetail: json["payment_method_detail"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "status": status,
    "sub_type": subType,
    "auto_renew": autoRenew,
    "starts_at": startsAt?.toIso8601String(),
    "ends_at": endsAt?.toIso8601String(),
    "renews_on": renewsOn?.toIso8601String(),
    "renewal_cancelled_at": renewalCancelledAt,
    "cancel_renewal_allowed": cancelRenewalAllowed,
    "amount_paid": amountPaid,
    "payment_gateway": paymentGateway,
    "payment_method": paymentMethod,
    "payment_method_detail": paymentMethodDetail,
  };
}
