import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../component/custom_widget.dart';
import '../../network/provider/auth_provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../utils/height_measure.dart';
import '../../widgets/button_widget.dart';
import '../../widgets/title_value_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      builder: (context, child) {
        final customColor = context.watch<CustomThemeProvider>().colors;
        final authProvider = context.watch<AuthProvider>();
        final theme = Theme.of(context).textTheme;

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 180.h,
                  width: double.infinity,
                  child: Image.asset(
                    "assets/images/login.png",
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      height20,
                      const TitleValueWidget(
                        title: "Create your Account",
                        subTitle:
                            "Join thousands of businesses creating professional designs with MMB.",
                        subTitleColor: Colors.red,
                      ),
                      AppText(
                        "Create your account using your mobile number or continue with Google.",
                      ),
                      SizedBox(height: 10),
                      // Title

                      // MOBILE NUMBER FIELD
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: customColor.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mobile number",
                              style: theme.bodySmall!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: customColor.baseColor,
                              ),
                            ),
                            const SizedBox(height: 6),

                            TextFormField(
                              keyboardType: TextInputType.phone,
                              onChanged: authProvider.updateMobile,
                              maxLength: 10,
                              decoration: const InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: theme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: customColor.baseColor,
                              ),
                            ),

                            // Validation error
                            if (authProvider.mobileError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  authProvider.mobileError!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      height12,

                      // OR Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 2,
                              color: customColor.borderColor,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              "or continue with".toUpperCase(),
                              style: theme.bodyLarge!.copyWith(
                                color: customColor.borderColor,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 2,
                              color: customColor.borderColor,
                            ),
                          ),
                        ],
                      ),

                      height12,

                      // Google Button
                      ButtonWidget(
                        buttonPress: () {},
                        title: "Continue with Google",
                        textStyle: theme.titleLarge!.copyWith(
                          color: customColor.blackColor,
                          fontWeight: FontWeight.w600,
                        ),
                        isLeftIconVisible: true,
                        icon: "assets/icons/google_ic.svg",
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: customColor.whiteColor,
                          border: Border.all(color: customColor.borderColor),
                        ),
                        height: 54.h,
                      ),

                      height12,

                      ButtonWidget(
                        isLoading: authProvider.isLoginLoading,
                        buttonPress: () async {
                          debugPrint("🔥 GET OTP clicked");

                          final isValid = authProvider.submitLogin();

                          debugPrint("🔥 submitLogin result: $isValid");

                          if (!isValid) {
                            debugPrint("❌ submitLogin returned FALSE");
                            return;
                          }

                          debugPrint("✅ Calling apiSendOtp...");

                          final otpSent = await authProvider.apiSendOtp(
                            authProvider.mobileNumber,
                            "login",
                          );

                          if (otpSent && context.mounted) {
                            final prefs = await SharedPreferences.getInstance();

                            await prefs.setString(
                              'saved_mobile_number',
                              authProvider.mobileNumber,
                            );

                            Navigator.pushNamed(
                              context,
                              "/OtpScreen",
                              arguments: {
                                'phone': authProvider.mobileNumber,
                              },
                            );
                          }
                        },
                        title: "GET OTP",
                        textStyle: theme.titleLarge!.copyWith(
                          color: customColor.whiteColor,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: customColor.redColor,
                        ),
                        height: 54.h,
                      ),

                      height20,

                      // Terms and Privacy links
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(12.0.r),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: theme.bodyMedium!.copyWith(fontSize: 14),
                              children: [
                                TextSpan(
                                  text: "By continuing, you agree to our ",
                                  style: theme.bodyMedium!.copyWith(
                                    color: customColor.textColor,
                                  ),
                                ),
                                TextSpan(
                                  text: "Terms & Conditions",
                                  style: theme.bodyMedium!.copyWith(
                                    color: customColor.baseColor,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {},
                                ),
                                TextSpan(
                                  text: " and ",
                                  style: theme.bodyMedium!.copyWith(
                                    color: customColor.textColor,
                                  ),
                                ),
                                TextSpan(
                                  text: "Privacy Policy",
                                  style: theme.bodyMedium!.copyWith(
                                    color: customColor.baseColor,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {},
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
