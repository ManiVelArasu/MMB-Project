import 'dart:convert';

Language meApiFromJson(String str) => Language.fromJson(json.decode(str));

String meApiToJson(Language data) => json.encode(data.toJson());

class Language {
  final bool success;
  final GetMe data;

  Language({required this.success, required this.data});

  factory Language.fromJson(Map<String, dynamic> json) => Language(
    success: json["success"] ?? false,
    data: json["data"] != null ? GetMe.fromJson(json["data"]) : GetMe.empty(),
  );

  Map<String, dynamic> toJson() => {"success": success, "data": data.toJson()};
}

class GetMe {
  final String? id;
  final String? uid;
  final String? name;
  final String? email;
  final String? phone;
  final String? accountType;
  final DateTime? onboardingCompletedAt;
  final String? profilePhotoS3Key;
  final String? razorpayCustomerId;
  final String? isActive;
  final String? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool hasPassword;
  final Onboarding? onboarding;

  GetMe({
    required this.id,
    required this.uid,
    required this.name,
    this.email,
    required this.phone,
    required this.accountType,
    this.onboardingCompletedAt,
    this.profilePhotoS3Key,
    this.razorpayCustomerId,
    required this.isActive,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
    required this.hasPassword,
    required this.onboarding,
  });

  factory GetMe.empty() => GetMe(
    id: "",
    uid: "",
    name: "",
    email: null,
    phone: "",
    accountType: "",
    onboardingCompletedAt: null,
    profilePhotoS3Key: null,
    razorpayCustomerId: null,
    isActive: "",
    lastLoginAt: null,
    createdAt: null,
    updatedAt: null,
    hasPassword: false,
    onboarding: Onboarding.empty(),
  );

  factory GetMe.fromJson(Map<String, dynamic> json) => GetMe(
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    name: json["name"]?.toString(),
    email: json["email"]?.toString(),
    phone: json["phone"]?.toString(),
    accountType: json["account_type"]?.toString(),
    onboardingCompletedAt: json["onboarding_completed_at"] != null
        ? DateTime.tryParse(json["onboarding_completed_at"])
        : null,
    profilePhotoS3Key: json["profile_photo_s3_key"]?.toString(),
    razorpayCustomerId: json["razorpay_customer_id"]?.toString(),
    isActive: json["is_active"]?.toString(),
    lastLoginAt: json["last_login_at"]?.toString(),
    createdAt: json["created_at"] != null
        ? DateTime.tryParse(json["created_at"])
        : null,
    updatedAt: json["updated_at"] != null
        ? DateTime.tryParse(json["updated_at"])
        : null,
    hasPassword: json["has_password"] ?? false,
    onboarding: json["onboarding"] != null
        ? Onboarding.fromJson(json["onboarding"])
        : Onboarding.empty(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "name": name,
    "email": email,
    "phone": phone,
    "account_type": accountType,
    "onboarding_completed_at": onboardingCompletedAt?.toIso8601String(),
    "profile_photo_s3_key": profilePhotoS3Key,
    "razorpay_customer_id": razorpayCustomerId,
    "is_active": isActive,
    "last_login_at": lastLoginAt,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "has_password": hasPassword,
    "onboarding": onboarding?.toJson(),
  };
}

class Onboarding {
  final String? accountType;
  final bool hasBusiness;
  final bool completed;

  Onboarding({
    required this.accountType,
    required this.hasBusiness,
    required this.completed,
  });

  factory Onboarding.empty() =>
      Onboarding(accountType: "", hasBusiness: false, completed: false);

  factory Onboarding.fromJson(Map<String, dynamic> json) => Onboarding(
    accountType: json["account_type"]?.toString(),
    hasBusiness: json["has_business"] ?? false,
    completed: json["completed"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "account_type": accountType,
    "has_business": hasBusiness,
    "completed": completed,
  };
}
