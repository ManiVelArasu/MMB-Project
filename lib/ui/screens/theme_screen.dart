import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../component/custom_searchbar.dart';
import '../../component/home_appbar.dart';
import '../../network/provider/theme_screen_provider.dart';

class ThemesScreen extends StatelessWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Consumer<ThemesScreenProvider>(
      builder: (context, provider, child) {
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
                  horizontal: size.width * 0.04,
                  vertical: 12.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. SEARCH BAR
                    CustomSearchBar(
                      hintText: "Find your Industry",
                      prefixAsset: "assets/images/search.png",
                      suffixAsset: "assets/images/search.png",
                      borderColor: const Color(0xFFFFCDD2),
                      onChanged: (query) {},
                    ),

                    SizedBox(height: 20.h),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(18.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(20.r),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8EAF6), Color(0xFFD1C4E9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                                  color: const Color(0xFF303F9F),
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                "Select, Customize, and Publish.\nAll in One Place!",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                              SizedBox(height: 14.h),

                              // "ACTIVATE NOW" Purple Button
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C4DFF),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 8.h,
                                  ),
                                ),
                                child: Text(
                                  "ACTIVATE NOW",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Background Character Illustration Asset
                          Positioned(
                            right: -10.w,
                            bottom: -10.h,
                            child: Image.asset(
                              "assets/images/theme_banner_illustration.png",
                              height: 110.h,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.auto_awesome,
                                size: 80.sp,
                                color: const Color(
                                  0xFF7C4DFF,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // 3. MIDNIGHT REBEL SECTION HEADER
                    Row(
                      children: [
                        // Quad Green App Icon
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
                        Text(
                          "Midnight Rebel",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "VIEW ALL",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 14.h),

                    // 4. HORIZONTAL THEME CARDS LIST
                    SizedBox(
                      height: 220.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: provider.midnightRebelList.length,
                        itemBuilder: (context, index) {
                          final item = provider.midnightRebelList[index];

                          return Container(
                            width: 150.w,
                            margin: EdgeInsets.only(right: 14.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Theme Preview Image Card
                                InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      "/ThemeDetailScreen",
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
                                          // Poster Image
                                          Positioned.fill(
                                            child: Image.asset(
                                              item.imagePath,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    color: Colors.grey.shade300,
                                                    child: Icon(
                                                      Icons.image_outlined,
                                                      size: 40.sp,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                            ),
                                          ),

                                          // Crown Badge (Top-Left)
                                          if (item.isPremium)
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

                                // Title & Likes Counter Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Heart Likes Badge
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.favorite_rounded,
                                          color: const Color(0xFFE53935),
                                          size: 14.sp,
                                        ),
                                        SizedBox(width: 3.w),
                                        Text(
                                          item.likesCount,
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                SizedBox(height: 2.h),

                                // Subtitle: Template Count
                                Text(
                                  item.templateCount,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        // Quad Green App Icon
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
                        Text(
                          "Lemon Buzz",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "VIEW ALL",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 14.h),

                    // 4. HORIZONTAL THEME CARDS LIST
                    SizedBox(
                      height: 220.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: provider.midnightRebelList.length,
                        itemBuilder: (context, index) {
                          final item = provider.midnightRebelList[index];

                          return Container(
                            width: 150.w,
                            margin: EdgeInsets.only(right: 14.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Theme Preview Image Card
                                Container(
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
                                        // Poster Image
                                        Positioned.fill(
                                          child: Image.asset(
                                            item.imagePath,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  color: Colors.grey.shade300,
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                    size: 40.sp,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          ),
                                        ),

                                        // Crown Badge (Top-Left)
                                        if (item.isPremium)
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

                                SizedBox(height: 8.h),

                                // Title & Likes Counter Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Heart Likes Badge
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.favorite_rounded,
                                          color: const Color(0xFFE53935),
                                          size: 14.sp,
                                        ),
                                        SizedBox(width: 3.w),
                                        Text(
                                          item.likesCount,
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                SizedBox(height: 2.h),

                                // Subtitle: Template Count
                                Text(
                                  item.templateCount,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        // Quad Green App Icon
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
                        Text(
                          "Cherry Rush",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "VIEW ALL",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 14.h),

                    // 4. HORIZONTAL THEME CARDS LIST
                    SizedBox(
                      height: 220.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: provider.midnightRebelList.length,
                        itemBuilder: (context, index) {
                          final item = provider.midnightRebelList[index];

                          return Container(
                            width: 150.w,
                            margin: EdgeInsets.only(right: 14.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Theme Preview Image Card
                                Container(
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
                                        // Poster Image
                                        Positioned.fill(
                                          child: Image.asset(
                                            item.imagePath,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  color: Colors.grey.shade300,
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                    size: 40.sp,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          ),
                                        ),

                                        // Crown Badge (Top-Left)
                                        if (item.isPremium)
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

                                SizedBox(height: 8.h),

                                // Title & Likes Counter Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Heart Likes Badge
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.favorite_rounded,
                                          color: const Color(0xFFE53935),
                                          size: 14.sp,
                                        ),
                                        SizedBox(width: 3.w),
                                        Text(
                                          item.likesCount,
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                SizedBox(height: 2.h),

                                // Subtitle: Template Count
                                Text(
                                  item.templateCount,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        // Quad Green App Icon
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
                        Text(
                          "Midnight Rebel",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "VIEW ALL",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 14.h),

                    // 4. HORIZONTAL THEME CARDS LIST
                    SizedBox(
                      height: 220.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: provider.midnightRebelList.length,
                        itemBuilder: (context, index) {
                          final item = provider.midnightRebelList[index];

                          return Container(
                            width: 150.w,
                            margin: EdgeInsets.only(right: 14.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Theme Preview Image Card
                                Container(
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
                                        // Poster Image
                                        Positioned.fill(
                                          child: Image.asset(
                                            item.imagePath,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  color: Colors.grey.shade300,
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                    size: 40.sp,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          ),
                                        ),

                                        // Crown Badge (Top-Left)
                                        if (item.isPremium)
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

                                SizedBox(height: 8.h),

                                // Title & Likes Counter Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Heart Likes Badge
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.favorite_rounded,
                                          color: const Color(0xFFE53935),
                                          size: 14.sp,
                                        ),
                                        SizedBox(width: 3.w),
                                        Text(
                                          item.likesCount,
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                SizedBox(height: 2.h),

                                // Subtitle: Template Count
                                Text(
                                  item.templateCount,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        // Quad Green App Icon
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
                        Text(
                          "Midnight Rebel",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "VIEW ALL",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 14.h),

                    // 4. HORIZONTAL THEME CARDS LIST
                    SizedBox(
                      height: 220.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: provider.midnightRebelList.length,
                        itemBuilder: (context, index) {
                          final item = provider.midnightRebelList[index];

                          return Container(
                            width: 150.w,
                            margin: EdgeInsets.only(right: 14.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Theme Preview Image Card
                                Container(
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
                                        // Poster Image
                                        Positioned.fill(
                                          child: Image.asset(
                                            item.imagePath,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  color: Colors.grey.shade300,
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                    size: 40.sp,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          ),
                                        ),

                                        // Crown Badge (Top-Left)
                                        if (item.isPremium)
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

                                SizedBox(height: 8.h),

                                // Title & Likes Counter Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Heart Likes Badge
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.favorite_rounded,
                                          color: const Color(0xFFE53935),
                                          size: 14.sp,
                                        ),
                                        SizedBox(width: 3.w),
                                        Text(
                                          item.likesCount,
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                SizedBox(height: 2.h),

                                // Subtitle: Template Count
                                Text(
                                  item.templateCount,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
