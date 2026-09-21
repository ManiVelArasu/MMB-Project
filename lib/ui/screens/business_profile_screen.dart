import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/business_provider.dart';
import '../../network/provider/businessprofile_provider.dart';

import '../../network/provider/custom_theme_provider.dart';
import '../industry/widgets/image_viewer.dart';

class BusinessProfileScreen extends StatelessWidget {
  const BusinessProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BusinessProfileProvider(),
      child: const BusinessProfileView(),
    );
  }
}

class BusinessProfileView extends StatelessWidget {
  const BusinessProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Consumer<BusinessProfileProvider>(
      builder: (context, provider, child) {
        final businessProvider = context.watch<BusinessProvider>();
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: provider.isKeyWordsLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.04,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                isDark
                                    ? const Color(0xFF2A1A1C)
                                    : const Color(
                                        0xFFFFECEE,
                                      ).withValues(alpha: 0.6),
                                isDark ? const Color(0xFF121212) : Colors.white,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Back Arrow
                              Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    height: 38.h,
                                    width: 38.w,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF2A1A1C)
                                          : const Color(0xFFFFECEE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      color: const Color(0xFFE53935),
                                      size: 20.sp,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 8.h),

                              // Profile Logo
                              Container(
                                width: 70.w,
                                height: 70.w,
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: ClipOval(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ImageViewerScreen(
                                              imagePath:
                                                  '${ApiEndpoints.cdnImageUrl}/${provider.commonProvider.business?.logoS3Key ?? ''}',
                                            ),
                                          ),
                                        );
                                      },
                                      child: Image.network(
                                        '${ApiEndpoints.cdnImageUrl}/${provider.commonProvider.business?.logoS3Key ?? ''}',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 10.h),

                              AppText(
                                provider.businessName.isEmpty
                                    ? "${provider.commonProvider.business?.name}"
                                    : provider.businessName,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              AppText(
                                "${provider.commonProvider.business?.businessCategory?.parent?.slug}",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              SizedBox(height: 8.h),

                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    "/EditProfileScreen",
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AppText(
                                      "EDIT BUSINESS DETAILS",
                                      style: TextStyle(
                                        color: const Color(0xFFE53935),
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(
                                      Icons.edit_note_rounded,
                                      color: const Color(0xFFE53935),
                                      size: 16.sp,
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 16.h),

                              Row(
                                children: [
                                  _buildActionCard(
                                    title: "ABOUT",
                                    iconAsset: "assets/images/about.png",
                                    bgColor: isDark
                                        ? const Color(0xFF332211)
                                        : const Color(0xFFFFDBB9),
                                    isDark: isDark,
                                  ),
                                  SizedBox(width: 10.w),
                                  _buildActionCard(
                                    title: "MY PRODUCTS",
                                    iconAsset: "assets/images/product.png",
                                    bgColor: isDark
                                        ? const Color(0xFF113338)
                                        : const Color(0xFF72E8F5),
                                    isDark: isDark,
                                  ),
                                  SizedBox(width: 10.w),
                                  _buildActionCard(
                                    title: "UPLOADS",
                                    iconAsset: "assets/images/uploads.png",
                                    bgColor: isDark
                                        ? const Color(0xFF1D3315)
                                        : const Color(0xFF9AE278),
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Divider(
                          height: 1,
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                        SizedBox(height: 16.h),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.04,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title + Plus Button
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                        "assets/images/frames_icon.png",
                                        height: 24.h,
                                        width: 24.w,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.layers_rounded,
                                          color: const Color(0xFFE53935),
                                          size: 22.sp,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      AppText(
                                        "My Frames",
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    height: 32.h,
                                    width: 32.w,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF2A1A1C)
                                          : const Color(0xFFFFECEE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_rounded,
                                      color: const Color(0xFFE53935),
                                      size: 22.sp,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 12.h),

                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => provider.updateFrameTab(0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          "Static Frames",
                                          style: TextStyle(
                                            color:
                                                provider.selectedFrameTab == 0
                                                ? (isDark
                                                      ? Colors.white
                                                      : Colors.black)
                                                : Colors.grey,
                                            fontSize: 14.sp,
                                            fontWeight:
                                                provider.selectedFrameTab == 0
                                                ? FontWeight.w900
                                                : FontWeight.w600,
                                          ),
                                        ),
                                        if (provider.selectedFrameTab == 0)
                                          Container(
                                            margin: EdgeInsets.only(top: 4.h),
                                            height: 3.h,
                                            width: 85.w,
                                            color: const Color(0xFFE53935),
                                          ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                  GestureDetector(
                                    onTap: () => provider.updateFrameTab(1),
                                    child: AppText(
                                      "Animated Frames",
                                      style: TextStyle(
                                        color: provider.selectedFrameTab == 1
                                            ? (isDark
                                                  ? Colors.white
                                                  : Colors.black)
                                            : Colors.grey.shade400,
                                        fontSize: 14.sp,
                                        fontWeight:
                                            provider.selectedFrameTab == 1
                                            ? FontWeight.w900
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 16.h),

                              // Frames Horizontal ListView
                              SizedBox(
                                height: 145.h,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: provider.staticFrames.length,
                                  itemBuilder: (context, index) {
                                    final frame = provider.staticFrames[index];

                                    return Container(
                                      width: 110.w,
                                      margin: EdgeInsets.only(right: 12.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF1E1E1E)
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                                border: Border.all(
                                                  color: isDark
                                                      ? Colors.grey.shade800
                                                      : Colors.grey.shade300,
                                                  width: 1.2,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10.r),
                                                child: Stack(
                                                  children: [
                                                    Positioned.fill(
                                                      child: Container(
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF1E1E1E,
                                                              )
                                                            : Colors.white,
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 8.h,
                                                      left: 0,
                                                      right: 0,
                                                      child: Center(
                                                        child: Image.asset(
                                                          "assets/images/abslogo.png",
                                                          height: 18.h,
                                                          errorBuilder:
                                                              (
                                                                _,
                                                                __,
                                                                ___,
                                                              ) => Icon(
                                                                Icons
                                                                    .auto_awesome,
                                                                size: 16.sp,
                                                                color:
                                                                    const Color(
                                                                      0xFFE53935,
                                                                    ),
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      bottom: 4.h,
                                                      left: 4.w,
                                                      right: 4.w,
                                                      child:
                                                          provider.isSolidBanner
                                                          ? _buildSolidBanner(
                                                              provider,
                                                            )
                                                          : _buildOutlineBanner(
                                                              provider,
                                                            ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 6.h),
                                          AppText(
                                            frame["price"] ??
                                                (index == 0
                                                    ? "Free"
                                                    : "Rs.0 (Rs.100 Unlocked)"),
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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

                        SizedBox(height: 12.h),
                        Divider(
                          height: 1,
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                        SizedBox(height: 16.h),

                        const _BrandKitSection(),

                        SizedBox(height: 16.h),
                        Divider(
                          height: 1,
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                        SizedBox(height: 16.h),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.04,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  AppText(
                                    "My Keywords",
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  AppText(
                                    "MANAGE",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 12.h),

                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: (provider.keyWords).map<Widget>((
                                  keywordItem,
                                ) {
                                  final keyword =
                                      keywordItem.name?.trim() ?? '';

                                  if (keyword.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E1E1E)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade300,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: AppText(
                                      keyword,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Divider(
                          height: 1,
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                        SizedBox(height: 16.h),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.04,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                "Online Presence",
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              SizedBox(height: 12.h),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildPresenceTile(
                                      title: "Business Profile",
                                      iconAsset: "assets/images/b_profile.png",
                                      bgColor: isDark
                                          ? const Color(0xFF2A1A1C)
                                          : const Color(0xFFFFECEE),
                                      isDark: isDark,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _buildPresenceTile(
                                      title: "Business Card",
                                      iconAsset: "assets/images/b_card.png",
                                      bgColor: isDark
                                          ? const Color(0xFF1B2A38)
                                          : const Color(0xFFE3F2FD),
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30.h),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _BrandKitSection extends StatefulWidget {
  const _BrandKitSection();

  @override
  State<_BrandKitSection> createState() => _BrandKitSectionState();
}

class _BrandKitSectionState extends State<_BrandKitSection> {
  int selectedTab = 1;

  final List<_BrandPalette> palettes = [
    _BrandPalette(
      name: "My first palette",
      colors: [
        Color(0xFF2864D7),
        Color(0xFF1E3A8A),
        Color(0xFFE53E3E),
        Color(0xFFFF4B4B),
      ],
    ),
    _BrandPalette(
      name: "My first palette",
      colors: [
        Color(0xFF2563EB),
        Color(0xFF172554),
        Color(0xFFDC2626),
        Color(0xFFEF4444),
      ],
    ),
  ];

  final List<_BrandPalette> popularPalettes = [
    _BrandPalette(
      name: "Autumn Harvest",
      colors: [
        Color(0xFFFFB703),
        Color(0xFFFFD166),
        Color(0xFFF4E3C1),
        Color(0xFF6A994E),
      ],
    ),
    _BrandPalette(
      name: "Modern Pop",
      colors: [
        Color(0xFFFF4D6D),
        Color(0xFFFF758F),
        Color(0xFFEF233C),
        Color(0xFF4361EE),
        Color(0xFF3A0CA3),
      ],
    ),
    _BrandPalette(
      name: "Warm Haven",
      colors: [
        Color(0xFFD98C8C),
        Color(0xFFE7B7A3),
        Color(0xFFEFE3C8),
        Color(0xFF6A994E),
        Color(0xFF9AA6B2),
      ],
    ),
    _BrandPalette(
      name: "Urban Slate",
      colors: [
        Color(0xFF78909C),
        Color(0xFF90A4AE),
        Color(0xFF263238),
        Color(0xFF37474F),
        Color(0xFFECEFF1),
      ],
    ),
    _BrandPalette(
      name: "Cinnamon Blend",
      colors: [
        Color(0xFFB0BEC5),
        Color(0xFF8D6E63),
        Color(0xFF795548),
        Color(0xFF6D4C41),
        Color(0xFF4E342E),
      ],
    ),
    _BrandPalette(
      name: "Golden Meadow",
      colors: [
        Color(0xFF8BC34A),
        Color(0xFFAED581),
        Color(0xFFFFCA28),
        Color(0xFF26A69A),
        Color(0xFFF5E6C8),
      ],
    ),
    _BrandPalette(
      name: "Cozy Twilight",
      colors: [
        Color(0xFFB8A9D6),
        Color(0xFF8E9AAF),
        Color(0xFF253858),
        Color(0xFFE7B8B8),
        Color(0xFFD98F8F),
      ],
    ),
    _BrandPalette(
      name: "Blush Bloom",
      colors: [
        Color(0xFFFFCAD4),
        Color(0xFFFFB3C1),
        Color(0xFFFF8FAB),
        Color(0xFFE76F9A),
        Color(0xFFD45087),
      ],
    ),
    _BrandPalette(
      name: "Sandstone",
      colors: [
        Color(0xFFF4E9D8),
        Color(0xFFE6D5B8),
        Color(0xFFD5BDAF),
        Color(0xFFC5A880),
        Color(0xFF9C755F),
      ],
    ),
    _BrandPalette(
      name: "Lavender Meadow",
      colors: [
        Color(0xFF2B2D66),
        Color(0xFF5C5AA8),
        Color(0xFF8E8CC7),
        Color(0xFFB8D8D8),
        Color(0xFF9ED8C5),
        Color(0xFF252A34),
      ],
    ),
    _BrandPalette(
      name: "Spring Blossom",
      colors: [
        Color(0xFFE63946),
        Color(0xFFFFB703),
        Color(0xFF90BE6D),
        Color(0xFFA8DADC),
        Color(0xFFB8A9D6),
      ],
    ),
    _BrandPalette(
      name: "Sunset Coral",
      colors: [
        Color(0xFFE63946),
        Color(0xFFF94144),
        Color(0xFFF3722C),
        Color(0xFF43AA8B),
        Color(0xFF577590),
      ],
    ),
    _BrandPalette(
      name: "Floral Charm",
      colors: [
        Color(0xFFFFB5C5),
        Color(0xFFF6C6D8),
        Color(0xFFA8D5BA),
        Color(0xFF8FCB9B),
        Color(0xFFB7D7C5),
      ],
    ),
  ];

  final List<_BrandFont> fonts = const [
    _BrandFont("Heading, Inter - 85", "AeBeeZ"),
    _BrandFont("Subheading, Poppins - 42", "AeBeeZ"),
    _BrandFont("Body text, Inter - 24", "AeBeeZ"),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.layers_rounded,
                    color: const Color(0xFFE53935),
                    size: 21.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Brand Kit",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              _roundPlus(
                isDark: isDark,
                onTap: () => _showCustomColorDialog(context),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          Row(
            children: [
              _kitTab("Logo", 0, isDark),
              SizedBox(width: 16.w),
              _kitTab("Brand Colors", 1, isDark),
              SizedBox(width: 16.w),
              _kitTab("Fonts", 2, isDark),
            ],
          ),
          SizedBox(height: 14.h),

          if (selectedTab == 0)
            _buildLogoTab(context, isDark)
          else if (selectedTab == 1)
            _buildColorsTab(context, isDark)
          else
            _buildFontsTab(context, isDark),
        ],
      ),
    );
  }

  Widget _kitTab(String title, int index, bool isDark) {
    final selected = selectedTab == index;

    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: selected
                  ? (isDark ? Colors.white : Colors.black)
                  : Colors.grey.shade500,
              fontSize: 12.sp,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          SizedBox(height: 5.h),
          if (selected)
            Container(
              height: 2.5.h,
              width: title == "Brand Colors" ? 82.w : 35.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoTab(BuildContext context, bool isDark) {
    final provider = context.read<BusinessProfileProvider>();
    final logoKey = provider.commonProvider.business?.logoS3Key ?? "";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 62.w,
            height: 62.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.black26 : Colors.grey.shade100,
            ),
            clipBehavior: Clip.antiAlias,
            child: logoKey.isEmpty
                ? Icon(Icons.image_outlined, color: Colors.grey, size: 30.sp)
                : Image.network(
                    '${ApiEndpoints.cdnImageUrl}/$logoKey',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image_outlined,
                      color: Colors.grey,
                      size: 30.sp,
                    ),
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Business Logo",
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Your primary brand logo",
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, size: 19.sp, color: Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _buildColorsTab(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Colors",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            _smallPlus(
              isDark: isDark,
              onTap: () => _showCustomColorDialog(context),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        ...palettes.map(
          (palette) =>
              _buildPaletteCard(context, palette, isDark, showDelete: true),
        ),

        SizedBox(height: 6.h),
        Text(
          "Popular Brand Color Palettes",
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),

        ...popularPalettes.map(
          (palette) =>
              _buildPaletteCard(context, palette, isDark, showDelete: false),
        ),
      ],
    );
  }

  Widget _buildPaletteCard(
    BuildContext context,
    _BrandPalette palette,
    bool isDark, {
    required bool showDelete,
  }) {
    final selected = palettes.any(
      (item) =>
          item.name == palette.name &&
          item.colors.length == palette.colors.length &&
          _sameColors(item.colors, palette.colors),
    );

    return GestureDetector(
      onTap: () {
        if (!palettes.contains(palette)) {
          setState(() {
            palettes.add(
              _BrandPalette(
                name: palette.name,
                colors: List<Color>.from(palette.colors),
              ),
            );
          });
        }
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171717) : Colors.white,
          borderRadius: BorderRadius.circular(9.r),
          border: Border.all(
            color: selected
                ? const Color(0xFFE53935)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    palette.name,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 5.w,
                    children: [
                      ...palette.colors.map(
                        (color) => Container(
                          width: 24.w,
                          height: 20.h,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                      ),
                      if (showDelete)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              palettes.remove(palette);
                            });
                          },
                          child: Container(
                            width: 24.w,
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFFFECEE),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 15.sp,
                              color: const Color(0xFFE53935),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (showDelete)
              Icon(
                Icons.delete_outline_rounded,
                size: 17.sp,
                color: const Color(0xFFE53935),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontsTab(BuildContext context, bool isDark) {
    return Column(
      children: fonts.map((font) {
        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171717) : Colors.white,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      font.title,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      font.family,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_outlined,
                size: 17.sp,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _roundPlus({required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30.h,
        width: 30.w,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.add_rounded,
          color: const Color(0xFFE53935),
          size: 21.sp,
        ),
      ),
    );
  }

  Widget _smallPlus({required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 26.h,
        width: 26.w,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.add_rounded,
          color: const Color(0xFFE53935),
          size: 18.sp,
        ),
      ),
    );
  }

  Future<void> _showCustomColorDialog(BuildContext context) async {
    final controller = TextEditingController(text: "#E53935");
    Color selectedColor = const Color(0xFFE53935);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isDark = context.read<CustomThemeProvider>().isDarkMode;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              titlePadding: EdgeInsets.fromLTRB(18.w, 16.h, 12.w, 4.h),
              contentPadding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 16.h),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Choose Your Brand Colors",
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(dialogContext),
                    child: Icon(
                      Icons.cancel,
                      color: const Color(0xFFFF9A9A),
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF202020)
                            : const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34.w,
                            height: 34.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selectedColor,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Custom Colors",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  "Add your brand color using HEX codes or the color picker.",
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "HEX Color",
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: controller,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.tag),
                        hintText: "#E53935",
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () {
                            final color = _colorFromHex(controller.text);
                            if (color != null) {
                              setDialogState(() => selectedColor = color);
                            }
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9.r),
                        ),
                      ),
                      onSubmitted: (value) {
                        final color = _colorFromHex(value);
                        if (color != null) {
                          setDialogState(() => selectedColor = color);
                        }
                      },
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      "Popular Brand Color Palettes",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ...popularPalettes.map(
                      (palette) => GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = palette.colors.first;
                            controller.text = _hex(selectedColor);
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 7.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 9.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF181818)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                palette.name,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Row(
                                children: palette.colors
                                    .map(
                                      (color) => Expanded(
                                        child: Container(
                                          height: 18.h,
                                          margin: EdgeInsets.only(right: 3.w),
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius: BorderRadius.circular(
                                              3.r,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final color =
                        _colorFromHex(controller.text) ?? selectedColor;

                    setState(() {
                      palettes.insert(
                        0,
                        _BrandPalette(
                          name: "My first palette",
                          colors: [color],
                        ),
                      );
                      selectedTab = 1;
                    });

                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Add Color"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value) return false;
    }
    return true;
  }

  Color? _colorFromHex(String value) {
    var hex = value.trim().replaceAll("#", "");

    if (hex.length == 6) {
      hex = "FF$hex";
    }

    if (hex.length != 8) return null;

    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }

  String _hex(Color color) {
    return "#${color.value.toRadixString(16).substring(2).toUpperCase()}";
  }
}

class _BrandPalette {
  final String name;
  final List<Color> colors;

  const _BrandPalette({required this.name, required this.colors});
}

class _BrandFont {
  final String title;
  final String family;

  const _BrandFont(this.title, this.family);
}

Widget _buildOutlineBanner(BusinessProfileProvider businessProvider) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFF0066FF), width: 1.5)),
    ),
    child: Row(
      children: [
        Icon(Icons.phone, color: const Color(0xFF0066FF), size: 6.sp),
        SizedBox(width: 2.w),
        Expanded(
          child: AppText(
            businessProvider.mobileNumber.isEmpty
                ? "+91 9876543210"
                : businessProvider.mobileNumber,
            style: TextStyle(
              color: const Color(0xFF0066FF),
              fontSize: 5.5.sp,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFF0066FF), width: 0.8),
          ),
          child: Row(
            children: [
              Icon(Icons.message, size: 5.sp, color: const Color(0xFF0066FF)),
              SizedBox(width: 1.w),
              Icon(Icons.facebook, size: 5.sp, color: const Color(0xFF0066FF)),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildSolidBanner(BusinessProfileProvider businessProvider) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
    decoration: BoxDecoration(
      color: const Color(0xFF0066FF),
      borderRadius: BorderRadius.circular(4.r),
    ),
    child: Row(
      children: [
        Icon(Icons.phone, color: Colors.white, size: 6.sp),
        SizedBox(width: 2.w),
        Expanded(
          child: AppText(
            businessProvider.mobileNumber.isEmpty
                ? "+91 9876543210"
                : businessProvider.mobileNumber,
            style: TextStyle(
              color: Colors.white,
              fontSize: 5.5.sp,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: Colors.white, width: 0.8),
          ),
          child: Row(
            children: [
              Icon(Icons.message, size: 5.sp, color: Colors.white),
              SizedBox(width: 1.w),
              Icon(Icons.facebook, size: 5.sp, color: Colors.white),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildActionCard({
  required String title,
  required String iconAsset,
  required Color bgColor,
  required bool isDark,
}) {
  return Expanded(
    child: Container(
      height: 100.h,
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconAsset,
            height: 36.h,
            width: 36.w,
            errorBuilder: (_, __, ___) => Icon(
              Icons.folder_outlined,
              size: 32.sp,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 8.h),
          AppText(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildPresenceTile({
  required String title,
  required String iconAsset,
  required Color bgColor,
  required bool isDark,
}) {
  return Container(
    height: 80.h,
    padding: EdgeInsets.all(12.r),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(16.r),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          iconAsset,
          height: 28.h,
          width: 28.w,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.badge_outlined, size: 24.sp, color: Colors.blueAccent),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: AppText(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
