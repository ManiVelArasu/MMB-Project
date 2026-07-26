import 'package:flutter/cupertino.dart';

import '../utils/global_variables.dart';
import 'app_routs.dart';

class AppRouter {
  AppRouter._();

  //==========================
  // Push
  //==========================

  static Future<T?> push<T>(AppRoutes route, {Object? arguments}) {
    return Navigator.pushNamed<T>(
      GlobalVariables.navigatorKey.currentContext!,
      route.path,
      arguments: arguments,
    );
  }

  //==========================
  // Push Replacement
  //==========================

  static Future<T?> pushReplacement<T, TO>(
    AppRoutes route, {
    Object? arguments,
    TO? result,
  }) {
    return Navigator.pushReplacementNamed<T, TO>(
      GlobalVariables.navigatorKey.currentContext!,
      route.path,
      arguments: arguments,
      result: result,
    );
  }

  //==========================
  // Push And Remove Until
  //==========================

  static Future<T?> pushAndRemoveUntil<T>(
    AppRoutes route, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      GlobalVariables.navigatorKey.currentContext!,
      route.path,
      (_) => false,
      arguments: arguments,
    );
  }

  //==========================
  // Pop
  //==========================

  static void pop<T>([T? result]) {
    Navigator.pop(GlobalVariables.navigatorKey.currentContext!, result);
  }

  //==========================
  // Maybe Pop
  //==========================

  static Future<bool> maybePop<T>([T? result]) {
    return Navigator.maybePop(
      GlobalVariables.navigatorKey.currentContext!,
      result,
    );
  }

  //==========================
  // Can Pop
  //==========================

  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }

  //==========================
  // Pop Until
  //==========================

  static void popUntil(AppRoutes route) {
    Navigator.popUntil(
      GlobalVariables.navigatorKey.currentContext!,
      ModalRoute.withName(route.path),
    );
  }
}
