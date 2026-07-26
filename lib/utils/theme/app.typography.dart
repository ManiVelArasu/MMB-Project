import 'package:flutter/material.dart';
import 'app.colors.dart';
import 'app.fonts.dart';

class AppTypography {
  AppTypography._();
  static const String poppins = 'defaultFont';
  static const String outFit = 'Outfit';
  static const String defaultFont=poppins;

  static TextStyle baseStyle = TextStyle(
    fontSize: AppFontSize.fontSize14,
    color: AppColors.appBlack,
  );

  static TextStyle baseTextFieldErrorStyle = TextStyle(
    fontSize: AppFontSize.fontSize11,
    color: AppColors.textFieldErrorColor,
  );
  static TextStyle baseHintStyle = TextStyle(
    fontSize: AppFontSize.fontSize14,
    color: AppColors.textFieldErrorColor,
  );
  static TextStyle baseTextFieldLabelStyle = TextStyle(
    fontSize: AppFontSize.fontSize14,
    color: AppColors.appBlack,
  );
  static TextStyle baseTextFieldHintStyle = TextStyle(
    fontSize: AppFontSize.fontSize14,
    color: AppColors.appBlack,
  );


  static TextStyle errorTitle = TextStyle(
    color: AppColors.appRed,
    fontSize: AppFontSize.fontSize10,
    fontWeight: FontWeight.bold,
  );



  static TextStyle font14w500 = TextStyle(
    fontWeight: FontWeight.w500,
    fontFamily: defaultFont,
    fontSize: AppFontSize.fontSize14,
  );
  static TextStyle header = TextStyle(
    fontWeight: FontWeight.w500,
    fontFamily: defaultFont,
    fontSize: AppFontSize.fontSize12,
  );
  static TextStyle textHeader = TextStyle(
    fontWeight: FontWeight.w500,
    fontFamily: defaultFont,
    fontSize: AppFontSize.fontSize16,
  );
}
