import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../Api Model/theme_screen_model.dart';
import '../../component/custom_searchbar.dart';
import '../../component/home_appbar.dart';
import '../../component/network_image.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/theme_screen_provider.dart';

import 'package:flutter/material.dart';



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
            child: const HomeCustomAppBar(
              businessCategory: "Cake and Sweets",
              notificationCount: "2",
            ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Search
                    CustomSearchBar(
                      hintText: "Find your Industry",
                      prefixAsset: "assets/images/search.png",
                      suffixAsset: "assets/images/search.png",
                      borderColor: const Color(0xFFFFCDD2),
                      onChanged: (value) {},
                    ),

                    SizedBox(height: 20.h),

                    /// Banner
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(18.r),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1E1E2C),
                                  const Color(0xFF2D2B42),
                                ]
                              : [
                                  const Color(0xFFE8EAF6),
                                  const Color(0xFFD1C4E9),
                                ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Level Up your SM with\nour Themes",
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? const Color(0xFF9FA8DA)
                                      : const Color(0xFF303F9F),
                                ),
                              ),

                              SizedBox(height: 8.h),

                              Text(
                                "Select, Customize, and Publish.\nAll in One Place!",
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),

                              SizedBox(height: 14.h),

                              ElevatedButton(
                                onPressed: () {},
                                child: const Text("ACTIVATE NOW"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 25.h),

                    /// Dynamic Theme Groups
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
              decoration: BoxDecoration(
                color: const Color(0xFF00E676),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child:NetworkAssetImage(
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
                  fontSize: 18.sp,
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
              child: Text(
                "VIEW ALL",
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 14.h),

        SizedBox(
          height: 220.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: group.variants.length,
            itemBuilder: (context, index) {
              return ThemeCard(theme: group.variants[index], isDark: isDark);
            },
          ),
        ),

        SizedBox(height: 24.h),
      ],
    );
  }
}

class ThemeCard extends StatelessWidget {
  final Variant theme;
  final bool isDark;

  const ThemeCard({super.key, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final String? thumbnailKey = theme.thumbnailS3Key;
    return Container(
      width: 150.w,
      margin: EdgeInsets.only(right: 14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {},
            child: Container(
              height: 160.h,
              width: 150.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: thumbnailKey == null || thumbnailKey.isEmpty
                          ? Container(
                              color: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.grey.shade300,
                              child: Icon(
                                Icons.image_outlined,
                                size: 40.sp,
                                color: Colors.grey,
                              ),
                            )
                          : Image.network(
                              // 🚀 CDN URL மற்றும் thumbnailKey-ஐ இணைப்பது
                              "${ApiEndpoints.cdnImageUrl}/$thumbnailKey",
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  color: isDark
                                      ? const Color(0xFF2C2C2C)
                                      : Colors.grey.shade300,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 40.sp,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                    ),

                    // கிரவுன் (Crown) ஐகான்
                    Positioned(
                      top: 10.h,
                      left: 10.w,
                      child: Image.asset(
                        "assets/images/crown.png",
                        width: 15,
                        height: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 8.h),

          // Variant Name மற்றும் Likes
          Row(
            children: [
              Expanded(
                child: Text(
                  theme.name ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),

              Icon(Icons.favorite, color: Colors.red, size: 14.sp),

              SizedBox(width: 4.w),

              Text(
                "${theme.likesCount ?? 0}",
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          Text(
            "${theme.businessCategories.length} Templates",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
