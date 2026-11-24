import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mmb_app/network/provider/search_provider.dart';
import 'package:mmb_app/ui/screens/search_screen.dart';
import 'package:mmb_app/ui/screens/template_detail_screen.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:mmb_app/ui/screens/video_widget/video_widget.dart';
import 'package:mmb_app/ui/screens/widget/download.dart';
import 'package:mmb_app/ui/screens/widget/dwonload_widget.dart';
import 'package:mmb_app/ui/screens/widget/template_popup.dart';
import 'package:mmb_app/ui/screens/widget/template_single_view_sheet.dart';
import 'package:mmb_app/widgets/button_widget.dart';
import 'package:provider/provider.dart';

import '../../Api Model/Template_model.dart';
import '../../Api Model/special_days.dart';
import '../../component/custom_searchbar.dart';
import '../../component/custom_widget.dart';
import '../../component/home_appbar.dart';
import '../../core/api/api_endpoints.dart';
import '../../model/my_space_model.dart';
import '../../network/provider/bottom_provider.dart';
import '../../network/provider/common_provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/favorite_provider.dart';
import '../../network/provider/home_screen_provider.dart';
import '../../network/provider/plan_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';
import '../industry/widgets/scaffold_widget.dart';
import '../shimmer/app_loading.dart';
import '../shimmer/home_shimmer.dart';

const _kRed = Color(0xFFE53935);

/// Builds a full image URL from an S3 key (http urls are returned as is).
String _cdnUrl(String? key) {
  final k = key?.trim() ?? '';
  if (k.isEmpty) return '';
  if (k.startsWith('http://') || k.startsWith('https://')) return k;
  return '${ApiEndpoints.cdnImageUrl}/$k';
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // HomeScreenProvider is created once by CustomBottomNavScreen.
    return const _HomeScreenView();
  }
}

class _LeadBanner {
  final String title;
  final String description;
  final String button;
  final VoidCallback onTap;
  final List<Color> gradient;
  final Color titleColor;
  final Color descriptionColor;

  const _LeadBanner({
    required this.title,
    required this.description,
    required this.button,
    required this.onTap,
    required this.gradient,
    required this.titleColor,
    required this.descriptionColor,
  });
}

class _HomeScreenView extends StatelessWidget {
  const _HomeScreenView();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = context.watch<CustomThemeProvider>().isDarkMode;
    final commonProvider = context.watch<CommonProvider>();
    final homeProvider = context.watch<HomeScreenProvider>();
    final searchProvider = context.watch<SearchProvider>();
    final me = commonProvider.me;

    final bool isInitialLoading =
        (homeProvider.isLoadingCategories || homeProvider.isKeyWordsLoading) &&
        homeProvider.templateCategories.isEmpty &&
        homeProvider.keyWords.isEmpty;

    if (isInitialLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        appBar: const HomeCustomAppBar(),
        body: SafeArea(child: HomeShimmer(isDark: isDark)),
      );
    }

    final bool showBrandSections = me?.data.accountType != 'personal';

    return CommonScaffold(
      isDarkMode: isDark,
      extendBodyBehindAppBar: true,
      appBar: const HomeCustomAppBar(),
      body: Stack(
        children: [
          if (!isDark)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300.h,
              child: Image.asset(
                'assets/images/plan_gradient.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          SafeArea(
            child: RefreshIndicator(
              color: _kRed,
              onRefresh: () async {
                await context.read<HomeScreenProvider>().refreshHomeScreen();
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: size.height * 0.015,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(context, searchProvider),
                      SizedBox(height: 20.h),

                      _buildSectionHeader(
                        title: 'My Space',
                        iconAsset: 'assets/images/myspace.png',
                        isDark: isDark,
                      ),
                      SizedBox(height: 12.h),
                      _buildMySpaceList(
                        homeProvider,
                        isDark,
                        (item) => _onMySpaceTap(context, homeProvider, item),
                      ),
                      SizedBox(height: 20.h),

                      _buildSpecialDaysHeader(context, isDark),
                      SizedBox(height: 12.h),
                      _buildSpecialDaysCalendar(context, homeProvider),
                      SizedBox(height: 12.h),

                      _buildMyZoneHeader(isDark),
                      SizedBox(height: 12.h),
                      _buildMyZoneSlider(homeProvider, isDark),
                      SizedBox(height: 24.h),

                      _buildMyFrameHeader(isDark, context),
                      SizedBox(height: 16.h),
                      _buildLeadBannerSlider(homeProvider, context),
                      SizedBox(height: 20.h),

                      if (showBrandSections) ...[
                        ..._buildBrandPosts(context, homeProvider, isDark),
                        ..._buildBrandVideoPosts(homeProvider, isDark),
                      ],

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: homeProvider.templateCategories.length,
                        itemBuilder: (context, index) => _buildCategorySection(
                          context,
                          homeProvider,
                          index,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // SEARCH + MY SPACE
  // =====================================================================

  Widget _buildSearchBar(BuildContext context, SearchProvider searchProvider) {
    return Hero(
      tag: 'search_bar_hero',
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pushNamed(context, '/SearchScreen'),
          child: AbsorbPointer(
            child: CustomSearchBar(
              hintText: "Search templates, Brand Series...",
              prefixAsset: "assets/images/search.png",
              suffixAsset: "assets/images/mic.png",
              borderColor: AppColors.searchBorderColor,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
  }

  void _onMySpaceTap(
    BuildContext context,
    HomeScreenProvider provider,
    MySpaceModel item,
  ) {
    switch (item.title) {
      case 'CREATE NEW':
        context.read<BottomNavProvider>().updateIndex(0);
        break;
      case 'FOR YOU':
        provider.setSelectedMySpace('FOR YOU');
        break;
      case 'FESTIVAL':
        Navigator.pushNamed(
          context,
          '/TemplateListScreen',
          arguments: {'type': 'holiday', 'range': 'year'},
        );
        break;
      case 'MY BRAND':
        context.read<BottomNavProvider>().updateIndex(4);
        break;
      case 'BRAND SERIES':
        context.read<BottomNavProvider>().updateIndex(1);
        break;
      case 'BRAND FRAMES':
        Navigator.pushNamed(context, '/BusinessFrameScreen');
        break;
      case 'AI HUB':
        Navigator.pushNamed(context, '/ExploreAiToolScreen');
        break;
    }
  }

  Widget _buildMySpaceList(
    HomeScreenProvider provider,
    bool isDark,
    void Function(MySpaceModel item) onTap,
  ) {
    return SizedBox(
      height: 100.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provider.mySpaceList.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = provider.mySpaceList[index];
          final isSelected = provider.selectedMySpace == item.title;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: isSelected ? 104.w : 100.w,
            height: isSelected ? 96.h : 90.h,
            margin: EdgeInsets.only(
              right: 12.w,
              top: isSelected ? 0 : 5.h,
              bottom: isSelected ? 0 : 5.h,
            ),
            child: InkWell(
              onTap: () => onTap(item),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(isSelected ? 8.r : 10.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      item.gradientColors.last.withValues(alpha: 0.1),
                      item.gradientColors.last.withValues(alpha: 0.25),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      item.icon,
                      height: isSelected ? 38.h : 36.h,
                      width: isSelected ? 38.w : 36.w,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 6.h),
                    AppText(
                      item.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: AppFontSize.fontSize10,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =====================================================================
  // SECTION HEADERS
  // =====================================================================

  Widget _buildSectionHeader({
    required String title,
    required String iconAsset,
    bool hasViewAll = false,
    required bool isDark,
    VoidCallback? onViewAll,
  }) {
    final icon = iconAsset.trim();
    final isNetwork = icon.startsWith('http://') || icon.startsWith('https://');
    final isSvg = icon.toLowerCase().endsWith('.svg');

    Widget iconWidget;
    if (icon.isEmpty) {
      iconWidget = _buildDefaultCategoryIcon(isDark);
    } else if (isNetwork && isSvg) {
      iconWidget = SvgPicture.network(
        icon,
        width: 32.w,
        height: 32.w,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _buildDefaultCategoryIcon(isDark),
      );
    } else if (isNetwork) {
      iconWidget = CachedNetworkImage(
        imageUrl: icon,
        width: 32.w,
        height: 32.w,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildDefaultCategoryIcon(isDark),
        errorWidget: (_, __, ___) => _buildDefaultCategoryIcon(isDark),
      );
    } else if (isSvg) {
      iconWidget = SvgPicture.asset(
        icon,
        width: 32.w,
        height: 32.w,
        fit: BoxFit.cover,
      );
    } else {
      iconWidget = Image.asset(
        icon,
        width: 32.w,
        height: 32.w,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultCategoryIcon(isDark),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 32.w,
          height: 32.w,
          child: ClipOval(child: iconWidget),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: AppText(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.darkBlack,
              fontSize: AppFontSize.fontSize18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (hasViewAll) _buildViewAll(isDark, onViewAll),
      ],
    );
  }

  Widget _buildViewAll(bool isDark, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: AppText(
          'VIEW ALL',
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: AppFontSize.fontSize12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultCategoryIcon(bool isDark) {
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.flash_on, color: _kRed, size: 18.sp),
    );
  }

  Widget _buildSpecialDaysHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Image.asset('assets/images/calendar.png', height: 32.h, width: 32.w),
        SizedBox(width: 8.w),
        AppText(
          'Special Days',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.darkBlack,
            fontSize: AppFontSize.fontSize18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18.r),
            onTap: () => Navigator.pushNamed(context, '/SpecialDaysScreen'),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 5.h),
              child: AppText(
                'VIEW ALL',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: AppFontSize.fontSize12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyZoneHeader(bool isDark) {
    return Row(
      children: [
        Image.asset('assets/images/myzone.png', height: 32.h, width: 32.w),
        SizedBox(width: 8.w),
        AppText(
          'My Zone',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.darkBlack,
            fontSize: AppFontSize.fontSize18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // SPECIAL DAYS
  // =====================================================================

  Widget _buildSpecialDaysCalendar(
    BuildContext context,
    HomeScreenProvider provider,
  ) {
    final range = provider.specialDaysRange;

    final List<DateTime> dates = [];
    int month;

    if (range == null) {
      dates.add(DateTime.now());
      month = DateTime.now().month;
    } else {
      final fromDate = range.from;
      final toDate = range.to;
      if (fromDate == null || toDate == null) return const SizedBox.shrink();

      final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
      final to = DateTime(toDate.year, toDate.month, toDate.day);

      var current = from;
      while (!current.isAfter(to)) {
        dates.add(current);
        current = current.add(const Duration(days: 1));
      }
      month = from.month;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateContainer(provider, dates, month),
        SizedBox(height: 12.h),
        if (provider.isLoadingSpecialDays)
          _miniLoader()
        else
          _buildSpecialDaysApiList(context, provider),
      ],
    );
  }

  Widget _miniLoader() {
    return const Center(
      child: SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildDateContainer(
    HomeScreenProvider provider,
    List<DateTime> dates,
    int month,
  ) {
    final now = DateTime.now();
    final selected = provider.selectedDates;

    int selectedIndex = dates.indexWhere((date) {
      if (selected == null || selected.isEmpty) return false;
      final parsed = DateTime.tryParse(selected);
      return parsed != null &&
          parsed.year == date.year &&
          parsed.month == date.month &&
          parsed.day == date.day;
    });

    if (selectedIndex < 0) {
      selectedIndex = dates.indexWhere(
        (date) =>
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day,
      );
    }
    if (selectedIndex < 0 && dates.isNotEmpty) selectedIndex = 0;

    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(15.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(
            width: 62.w,
            height: double.infinity,
            color: const Color(0xFFF51B23),
            alignment: Alignment.center,
            child: AppText(
              _monthName(month),
              style: TextStyle(
                color: Colors.white,
                fontSize: AppFontSize.fontSize16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              physics: const BouncingScrollPhysics(),
              itemCount: dates.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected = index == selectedIndex;

                return GestureDetector(
                  onTap: () => provider.setSelectedDate(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFFFF7F7),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF51B23)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: AppText(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 12.w, left: 2.w),
            child: GestureDetector(
              onTap: provider.specialDaysRange == null
                  ? null
                  : provider.loadNextSpecialDaysRange,
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 19.sp,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'March',
      'April',
      'May',
      'June',
      'July',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  Widget _buildSpecialDaysApiList(
    BuildContext context,
    HomeScreenProvider provider,
  ) {
    final List<Template> allTemplates = [];
    final Set<String> addedKeys = {};

    for (final event in provider.specialDays) {
      for (final template in event.templates) {
        final uid = template.uid?.trim() ?? '';
        final uniqueKey = uid.isNotEmpty
            ? uid
            : '${template.id ?? ''}_${template.name ?? ''}';

        if (addedKeys.add(uniqueKey)) allTemplates.add(template);
      }
    }

    if (allTemplates.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: 4.w, top: 2.h),
        child: Center(
          child: AppText(
            'No special days for this date',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(left: 2.w, right: 12.w),
        itemCount: allTemplates.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) =>
            _buildSpecialDayTemplateCard(context, allTemplates[index]),
      ),
    );
  }

  Widget _buildSpecialDayTemplateCard(BuildContext context, Template template) {
    final imageUrl = _cdnUrl(template.thumbnailS3Key);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _customizeTemplate(context, template),
      child: Container(
        width: 145.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: imageUrl.isEmpty
                  ? _specialDayPlaceholder()
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey.shade100,
                        child: _miniLoader(),
                      ),
                      errorWidget: (_, __, ___) => _specialDayPlaceholder(),
                    ),
            ),
            _buildCardTopBar(context, template),
          ],
        ),
      ),
    );
  }

  Widget _specialDayPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFFFE5E5),
      child: const Center(
        child: Icon(Icons.image_outlined, color: _kRed, size: 35),
      ),
    );
  }

  // =====================================================================
  // CARD TOP BAR  (crown + favorite / customize popup, shared by cards)
  // =====================================================================

  Widget _buildCardTopBar(BuildContext context, dynamic template) {
    final locked = (template.isLocked as bool?) ?? false;
    final familyUid = (template.familyUid as String?)?.trim() ?? '';

    return Positioned(
      top: 5.h,
      left: 5.w,
      right: 5.w,
      child: SizedBox(
        height: 38.h,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (locked)
              SizedBox(
                width: 24.w,
                height: 28.h,
                child: Image.asset(
                  'assets/images/crown.png',
                  fit: BoxFit.contain,
                ),
              )
            else
              SizedBox(width: 24.w, height: 28.h),

            Flexible(
              child: Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: 38.w,
                  height: 25.h,
                  child: TemplateActionPopup(
                    isFavorite: true,
                    showDownload: false,
                    showDelete: false,
                    onCustomize: () => _customizeTemplate(context, template),
                    onDownload: () => _downloadTemplate(template),
                    onFavorite: () => _toggleFavorite(context, familyUid),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(BuildContext context, String familyUid) async {
    if (familyUid.isEmpty) return;

    final ok = await context.read<FavoriteProvider>().toggle(familyUid);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('Something went wrong. Try again.')),
      );
    }
  }

  Future<void> _downloadTemplate(dynamic template) async {
    final url = _cdnUrl(template.thumbnailS3Key as String?);
    if (url.isEmpty) return;
    await downloadThumbnail(url);
  }

  /// Opens the detail screen (premium templates show the upgrade dialog).
  void _customizeTemplate(BuildContext context, dynamic template) {
    final uid = (template.uid as String?)?.trim() ?? '';
    if (uid.isEmpty) {
      _showUidMissing(context);
      return;
    }

    int? categoryId;
    try {
      final dynamic raw = template.categoryId;
      categoryId = raw is int ? raw : int.tryParse('$raw');
    } catch (_) {
      categoryId = null;
    }

    TemplateQuickViewSheet.show(
      context,
      templateUid: uid,
      categoryId: categoryId,
    );
  }

  void _showUidMissing(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: AppText('Template UID not available')),
    );
  }

  /// Template tap -> Template Detail screen
  void _openTemplateDetail(BuildContext context, dynamic template) {
    final uid = (template.uid?.toString().trim()) ?? '';
    if (uid.isEmpty) {
      _showUidMissing(context);
      return;
    }

    int? categoryId;
    try {
      final dynamic raw = template.categoryId;
      categoryId = raw is int ? raw : int.tryParse('$raw');
    } catch (_) {
      categoryId = null;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TemplateDetailScreen(templateUid: uid, categoryId: categoryId),
      ),
    );
  }

  // =====================================================================
  // MY BRAND POSTS / VIDEO POSTS
  // =====================================================================

  List<Widget> _buildBrandPosts(
    BuildContext context,
    HomeScreenProvider provider,
    bool isDark,
  ) {
    return [
      _buildSectionHeader(
        title: 'My Brand Posts',
        iconAsset: 'assets/images/my_brand_posts.png',
        hasViewAll: true,
        isDark: isDark,
        onViewAll: () {
          final tag = provider.selectedKeyword?.trim() ?? '';
          Navigator.pushNamed(
            context,
            '/BrowseTemplatesScreen',
            arguments: {if (tag.isNotEmpty) 'tag': tag},
          );
        },
      ),
      SizedBox(height: 12.h),
      _buildKeywordChips(provider, isDark),
      SizedBox(height: 16.h),
      SizedBox(
        height: 190.h,
        child: _buildPopularTemplates(context, provider, isDark),
      ),
      SizedBox(height: 12.h),
    ];
  }

  List<Widget> _buildBrandVideoPosts(HomeScreenProvider provider, bool isDark) {
    return [
      _buildSectionHeader(
        title: 'My Brand Video Posts',
        iconAsset: 'assets/images/my_brand_posts.png',
        hasViewAll: true,
        isDark: isDark,
      ),
      SizedBox(height: 12.h),
      _buildKeywordChips(provider, isDark),
      SizedBox(height: 16.h),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.brandVideoPostsList.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          final videoData = provider.brandVideoPostsList[index];
          return BrandVideoCard(
            thumbnailUrl: videoData['thumbnail'] ?? '',
            videoUrl: videoData['videoUrl'] ?? '',
          );
        },
      ),
      SizedBox(height: 12.h),
    ];
  }

  Widget _buildKeywordChips(HomeScreenProvider provider, bool isDark) {
    return SizedBox(
      height: 38.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(right: 8.w),
        itemCount: provider.keyWords.length,
        itemBuilder: (context, index) {
          final keyword = provider.keyWords[index].name?.trim() ?? '';
          if (keyword.isEmpty) return const SizedBox.shrink();

          final selected = provider.selectedKeyword == keyword;

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap: () => provider.fetchTemplatesByPopular(keyword: keyword),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFFFECEE)
                      : isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: selected
                        ? Colors.red
                        : isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                    width: 1.2,
                  ),
                ),
                child: AppText(
                  keyword,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: AppFontSize.fontSize14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularTemplates(
    BuildContext context,
    HomeScreenProvider provider,
    bool isDark,
  ) {
    if (provider.isLoadingPopularTemplates) {
      return const Center(
        child: CircularProgressIndicator(color: _kRed, strokeWidth: 2),
      );
    }

    if (provider.popularTemplates.isEmpty) {
      return Center(
        child: AppText(
          'No templates available',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
            fontSize: 13.sp,
          ),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: provider.popularTemplates.length,
      itemBuilder: (context, index) {
        final item = provider.popularTemplates[index];
        final imageUrl = _cdnUrl(item.thumbnailS3Key);

        return Padding(
          padding: EdgeInsets.only(right: 12.w),
          child: InkWell(
            onTap: () => _customizeTemplate(context, item),
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              width: 145.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: imageUrl.isEmpty
                    ? const Center(
                        child: Icon(Icons.image_outlined, color: Colors.grey),
                      )
                    : buildProfileImage(imageUrl),
              ),
            ),
          ),
        );
      },
    );
  }

  // =====================================================================
  // CATEGORY SECTIONS
  // =====================================================================

  Widget _buildCategorySection(
    BuildContext context,
    HomeScreenProvider provider,
    int index,
    bool isDark,
  ) {
    final category = provider.templateCategories[index];
    final name = category.name?.trim() ?? '';
    final lower = name.toLowerCase();
    final slug = category.slug?.trim() ?? '';

    final bool isSpecial =
        lower == 'celebrate moments' ||
        lower == 'devotional/daily posts' ||
        lower == 'devotional / daily posts';

    if (isSpecial) {
      if (category.children.isEmpty) return const SizedBox.shrink();
      return _buildSpecialCategory(
        context,
        name: name,
        isCelebrate: lower == 'celebrate moments',
        children: category.children,
        isDark: isDark,
      );
    }

    if (slug.isEmpty) return const SizedBox.shrink();

    final templates = provider.templatesForCategory(slug);
    final isLoading = provider.isTemplateLoading(slug);
    final bool isYoutube =
        slug.toLowerCase() == 'youtube-thumbnails' ||
        lower == 'youtube thumbnails';

    Widget content;
    if (isLoading) {
      content = AppShimmer(
        isDark: isDark,
        child: SizedBox(
          height: isYoutube ? 175.h : 165.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (_, __) =>
                ShimmerBox(width: isYoutube ? 220.w : 145.w, radius: 16.r),
          ),
        ),
      );
    } else if (templates.isEmpty) {
      content = SizedBox(
        height: isYoutube ? 250.h : 110.h,
        child: Center(
          child: AppText(
            'No templates available',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 13.sp,
            ),
          ),
        ),
      );
    } else if (isYoutube) {
      content = _buildYoutubeGrid(context, templates, isDark);
    } else {
      content = SizedBox(
        height: 165.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: templates.length,
          separatorBuilder: (_, __) => SizedBox(width: 0.5.w),
          itemBuilder: (context, i) => SizedBox(
            width: 145.w,
            child: _buildApiTemplateCard(context, templates[i], isDark),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: name,
            iconAsset: _cdnUrl(category.iconS3Key),
            hasViewAll: true,
            isDark: isDark,
            onViewAll: () => Navigator.pushNamed(
              context,
              '/TemplateDetailScreen',
              arguments: {'category': slug},
            ),
          ),
          SizedBox(height: 12.h),
          content,
        ],
      ),
    );
  }

  /// "Celebrate Moments" / "Devotional" -> horizontal list of sub categories.
  Widget _buildSpecialCategory(
    BuildContext context, {
    required String name,
    required bool isCelebrate,
    required List<dynamic> children,
    required bool isDark,
  }) {
    final categoryIcon = isCelebrate
        ? 'assets/images/flash.png'
        : 'assets/images/devotional.png';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(5.w, 14.h, 12.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(categoryIcon, width: 32.w, height: 32.w),
              SizedBox(width: 8.w),
              AppText(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSize.fontSize18,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 112.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: children.length,
              separatorBuilder: (_, __) => SizedBox(width: 7.w),
              itemBuilder: (context, i) {
                final child = children[i];
                final childName = child.name?.trim() ?? '';
                final childSlug = child.slug?.trim() ?? '';
                final imageUrl = _cdnUrl(child.iconS3Key);

                return SizedBox(
                  width: 90.w,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/TemplateDetailScreen',
                      arguments: {
                        'category': childSlug,
                        'categoryUid': child.uid,
                        'categoryName': child.name,
                      },
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: Container(
                            width: 84.w,
                            height: 88.w,
                            color: isDark
                                ? const Color(0xFF252525)
                                : Colors.grey.shade100,
                            child: imageUrl.isEmpty
                                ? Icon(
                                    Icons.image_outlined,
                                    size: 28.sp,
                                    color: Colors.grey,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: 84.w,
                                    height: 88.w,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => _defaultLogo(),
                                    errorWidget: (_, __, ___) => _defaultLogo(),
                                  ),
                          ),
                        ),
                        SizedBox(
                          height: 30.h,
                          child: AppText(
                            childName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: AppFontSize.fontSize12.sp,
                              fontWeight: FontWeight.w400,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// YouTube thumbnails: 2 x 2 grid per horizontal page.
  Widget _buildYoutubeGrid(
    BuildContext context,
    List<TemplateModel> templates,
    bool isDark,
  ) {
    final double totalHeight = 175.h;
    final double horizontalGap = 3.w;
    final double verticalGap = 13.w;
    final double cardHeight = (totalHeight - (verticalGap * 3)) / 2;
    final int pageCount = (templates.length / 4).ceil();

    Widget cell(int i) => Expanded(
      child: i < templates.length
          ? _buildApiTemplateCard(context, templates[i], isDark)
          : const SizedBox(),
    );

    Widget row(int first) => SizedBox(
      height: cardHeight,
      child: Row(
        children: [
          cell(first),
          SizedBox(width: horizontalGap),
          cell(first + 1),
        ],
      ),
    );

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double pageWidth = constraints.maxWidth * 0.92;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: pageCount,
            itemBuilder: (context, pageIndex) {
              final int start = pageIndex * 4;

              return SizedBox(
                width: pageWidth,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalGap,
                    vertical: verticalGap,
                  ),
                  child: Column(
                    children: [
                      row(start),
                      SizedBox(height: verticalGap),
                      row(start + 2),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildApiTemplateCard(
    BuildContext context,
    TemplateModel template,
    bool isDark,
  ) {
    final imageUrl = _cdnUrl(template.thumbnailS3Key);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _customizeTemplate(context, template),
      child: Container(
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageUrl.isEmpty
                  ? _templateImagePlaceholder(isDark)
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) =>
                          _templateImagePlaceholder(isDark),
                    ),
              _buildCardTopBar(context, template),
            ],
          ),
        ),
      ),
    );
  }

  Widget _templateImagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
      child: Icon(
        Icons.image_outlined,
        size: 36.sp,
        color: Colors.grey.shade400,
      ),
    );
  }

  // =====================================================================
  // MY ZONE
  // =====================================================================

  Future<void> _onDownloadMyZone(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = await context.read<HomeScreenProvider>().downloadMyZone();
    messenger.showSnackBar(SnackBar(content: AppText(message)));
  }

  Widget _buildMyZoneSlider(HomeScreenProvider provider, bool isDark) {
    final popularTemplates = provider.popularTemplates.take(4).toList();

    return SizedBox(
      height: 360.h,
      child: popularTemplates.isEmpty
          ? Container(
              margin: EdgeInsets.symmetric(horizontal: 25.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Image.asset(
                  'assets/images/BName.png',
                  fit: BoxFit.cover,
                ),
              ),
            )
          : PageView.builder(
              controller: provider.zonePageController,
              itemCount: popularTemplates.length,
              itemBuilder: (context, index) {
                final item = popularTemplates[index];
                final imageUrl = _cdnUrl(item.thumbnailS3Key);
                final phone =
                    provider.provider.me?.data.phone?.toString() ?? '';
                final email =
                    provider.provider.me?.data.email?.toString() ?? '';

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 25.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    color: isDark
                        ? const Color(0xFF1E1E1E)
                        : Colors.grey.shade100,
                  ),
                  // Everything inside this boundary is what gets downloaded.
                  child: RepaintBoundary(
                    key: provider.zoneKey(index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned.fill(child: buildProfileImage(imageUrl)),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 55.h,
                            child: ClipPath(
                              clipper: BottomWaveClipper(),
                              child: Container(
                                padding: EdgeInsets.only(
                                  left: 20.w,
                                  right: 20.w,
                                  top: 12.h,
                                ),
                                color: const Color(0xFF246BFE),
                                child: Row(
                                  children: [
                                    SizedBox(width: 8.w),
                                    Icon(
                                      Icons.phone,
                                      color: Colors.white,
                                      size: 14.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        phone,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 5.w),
                                    Expanded(
                                      flex: 6,
                                      child: Text(
                                        email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // =====================================================================
  // MY FRAME HEADER
  // =====================================================================

  Widget _circleAction({
    required bool isDark,
    required VoidCallback onTap,
    required String asset,
  }) {
    return Container(
      width: 38.w,
      height: 38.w,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A2929) : const Color(0xFFFFE5E5),
        shape: BoxShape.circle,
      ),
      child: InkWell(onTap: onTap, child: Image.asset(asset)),
    );
  }

  Widget _buildMyFrameHeader(bool isDark, BuildContext context) {
    return Row(
      children: [
        AppText(
          'MY FRAME - 1',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.darkBlack,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3A2929) : const Color(0xFFFFE5E5),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              // TODO: more options
            },
            icon: Icon(Icons.more_vert_rounded, color: Colors.red, size: 19.sp),
          ),
        ),
        const Spacer(),
        _circleAction(
          isDark: isDark,
          asset: 'assets/images/frame_edit.png',
          onTap: () {
            final popular = context.read<HomeScreenProvider>().popularTemplates;
            final template = popular.isNotEmpty ? popular.first : null;
            final templateUid = template?.uid?.trim() ?? '';

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => templateUid.isNotEmpty
                    ? TemplateEditScreen(templateUid: templateUid)
                    : const TemplateEditScreen(),
              ),
            );
          },
        ),
        SizedBox(width: 8.w),
        _circleAction(
          isDark: isDark,
          asset: 'assets/images/content.png',
          onTap: () {
            CommonShareBottomSheet.show(
              context: context,
              isDark: isDark,
              onDownload: () => _onDownloadMyZone(context),
              onInstagram: () {},
              onFacebook: () {},
              onX: () {},
              onLinkedIn: () {},
              onPinterest: () {},
              onBoost: () {},
              onWhatsApp: () {},
              onMessenger: () {},
              onDrive: () {},
              onCopyLink: () {},
              onCaption: () {},
              onSchedule: () {},
            );
          },
        ),
      ],
    );
  }

  // =====================================================================
  // LEAD BANNERS
  // =====================================================================

  Future<void> _openPlanScreen(BuildContext context) async {
    final bool hasActivePlan = await PlanProvider().fetchMySubscription();
    if (!context.mounted) return;

    if (hasActivePlan) {
      Navigator.pushNamed(context, '/MySubscriptionScreen');
    } else {
      Navigator.pushNamed(
        context,
        '/FreePlanScreen',
        arguments: {'showSkip': true},
      );
    }
  }

  Widget _buildLeadBannerSlider(
    HomeScreenProvider provider,
    BuildContext context,
  ) {
    final controller = provider.leadPageController;

    final banners = <_LeadBanner>[
      _LeadBanner(
        title: 'Grow Your Business',
        description:
            'List your business on MMB and get discovered by potential customers.',
        button: 'GO PREMIUM',
        onTap: () => _openPlanScreen(context),
        gradient: const [Color(0xFFFFEEEE), Color(0xFFFFF9EA)],
        titleColor: const Color(0xFFD4A017),
        descriptionColor: const Color(0xFF333333),
      ),
      _LeadBanner(
        title: '2000+ Business Templates',
        description: 'Find ready-made templates designed for your industry',
        button: 'BROWSE TEMPLATES',
        onTap: () => Navigator.pushNamed(context, '/SpecialDaysScreen'),
        gradient: const [Color(0xFFEEF4FF), Color(0xFFEEEAFF)],
        titleColor: const Color(0xFF8D77FB),
        descriptionColor: const Color(0xFF343434),
      ),
      _LeadBanner(
        title: 'Powerful AI Tools',
        description:
            'Generate logos, remove backgrounds, create images, and write caption instantly',
        button: 'EXPLORE AI',
        onTap: () => Navigator.pushNamed(context, '/ExploreAiToolScreen'),
        gradient: const [Color(0xFFFFFBEE), Color(0xFFEAFEFF)],
        titleColor: const Color(0xFF26A3D9),
        descriptionColor: const Color(0xFF303030),
      ),
    ];

    return SizedBox(
      height: 165.h,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: banners.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final banner = banners[index];

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: banner.onTap, // full container click
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: banner.gradient,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          banner.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: banner.titleColor,
                            fontSize: AppFontSize.fontSize24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        AppText(
                          banner.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: banner.descriptionColor,
                            fontSize: AppFontSize.fontSize16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 7.h),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            height: 28.h,
                            child: IntrinsicWidth(
                              child: ButtonWidget(
                                buttonPress:
                                    banner.onTap, // button click (as before)
                                title: banner.button,
                                buttonColor: banner.titleColor,
                                textStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize: AppFontSize.fontSize14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 7.h),
          _buildBannerDots(controller, banners.length),
        ],
      ),
    );
  }

  Widget _buildBannerDots(PageController controller, int itemCount) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        int currentIndex = 0;
        if (controller.hasClients && controller.page != null) {
          currentIndex = controller.page!.round().clamp(0, itemCount - 1);
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(itemCount, (index) {
            final isActive = currentIndex == index;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: isActive ? 24.w : 7.w,
              height: 7.h,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF17295C)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10.r),
              ),
            );
          }),
        );
      },
    );
  }

  Widget buildProfileImage(String imageUrl) {
    if (imageUrl.isEmpty) return _defaultLogo();

    final path = Uri.tryParse(imageUrl)?.path.toLowerCase() ?? '';

    if (path.endsWith('.svg')) {
      return SvgPicture.network(
        imageUrl,
        width: 50.w,
        height: 50.w,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _defaultLogo(),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: imageUrl,
      width: 50.w,
      height: 50.w,
      fit: BoxFit.cover,
      placeholder: (_, __) => _defaultLogo(),
      errorWidget: (_, url, error) {
        debugPrint('Image load failed: $url | $error');
        return _defaultLogo();
      },
    );
  }

  Widget _defaultLogo() {
    return Image.asset(
      'assets/images/BName.png',
      width: 50.w,
      height: 50.w,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 50.w,
        height: 50.w,
        color: const Color(0xFFE91E63),
        child: const Icon(Icons.business, color: Colors.white),
      ),
    );
  }
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start from bottom-left
    path.moveTo(0, size.height);

    // Upward curve on the left side
    path.quadraticBezierTo(size.width * 0.15, 0, size.width * 0.35, 0.5.h);

    // Across the top right, then down to the bottom-right
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
