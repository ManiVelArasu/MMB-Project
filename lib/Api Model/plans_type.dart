class PlanResponse {
  final bool success;
  final List<Plan> data;

  PlanResponse({required this.success, required this.data});

  factory PlanResponse.fromJson(Map<String, dynamic> json) {
    return PlanResponse(
      success: json["success"] ?? false,
      data: (json["data"] as List<dynamic>? ?? [])
          .map((e) => Plan.fromJson(e))
          .toList(),
    );
  }
}

class Plan {
  String? id;
  String? uid;
  String? name;
  String? description;
  String? planType;
  String? trialDays;
  String? passPrice;
  String? passDays;
  String? isPopular;
  String? status;
  String? displayOrder;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<PlanBillingOption> planBillingOptions;
  List<PlanFeature> features; // 🚀 JSON-ல் "features" என உள்ளதால் இது சரியாக மாற்றப்பட்டுள்ளது
  List<dynamic> coupons;

  Plan({
    required this.id,
    required this.uid,
    required this.name,
    required this.description,
    required this.planType,
    required this.trialDays,
    required this.passPrice,
    required this.passDays,
    required this.isPopular,
    required this.status,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
    required this.planBillingOptions,
    required this.features,
    required this.coupons,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    name: json["name"]?.toString(),
    description: json["description"]?.toString(),
    planType: json["plan_type"]?.toString(),
    trialDays: json["trial_days"]?.toString(),
    passPrice: json["pass_price"]?.toString(),
    passDays: json["pass_days"]?.toString(),
    isPopular: json["is_popular"]?.toString(),
    status: json["status"]?.toString(),
    displayOrder: json["display_order"]?.toString(),
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.parse(json["updated_at"]),

    // 🚀 JSON-ல் உள்ள "PlanBillingOptions" சரியாகக் கையாளப்பட்டுள்ளது
    planBillingOptions: json["PlanBillingOptions"] == null
        ? []
        : List<PlanBillingOption>.from(
      json["PlanBillingOptions"].map(
            (x) => PlanBillingOption.fromJson(x),
      ),
    ),

    // 🚀 JSON-ல் உள்ள "features" சரியாகக் கையாளப்பட்டுள்ளது
    features: json["features"] == null
        ? []
        : List<PlanFeature>.from(
      json["features"].map((x) => PlanFeature.fromJson(x)),
    ),

    coupons: json["coupons"] == null
        ? []
        : List<dynamic>.from(json["coupons"].map((x) => x)),
  );

  Plan copyWith({
    String? id,
    String? uid,
    String? name,
    String? description,
    String? planType,
    String? trialDays,
    String? passPrice,
    String? passDays,
    String? isPopular,
    String? status,
    String? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PlanBillingOption>? planBillingOptions,
    List<PlanFeature>? features,
    List<dynamic>? coupons,
  }) =>
      Plan(
        id: id ?? this.id,
        uid: uid ?? this.uid,
        name: name ?? this.name,
        description: description ?? this.description,
        planType: planType ?? this.planType,
        trialDays: trialDays ?? this.trialDays,
        passPrice: passPrice ?? this.passPrice,
        passDays: passDays ?? this.passDays,
        isPopular: isPopular ?? this.isPopular,
        status: status ?? this.status,
        displayOrder: displayOrder ?? this.displayOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        planBillingOptions: planBillingOptions ?? this.planBillingOptions,
        features: features ?? this.features,
        coupons: coupons ?? this.coupons,
      );
}

class PlanBillingOption {
  String? id;
  String? planId;
  String? billingCycle;
  String? price;
  String? discountedPrice;
  String? discountLabel;
  String? currency;
  String? razorpayPlanId;
  String? isActive;
  DateTime? createdAt;
  DateTime? updatedAt;

  PlanBillingOption({
    required this.id,
    required this.planId,
    required this.billingCycle,
    required this.price,
    required this.discountedPrice,
    required this.discountLabel,
    required this.currency,
    required this.razorpayPlanId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlanBillingOption.fromJson(Map<String, dynamic> json) =>
      PlanBillingOption(
        id: json["id"]?.toString(),
        planId: json["plan_id"]?.toString(),
        billingCycle: json["billing_cycle"]?.toString(),
        price: json["price"]?.toString(),
        discountedPrice: json["discounted_price"]?.toString(),
        discountLabel: json["discount_label"]?.toString(),
        currency: json["currency"]?.toString(),
        razorpayPlanId: json["razorpay_plan_id"]?.toString(),
        isActive: json["is_active"]?.toString(),
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  PlanBillingOption copyWith({
    String? id,
    String? planId,
    String? billingCycle,
    String? price,
    String? discountedPrice,
    String? discountLabel,
    String? currency,
    String? razorpayPlanId,
    String? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PlanBillingOption(
        id: id ?? this.id,
        planId: planId ?? this.planId,
        billingCycle: billingCycle ?? this.billingCycle,
        price: price ?? this.price,
        discountedPrice: discountedPrice ?? this.discountedPrice,
        discountLabel: discountLabel ?? this.discountLabel,
        currency: currency ?? this.currency,
        razorpayPlanId: razorpayPlanId ?? this.razorpayPlanId,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class PlanFeature {
  String? key;
  String? label;
  String? displayLabel;
  String? value;
  String? dataType;
  bool enabled;
  bool unlimited;
  String? displayOrder;

  PlanFeature({
    required this.key,
    required this.label,
    required this.displayLabel,
    required this.value,
    required this.dataType,
    required this.enabled,
    required this.unlimited,
    required this.displayOrder,
  });

  // 🚀 JSON-ல் உள்ள சரியான கீகளுடன் மேப் செய்யப்பட்டுள்ளது
  factory PlanFeature.fromJson(Map<String, dynamic> json) => PlanFeature(
    key: json["key"]?.toString(),
    label: json["label"]?.toString(),
    displayLabel: json["display_label"]?.toString(),
    value: json["value"]?.toString(),
    dataType: json["data_type"]?.toString(),
    enabled: json["enabled"] ?? false,
    unlimited: json["unlimited"] ?? false,
    displayOrder: json["display_order"]?.toString(),
  );

  PlanFeature copyWith({
    String? key,
    String? label,
    String? displayLabel,
    String? value,
    String? dataType,
    bool? enabled,
    bool? unlimited,
    String? displayOrder,
  }) =>
      PlanFeature(
        key: key ?? this.key,
        label: label ?? this.label,
        displayLabel: displayLabel ?? this.displayLabel,
        value: value ?? this.value,
        dataType: dataType ?? this.dataType,
        enabled: enabled ?? this.enabled,
        unlimited: unlimited ?? this.unlimited,
        displayOrder: displayOrder ?? this.displayOrder,
      );
}

class FeatureType {
  String? id;
  String? key;
  String? label;
  String? description;
  String? resetPeriod;
  String? dataType;
  DateTime? createdAt;

  FeatureType({
    required this.id,
    required this.key,
    required this.label,
    required this.description,
    required this.resetPeriod,
    required this.dataType,
    required this.createdAt,
  });

  factory FeatureType.fromJson(Map<String, dynamic> json) => FeatureType(
    id: json["id"]?.toString(),
    key: json["key"]?.toString(),
    label: json["label"]?.toString(),
    description: json["description"]?.toString(),
    resetPeriod: json["reset_period"]?.toString(),
    dataType: json["data_type"]?.toString(),
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
  );

  FeatureType copyWith({
    String? id,
    String? key,
    String? label,
    String? description,
    String? resetPeriod,
    String? dataType,
    DateTime? createdAt,
  }) =>
      FeatureType(
        id: id ?? this.id,
        key: key ?? this.key,
        label: label ?? this.label,
        description: description ?? this.description,
        resetPeriod: resetPeriod ?? this.resetPeriod,
        dataType: dataType ?? this.dataType,
        createdAt: createdAt ?? this.createdAt,
      );
}
