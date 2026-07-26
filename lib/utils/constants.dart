import 'dart:ui';

import 'package:flutter/material.dart';

const String baseUrl = "https://inston.showmydemo.in/api/";
const String driveUrl = "https://drive.google.com/uc?export=view&id=";
const String mapUrl = 'https://maps.googleapis.com/maps/api/';
const String apiKey = 'AIzaSyBcp7UpU50v0qi58iAeNM9HBdtJJh24b0k';

const blueThemeColors = CustomColors(
  buttonColor: Color(0xffED2024),
  baseColor: Color(0xff1E2E5F),
  formBorderColor: Color(0xff0130A6),
  textColor: Color(0xff525252),
  whiteColor: Color(0xffffffff),
  borderColor: Color(0xff0CDCDCD),
  checkInUnselectedColor: Color(0xff0020720f),
  blackColor: Color(0xff040404),
  greyColor: Color(0xff1F1F1F),
  topBackgroundGradient: LinearGradient(
    colors: [
      Color(0xff0130A6),
      Color(0xff002072),
      // Add a second color for a smooth gradient
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  bottomBackgroundGradient: LinearGradient(
    colors: [
      Color(0xff0130A6),
      Color(0xff002072),
      // Add a second color for a smooth gradient
    ],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  ),
  splashBackgroundGradient: LinearGradient(
    colors: [
      Color(0xff022DAD),
      Color(0xff02035F),
      // Add a second color for a smooth gradienturl
    ],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  ),
  backgroundColor: Color(0xffF8FCFF),
  greenColor: Color(0xff66BB6A),
  orangeColor: Color(0xffFFA726),
  redColor: Color(0xffED2024),
);

// const yellowThemeColors = CustomColors(
//   buttonColor: Color(0xffFFEB3B),
//   baseColor: Color(0xffFFFDE7),
//   formBorderColor: Color(0xffFBC02D),
//   textColor: Color(0xff525252),
//   whiteColor: Color(0xffffffff),
//   borderColor: Color(0xffE1E6F5),
//   checkInUnselectedColor: Color(0xfff57f1714),
//   blackColor: Color(0xff050505),
//   greyColor: Color(0xffE0E0E0),
//   topBackgroundGradient: LinearGradient(
//     colors: [
//       Color(0xffFBC02D),
//       Color(0xffF57F17),
//       // Add a second color for a smooth gradient
//     ],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   ),
//   bottomBackgroundGradient: LinearGradient(
//     colors: [
//       Color(0xffFBC02D),
//       Color(0xffF57F17),
//       // Add a second color for a smooth gradient
//     ],
//     begin: Alignment.bottomLeft,
//     end: Alignment.topRight,
//   ),
//   splashBackgroundGradient: LinearGradient(
//     colors: [
//       Color(0xffFBC02D),
//       Color(0xffF57F17),
//       // Add a second color for a smooth gradient
//     ],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   ),
//   backgroundColor: Color(0xffF8FCFF),
//   greenColor: Color(0xff66BB6A),
//   orangeColor: Color(0xffFFA726),
//   redColor: Color(0xffFF5454),
// );

class CustomColors {
  final Color buttonColor;
  final Color baseColor;
  final Color formBorderColor;
  final Color textColor;
  final Color whiteColor;
  final Color borderColor;
  final Color checkInUnselectedColor;
  final Color blackColor;
  final Color greyColor;
  final Gradient topBackgroundGradient;
  final Gradient bottomBackgroundGradient;
  final Gradient splashBackgroundGradient;
  final Color backgroundColor;
  final Color greenColor;
  final Color redColor;
  final Color orangeColor;

  const CustomColors({
    required this.buttonColor,
    required this.baseColor,
    required this.formBorderColor,
    required this.textColor,
    required this.whiteColor,
    required this.borderColor,
    required this.checkInUnselectedColor,
    required this.blackColor,
    required this.greyColor,
    required this.topBackgroundGradient,
    required this.bottomBackgroundGradient,
    required this.splashBackgroundGradient,
    required this.backgroundColor,
    required this.greenColor,
    required this.redColor,
    required this.orangeColor,
  });
}

class PreferenceConstants {
  PreferenceConstants._();

  static const String strToken = "STR_TOKEN";
  static const String isLoggedIn = "IS_LOGGED_IN";
  static const String userId = "USER_ID";
  static const String isPunchIn = "IS_PUNCH_IN";
  static const String attendanceMode = "ATTENDANCE_MODE";
  static const String userName = "USER_NAME";
  static const String employeeId = "EMPLOYEE_ID";
  static const String role = "ROLE";
}
