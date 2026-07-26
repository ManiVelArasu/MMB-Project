import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/network/provider/business_provider.dart';
import 'package:project_mmb/network/provider/auth_provider.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/network/provider/home_screen_provider.dart';
import 'package:project_mmb/theme/app_theme.dart';
import 'package:project_mmb/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'network/provider/bottom_provider.dart';
import 'network/provider/businessprofile_provider.dart';
import 'network/provider/custom_screen_provider.dart';
import 'network/provider/mydownload_provider.dart';
import 'network/provider/smcalender_provider.dart';
import 'network/provider/theme_detail_screen_provider.dart';
import 'network/provider/theme_screen_provider.dart';
import 'network/provider/you_screen_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //await Firebase.initializeApp();
    SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final RouteGenerator _routeGenerator = RouteGenerator();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CustomThemeProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => BusinessProvider()),
            ChangeNotifierProvider(create: (_) => HomeScreenProvider()),
            ChangeNotifierProvider(create: (_) => CustomScreenProvider()),
            ChangeNotifierProvider(create: (_) => BottomNavProvider()),
            ChangeNotifierProvider(create: (_) => ThemesScreenProvider()),
            ChangeNotifierProvider(create: (_) => ThemeDetailProvider()),
            ChangeNotifierProvider(create: (_) => ProfileScreenProvider()),
            ChangeNotifierProvider(create: (_) => BusinessProfileProvider()),
            ChangeNotifierProvider(create: (_) => MyDownloadsProvider()),
            ChangeNotifierProvider(create: (_) => SmCalendarProvider()),
          ],
          child: Consumer<CustomThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'MMB',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,
                onGenerateRoute: _routeGenerator.generateRoute,
                initialRoute: "/SplashScreen",
              );
            },
          ),
        );
      },
    );
  }
}
