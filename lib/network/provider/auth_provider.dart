import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_mmb/core/app_provider/my_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Repository/auth_repository.dart';
import '../../core/api/api_repository.dart';

class AuthProvider extends ChangeNotifier with MyNotifier {
  //final FirebaseAuth _auth = FirebaseAuth.instance;
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

      //await _auth.signInWithCredential(credential);

      setLoading(false);

      onSuccess();
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      onError(e.message ?? "OTP verification failed");
    }
  }

  Future<Map<String, dynamic>?> verifyOtpApi() async {
    String enteredOtp = getOtp();

    if (enteredOtp.length < 6) {
      _errorMessage = "Please enter complete 6-digit OTP";
      notifyListeners();
      return null;
    }

    setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthRepository.instance.verifyOtp(
        _mobileNumber,
        "login",
        enteredOtp,
        "string",
      );
      print(result);
      setLoading(false);

      return result.when(
        success: (data) {
          notifyListeners();
          return data;
        },
        failure: (error) {
          _errorMessage = error.message ?? "Verification failed";
          notifyListeners();
          return null;
        },
      );
    } catch (e) {
      setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> resendOtp({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    /*await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (e) {
        onError(e.message ?? "Verification failed");
      },
      codeSent: (verificationId, _) {
        clearOtp();
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );*/
  }
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      setLoading(true);

      /*await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,

        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          setLoading(false);
        },

        verificationFailed: (FirebaseAuthException e) {
          setLoading(false);
          onError(e.message ?? "Verification failed");
        },

        codeSent: (String verificationId, int? resendToken) {
          setLoading(false);
          onCodeSent(verificationId);
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          setLoading(false);
        },

        timeout: const Duration(seconds: 60),
      );*/
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

  Future<String?> apiSendOtp(String phone, String purpose) async {
    setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthRepository.instance.sendOtp(phone, purpose);

      setLoading(false);

      return result.when(
        success: (data) => data.otp,
        failure: (error) {
          _errorMessage = error.toString();
          notifyListeners();
          return null;
        },
      );
    } catch (e) {
      setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

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
