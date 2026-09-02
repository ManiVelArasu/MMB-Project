// Only for web
import 'dart:js' as js;
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