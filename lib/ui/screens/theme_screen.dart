import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/ui/screens/widget/theme_data_card.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:provider/provider.dart';
import '../../Api Model/theme_screen_model.dart';
import '../../component/custom_searchbar.dart';
import '../../component/home_appbar.dart';
import '../../component/network_image.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/theme_screen_provider.dart';

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ThemesScreenProvider>().fetchPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Consumer<ThemesScreenProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingPlans) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.plansErrorMessage != null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Text(
                provider.plansErrorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          );
        }

        final groups = provider.groups;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(70.h),
            child: const HomeCustomAppBar(),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * .04,
                  vertical: 12.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText(
                      "Brand Series",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.appBlack,
                        fontSize: AppFontSize.fontSize22,
                      ),
                    ),

                    SizedBox(height: 2),

                    // DESCRIPTION
                    AppText(
                      "Create a consistent brand identity with\n"
                      "professionally designed template collections.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize18,
                        color: AppColors.lightTextGrey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    SizedBox(height: 4),

                    Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _brandBadge("2,500+ TEMPLATES"),
                            _brandBadge("50+ INDUSTRIES"),
                            _brandBadge("FULLY CUSTOMIZABLE"),
                            _brandBadge("INDUSTRY-SPECIFIC COLLECTIONS"),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 10),

                    /// Search
                    CustomSearchBar(
                      hintText: "Search Brand Series",
                      prefixAsset: "assets/images/search.png",
                      suffixAsset: "assets/images/mic.png",
                      borderColor: const Color(0xFFFFCDD2),
                      onChanged: (value) {},
                    ),

                    SizedBox(height: 20.h),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return ThemeGroupSection(group: group, isDark: isDark);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _brandBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD5D5)),
      ),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: AppColors.appRed,
          fontSize: AppFontSize.fontSize14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ThemeGroupSection extends StatelessWidget {
  final ThemeItem group;
  final bool isDark;

  const ThemeGroupSection({
    super.key,
    required this.group,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    String? iconUrl = group.iconS3Key;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 32.h,
              width: 32.w,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: NetworkAssetImage(
                  url: "${ApiEndpoints.cdnImageUrl}/${iconUrl ?? ''}",
                  fit: BoxFit.cover,
                  errorWidget: const Icon(
                    Icons.category,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(width: 8.w),

            Expanded(
              child: Text(
                group.slug ?? "",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: AppFontSize.fontSize22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  "/ThemeDetailScreen",
                  arguments: group,
                );
              },
              child: AppText(
                "VIEW ALL",
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: AppFontSize.fontSize12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 14.h),

        group.variants.isEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Center(
                  child: AppText(
                    "Variants for this series are on their way.",
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: AppFontSize.fontSize14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: group.variants.map((variant) {
                    final thumbnailKey = variant.thumbnailS3Key;

                    final thumbnail =
                        thumbnailKey != null && thumbnailKey.isNotEmpty
                        ? "${ApiEndpoints.cdnImageUrl}/$thumbnailKey"
                        : null;

                    return Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: SizedBox(
                        width: 150.w,
                        child: BrandSeriesCard(
                          thumbnail: thumbnail,
                          title: variant.name ?? "Theme",
                          description:
                              "${variant.businessCategories.length} Ready-to-Use TemplatesTemplates",
                          perfectFor: variant.businessCategories
                              .map(
                                (category) => category.slug?.isNotEmpty == true
                                    ? category.slug!
                                    : variant.description ?? '',
                              )
                              .where((slug) => slug.isNotEmpty)
                              .join(", "),
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
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

        SizedBox(height: 24.h),
      ],
    );
  }
}
