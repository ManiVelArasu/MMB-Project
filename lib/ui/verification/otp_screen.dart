import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project_mmb/network/provider/auth_provider.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/utils/height_measure.dart';
import 'package:project_mmb/widgets/button_widget.dart';
import 'package:project_mmb/widgets/title_value_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../network/provider/business_provider.dart';
import '../../utils/constants.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String receivedOtp = args?['otp'] ?? "";
    final String phone = args?['phone'] ?? "";

    return ChangeNotifierProvider(
      create: (_) {
        final provider = AuthProvider();
        if (phone.isNotEmpty) {
          provider.setMobileNumber(phone);
        } else {
          provider.loadSavedMobileNumber();
        }
        return provider;
      },
      builder: (context, child) {
        final customColor = Provider.of<CustomThemeProvider>(context).colors;
        final theme = Theme.of(context).textTheme;

        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: SvgPicture.asset("assets/icons/back_icon.svg"),
                ),
                backgroundColor: customColor.whiteColor,
                surfaceTintColor: customColor.whiteColor,
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TitleValueWidget(
                              title: "OTP Verification",
                              subTitle:
                                  "Please enter the 6-digit code received on your registered WhatsApp number",
                            ),
                            const SizedBox(height: 10),
                            if (receivedOtp.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  "Your OTP is: $receivedOtp",
                                  style: TextStyle(
                                    color: customColor.redColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: customColor.borderColor,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: authProvider.isEditingMobile
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              TextFormField(
                                                keyboardType:
                                                    TextInputType.phone,
                                                autofocus: authProvider
                                                    .isEditingMobile,
                                                initialValue:
                                                    authProvider.mobileNumber,
                                                onChanged:
                                                    authProvider.updateMobile,
                                                decoration:
                                                    const InputDecoration(
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                                style: theme.bodyMedium!
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          customColor.baseColor,
                                                    ),
                                                enabled: authProvider
                                                    .isEditingMobile,
                                              ),
                                              if (authProvider.mobileError !=
                                                  null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                  child: Text(
                                                    authProvider.mobileError!,
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          )
                                        : Text(
                                            authProvider.mobileNumber.isEmpty
                                                ? "Enter mobile number"
                                                : authProvider.mobileNumber,
                                            style: theme.bodyMedium!.copyWith(
                                              color:
                                                  authProvider
                                                      .mobileNumber
                                                      .isEmpty
                                                  ? Colors.grey
                                                  : customColor.baseColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      _showEditMobileDialog(
                                        context,
                                        authProvider,
                                        customColor,
                                        theme,
                                      );
                                    },
                                    child: SvgPicture.asset(
                                      "assets/icons/edit_ic.svg",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            height16,

                            Stack(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(6, (index) {
                                    return Container(
                                      width: 52.w,
                                      height: 64.h,
                                      decoration: BoxDecoration(
                                        color: const Color(0xffF8F8F8),
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          authProvider.controllers[index].text,
                                          style: theme.bodyLarge!.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: customColor.blackColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),

                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.0,
                                    child: TextFormField(
                                      autofocus: true,
                                      keyboardType: TextInputType.number,
                                      autofillHints: const [
                                        AutofillHints.oneTimeCode,
                                      ],
                                      maxLength: 6,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        counterText: '',
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (value) {
                                        for (int i = 0; i < 6; i++) {
                                          if (i < value.length) {
                                            authProvider.controllers[i].text =
                                                value[i];
                                          } else {
                                            authProvider.controllers[i].clear();
                                          }
                                        }
                                        authProvider.notifyListeners();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            height12,
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Didn't receive the code?",
                                      style: theme.titleMedium!.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: customColor.baseColor,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        print('asdasdsadsads');
                                        if (authProvider.submitLogin()) {
                                          String? otp = await authProvider
                                              .apiSendOtp(
                                                authProvider.mobileNumber,
                                                "login",
                                              );

                                          if (otp != null && context.mounted) {
                                            final prefs =
                                                await SharedPreferences.getInstance();
                                            await prefs.setString(
                                              'saved_mobile_number',
                                              authProvider.mobileNumber,
                                            );

                                            Navigator.pushNamed(
                                              context,
                                              "/OtpScreen",
                                              arguments: {
                                                'otp': otp,
                                                'phone':
                                                    authProvider.mobileNumber,
                                              },
                                            );
                                          } else {}
                                        }
                                      },
                                      child: Text(
                                        "Resend OTP",
                                        style: theme.titleMedium!.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: customColor.redColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          ButtonWidget(
                            isLoading: authProvider.isVerifyLoading,
                            decoration: BoxDecoration(
                              color: customColor.redColor,
                            ),
                            buttonPress: () async {
                              // 🚀 1. OTP வெரிஃபிகேஷன் API-ஐ கால் செய்வது (இதுவே உள்ளே சரியான ஸ்கிரீனுக்கு நேவிகேட் செய்துவிடும்)
                              final responseData = await authProvider
                                  .verifyOtpApi(context);

                              if (!context.mounted) return;

                              if (responseData != null) {
                                String message =
                                    responseData['message'] ??
                                    "OTP Verified Successfully";
                                Fluttertoast.showToast(msg: message);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      authProvider.errorMessage ??
                                          "Invalid OTP",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            title: "CONTINUE",
                          ),
                          height24,
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(12.0.r),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: theme.bodyMedium!.copyWith(
                                    fontSize: 14,
                                  ),
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
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditMobileDialog(
    BuildContext context,
    AuthProvider authProvider,
    CustomColors customColor,
    TextTheme theme,
  ) {
    authProvider.newMobileInput = authProvider.mobileNumber;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: customColor.whiteColor,
          title: Text(
            "Change Mobile Number",
            style: theme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: customColor.baseColor,
            ),
          ),
          content: TextField(
            keyboardType: TextInputType.phone,
            maxLength: 10,
            autofocus: true,
            controller: TextEditingController(text: authProvider.mobileNumber),
            onChanged: (val) => authProvider.setNewMobileInput(val),
            decoration: const InputDecoration(
              counterText: "",
              hintText: "Enter new mobile number",
            ),
            style: theme.bodyMedium!.copyWith(
              color: customColor.baseColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: customColor.redColor,
              ),
              onPressed: () async {
                bool success = await authProvider.updateAndSaveNewMobile();
                if (success) {
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  Fluttertoast.showToast(
                    msg: "Mobile number updated successfully!",
                  );
                }
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
