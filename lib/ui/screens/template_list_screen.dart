
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../Api Model/special_days.dart';
import '../../component/appbar_widget.dart';
import '../../component/custom_searchbar.dart';
import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/search_provider.dart';
import '../../network/provider/template_list_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';
import '../../widgets/button_widget.dart';
import '../shimmer/app_loading.dart';
import 'festival_template_list_screen.dart';
import 'package:mmb_app/ui/screens/search_screen.dart';

class TemplateListScreen extends StatelessWidget {
  final String? type;
  final String? range;

  const TemplateListScreen({
    super.key,
    this.type,
    this.range,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("TemplateListScreen type: $type");
    debugPrint("TemplateListScreen range: $range");

    return ChangeNotifierProvider(
      create: (_) => TemplateListProvider()
        ..loadSpecialDays(type: type, range: range),
      child: _TemplateListScreenView(type, range),
    );
  }
}

class _TemplateListScreenView extends StatelessWidget {
  final String? type;
  final String? range;

  const _TemplateListScreenView(this.type, this.range);

  @override
  Widget build(BuildContext context) {
    final isDark =
        context.watch<CustomThemeProvider>().isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Festival',
        showTitle: true,
        showRightIcon: false,
      ),
      body: Stack(
        children: [
          if (!isDark)
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
            child: Consumer<TemplateListProvider>(
              builder: (context, provider, _) {
                // API response data
                final specialDays =
                    provider.specialDays?.data ?? [];

                final searchProvider =
                context.watch<SearchProvider>();

                debugPrint(
                  'Special Days Count: ${specialDays.length}',
                );

                for (final item in specialDays) {
                  debugPrint('Festival: ${item.name}');
                  debugPrint(
                    'Templates Count: ${item.templates.length}',
                  );
                }

                // IMPORTANT: Check actual API list.
                // Do not use an empty local templates list here.
                final Widget content = specialDays.isEmpty
                    ? _buildEmptyState(context)
                    : Padding(
                  padding: EdgeInsets.fromLTRB(
                    12.w,
                    12.h,
                    12.w,
                    30.h,
                  ),
                  child: Column(
                    children: [
                      AppText(
                        "Find the Right Festival Templates",
                        style: TextStyle(
                          color: AppColors.appBlack,
                          fontWeight: FontWeight.w600,
                          fontSize:
                          AppFontSize.fontSize18,
                        ),
                      ),

                      AppText(
                        "Choose the festival to discover ready-to-edit designs for promotions, offers, announcements, and everyday marketing.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.lightedGrey,
                          fontWeight: FontWeight.w400,
                          fontSize:
                          AppFontSize.fontSize14,
                        ),
                      ),

                      SizedBox(height: 10.h),

                      Row(
                        children: [
                          Expanded(
                            child: CustomSearchBar(
                              controller:
                              searchProvider.controller,
                              hintText:
                              "Search your festival",
                              prefixAsset:
                              "assets/images/search.png",
                              suffixAsset:
                              "assets/images/mic.png",
                              borderColor:
                              AppColors.searchBorderColor,

                              onChanged:
                              searchProvider.onTextChanged,

                              suggestions: searchProvider
                                  .suggestions
                                  .map((e) => e.label)
                                  .toList(),

                              showSuggestions: true,

                              onSuggestionTap: (value) {
                                final q = value.trim();

                                if (q.length < 2) return;

                                searchProvider.clearSuggestions();
                                searchProvider.controller.clear();

                                FocusManager
                                    .instance
                                    .primaryFocus
                                    ?.unfocus();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SearchScreen(
                                          initialQuery: q,
                                        ),
                                  ),
                                );
                              },

                              onSubmitted: (query) {
                                final q = query.trim();

                                if (q.length < 2) return;

                                searchProvider.clearSuggestions();
                                searchProvider.controller.clear();

                                FocusManager
                                    .instance
                                    .primaryFocus
                                    ?.unfocus();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SearchScreen(
                                          initialQuery: q,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),

                          SizedBox(width: 10.w),

                          GestureDetector(
                            onTap: () async {
                              final DateTime today =
                              DateUtils.dateOnly(
                                DateTime.now(),
                              );

                              final DateTime lastDayOfMonth =
                              DateTime(
                                today.year,
                                today.month + 1,
                                0,
                              );

                              final DateTimeRange? dateRange =
                              await showDateRangePicker(
                                context: context,
                                firstDate: today,
                                lastDate: lastDayOfMonth,
                                initialDateRange:
                                DateTimeRange(
                                  start: today,
                                  end: today,
                                ),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context)
                                        .copyWith(
                                      colorScheme:
                                      Theme.of(context)
                                          .colorScheme
                                          .copyWith(
                                        primary:
                                        const Color(
                                          0xFFE53935,
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (dateRange != null &&
                                  context.mounted) {
                                final String fromDate =
                                    '${dateRange.start.year}-'
                                    '${dateRange.start.month.toString().padLeft(2, '0')}-'
                                    '${dateRange.start.day.toString().padLeft(2, '0')}';

                                final String toDate =
                                    '${dateRange.end.year}-'
                                    '${dateRange.end.month.toString().padLeft(2, '0')}-'
                                    '${dateRange.end.day.toString().padLeft(2, '0')}';

                                await context
                                    .read<TemplateListProvider>()
                                    .loadSpecialDays(
                                  fromDate: fromDate,
                                  toDate: toDate,
                                );
                              }
                            },
                            child: Image.asset(
                              'assets/images/calender.png',
                              width: 44.w,
                              height: 44.h,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 15.h),

                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => provider.loadSpecialDays(
                            type: type,
                            range: range,
                            showOverlayLoader: false,
                          ),
                          child: GridView.builder(
                            padding: EdgeInsets.only(
                              bottom: 40.h,
                            ),
                            physics:
                            const AlwaysScrollableScrollPhysics(
                              parent:
                              BouncingScrollPhysics(),
                            ),
                            gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10.w,
                              mainAxisSpacing: 10.h,
                              childAspectRatio: 0.78,
                            ),
                            itemCount: specialDays.length,
                            itemBuilder: (context, index) {
                              final item =
                              specialDays[index];

                              if (item.templates.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return _TemplateCard(
                                specialDay: item,
                                specialDayName:
                                item.name ?? '',
                                isDark: isDark,
                                templateCount:
                                item.templates.length,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                return AppLoadingView(
                  isInitialLoading:
                  provider.isInitialLoading,
                  isRefreshing: provider.isRefreshing,
                  isDark: isDark,
                  skeleton: AppShimmerGrid(
                    isDark: isDark,
                    padding: EdgeInsets.fromLTRB(
                      12.w,
                      12.h,
                      12.w,
                      30.h,
                    ),
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                  ),
                  child: content,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TEMPLATE CARD
// ============================================================

class _TemplateCard extends StatelessWidget {
  final SpecialDaysList specialDay;
  final String specialDayName;
  final bool isDark;
  final int templateCount;

  const _TemplateCard({
    required this.specialDay,
    required this.specialDayName,
    required this.isDark,
    required this.templateCount,
  });

  @override
  Widget build(BuildContext context) {
    final key =
        specialDay.thumbnailS3Key?.trim() ?? '';

    final imageUrl = key.isEmpty
        ? ''
        : key.startsWith('http://') ||
        key.startsWith('https://')
        ? key
        : '${ApiEndpoints.cdnImageUrl}/$key';

    return GestureDetector(
      onTap: () {
        if (specialDay.templates.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No templates available'),
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SpecialDayTemplatesScreen(
              specialDayName: specialDayName,
              templates: specialDay.templates,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F1F1F)
                        : Colors.white,
                    borderRadius:
                    BorderRadius.circular(12.r),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl.isEmpty
                      ? const Center(
                    child: Icon(Icons.image_outlined),
                  )
                      : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorWidget: (_, __, ___) =>
                    const Center(
                      child: Icon(
                        Icons.image_not_supported_rounded,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 9.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius:
                      BorderRadius.circular(20.r),
                    ),
                    child: AppText(
                      '$templateCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: AppText(
              specialDayName,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSize.fontSize12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

Widget _buildEmptyState(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) =>
        SingleChildScrollView(
          keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/no_downloads.png',
                      width: 140,
                      height: 140,
                    ),

                    const SizedBox(height: 8),

                     AppText(
                      'No Templates Found',
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    AppText(
                      'We couldn’t find any templates matching your search. Try a different keyword or explore our categories.',
                      textAlign: TextAlign.center,
                      style:  TextStyle( fontSize: AppFontSize.fontSize13,),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Flexible(
                          child: ButtonWidget(
                            buttonPress: () {
                              Navigator.pushNamed(
                                context,
                                '/BrowseTemplatesScreen',
                              );
                            },
                            title: 'Browse Categories',
                            textStyle: TextStyle(
                              fontSize:
                              AppFontSize.fontSize14,
                              color: AppColors.appRed,
                              fontWeight: FontWeight.w600,
                            ),
                            textColor: AppColors.appRed,
                            buttonColor: AppColors.appWhite,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.appRed,
                              ),
                              borderRadius:
                              const BorderRadius.all(
                                Radius.circular(15),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Flexible(
                          child: ButtonWidget(
                            buttonPress: () {},
                            title: 'Clear Search',
                            textStyle: TextStyle(
                              fontSize:
                              AppFontSize.fontSize14,
                              color: AppColors.appWhite,
                              fontWeight: FontWeight.w600,
                            ),
                            textColor: AppColors.appWhite,
                            buttonColor: AppColors.appRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
  );
}

class SpecialDayTemplateItem {
  final SpecialDaysList template;
  final String specialDayName;

  SpecialDayTemplateItem({
    required this.template,
    required this.specialDayName,
  });
}
