import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:provider/provider.dart';

import '../../Api Model/special_days.dart';
import '../../component/appbar_widget.dart';
import '../../component/custom_searchbar.dart';
import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/special_days_provider.dart';
import '../../network/provider/template_list_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';
import 'festival_template_list_screen.dart';

class TemplateListScreen extends StatelessWidget {
  final String? type;
  final String? range;

  const TemplateListScreen({super.key, this.type, this.range});

  @override
  Widget build(BuildContext context) {
    debugPrint("🎉 TemplateListScreen type: $type");
    debugPrint("🎉 TemplateListScreen range: $range");

    return ChangeNotifierProvider(
      create: (_) =>
          TemplateListProvider()..loadSpecialDays(type: type, range: range),
      child:  _TemplateListScreenView(type,range),
    );
  }
}

class _TemplateListScreenView extends StatelessWidget {
  final String? type;
  final String? range;
  const _TemplateListScreenView( this.type, this.range);

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<CustomThemeProvider>().isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: const CustomAppBar(
        title: 'Festival',
        showTitle: true,
        showRightIcon: false,
      ),

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
            child: Consumer<TemplateListProvider>(
              builder: (context, provider, _) {
                // First screen load மட்டும் loader
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE53935)),
                  );
                }

                final specialDays = provider.specialDays?.data ?? [];

                final List<SpecialDayTemplateItem> templates = [];

                for (final specialDay in specialDays) {
                  for (final template in specialDay.templates) {
                    templates.add(
                      SpecialDayTemplateItem(
                        template: specialDay,
                        specialDayName: specialDay.name ?? '',
                      ),
                    );
                  }
                }

                if (templates.isEmpty) {
                  return _EmptyState(isDark: isDark);
                }

                return Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 30.h),
                  child: Column(
                    children: [
                      AppText(
                        "Find the Right Festival Templates",
                        style: TextStyle(
                          color: AppColors.appBlack,
                          fontWeight: FontWeight.w600,
                          fontSize: AppFontSize.fontSize18,
                        ),
                      ),

                      AppText(
                        "Choose the festival to discover ready-to-edit designs for promotions, offers, announcements, and everyday marketing.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.lightedGrey,
                          fontWeight: FontWeight.w400,
                          fontSize: AppFontSize.fontSize14,
                        ),
                      ),

                      SizedBox(height: 10.h),

                      Row(
                        children: [
                          Expanded(
                            child: CustomSearchBar(
                              hintText: 'Search your festival',
                              showSuffixIcon: false,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          GestureDetector(
                            onTap: () async {
                              final DateTime today = DateUtils.dateOnly(
                                DateTime.now(),
                              );

                              final DateTimeRange? dateRange =
                                  await showDateRangePicker(
                                    context: context,
                                    firstDate: today,
                                    lastDate: DateTime(2035),
                                    initialDateRange: DateTimeRange(
                                      start: today,
                                      end: today,
                                    ),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: Theme.of(context)
                                              .colorScheme
                                              .copyWith(
                                                primary: const Color(
                                                  0xFFE53935,
                                                ),
                                              ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );

                              if (dateRange != null && context.mounted) {
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
                          onRefresh: () => provider.loadSpecialDays(type: type, range: range),
                          child: GridView.builder(
                            padding: EdgeInsets.only(bottom: 40.h),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
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
                              final item = specialDays[index];

                              if (item.templates.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return _TemplateCard(
                                specialDay: item,
                                specialDayName: item.name ?? '',
                                isDark: isDark,
                                templateCount: item.templates.length,
                              );
                            },
                          ),
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
    );
  }
}

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
    final key = specialDay.thumbnailS3Key?.trim() ?? '';

    final imageUrl = key.isEmpty
        ? ''
        : key.startsWith('http://') || key.startsWith('https://')
        ? key
        : '${ApiEndpoints.cdnImageUrl}/$key';

    return GestureDetector(
      onTap: () {
        if (specialDay.templates.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No templates available')),
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
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl.isEmpty
                      ? const Center(child: Icon(Icons.image_outlined))
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.image_not_supported_rounded),
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
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
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
                color: isDark ? Colors.white : Colors.black87,
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

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final String message;

  const _EmptyState({
    required this.isDark,
    this.message = 'No special days found',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.w),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 46.sp,
              color: const Color(0xFFE53935),
            ),

            SizedBox(height: 10.h),

            Text(
              message,

              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpecialDayTemplateItem {
  final SpecialDaysList template;
  final String specialDayName;

  SpecialDayTemplateItem({
    required this.template,
    required this.specialDayName,
  });
}
