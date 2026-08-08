class OtpResponseModel {
  final String message;
  final String otp;

  OtpResponseModel({required this.message, required this.otp});

  factory OtpResponseModel.fromJson(Map<String, dynamic> json) {
    return OtpResponseModel(
      message: json['message'] ?? "",
      otp: json['otp'] ?? "",
    );
  }
}