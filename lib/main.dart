import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/core/api/api_endpoints.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/theme/app_theme.dart';
import 'package:project_mmb/utils/routes.dart';
import 'package:provider/provider.dart';

import 'core/api/api_handler.dart';
import 'core/api/api_interceptor.dart';
import 'core/api/enums/api_content_type.dart';
import 'core/api/enums/toast_position.dart';
import 'network/provider/business_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await _initializeApp();
  runApp(const MyApp());
}

Future<void> _initializeApp() async {
  await _initApi();
}

Future<void> _initApi() async {
  ApiHandler.init(
    baseUrl: ApiEndpoints.baseUrl,
    defaultContentType: ApiContentType.json,
    connectTimeoutMs: 30000,
    receiveTimeoutMs: 30000,
    rethrowExceptions: false,
    showToastOnError: true,
    defaultToastPosition: ApiToastPosition.bottom,
    interceptor: ApiLoggerInterceptor(),
  );
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
            ChangeNotifierProvider(create: (_) => BusinessProvider()),
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
