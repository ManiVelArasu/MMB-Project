import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../component/appbar_widget.dart';
import '../../../component/custom_widget.dart';
import '../../../network/provider/custom_theme_provider.dart';
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

  String? selectedPopularSize;

  final List<Map<String, dynamic>> popularSizes = [
    {
      "title": "Youtube Cover",
      "subtitle": "2560 × 1440 PX",
      "width": 2560,
      "height": 1440,
    },
    {
      "title": "Facebook Cover",
      "subtitle": "820 × 315 PX",
      "width": 820,
      "height": 315,
    },
    {
      "title": "Pinterest",
      "subtitle": "1000 × 1500 PX",
      "width": 1000,
      "height": 1500,
    },
    {
      "title": "Linked In Banner",
      "subtitle": "1584 × 396 PX",
      "width": 1584,
      "height": 396,
    },
  ];

  @override
  void dispose() {
    widthController.dispose();
    heightController.dispose();
    super.dispose();
  }

  void _selectPopularSize(Map<String, dynamic> item) {
    setState(() {
      selectedPopularSize = item["title"];
      widthController.text = item["width"].toString();
      heightController.text = item["height"].toString();
    });
  }

  void _createDesign() {
    final double? width = double.tryParse(widthController.text.trim());
    final double? height = double.tryParse(heightController.text.trim());

    if (width == null ||
        height == null ||
        width <= 0 ||
        height <= 0 ||
        width > 4000 ||
        height > 4000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter valid width and height (Max 4000)."),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TemplateEditScreen(canvasWidth: width, canvasHeight: height),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: CustomAppBar(title: "Custom Size", showRightIcon: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              // Width and Height
              Row(
                children: [
                  Expanded(
                    child: _buildSizeInput(
                      title: "Width (px)",
                      controller: widthController,
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
                    child: _buildSizeInput(
                      title: "Height (px)",
                      controller: heightController,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Popular section
              AppText(
                "POPULAR",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: AppFontSize.fontSize14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 10.h),

              // Popular size chips
              SizedBox(
                height: 40.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: popularSizes.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (context, index) {
                    final item = popularSizes[index];

                    final bool isSelected =
                        selectedPopularSize == item["title"];

                    return GestureDetector(
                      onTap: () {
                        _selectPopularSize(item);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          color: isSelected
                              ? Colors.red.withValues(alpha: .08)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? Colors.red
                                : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText(
                              item["title"],
                              style: TextStyle(
                                fontSize: AppFontSize.fontSize14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected ? Colors.red : Colors.black87,
                              ),
                            ),

                            SizedBox(width: 6.w),

                            AppText(
                              item["subtitle"],
                              style: TextStyle(
                                fontSize: AppFontSize.fontSize14,
                                fontWeight: FontWeight.w400,
                                color: isSelected ? Colors.red : Colors.grey,
                              ),
                            ),

                            if (isSelected) ...[
                              SizedBox(width: 5.w),
                              Icon(
                                Icons.check_circle,
                                color: Colors.red,
                                size: 15.sp,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 40.h),

              // Create Design Button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _createDesign,
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
                      fontSize: AppFontSize.fontSize14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 14.h),

              // Footer
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      "Want inspiration? ",
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize12,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        // Browse templates action
                      },
                      child: AppText(
                        "BROWSE TEMPLATES",
                        style: TextStyle(
                          fontSize: AppFontSize.fontSize12,
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

  // Width / Height input widget
  Widget _buildSizeInput({
    required String title,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title,
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
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFFFD5D8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFFFD5D8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
