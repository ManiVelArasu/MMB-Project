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
  List<PlanFeature> planFeatures;
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
    required this.planFeatures,
    required this.coupons,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    name: json["name"]?.toString(),
    description: json["description"]?.toString(),
    planType: json["planType"]?.toString(),
    trialDays: json["trialDays"]?.toString(),
    passPrice: json["passPrice"]?.toString(),
    passDays: json["passDays"]?.toString(),
    isPopular: json["isPopular"]?.toString(),
    status: json["status"]?.toString(),
    displayOrder: json["displayOrder"]?.toString(),
    createdAt: json["createdAt"] == null
        ? null
        : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null
        ? null
        : DateTime.parse(json["updatedAt"]),
    planBillingOptions: json["planBillingOptions"] == null
        ? []
        : List<PlanBillingOption>.from(
            json["planBillingOptions"].map(
              (x) => PlanBillingOption.fromJson(x),
            ),
          ),
    planFeatures: json["planFeatures"] == null
        ? []
        : List<PlanFeature>.from(
            json["planFeatures"].map((x) => PlanFeature.fromJson(x)),
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
    List<PlanFeature>? planFeatures,
    List<dynamic>? coupons,
  }) => Plan(
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
    planFeatures: planFeatures ?? this.planFeatures,
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
        planId: json["planId"]?.toString(),
        billingCycle: json["billingCycle"]?.toString(),
        price: json["price"]?.toString(),
        discountedPrice: json["discountedPrice"]?.toString(),
        discountLabel: json["discountLabel"]?.toString(),
        currency: json["currency"]?.toString(),
        razorpayPlanId: json["razorpayPlanId"]?.toString(),
        isActive: json["isActive"]?.toString(),
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.parse(json["updatedAt"]),
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
  }) => PlanBillingOption(
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
  String? id;
  String? planId;
  String? featureTypeId;
  String? value;
  String? displayLabel;
  String? displayOrder;
  String? showOnCard;
  FeatureType? featureType;

  PlanFeature({
    required this.id,
    required this.planId,
    required this.featureTypeId,
    required this.value,
    required this.displayLabel,
    required this.displayOrder,
    required this.showOnCard,
    required this.featureType,
  });

  factory PlanFeature.fromJson(Map<String, dynamic> json) => PlanFeature(
    id: json["id"]?.toString(),
    planId: json["planId"]?.toString(),
    featureTypeId: json["featureTypeId"]?.toString(),
    value: json["value"]?.toString(),
    displayLabel: json["displayLabel"]?.toString(),
    displayOrder: json["displayOrder"]?.toString(),
    showOnCard: json["showOnCard"]?.toString(),
    featureType: json["featureType"] == null
        ? null
        : FeatureType.fromJson(json["featureType"]),
  );

  PlanFeature copyWith({
    String? id,
    String? planId,
    String? featureTypeId,
    String? value,
    String? displayLabel,
    String? displayOrder,
    String? showOnCard,
    FeatureType? featureType,
  }) => PlanFeature(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    featureTypeId: featureTypeId ?? this.featureTypeId,
    value: value ?? this.value,
    displayLabel: displayLabel ?? this.displayLabel,
    displayOrder: displayOrder ?? this.displayOrder,
    showOnCard: showOnCard ?? this.showOnCard,
    featureType: featureType ?? this.featureType,
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
    resetPeriod: json["resetPeriod"]?.toString(),
    dataType: json["dataType"]?.toString(),
    createdAt: json["createdAt"] == null
        ? null
        : DateTime.parse(json["createdAt"]),
  );

  FeatureType copyWith({
    String? id,
    String? key,
    String? label,
    String? description,
    String? resetPeriod,
    String? dataType,
    DateTime? createdAt,
  }) => FeatureType(
    id: id ?? this.id,
    key: key ?? this.key,
    label: label ?? this.label,
    description: description ?? this.description,
    resetPeriod: resetPeriod ?? this.resetPeriod,
    dataType: dataType ?? this.dataType,
    createdAt: createdAt ?? this.createdAt,
  );
}
