class OtpResponseModel {
  final String? message;

  OtpResponseModel({
    this.message,
  });

  factory OtpResponseModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return OtpResponseModel(
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
    };
  }
}