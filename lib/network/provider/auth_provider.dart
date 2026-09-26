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

  String _formatIndianMobile(String phone) {
    String number = phone.trim();

    number = number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (number.startsWith('+91')) {
      return number;
    }
    if (number.startsWith('91') && number.length == 12) {
      return '+$number';
    }
    if (number.length == 10) {
      return '+91$number';
    }

    return number;
  }

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

    final formattedPhone = _formatIndianMobile(phone);
    _mobileNumber = formattedPhone;

    notifyListeners();

    try {
      final result = await AuthRepository.instance.sendOtp(
        formattedPhone,
        purpose,
      );
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('saved_mobile_number', formattedPhone);

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

    final formattedPhone = _formatIndianMobile(phone);

    _mobileNumber = formattedPhone;

    // Save +91 number
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('saved_mobile_number', formattedPhone);

    notifyListeners();

    try {
      // Send +91 number
      final result = await AuthRepository.instance.sendOtp(
        formattedPhone,
        purpose,
      );

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

  Future<Map<String, dynamic>?> verifyOtpApi(
      BuildContext context,
      ) async {
    final String enteredOtp = getOtp();

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

      return await result.when(
        success: (data) async {
          try {
            debugPrint("================================");
            debugPrint("✅ OTP API SUCCESS");
            debugPrint("API RESPONSE:");
            debugPrint(data.toString());
            debugPrint("================================");

            // ====================================================
            // TOKENS
            // ====================================================

            final String? accessToken =
            data['access_token']?.toString();

            final String? refreshToken =
            data['refresh_token']?.toString();

            if (accessToken == null ||
                accessToken.isEmpty) {
              _errorMessage = "Login token missing";
              _isVerifyLoading = false;
              notifyListeners();
              return null;
            }

            if (refreshToken == null ||
                refreshToken.isEmpty) {
              _errorMessage = "Refresh token missing";
              _isVerifyLoading = false;
              notifyListeners();
              return null;
            }

            // ====================================================
            // USER
            // ====================================================

            final bool isNewUser =
                data['is_new_user'] == true ||
                    data['data']?['is_new_user'] == true;

            // ====================================================
            // ONBOARDING
            // ====================================================

            final dynamic onboardingData =
                data['onboarding'] ??
                    data['data']?['onboarding'];

            String? accountType;

            bool hasBusiness = false;
            bool completed = false;

            if (onboardingData is Map) {
              final dynamic accountTypeValue =
              onboardingData['account_type'];

              if (accountTypeValue != null &&
                  accountTypeValue
                      .toString()
                      .trim()
                      .isNotEmpty) {
                accountType =
                    accountTypeValue
                        .toString()
                        .trim()
                        .toLowerCase();
              }

              hasBusiness =
                  onboardingData['has_business'] == true;

              completed =
                  onboardingData['completed'] == true;
            }

            // ====================================================
            // PREFS
            // ====================================================

            final prefs =
            await SharedPreferences.getInstance();

            // ====================================================
            // IMPORTANT:
            // READ OLD CONTINUE VALUE BEFORE CHANGING ANYTHING
            // ====================================================

            final bool oldContinue =
                prefs.getBool('continue') ?? false;

            debugPrint("================================");
            debugPrint("🔐 OTP FLOW");
            debugPrint("isNewUser     : $isNewUser");
            debugPrint("accountType   : $accountType");
            debugPrint("hasBusiness   : $hasBusiness");
            debugPrint("completed     : $completed");
            debugPrint("oldContinue   : $oldContinue");
            debugPrint("================================");

            // ====================================================
            // SAVE LOGIN DATA
            // ====================================================

            await prefs.setString(
              'access_token',
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

            // ====================================================
            // SAVE ONBOARDING
            // ====================================================

            await prefs.setBool(
              'is_business_completed',
              completed,
            );

            if (accountType != null &&
                accountType.isNotEmpty) {
              await prefs.setString(
                'account_type',
                accountType,
              );
            }

            // ====================================================
            // SET API TOKENS
            // ====================================================

            await ApiHandler.instance.setTokens(
              token: accessToken,
              refreshToken: refreshToken,
            );

            // ====================================================
            // NEW USER
            //
            // Never consider new user as completed just because
            // API has some business data.
            // ====================================================

            if (isNewUser) {
              debugPrint(
                "🆕 NEW USER → PlansAndPricingScreen",
              );

              // New onboarding has not been continued yet.
              await prefs.setBool(
                'continue',
                false,
              );

              _isVerifyLoading = false;
              notifyListeners();

              if (!context.mounted) {
                return data;
              }

              Navigator.pushNamedAndRemoveUntil(
                context,
                "/PlansAndPricingScreen",
                    (route) => false,
              );

              return data;
            }

            // ====================================================
            // EXISTING USER
            // ====================================================

            if (accountType == null ||
                accountType.isEmpty) {
              debugPrint(
                "⚠️ EXISTING USER BUT ACCOUNT TYPE NULL"
                    " → PlansAndPricingScreen",
              );

              _isVerifyLoading = false;
              notifyListeners();

              if (!context.mounted) {
                return data;
              }

              Navigator.pushNamedAndRemoveUntil(
                context,
                "/PlansAndPricingScreen",
                    (route) => false,
              );

              return data;
            }

            // ====================================================
            // FULL ONBOARDING
            // ====================================================

            final bool onboardingCompleted =
                completed &&
                    (
                        accountType == "business"
                            ? hasBusiness
                            : true
                    );

            // ====================================================
            // IMPORTANT NAVIGATION RULE
            //
            // COMPLETE + CONTINUE TRUE
            //      → HOME
            //
            // COMPLETE + CONTINUE FALSE
            //      → BUSINESS DETAILS
            //
            // This handles:
            // user filled data but closed app before Continue.
            // ====================================================

            if (onboardingCompleted &&
                oldContinue) {
              debugPrint(
                "✅ COMPLETE + CONTINUE TRUE"
                    " → CustomBottomNavScreen",
              );

              // Keep it true.
              await prefs.setBool(
                'continue',
                true,
              );

              _isVerifyLoading = false;
              notifyListeners();

              if (!context.mounted) {
                return data;
              }

              Navigator.pushNamedAndRemoveUntil(
                context,
                "/CustomBottomNavScreen",
                    (route) => false,
              );

              return data;
            }

            // ====================================================
            // COMPLETE BUT CONTINUE FALSE
            //
            // Business data exists, but user never pressed
            // Continue.
            //
            // So resume BusinessDetailsScreen.
            // ====================================================

            if (onboardingCompleted &&
                !oldContinue) {
              debugPrint(
                "⚠️ COMPLETE DATA"
                    " BUT CONTINUE FALSE"
                    " → BusinessDetailsScreen",
              );

              // DO NOT set continue true here.
              await prefs.setBool(
                'continue',
                false,
              );

              _isVerifyLoading = false;
              notifyListeners();

              if (!context.mounted) {
                return data;
              }

              Navigator.pushNamedAndRemoveUntil(
                context,
                "/BusinessDetailsScreen",
                    (route) => false,
              );

              return data;
            }

            // ====================================================
            // INCOMPLETE
            // ====================================================

            debugPrint(
              "⚠️ ONBOARDING INCOMPLETE"
                  " → BusinessDetailsScreen",
            );

            await prefs.setBool(
              'continue',
              false,
            );

            _isVerifyLoading = false;
            notifyListeners();

            if (!context.mounted) {
              return data;
            }

            Navigator.pushNamedAndRemoveUntil(
              context,
              "/BusinessDetailsScreen",
                  (route) => false,
            );

            return data;
          } catch (e, stackTrace) {
            debugPrint(
              "❌ OTP SUCCESS HANDLING ERROR: $e",
            );

            debugPrintStack(
              stackTrace: stackTrace,
            );

            _isVerifyLoading = false;
            _errorMessage = e.toString();

            notifyListeners();

            return null;
          }
        },

        failure: (error) {
          _isVerifyLoading = false;
          _errorMessage = error.message;

          debugPrint(
            "❌ OTP VERIFICATION FAILED: "
                "${error.message}",
          );

          notifyListeners();

          return null;
        },
      );
    } catch (e, stackTrace) {
      _isVerifyLoading = false;
      _errorMessage = e.toString();

      debugPrint(
        "❌ OTP API EXCEPTION: $e",
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

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
