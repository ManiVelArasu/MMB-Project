import 'package:flutter/cupertino.dart';


import '../../network/provider/auth_provider.dart';
import '../../network/provider/business_provider.dart';
import '../../network/provider/industry_provider.dart';
import '../rout_config/app_navigator.dart';
import '../rout_config/app_routs.dart' hide AppRouter;
import 'my_notifier.dart';

import 'package:flutter/material.dart';



class LocaleProvider extends ChangeNotifier with MyNotifier {
  late final AuthProvider authProvider = AuthProvider();
  late final BusinessProvider businessProvider = BusinessProvider();
  late final IndustryProvider industryProvider = IndustryProvider();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  LocaleProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));
      final bool isLoggedIn = await _checkSession();

      if (isLoggedIn) {
        AppRouter.pushReplacement(AppRoutes.customBottomNav);
      } else {
        AppRouter.pushReplacement(AppRoutes.login);
      }
    } catch (e) {
      AppRouter.pushReplacement(AppRoutes.login);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _checkSession() async {
    return false;
  }

  @override
  void dispose() {
    authProvider.dispose();
    super.dispose();
  }
}
