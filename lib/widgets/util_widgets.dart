import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';


class Widgets {
  AppBar loginAppbar(
    String title,
    BuildContext context, [
    bool? isShowBackButton = true,
  ]) {
    return AppBar(
      centerTitle: true,
      leading:
          isShowBackButton!
              ? InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(Icons.arrow_back_ios),
              )
              : const SizedBox(),
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<bool?> toastWidget(String message, BuildContext context) {
    return Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

Future<void> snackBarWidget(BuildContext context, String message,Color color,TextTheme? theme) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: theme!.bodyMedium!.copyWith(color: Colors.white)
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 6,
      duration: const Duration(seconds: 3),
    ),
  );
}

  InkWell categoryButtonWidget(
    String title,
    Color color,
    Color borderColor,
    Function() buttonPress,
    Color titleColor,
    bool isHideIcons,
    double height,
    double ClipValue,
    double fontSize,
    String svgImage,
    EdgeInsetsGeometry padding,
    bool isSvgNetworkImage,
  ) {
    return InkWell(
      onTap: buttonPress,
      child: Container(
        padding: padding,
        height: height,
        // width: 60,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(ClipValue),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Visibility(
              visible: isHideIcons,
              child:
                  isSvgNetworkImage
                      ? SvgPicture.network(
                        svgImage,
                        height: 12,
                        color: titleColor,
                      )
                      : SvgPicture.asset(
                        svgImage,
                        height: 12,
                        color: titleColor,
                      ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isHideIcons ? 14.0 : 0.0,
              ),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  color: titleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Visibility(
              visible: isHideIcons,
              child: const Center(
                child: Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SizedBox loaderWidget() {
    return SizedBox(height: 24, width: 24, child: CircularProgressIndicator());
  }

  InkWell buttonWidget(
    String title,
    Color color,
    Color borderColor,
    Function() buttonPress,
    Color titleColor,
    bool isHideIcons,
    double ClipValue, // not using gave value directly
    double fontSize,
    EdgeInsetsGeometry padding,
  ) {
    return InkWell(
      onTap: buttonPress,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(ClipValue),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Visibility(
              visible: isHideIcons,
              child: const Icon(Icons.cell_tower, size: 14),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isHideIcons ? 14.0 : 0.0,
              ),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  color: titleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Visibility(
              visible: isHideIcons,
              child: Container(
                width: 40, // Adjust the width as needed
                height: 40, // Adjust the height as needed
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    5,
                  ), // Adjust the border radius as needed
                ),
                child: const Center(child: Icon(Icons.arrow_forward)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void snackBarFunctionWidget(
    BuildContext context,
    TextStyle? style,
    String title,
    Color color, {
    IconData? icon = Icons.info_outline,
    Duration duration = const Duration(seconds: 3),
  }) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style:
                    style ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Divider dividerWidget({Color? color, double? height = 12, double? thickness = 1}) {
    return Divider(color: color, height: height, thickness: thickness);
  }

  Container verticalDivider(CustomColors? customColor,{ double? height = 80}) {

    return Container(
      decoration: BoxDecoration(
        color: customColor!.borderColor.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
      ),
      height: height!.h,
      width: 1.5.w,
    );
  }
}
