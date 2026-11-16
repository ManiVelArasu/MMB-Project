import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../network/provider/auth_provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../utils/constants.dart';
import '../../utils/height_measure.dart';
import '../../widgets/button_widget.dart';
import '../../widgets/title_value_widget.dart';

/// Test number (9000000001) kudutha OTP fill aana udane auto-verify aaganuma?
const bool kAutoVerifyTestOtp = true;

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
          provider.fillTestOtpIfNeeded();
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
            // -----------------------------------------------------------
            // AUTO VERIFY: test number + OTP boxes full -> verify API call
            // -----------------------------------------------------------
            if (kAutoVerifyTestOtp && authProvider.shouldAutoVerify) {
              authProvider.markAutoVerifyDone();
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!context.mounted) return;
                debugPrint(
                  "🔥 AUTO VERIFY STARTED, OTP: ${authProvider.getOtp()}",
                );
                final res = await authProvider.verifyOtpApi(context);
                if (res == null) {
                  Fluttertoast.showToast(
                    msg: authProvider.errorMessage ??
                        "OTP verification failed",
                  );
                }
              });
            }

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
              body: Stack(
                children: [
                  SafeArea(
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
                                  "Enter the 6-digit verification code sent to your mobile number.",
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
                                              initialValue: authProvider
                                                  .mobileNumber,
                                              onChanged: authProvider
                                                  .updateMobile,
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
                                            if (authProvider
                                                .mobileError !=
                                                null)
                                              Padding(
                                                padding:
                                                const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  authProvider
                                                      .mobileError!,
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        )
                                            : Text(
                                          authProvider
                                              .mobileNumber.isEmpty
                                              ? "Enter mobile number"
                                              : authProvider
                                              .mobileNumber,
                                          style:
                                          theme.bodyMedium!.copyWith(
                                            color: authProvider
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
                                        final bool isCurrentBox =
                                            authProvider
                                                .controllers[index]
                                                .text
                                                .isEmpty &&
                                                (index == 0 ||
                                                    authProvider
                                                        .controllers[index - 1]
                                                        .text
                                                        .isNotEmpty);

                                        return Container(
                                          width: 50.w,
                                          height: 50.h,
                                          decoration: BoxDecoration(
                                            color: const Color(0xffF8F8F8),
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            border: Border.all(
                                              color: isCurrentBox
                                                  ? customColor.redColor
                                                  : customColor.borderColor,
                                              width: isCurrentBox ? 2.0 : 1.0,
                                            ),
                                          ),
                                          child: Center(
                                            child: authProvider
                                                .controllers[index]
                                                .text
                                                .isEmpty &&
                                                isCurrentBox
                                                ? Container(
                                              width: 12,
                                              height: 2,
                                              color: customColor.redColor,
                                            )
                                                : Text(
                                              authProvider
                                                  .controllers[index]
                                                  .text,
                                              style: theme.bodyLarge!
                                                  .copyWith(
                                                fontWeight:
                                                FontWeight.w600,
                                                color: customColor
                                                    .blackColor,
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
                                          // Number maarina field rebuild aagi
                                          // initialValue refresh aagum
                                          key: ValueKey(
                                            authProvider.mobileNumber,
                                          ),
                                          initialValue: authProvider.isTestNumber
                                              ? AuthProvider.testOtp
                                              : null,
                                          autofocus: true,
                                          keyboardType: TextInputType.number,
                                          autofillHints: const [
                                            AutofillHints.oneTimeCode,
                                          ],
                                          maxLength: 6,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: const InputDecoration(
                                            counterText: '',
                                            border: InputBorder.none,
                                          ),
                                          onChanged: (value) async {
                                            for (int i = 0; i < 6; i++) {
                                              if (i < value.length) {
                                                authProvider
                                                    .controllers[i]
                                                    .text = value[i];
                                              } else {
                                                authProvider.controllers[i]
                                                    .clear();
                                              }
                                            }

                                            authProvider.notifyListeners();

                                            // OTP 6 digits completed
                                            if (value.length == 6 &&
                                                !authProvider.isVerifyLoading) {
                                              debugPrint(
                                                "🔥 onChanged 6 digits -> verify",
                                              );
                                              final res = await authProvider
                                                  .verifyOtpApi(context);
                                              if (res == null) {
                                                Fluttertoast.showToast(
                                                  msg: authProvider
                                                      .errorMessage ??
                                                      "OTP verification failed",
                                                );
                                              }
                                            }
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
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Didn't receive the code?",
                                          style: theme.titleMedium!.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: customColor.baseColor,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: authProvider.isReSendLoading
                                              ? null
                                              : () async {
                                            if (authProvider
                                                .submitLogin()) {
                                              String? otp =
                                              await authProvider
                                                  .reSendOtp(
                                                authProvider.mobileNumber,
                                                "login",
                                              );

                                              if (otp != null &&
                                                  context.mounted) {
                                                final prefs =
                                                await SharedPreferences
                                                    .getInstance();
                                                await prefs.setString(
                                                  'saved_mobile_number',
                                                  authProvider
                                                      .mobileNumber,
                                                );

                                                Fluttertoast.showToast(
                                                  msg:
                                                  "OTP Resent Successfully!",
                                                );
                                              }
                                            }
                                          },
                                          child: authProvider.isReSendLoading
                                              ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child:
                                            CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color:
                                              customColor.redColor,
                                            ),
                                          )
                                              : Text(
                                            "Resend the code",
                                            style: theme.titleMedium!
                                                .copyWith(
                                              fontWeight: FontWeight.w600,
                                              color:
                                              customColor.redColor,
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

                          // CONTINUE button (manual verify / retry)
                          ButtonWidget(
                            isLoading: authProvider.isVerifyLoading,
                            title: "CONTINUE",
                            height: 54.h,
                            textStyle: theme.titleLarge!.copyWith(
                              color: customColor.whiteColor,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: customColor.redColor,
                            ),
                            buttonPress: () async {
                              debugPrint(
                                "🔥 CONTINUE clicked, OTP: ${authProvider.getOtp()}",
                              );

                              if (!authProvider.isOtpComplete()) {
                                Fluttertoast.showToast(
                                  msg: "Enter complete 6-digit OTP",
                                );
                                return;
                              }

                              final res =
                              await authProvider.verifyOtpApi(context);
                              if (res == null) {
                                Fluttertoast.showToast(
                                  msg: authProvider.errorMessage ??
                                      "OTP verification failed",
                                );
                              }
                            },
                          ),
                          height12,
                        ],
                      ),
                    ),
                  ),
                  if (authProvider.isVerifyLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: customColor.redColor,
                          ),
                        ),
                      ),
                    ),
                ],
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
    final currentNumber = authProvider.mobileNumber
        .replaceFirst(RegExp(r'^\+91'), '')
        .trim();

    final controller = TextEditingController(text: currentNumber);

    authProvider.newMobileInput = currentNumber;

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
            controller: controller,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (value) {
              authProvider.setNewMobileInput(value);
            },
            decoration: const InputDecoration(
              counterText: "",
              prefixText: "+91 ",
              hintText: "Enter mobile number",
            ),
            style: theme.bodyMedium!.copyWith(
              color: customColor.baseColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: customColor.redColor,
              ),
              onPressed: () async {
                if (controller.text.length != 10) {
                  Fluttertoast.showToast(
                    msg: "Enter a valid 10-digit mobile number",
                  );
                  return;
                }

                authProvider.setNewMobileInput(controller.text);

                final success = await authProvider.updateAndSaveNewMobile();

                if (!dialogContext.mounted) return;

                if (success) {
                  Navigator.pop(dialogContext);
                  Fluttertoast.showToast(
                    msg: "Mobile number updated successfully!",
                  );
                }
              },
              child: const Text(
                "Save",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    ).then((_) => controller.dispose());
  }
}