// Only for web
import 'package:flutter/material.dart';
class FirebaseWebAuth {
  static void initialize() {
    js.context.callMethod('initializeFirebase', []);
  }

  static Future<void> signInWithPhone(
      String phoneNumber, Function(String) onCodeSent) async {

    var result = await js.context.callMethod('signInWithPhone', [phoneNumber]);
    onCodeSent(result['verificationId']);
  }
}