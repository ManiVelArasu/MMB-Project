import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/network/provider/auth_provider.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/ui/verification/otp_screen.dart';
import 'package:project_mmb/utils/height_measure.dart';
import 'package:project_mmb/widgets/button_widget.dart';
import 'package:project_mmb/widgets/title_value_widget.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customColor = context.watch<CustomThemeProvider>().colors;
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                "assets/images/login_img_temp.png",
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    height20,
                    TitleValueWidget(
                      title: "Create your Account",
                      subTitle:
                          "Login with Google or Mobile Number. Enter your country code to create account with mobile number",
                    ),
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
                            decoration: const InputDecoration(
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
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "OR Sign In with",
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

                    // REQUEST OTP (uses provider validation)
                    ButtonWidget(
                      buttonPress: () {
                        // if (authProvider.submitLogin()) {
                          // Valid → Continue
                          Navigator.pushNamed(context, "/OtpScreen");
                        // }
                      },
                      title: "REQUEST OTP",
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
                        padding:   EdgeInsets.all(12.0.r),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: theme.bodyMedium!.copyWith(fontSize: 14),
                            children: [
                              TextSpan(
                                text: "By continuing, you agree to our ",
                                style: theme.bodyMedium!.copyWith(color: customColor.textColor),
                              ),
                              TextSpan(
                                text: "Terms & Conditions",
                                style:  theme.bodyMedium!.copyWith(color: customColor.baseColor),
                                recognizer: TapGestureRecognizer()..onTap = () {},

                              ),
                              TextSpan(
                                text: " and ",
                                style:  theme.bodyMedium!.copyWith(color: customColor.textColor),
                              ),
                              TextSpan(
                                text: "Privacy Policy",
                                style:  theme.bodyMedium!.copyWith(color: customColor.baseColor),
                                recognizer: TapGestureRecognizer()..onTap = () {},
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
      ),
    );
  }
}
