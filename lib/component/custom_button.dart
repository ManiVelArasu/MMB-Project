import 'package:flutter/material.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:project_mmb/component/svg_loader.dart';


import '../../utils/theme/app.colors.dart';
import '../utils/theme/app.fonts.dart';


class CustomElevatedButton extends StatefulWidget {
  const CustomElevatedButton(
      {super.key,
      this.text,
      this.buttonColor,
      this.textColor,
      this.borderColor,
      required this.onTapFunction,
      this.buttonWidth,
      this.buttonHeight,
      this.fontSize,
      this.buttonRadius,
      this.icon,
      this.prefixIconColor,
      this.prefixIcon,
      this.fontWeight,
      this.mainAxisAlignment = MainAxisAlignment.center,
      this.iconColor,
      this.isLoading = false});

  final String? text;
  final Color? buttonColor;
  final Color? textColor;
  final Color? borderColor;
  final Color? prefixIconColor;
  final double? buttonWidth;
  final double? buttonHeight;
  final double? fontSize;
  final BorderRadius? buttonRadius;
  final Function() onTapFunction;
  final String? icon;
  final String? prefixIcon;
  final FontWeight? fontWeight;
  final MainAxisAlignment mainAxisAlignment;
  final Color? iconColor;
  final bool isLoading;

  @override
  State<CustomElevatedButton> createState() => _CustomElevatedButtonState();
}

class _CustomElevatedButtonState extends State<CustomElevatedButton> {
  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap:widget.isLoading?null: widget.onTapFunction,
      child: Container(
        height: widget.buttonHeight ?? 46,
        width: widget.buttonWidth ??70,
        decoration: BoxDecoration(
          color: widget.buttonColor,
          borderRadius: widget.buttonRadius ?? BorderRadius.circular(15),
          border:
              Border.all(color: widget.borderColor ?? AppColors.appDarkBlue),
        ),
        child: widget.isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.appWhite,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.prefixIcon != null) ...[
                    SvgLoaderWidget(
                        image: '${widget.prefixIcon}',
                        iconColor: widget.prefixIconColor),
                    const SizedBox(
                      width: 5,
                    )
                  ],
                  if (widget.text != null)
                    AppText(
                       widget.text ?? '',
                      style: TextStyle(
                        fontSize: widget.fontSize ?? AppFontSize.fontSize13,
                        fontWeight: widget.fontWeight ?? FontWeight.bold,
                        color: widget.textColor,
                      ),
                    ),

                  if (widget.icon != null) ...[
                    const SizedBox(
                      width: 8,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: SvgLoaderWidget(
                        image: widget.icon!,
                        iconColor: widget.iconColor,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
