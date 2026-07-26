import 'package:flutter/material.dart';


import '../../ui/login/login_screen.dart';
import '../../ui/splash/splash_screen.dart';
// import other screens here

enum AppRoutes {
  splash('/'),
  bottomNav('/bottomNav'),
  logIn('/login');

  final String path;

  const AppRoutes(this.path);
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    print('fucking settings name>>>>${settings.name}');
    switch (settings.name) {
      case '/':
        return _page(const SplashScreen(), settings: settings);
      case '/login':
        return _page(const LoginScreen(), settings: settings);

     /* case '/bottomNav':
        return _page(const BottomNavScreen(), settings: settings);*/
      default:
        return _page(
          const Scaffold(body: Center(child: Text('404 - Page Not Found'))),
        );
    }
  }

  static MaterialPageRoute _page(Widget child, {RouteSettings? settings}) {
    return MaterialPageRoute(builder: (_) => child, settings: settings);
  }
}
