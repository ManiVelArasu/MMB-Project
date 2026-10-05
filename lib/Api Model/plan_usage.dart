class PlanUsage {
  final bool? success;
  final PlanUsageDetail? data;

  PlanUsage({required this.success, required this.data});

  factory PlanUsage.fromJson(Map<String, dynamic> json) => PlanUsage(
    success: json["success"] ?? false,
    data: json["data"] == null ? null : PlanUsageDetail.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {"success": success, "data": data?.toJson()};
}

class PlanUsageDetail {
  final Period? period;
  final List<Feature> features;

  PlanUsageDetail({required this.period, required this.features});

  factory PlanUsageDetail.fromJson(Map<String, dynamic> json) => PlanUsageDetail(
    period: json["period"] == null ? null : Period.fromJson(json["period"]),
    features: json["features"] == null
        ? []
        : List<Feature>.from(json["features"].map((x) => Feature.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "period": period?.toJson(),
    "features": List<dynamic>.from(features.map((x) => x.toJson())),
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
  final List<dynamic>? breakdown;
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
    this.breakdown,
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
    breakdown: json["breakdown"] == null
        ? []
        : List<dynamic>.from(json["breakdown"]!.map((x) => x)),
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
    "breakdown": breakdown == null
        ? []
        : List<dynamic>.from(breakdown!.map((x) => x)),
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
