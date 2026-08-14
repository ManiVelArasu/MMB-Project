import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static Color primaryColor = const Color(0xffED2024);

  ///RGB COLORS-------->
  static const Color appRed = Color(0xffFF0000);
  static const Color appGreen = Color(0xff00FF00);
  static const Color appBlue = Color(0xff0000FF);
  static Color appGrey = const Color(0xff808080);
  static Color litePink = const Color(0xFFFFF2F4);

  ///------------>

  ///BASE COLORS-------->
  static const Color appWhite = Color(0xffFFFFFF);
  static const Color appBlack = Color(0xff000000);
  static const Color appTransparent = Colors.transparent;

  ///----------->

  ///ERROR TEXT FIELD  COLORS
  static const Color textFieldErrorColor = appRed;
  static const Color textFieldHintColor = grey;
  static const Color textFieldBorderColor = lightGrey;

  ///TODO APP CUSTOM COLORS CAN BE ADDED HERE---->
  ///....>

  ///grey related---------->
  static const Color lightGrey = Color(0xffCCCCCC);
  static const Color textBlack = Color(0xff121417);
  static const Color grey = Color(0xffC8C8C8);

  ///grey related----------/>

  ///Blue related------->

  static const Color lightBlue = Color(0xFF8DB9F7);
  static const Color cyanBlue = Color(0xFFE2F1FF);
  static const Color cyanBlue2 = Color(0xFFE0F0FF);
  static Color textBlue = const Color(0xff1172D3);
  static Color textButton = const Color(0xff1e84ff);

  ///Blue related-------/>

  ///black related------->
  static Color darkBlack = const Color(0xff1E1E1E);

  ///black related-------/>

  /// Gradient colors---------->
  static LinearGradient primaryGradient = const LinearGradient(
    colors: [cyanBlue, appWhite],
    end: FractionalOffset(1.0, 1.0),
  );

  /// Custom colors--------->
  static Color darkRed = const Color(0xffC9475A);
  static Color lightRed = const Color(0xffDB7D7D);
  static Color statusRedColor = const Color(0xFFD80000);
  static Color statusGreenColor = const Color(0xFF61DF00);
  static Color statusYellowColor = const Color(0xFFFFA726);


  static const Color darkGreen =  Color(0xff006654);
  static const Color green =  Color(0xff0C582C);
  static const Color greenCyan =  Color(0xffCAEBD8);
  static const Color darkGreen1 =  Color(0xff0c582B);
  static const Color  lightGreen =  Color(0xffA9E4B8);
  static const Color semiLightGreen =  Color(0xff9bf2ad);
  static const Color semiLightGreen1 =  Color(0xffB2DFB6);
  static const Color semiDarkLightGreen =  Color(0xff388253);
  static const Color lightGreen01 =  Color(0xffB2DFB6);
  static const Color darkSpringGreen =  Color(0xff1F7543);
  static const Color lightCurvedGreen =  Color(0xff98DFA8);

  static const Color lavender =  Color(0xFFBA99FF);
  static const Color appDarkBlue =  Color(0xff0000FF);
  static const Color lightBrown =  Color(0xff970821);
  static const Color redLite= Color(0xffFE717A);

  static Color darkViolet = const Color(0xFF3D1C84);

  static const Color tigerOrange =  Color(0xFFC58448);
  static const Color tigerOrange1 =  Color(0xFFF1E7C3);
  static const Color lightOrange =  Color(0xffFBC7A1);
  static const Color darkOrange =  Color(0xffC55C10);
  static const Color bluishPurple =  Color(0xFFE1D3FF);

  static const Color fuchsiaBlue =  Color(0xFF6A44BD);
  static const Color liteGrey =  Color(0xff494949);

  static const Color appPink =  Color(0xffFC8CA4);
  static const Color appPink01 =  Color(0xffFCACB5);
  static const Color appPink02 =  Color(0xffFFCCCC);
  static const Color appPink03 =  Color(0xffE59F89);
  static const Color appLightPink =  Color(0xFFFFC5CC);
  static const Color appLightPink01 =  Color(0xFFFFCFC0);

  static const Color mistyRose =  Color(0xFFFFE4E1);

  static const Color normalButtonColor = Color(0xFF4ED8F2);
  static const Color searchBorderColor = Color(0xFFFFE4E5);
  static const Color deepBlue = Color(0xFF1E2E5F);
}
