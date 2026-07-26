import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_mmb/network/provider/auth_provider.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/utils/height_measure.dart';
import 'package:project_mmb/widgets/button_widget.dart';
import 'package:project_mmb/widgets/title_value_widget.dart';
import 'package:provider/provider.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      children: [
                        TitleValueWidget(
                          title: "OTP Verification",
                          subTitle:
                              "Please enter the 4-digit code received on your registered WhatsApp number",
                        ),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: customColor.borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: authProvider.isEditingMobile
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          TextFormField(
                                            keyboardType: TextInputType.phone,
                                            autofocus: authProvider.isEditingMobile,
                                            initialValue: authProvider.mobileNumber,
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
                                            enabled: authProvider.isEditingMobile,
                                          ),
                        
                                          if (authProvider.mobileError != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                authProvider.mobileError!,
                                                style: TextStyle(
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
                                          color: authProvider.mobileNumber.isEmpty
                                              ? Colors.grey
                                              : customColor.baseColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                        
                              // Edit Icon
                              GestureDetector(
                                onTap: authProvider.toggleMobileEdit,
                                child: SvgPicture.asset(
                                  // authProvider.isEditingMobile ? Icons.check : Icons.edit,
                                  "assets/icons/edit_ic.svg",
                                ),
                              ),
                            ],
                          ),
                        ),
                        height16,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (index) {
                            return Container(
                              width: 72.w,
                              height: 64.h,
                              decoration: BoxDecoration(
                                color: Color(0xffF8F8F8),
                        
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                        
                                child: Center(
                                  child: TextFormField(
                                    style: theme.bodyLarge!.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: customColor.blackColor,
                                    ),
                                    autofocus: true,
                                    controller: authProvider.controllers[index],
                                    focusNode: authProvider.focusNodes[index],
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    maxLength: 1,
                                    textAlign: TextAlign.center,
                                    textInputAction: TextInputAction.next,
                        
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                        
                                      filled: false,
                        
                                      contentPadding: EdgeInsets.only(
                                        top: 10,
                                        bottom: 10,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        if (index < 3) {
                                          FocusScope.of(context).requestFocus(
                                            authProvider.focusNodes[index + 1],
                                          );
                                        } else {
                                          authProvider.focusNodes[index].unfocus();
                                        }
                                      } else if (value.isEmpty && index > 0) {
                                        authProvider.controllers[index].clear();
                                        FocusScope.of(context).requestFocus(
                                          authProvider.focusNodes[index - 1],
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        height12,
                        Center(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),

                            onTap: (){

                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Haven’t received the code?",
                                    style: theme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: customColor.baseColor,
                                    ),
                                  ),
                                  Text(
                                    "Resend OTP",
                                    style: theme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: customColor.redColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      ButtonWidget(
                        buttonPress: () {
                          // if (authProvider.submitLogin()) {
                            // Valid → Continue
                            Navigator.pushNamed(context, "/PlansAndPricingScreen");
                          // }
                        },
                        title: "CONTINUE",
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
                      height24,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
