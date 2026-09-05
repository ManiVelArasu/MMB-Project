import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Repository/auth_repository.dart';
import '../../core/api/api_handler.dart';
import '../../core/app_provider/my_notifier.dart';
import 'business_provider.dart';

class AuthProvider extends ChangeNotifier with MyNotifier {
  String _mobileNumber = "";
  String? mobileError;
  bool _isEditingMobile = false;

  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  /// get
  String get mobileNumber => _mobileNumber;

  bool get isEditingMobile => _isEditingMobile;

  List<TextEditingController> get controllers => _controllers;

  List<FocusNode> get focusNodes => _focusNodes;

  /// set method

  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool _isLoginLoading = false;
  bool get isLoginLoading => _isLoginLoading;

  bool _isReSendLoading = false;
  bool get isReSendLoading => _isReSendLoading;

  bool _isVerifyLoading = false;
  bool get isVerifyLoading => _isVerifyLoading;

  bool _isResendLoading = false;
  bool get isResendLoading => _isResendLoading;

  String newMobileInput = "";

  void setNewMobileInput(String val) {
    newMobileInput = val;
    notifyListeners();
  }

  // 🚀 புதிய மொபைல் எண்ணை சேமிக்கும் மெத்தட்
  Future<bool> updateAndSaveNewMobile() async {
    if (newMobileInput.trim().length != 10) {
      mobileError = "Enter a valid 10-digit number";
      notifyListeners();
      return false;
    }

    try {
      _mobileNumber = newMobileInput.trim();
      mobileError = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_mobile_number', _mobileNumber);

      _isEditingMobile = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error saving mobile: $e");
      return false;
    }
  }

  // 🚀 லோகவுட் அல்லது புதிய லாகின் போது டேட்டாவை க்ளியர் செய்ய
  Future<void> clearAuthDataForNewLogin() async {
    _mobileNumber = "";
    newMobileInput = "";
    clearOtp();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_mobile_number');
    await prefs.remove('is_logged_in');

    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  bool isOtpComplete() {
    return _controllers.every(
      (controller) => controller.text.trim().isNotEmpty,
    );
  }

  String getOtp() {
    return _controllers.map((controller) => controller.text).join();
  }

  void clearOtp() {
    for (var controller in _controllers) {
      controller.clear();
    }
  }

  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      setLoading(true);

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      setLoading(false);
      onSuccess();
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      onError(e.message ?? "OTP verification failed");
    }
  }

  Future<bool> apiSendOtp(String phone, String purpose) async {
    _isLoginLoading = true;
    _errorMessage = null;
    _mobileNumber = phone.trim();

    notifyListeners();

    try {
      final result = await AuthRepository.instance.sendOtp(phone, purpose);
      _isLoginLoading = false;
      notifyListeners();

      return await result.when(
        success: (data) {
          return true;
        },
        failure: (error) {
          _errorMessage = error.toString();
          notifyListeners();

          return false;
        },
      );
    } catch (e, stackTrace) {
      debugPrint("$stackTrace");

      _isLoginLoading = false;
      _errorMessage = e.toString();

      notifyListeners();

      return false;
    }
  }

  Future<String?> reSendOtp(String phone, String purpose) async {
    _isReSendLoading = true;
    _errorMessage = null;

    _mobileNumber = phone.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_mobile_number', _mobileNumber);

    notifyListeners();

    try {
      final result = await AuthRepository.instance.sendOtp(phone, purpose);

      _isReSendLoading = false;
      notifyListeners();

      return await result.when(
        success: (data) => data.message,
        failure: (error) {
          _errorMessage = error.toString();
          notifyListeners();
          return null;
        },
      );
    } catch (e) {
      _isReSendLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> verifyOtpApi(BuildContext context) async {
    String enteredOtp = getOtp();

    if (enteredOtp.length < 6) {
      _errorMessage = "Please enter complete 6-digit OTP";
      notifyListeners();
      return null;
    }

    _isVerifyLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthRepository.instance.verifyOtp(
        _mobileNumber,
        "login",
        enteredOtp,
        "android",
      );
      _isVerifyLoading = false;
      notifyListeners();

      return await result.when(
        success: (data) async {
          final accessToken = data['access_token']?.toString();
          final refreshToken = data['refresh_token']?.toString();

          final bool isNewUser =
              data['is_new_user'] ??
                  data['data']?['is_new_user'] ??
                  false;

          final onboardingData =
              data['onboarding'] ??
                  data['data']?['onboarding'];

          final String accountType =
              onboardingData?['account_type']?.toString() ?? "";

          final bool hasBusiness =
              onboardingData?['has_business'] ?? false;

          final bool completed =
              onboardingData?['completed'] ?? false;

          // 🔥 Token must exist
          if (accessToken == null || accessToken.isEmpty) {
            debugPrint("❌ Access token missing after OTP verification");

            _errorMessage = "Login token missing";
            _isVerifyLoading = false;
            notifyListeners();

            return null;
          }

          // 🔥 Refresh token must exist
          if (refreshToken == null || refreshToken.isEmpty) {
            debugPrint("❌ Refresh token missing after OTP verification");

            _errorMessage = "Refresh token missing";
            _isVerifyLoading = false;
            notifyListeners();

            return null;
          }

          // 🔥 Save tokens permanently
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString(
            'auth_token',
            accessToken,
          );

          await prefs.setString(
            'refresh_token',
            refreshToken,
          );

          await prefs.setString(
            'saved_mobile_number',
            _mobileNumber.trim(),
          );

          await prefs.setBool(
            'is_new_user',
            isNewUser,
          );

          await prefs.setBool(
            'is_logged_in',
            true,
          );

          await prefs.setBool(
            'is_business_completed',
            completed,
          );

          await prefs.setString(
            'account_type',
            accountType,
          );

          // 🔥 Also update ApiHandler
          await ApiHandler.instance.setTokens(
            token: accessToken,
            refreshToken: refreshToken,
          );

          // 🔥 Verify that SharedPreferences actually saved them
          final savedAccessToken =
          prefs.getString('auth_token');

          final savedRefreshToken =
          prefs.getString('refresh_token');

          debugPrint(
            '✅ Access token saved: '
                '${savedAccessToken != null && savedAccessToken.isNotEmpty}',
          );

          debugPrint(
            '✅ Refresh token saved: '
                '${savedRefreshToken != null && savedRefreshToken.isNotEmpty}',
          );

          _isVerifyLoading = false;
          notifyListeners();

          if (context.mounted) {
            if (completed ||
                (accountType == "business" && hasBusiness)) {
              debugPrint(
                "👉 Navigating to CustomBottomNavScreen",
              );

              Navigator.pushReplacementNamed(
                context,
                "/CustomBottomNavScreen",
              );
            } else {
              debugPrint(
                "👉 Navigating to BusinessDetailsScreen",
              );

              Navigator.pushReplacementNamed(
                context,
                "/BusinessDetailsScreen",
              );
            }
          }

          return data;
        },
        failure: (error) {
          _errorMessage = error.message;
          notifyListeners();
          return null;
        },
      );
    } catch (e) {
      _isVerifyLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> resendOtp({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {}

  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      setLoading(true);
    } catch (e) {
      setLoading(false);
      onError(e.toString());
    }
  }

  void setMobileNumber(String value) {
    _mobileNumber = value;
    notifyListeners();
  }

  void setIsEditingMobile(bool value) {
    _isEditingMobile = value;
    notifyListeners();
  }

  void updateMobile(String value) {
    setMobileNumber(value.trim());

    if (mobileNumber.isEmpty) {
      mobileError = "Mobile number required";
    } else if (mobileNumber.length < 10) {
      mobileError = "Enter valid number";
    } else {
      mobileError = null;
    }

    notifyListeners();
  }

  bool validateMobile() {
    if (mobileNumber.isEmpty) {
      mobileError = "Mobile number is required";
      return false;
    }
    if (mobileNumber.length < 10) {
      mobileError = "Enter a valid 10-digit mobile number";
      return false;
    }

    mobileError = null;
    return true;
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void toggleMobileEdit() {
    if (isEditingMobile && mobileError != null) return;

    setIsEditingMobile(!isEditingMobile);
    notifyListeners();
  }

  bool submitLogin() {
    final isValid = validateMobile();
    notifyListeners();
    return isValid;
  }

  Future<void> loadSavedMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNumber = prefs.getString('saved_mobile_number');
    if (savedNumber != null && savedNumber.isNotEmpty) {
      _mobileNumber = savedNumber;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
  }
}
