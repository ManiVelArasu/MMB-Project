import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/ui/screens/widget/theme_data_card.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:provider/provider.dart';

import '../../Api Model/theme_screen_model.dart';
import '../../component/custom_widget.dart';
import '../../component/home_appbar.dart';
import '../../component/network_image.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/theme_screen_provider.dart';

import '../../network/provider/custom_theme_provider.dart';
class ThemeDetailScreen extends StatelessWidget {
  final ThemeItem? themeItem;

  const ThemeDetailScreen({
    super.key,
    this.themeItem,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeItem? item =
        themeItem ??
            (ModalRoute.of(context)?.settings.arguments as ThemeItem?);

    return ChangeNotifierProvider(
      create: (_) => ThemesScreenProvider(),
      child: Builder(
        builder: (context) {
          return ThemeDetailView(themeItem: item);
        },
      ),
    );
  }
}

class ThemeDetailView extends StatelessWidget {
  final ThemeItem? themeItem;

  const ThemeDetailView({
    super.key,
    this.themeItem,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Consumer<ThemesScreenProvider>(
      builder: (context, provider, child) {
        final String title = themeItem?.name ?? "";

        final String caption =
            themeItem?.caption ??
                "Bright ideas deserve bright branding";

        final String description =
            themeItem?.description ??
                "Fresh, vibrant, energetic visuals for businesses that want to grab attention instantly, while keeping every single post consistent, lively, and unmistakably you.";

        final List<dynamic> tags =
        themeItem?.tags.isNotEmpty == true
            ? themeItem!.tags
            : [
          "Fresh",
          "Bright",
          "Energetic",
          "Modern",
          "Friendly",
        ];

        final List<Variant> variants =
            themeItem?.variants ?? [];

        return Scaffold(
          backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,

          appBar: PreferredSize(
            preferredSize: Size.fromHeight(70.h),
            child: const HomeCustomAppBar(),
          ),

          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.center,
                  children: [
                    // =====================================================
                    // TITLE
                    // =====================================================

                    AppText(
                      themeItem?.name ?? "",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    SizedBox(height: 6.h),


                    AppText(
                      caption,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFE53935),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    SizedBox(height: 10.h),


                    AppText(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.black87,
                        fontSize: AppFontSize.fontSize18,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: 16.h),


                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      alignment: WrapAlignment.center,
                      children: themeItem!.stylePersonalities
                          .where(
                            (tag) =>
                        tag.name != null &&
                            tag.name!.isNotEmpty,
                      )
                          .map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A1A1C)
                                : const Color(0xFFFFE4E5),
                            borderRadius:
                            BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.red.shade900
                                  : Colors.red.shade100,
                            ),
                          ),
                          child: AppText(
                            tag.name!,
                            style: TextStyle(
                              color: AppColors.appBlack,
                              fontSize:
                              AppFontSize.fontSize14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 20.h),

                    IntrinsicWidth(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 200.w,
                        ),
                        child: SizedBox(
                          height: 42.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xFFE53935),
                              padding: EdgeInsets.symmetric(
                                horizontal: 18.w,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10.r),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: AppText(
                                    "Theme Unlocked Successfully!",
                                  ),
                                ),
                              );
                            },
                            child: AppText(
                              "Unlock $title →",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                AppFontSize.fontSize14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),



                    if (variants.isNotEmpty) ...[
                      SizedBox(height: 24.h),
                      

                      GridView.builder(
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        itemCount: variants.length,
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 0.68,
                        ),
                        itemBuilder: (context, index) {
                          final variant = variants[index];

                          final thumbnailKey =
                              variant.thumbnailS3Key;

                          final thumbnail =
                          thumbnailKey != null &&
                              thumbnailKey.isNotEmpty
                              ? "${ApiEndpoints.cdnImageUrl}/$thumbnailKey"
                              : null;

                          final variantName =
                              variant.name ??
                                  "$title-0${index + 1}";

                          final variantDescription =
                              variant.description
                                  ?.toString() ??
                                  description;

                          final perfectFor =
                          variant.businessCategories
                              .map(
                                (category) =>
                            category.slug
                                ?.isNotEmpty ==
                                true
                                ? category.slug!
                                : variant.description ??
                                '',
                          )
                              .where(
                                (value) =>
                            value.isNotEmpty,
                          )
                              .join(", ");

                          return BrandSeriesCard(
                            thumbnail: thumbnail,
                            title: variantName,
                            description: variantDescription,
                            perfectFor: perfectFor.isNotEmpty
                                ? "Perfect for $perfectFor"
                                : "Perfect for modern brands",
                            isLocked: false,
                            isDark: isDark,
                            onTap: variant.uid != null
                                ? () {
                              Navigator.pushNamed(
                                context,
                                "/ThemeSingleitemViewScreen",
                                arguments: variant.uid,
                              );
                            }
                                : null,
                          );
                        },
                      ),

                      SizedBox(height: 30.h),

                      // ===================================================
                      // ALSO WORKS GREAT FOR
                      // ===================================================

                      Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.grey.shade100,
                            borderRadius:
                            BorderRadius.circular(12.r),
                          ),
                          child: AppText(
                            "Also works great for",
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 8.h),

                      // ===================================================
                      // BEYOND THE OBVIOUS
                      // ===================================================

                      AppText(
                        "Beyond the obvious",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // ===================================================
                      // BUSINESS CATEGORY CHIPS
                      // ===================================================

                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        alignment: WrapAlignment.center,
                        children: [
                          "Cafe",
                          "Juice Shop",
                          "Organic Store",
                          "Bakery",
                          "Dessert Shop",
                          "Smoothie Bar",
                        ].map((category) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color:
                              const Color(0xFFE53935),
                              borderRadius:
                              BorderRadius.circular(10.r),
                            ),
                            child: AppText(
                              category,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                AppFontSize.fontSize14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: 30.h),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getPerfectFor(ThemeItem item) {
    final caption = item.caption?.trim() ?? "";

    if (caption.isNotEmpty) {
      return "Perfect for $caption";
    }

    return "Perfect for modern brands";
  }
}
