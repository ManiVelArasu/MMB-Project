import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/appbar_widget.dart';
import 'package:mmb_app/component/home_appbar.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:provider/provider.dart';

import '../../component/custom_widget.dart';
import '../../network/provider/custom_screen_provider.dart';
import '../../network/provider/custom_theme_provider.dart';

class ExploreAiToolScreen extends StatefulWidget {
  const ExploreAiToolScreen({super.key});

  @override
  State<ExploreAiToolScreen> createState() => _ExploreAiToolScreenState();
}

class _ExploreAiToolScreenState extends State<ExploreAiToolScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: HomeCustomAppBar(),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300.h,
            child: Image.asset(
              "assets/images/plan_gradient.png",
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: ChangeNotifierProvider(
              create: (_) => CustomScreenProvider(),
              child: Consumer2<CustomScreenProvider, CustomThemeProvider>(
                builder: (context, provider, themeProvider, child) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          "AI HUB",
                          style: TextStyle(
                            fontSize: AppFontSize.fontSize22,
                            fontWeight: FontWeight.w500,
                            color: AppColors.appBlack,
                          ),
                        ),
                        SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: provider.aiToolsList.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12.w,
                                    mainAxisSpacing: 12.h,
                                    childAspectRatio: 0.82,
                                  ),
                              itemBuilder: (context, index) {
                                final tool = provider.aiToolsList[index];

                                return InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      tool.routeName,
                                    );
                                  },

                                  child: Container(
                                    padding: EdgeInsets.all(12.r),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E1E1E)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.grey.shade800
                                            : const Color(0xFFE8EEF5),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.2 : 0.02,
                                          ),
                                          blurRadius: 8.r,
                                          offset: Offset(0, 2.h),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 52.h,
                                          width: 52.w,
                                          child:
                                              tool.imagePath.trim().isNotEmpty
                                              ? Image.asset(
                                                  tool.imagePath,
                                                  fit: BoxFit.contain,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => _buildFallbackIcon(),
                                                )
                                              : _buildFallbackIcon(),
                                        ),

                                        SizedBox(height: 10.h),

                                        // 2. TOOL TITLE
                                        AppText(
                                          tool.title,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        SizedBox(height: 4.h),

                                        // 3. TOOL SUBTITLE
                                        AppText(
                                          tool.subtitle,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                            fontSize: 9.5.sp,
                                            fontWeight: FontWeight.w500,
                                            height: 1.2,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildFallbackIcon() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFFECEE),
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: Icon(
      Icons.auto_awesome,
      color: const Color(0xFFE53935),
      size: 26.sp,
    ),
  );
}
