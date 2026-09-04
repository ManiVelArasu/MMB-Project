import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/theme/app_theme.dart';
import 'package:mmb_app/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Repository/refresh_token.dart';
import 'core/api/api_endpoints.dart';
import 'core/api/api_handler.dart';
import 'core/api/api_interceptor.dart';
import 'core/api/enums/api_content_type.dart';
import 'core/api/enums/toast_position.dart';
import 'network/provider/business_provider.dart';
import 'network/provider/custom_theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ],
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await _initApi();

  await _initializeApp();

  runApp(const MyApp());
}

Future<void> _initializeApp() async {
  final prefs = await SharedPreferences.getInstance();

  final accessToken = prefs.getString('auth_token');
  final refreshToken = prefs.getString('refresh_token');

  debugPrint(
    '🔐 Stored access token: ${accessToken != null}',
  );

  debugPrint(
    '🔄 Stored refresh token: ${refreshToken != null}',
  );

  if (refreshToken != null && refreshToken.isNotEmpty) {
    try {

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final repository = RefreshRepository(refreshDio);
      final result = await repository.refreshToken(
        refreshToken: refreshToken,
      );

      if (result != null) {
        // Save NEW access token
        await prefs.setString(
          'auth_token',
          result.accessToken,
        );

        // Save NEW refresh token
        await prefs.setString(
          'refresh_token',
          result.refreshToken,
        );

        debugPrint('✅ Startup refresh successful');

        await ApiHandler.instance.setTokens(
          token: result.accessToken,
          refreshToken: result.refreshToken,
        );
      } else {
        debugPrint('❌ Startup refresh failed');
      }
    } catch (e) {
      debugPrint('❌ Startup refresh exception: $e');
    }
  }

  // Continue app initialization
}
Future<bool> _refreshSessionOnStartup(
    String refreshToken,
    ) async {
  try {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    final response = await dio.post(
      ApiEndpoints.refreshToken,
      data: {
        'refresh_token': refreshToken,
      },
    );

    final data = response.data;

    if (data is! Map) {
      return false;
    }

    final newAccessToken =
        data['access_token'] ??
            data['accessToken'];

    final newRefreshToken =
        data['refresh_token'] ??
            data['refreshToken'] ??
            refreshToken;

    if (newAccessToken == null ||
        newAccessToken.toString().isEmpty) {
      return false;
    }

    final access = newAccessToken.toString();
    final refresh = newRefreshToken.toString();

    // SharedPreferences + ApiHandler இரண்டிலும் update
    await ApiHandler.instance.setTokens(
      token: access,
      refreshToken: refresh,
    );

    debugPrint('✅ Startup token refresh success');

    return true;
  } on DioException catch (e) {
    debugPrint(
      '❌ Startup refresh error: ${e.response?.statusCode}',
    );

    return false;
  } catch (e) {
    debugPrint('❌ Startup refresh error: $e');

    return false;
  }
}
Future<void> _initApi() async {
  final dioForInterceptor = Dio(
    BaseOptions(baseUrl: ApiEndpoints.baseUrl),
  );

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
