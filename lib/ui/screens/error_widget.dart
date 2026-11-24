
import 'package:flutter/material.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:mmb_app/widgets/button_widget.dart';

class CommonEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String imagePath;
  final String? topMessage;
  final String primaryButtonText;
  final String secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final Color foregroundColor;
  final Color subtitleColor;
  final Color primaryColor;
  final bool isDark;

  const CommonEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.imagePath,
    required this.primaryButtonText,
    required this.secondaryButtonText,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
    required this.foregroundColor,
    required this.subtitleColor,
    this.primaryColor = Colors.red,
    this.topMessage,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (topMessage != null && topMessage!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              topMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
              ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            imagePath,
                            width: 140,
                            height: 140,
                            errorBuilder: (_, __, ___) {
                              return const Icon(
                                Icons.image_not_supported,
                                size: 100,
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          AppText(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: foregroundColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppText(
                            message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: foregroundColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ButtonWidget(
                                  buttonPress: onPrimaryPressed,
                                  title: primaryButtonText,
                                  buttonColor: AppColors.appRed,
                                  textColor: Colors.white,
                                  textStyle: TextStyle(fontSize: AppFontSize.fontSize13,fontWeight: FontWeight.w600,color: AppColors.appWhite),

                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child:ButtonWidget(
                                  buttonPress: onSecondaryPressed,
                                  title: secondaryButtonText,
                                  buttonColor: AppColors.appRed,
                                  textStyle: TextStyle(fontSize: AppFontSize.fontSize13,fontWeight: FontWeight.w600,color: AppColors.appWhite),


                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
