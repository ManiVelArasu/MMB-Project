class AiTopUp {
  final bool? success;
  final List<AiTopUpData> data;
  final Meta? meta;

  AiTopUp({required this.success, required this.data, required this.meta});

  factory AiTopUp.fromJson(Map<String, dynamic> json) => AiTopUp(
    success: json["success"] ?? false,
    data: json["data"] == null
        ? []
        : List<AiTopUpData>.from(
            json["data"].map((x) => AiTopUpData.fromJson(x)),
          ),
    meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "meta": meta?.toJson(),
  };
}

class AiTopUpData {
  final String? id;
  final String? uid;
  final String? featureTypeId;
  final String? name;
  final String? description;
  final String? quantity;
  final String? price;
  final String? strikePrice;
  final String? badge;
  final String? displayOrder;
  final String? status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final FeatureType? featureType;
  final Feature? feature;
  final String? gstAmount;
  final String? totalPrice;

  AiTopUpData({
    required this.id,
    required this.uid,
    required this.featureTypeId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.price,
    required this.strikePrice,
    required this.badge,
    required this.displayOrder,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.featureType,
    required this.feature,
    required this.gstAmount,
    required this.totalPrice,
  });

  factory AiTopUpData.fromJson(Map<String, dynamic> json) => AiTopUpData(
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    featureTypeId: json["feature_type_id"]?.toString(),
    name: json["name"]?.toString(),
    description: json["description"]?.toString(),
    quantity: json["quantity"]?.toString(),
    price: json["price"]?.toString(),
    strikePrice: json["strike_price"]?.toString(),
    badge: json["badge"]?.toString(),
    displayOrder: json["display_order"]?.toString(),
    status: json["status"]?.toString(),
    createdBy: json["created_by"]?.toString(),
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.parse(json["updated_at"]),
    featureType: json["FeatureType"] == null
        ? null
        : FeatureType.fromJson(json["FeatureType"]),
    feature: json["feature"] == null ? null : Feature.fromJson(json["feature"]),
    gstAmount: json["gst_amount"]?.toString(),
    totalPrice: json["total_price"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "feature_type_id": featureTypeId,
    "name": name,
    "description": description,
    "quantity": quantity,
    "price": price,
    "strike_price": strikePrice,
    "badge": badge,
    "display_order": displayOrder,
    "status": status,
    "created_by": createdBy,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "FeatureType": featureType?.toJson(),
    "feature": feature?.toJson(),
    "gst_amount": gstAmount,
    "total_price": totalPrice,
  };
}

class Feature {
  final String? key;
  final String? label;
  final String? unit;

  Feature({required this.key, required this.label, required this.unit});

  factory Feature.fromJson(Map<String, dynamic> json) => Feature(
    key: json["key"]?.toString(),
    label: json["label"]?.toString(),
    unit: json["unit"]?.toString(),
  );

  Map<String, dynamic> toJson() => {"key": key, "label": label, "unit": unit};
}

class FeatureType {
  final String? id;
  final String? key;
  final String? label;
  final String? resetPeriod;
  final String? dataType;
  final String? isTopupable;

  FeatureType({
    required this.id,
    required this.key,
    required this.label,
    required this.resetPeriod,
    required this.dataType,
    required this.isTopupable,
  });

  factory FeatureType.fromJson(Map<String, dynamic> json) => FeatureType(
    id: json["id"]?.toString(),
    key: json["key"]?.toString(),
    label: json["label"]?.toString(),
    resetPeriod: json["reset_period"]?.toString(),
    dataType: json["data_type"]?.toString(),
    isTopupable: json["is_topupable"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "key": key,
    "label": label,
    "reset_period": resetPeriod,
    "data_type": dataType,
    "is_topupable": isTopupable,
  };
}

class Meta {
  final String? total;

  Meta({required this.total});

  factory Meta.fromJson(Map<String, dynamic> json) =>
      Meta(total: json["total"]?.toString());

  Map<String, dynamic> toJson() => {"total": total};
}
