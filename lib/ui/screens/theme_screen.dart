import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../Api Model/theme_screen_model.dart';
import '../../component/custom_searchbar.dart';
import '../../component/home_appbar.dart';
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

    return Consumer<ThemesScreenProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingPlans) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.plansErrorMessage != null) {
          return Scaffold(
            body: Center(child: Text(provider.plansErrorMessage!)),
          );
        }

        final groups = provider.groups;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(70.h),
            child: HomeCustomAppBar(
              businessName: "Business Name",
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8EAF6), Color(0xFFD1C4E9)],
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
                                  color: const Color(0xFF303F9F),
                                ),
                              ),

                              SizedBox(height: 8.h),

                              Text(
                                "Select, Customize, and Publish.\nAll in One Place!",
                                style: TextStyle(fontSize: 11.sp),
                              ),

                              SizedBox(height: 14.h),

                              ElevatedButton(
                                onPressed: () {},
                                child: const Text("ACTIVATE NOW"),
                              ),
                            ],
                          ),

                          /*Positioned(
                            right: -10,
                            bottom: -10,
                            child: Image.asset(
                              "assets/images/theme_banner_illustration.png",
                              height: 110.h,
                            ),
                          ),*/
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

                        return ThemeGroupSection(group: group);
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
  final ThemeGroup group;

  const ThemeGroupSection({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
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
              child: Image.asset("assets/images/rebel.png"),
            ),

            SizedBox(width: 8.w),

            Expanded(
              child: Text(
                group.name ?? "",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  "/ThemeGroupScreen",
                  arguments: group,
                );
              },
              child: Text(
                "VIEW ALL",
                style: TextStyle(
                  color: Colors.grey.shade600,
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
            itemCount: group.themes?.length ?? 0,
            itemBuilder: (context, index) {
              return ThemeCard(theme: group.themes![index]);
            },
          ),
        ),

        SizedBox(height: 24.h),
      ],
    );
  }
}

class ThemeCard extends StatelessWidget {
  final ThemeModel theme;

  const ThemeCard({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150.w,
      margin: EdgeInsets.only(right: 14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                "/ThemeDetailScreen",
                arguments: theme,
              );
            },
            child: Container(
              height: 160.h,
              width: 150.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color: Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child:
                          theme.thumbnailS3Key == null ||
                              theme.thumbnailS3Key!.isEmpty
                          ? Container(
                              color: Colors.grey.shade300,
                              child: Icon(
                                Icons.image_outlined,
                                size: 40.sp,
                                color: Colors.grey,
                              ),
                            )
                          : Image.network(
                              theme.thumbnailS3Key ?? "",
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 40.sp,
                                  ),
                                );
                              },
                            ),
                    ),

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
                  ),
                ),
              ),

              Icon(Icons.favorite, color: Colors.red, size: 14.sp),

              SizedBox(width: 4.w),

              Text(
                "${theme.likesCount ?? 0}",
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          Text(
            "${theme.businessCategories?.length ?? 0} Templates",
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
