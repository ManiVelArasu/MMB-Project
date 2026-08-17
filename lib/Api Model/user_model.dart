class UserResponseModel {
  final bool? success;
  final UserData? data;

  UserResponseModel({this.success, this.data});

  factory UserResponseModel.fromJson(Map<String, dynamic> json) {
    return UserResponseModel(
      success: json['success'] as bool?,
      data: json['data'] != null ? UserData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'data': data?.toJson()};
  }
}

class UserData {
  final String? id;
  final String? uid;
  final String? name;
  final String? email;
  final String? phone;
  final String? accountType;
  final String? onboardingCompletedAt;
  final String? profilePhotoS3Key;
  final String? razorpayCustomerId;
  final String? isActive;
  final String? lastLoginAt;
  final String? createdAt;
  final String? updatedAt;
  final bool? hasPassword;
  final Onboarding? onboarding;

  UserData({
    this.id,
    this.uid,
    this.name,
    this.email,
    this.phone,
    this.accountType,
    this.onboardingCompletedAt,
    this.profilePhotoS3Key,
    this.razorpayCustomerId,
    this.isActive,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
    this.hasPassword,
    this.onboarding,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id']?.toString(),
      uid: json['uid']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      accountType: json['account_type']?.toString(),
      onboardingCompletedAt: json['onboarding_completed_at']?.toString(),
      profilePhotoS3Key: json['profile_photo_s3_key']?.toString(),
      razorpayCustomerId: json['razorpay_customer_id']?.toString(),
      isActive: json['is_active']?.toString(),
      lastLoginAt: json['last_login_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      hasPassword: json['has_password'] ?? false,
      onboarding: json['onboarding'] != null
          ? Onboarding.fromJson(json['onboarding'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'account_type': accountType,
      'onboarding_completed_at': onboardingCompletedAt,
      'profile_photo_s3_key': profilePhotoS3Key,
      'razorpay_customer_id': razorpayCustomerId,
      'is_active': isActive,
      'last_login_at': lastLoginAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'has_password': hasPassword,
      'onboarding': onboarding?.toJson(),
    };
  }
}

class Onboarding {
  final String? accountType;
  final bool? hasBusiness;
  final bool? completed;

  Onboarding({this.accountType, this.hasBusiness, this.completed});

  factory Onboarding.fromJson(Map<String, dynamic> json) {
    return Onboarding(
      accountType: json['account_type']?.toString(),
      hasBusiness: json['has_business'] ?? false,
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_type': accountType,
      'has_business': hasBusiness,
      'completed': completed,
    };
  }
}
