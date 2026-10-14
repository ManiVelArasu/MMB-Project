import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../component/appbar_widget.dart';
import '../../../component/custom_widget.dart';
import '../../../utils/theme/app.colors.dart';
import '../../../utils/theme/app.fonts.dart';
import '../template_edit.dart';

class CustomSizeScreen extends StatefulWidget {
  const CustomSizeScreen({super.key});

  @override
  State<CustomSizeScreen> createState() => _CustomSizeScreenState();
}

class _CustomSizeScreenState extends State<CustomSizeScreen> {
  final TextEditingController widthController = TextEditingController(
    text: "1080",
  );
  final TextEditingController heightController = TextEditingController(
    text: "1080",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "Custom Size",
        showRightIcon: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle
              AppText(
                "Enter exact dimensions for a billboard, packaging label, or any size we don't have ready-made.",
                style: TextStyle(
                  fontSize: AppFontSize.fontSize14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF666666),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),

              // Width & Height Inputs with Cross Icon
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          "Width (px)",
                          style: TextStyle(
                            fontSize: AppFontSize.fontSize16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.appBlack,
                          ),
                        ),
                        AppText(
                          "Max 4000",
                          style: TextStyle(
                            fontSize: AppFontSize.fontSize14,
                            fontWeight: FontWeight.w300,
                            color: AppColors.appBlack,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        TextField(
                          controller: widthController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 12.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFD5D8),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFD5D8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 15.h,
                    ),
                    child: const Icon(Icons.close, color: Colors.red, size: 18),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          "Height (px)",
                          style: TextStyle(
                            fontSize: AppFontSize.fontSize16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.appBlack,
                          ),
                        ),
                        AppText(
                          "Max 4000",
                          style: TextStyle(
                            fontSize: AppFontSize.fontSize14,
                            fontWeight: FontWeight.w300,
                            color: AppColors.appBlack,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        TextField(
                          controller: heightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 12.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFD5D8),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFD5D8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Popular Section Title
              AppText(
                "POPULAR",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: AppFontSize.fontSize14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10.h),

              // Popular Horizontal Chips
              SizedBox(
                height: 38.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildPopularChip("Youtube Cover", "2560 × 1440 PX"),
                    SizedBox(width: 8.w),
                    _buildPopularChip("Facebook Cover", "820 × 315 PX"),
                    SizedBox(width: 8.w),
                    _buildPopularChip("Pinterest", "1000 × 1500 PX"),
                    SizedBox(width: 8.w),
                    _buildPopularChip("Linked In Banner", "1584 × 396 PX"),
                  ],
                ),
              ),
              SizedBox(height: 40.h),

              // Create Design Button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () {
                    final double? w = double.tryParse(widthController.text);
                    final double? h = double.tryParse(heightController.text);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TemplateEditScreen(canvasWidth: w, canvasHeight: h),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: AppText(
                    "CREATE DESIGN",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // Footer Link
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      "Want inspiration? ",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Action for browse templates
                      },
                      child: AppText(
                        "BROWSE TEMPLATES",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.red,
                          fontWeight: FontWeight.w800,
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

  Widget _buildPopularChip(String title, String subtitle) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            title,
            style: TextStyle(
              fontSize: AppFontSize.fontSize14,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          SizedBox(width: 6.w),
          AppText(
            subtitle,
            style: TextStyle(
              fontSize: AppFontSize.fontSize14,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}