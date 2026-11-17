import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/network/provider/search_provider.dart';
import 'package:mmb_app/theme/app_theme.dart';
import 'package:mmb_app/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'Repository/refresh_token.dart';
import 'core/api/api_endpoints.dart';
import 'core/api/api_handler.dart';
import 'core/api/api_interceptor.dart';
import 'core/api/enums/api_content_type.dart';
import 'core/api/enums/toast_position.dart';
import 'network/provider/bottom_provider.dart';
import 'network/provider/business_provider.dart';
import 'network/provider/custom_theme_provider.dart';
import 'network/provider/common_provider.dart';
import 'network/provider/favorite_provider.dart';
import 'network/provider/plan_provider.dart';

/// Startup-la network/refresh evlo neram wait pannalaam.
/// Athukku mela aana app-a open pannidum (black screen varaadhu).
const Duration _kStartupTimeout = Duration(seconds: 8);

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('❌ FlutterError: ${details.exceptionAsString()}');
      };

      try {
        if (WebViewPlatform.instance == null) {
          WebViewPlatform.instance = AndroidWebViewPlatform();
        }
      } catch (e) {
        debugPrint('❌ WebView init error: $e');
      }

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

      // Startup init fail aanaalum / timeout aanaalum runApp kattaayam call aaganum.
      try {
        await _initApi().timeout(
          _kStartupTimeout,
          onTimeout: () {
            debugPrint('⏱️ Startup init timed out, launching app anyway');
          },
        );
      } catch (e, stackTrace) {
        debugPrint('❌ Startup init error: $e');
        debugPrintStack(stackTrace: stackTrace);
      }

      runApp(const MyApp());
    },
    (error, stackTrace) {
      debugPrint('❌ Uncaught error: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}

/// ApiHandler init + stored tokens load + ore oru thadavai token refresh.
/// (Munnadi _initApi and _initializeApp rendum refresh call pannichu,
/// ippo onnaaga merge pannirukken.)
Future<void> _initApi() async {
  final dioForInterceptor = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));

  ApiHandler.init(
    baseUrl: ApiEndpoints.baseUrl,
    defaultContentType: ApiContentType.json,
    connectTimeoutMs: 30000,
    receiveTimeoutMs: 30000,
    rethrowExceptions: false,
    showToastOnError: true,
    defaultToastPosition: ApiToastPosition.bottom,
    interceptor: TokenRefreshInterceptor(dioForInterceptor),
  );

  final prefs = await SharedPreferences.getInstance();

  // Login 'access_token' nu save pannudhu, main 'auth_token' nu padikkudhu.
  // Rendaiyum check pannurom.
  final accessToken =
      prefs.getString('auth_token') ?? prefs.getString('access_token');
  final refreshToken = prefs.getString('refresh_token');

  debugPrint('🔐 Stored access token: ${accessToken != null}');
  debugPrint('🔄 Stored refresh token: ${refreshToken != null}');

  if (accessToken != null && accessToken.isNotEmpty) {
    await ApiHandler.instance.setTokens(
      token: accessToken,
      refreshToken: refreshToken,
    );
  } else {
    debugPrint('✅ No stored session');
  }

  // Refresh token illana (first install / logout) -> direct-a app open.
  if (refreshToken == null || refreshToken.isEmpty) {
    return;
  }

  try {
    // Separate Dio: 401 interceptor recursion varaama irukka.
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final repository = RefreshRepository(refreshDio);
    final result = await repository.refreshToken(refreshToken: refreshToken);

    if (result == null) {
      debugPrint('❌ Startup refresh failed; keeping stored access token');
      return;
    }

    await ApiHandler.instance.setTokens(
      token: result.accessToken,
      refreshToken: result.refreshToken,
    );

    debugPrint('✅ Startup token refresh completed');
  } catch (e, stackTrace) {
    debugPrint('❌ Startup refresh error: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
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
            ChangeNotifierProvider(create: (_) => BottomNavProvider()),
            ChangeNotifierProvider(create: (_) => CustomThemeProvider()),
            ChangeNotifierProvider(create: (_) => BusinessProvider()),
            ChangeNotifierProvider(create: (_) => PlanProvider()),
            ChangeNotifierProvider(create: (_) => SearchProvider()),
            ChangeNotifierProvider(create: (_) => FavoriteProvider()),
            ChangeNotifierProvider<CommonProvider>(
              create: (_) => CommonProvider.instance,
            ),
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
