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
      child: const _TemplateListScreenView(),
    );
  }
}

class _TemplateListScreenView extends StatelessWidget {
  const _TemplateListScreenView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<CustomThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F8F8),

      appBar: const CustomAppBar(
        title: 'Festival',
        showTitle: true,
        showRightIcon: false,
      ),

      body: SafeArea(
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
                    template: template,
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
                      fontWeight: FontWeight.w500,
                      fontSize: AppFontSize.fontSize16,
                    ),
                  ),

                  AppText(
                    "Choose the festival to discover ready-to-edit designs for promotions, offers, announcements, and everyday marketing.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.grey,
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
                          final DateTimeRange? dateRange = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                            initialDateRange: DateTimeRange(
                              start: DateTime.now(),
                              end: DateTime.now(),
                            ),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: Theme.of(context).colorScheme.copyWith(
                                    primary: const Color(0xFFE53935),
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

                            await context.read<TemplateListProvider>().loadSpecialDays(
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
                      )
                    ],
                  ),

                  SizedBox(height: 15.h),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () {
                        // Refresh-ல் full screen loader வராது
                        return provider.loadSpecialDays();
                      },
                      child: GridView.builder(
                        padding: EdgeInsets.only(bottom: 40.h),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10.w,
                          mainAxisSpacing: 10.h,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: templates.length,
                        itemBuilder: (context, index) {
                          final item = templates[index];

                          return _TemplateCard(
                            template: item.template,
                            specialDayName: item.specialDayName,
                            isDark: isDark,
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
    );
  }
}

// ============================================================
// TEMPLATE CARD
// ============================================================

class _TemplateCard extends StatelessWidget {
  final Template template;
  final String specialDayName;
  final bool isDark;

  const _TemplateCard({
    required this.template,
    required this.specialDayName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final key = template.thumbnailS3Key?.trim() ?? '';

    final imageUrl = key.isEmpty
        ? ''
        : key.startsWith('http://') || key.startsWith('https://')
        ? key
        : '${ApiEndpoints.cdnImageUrl}/$key';

    return GestureDetector(
      onTap: () {
        final templateUid = template.uid?.trim() ?? '';

        if (templateUid.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template UID not available')),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TemplateEditScreen(templateUid: templateUid),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // IMAGE CARD
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFEAEAEA),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl.isEmpty
                  ? Container(
                      color: const Color(0xFFFFE5E5),
                      child: Icon(
                        Icons.image_outlined,
                        color: const Color(0xFFE53935),
                        size: 38.sp,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: isDark
                            ? const Color(0xFF292929)
                            : const Color(0xFFF3F3F3),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFFFE5E5),
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: const Color(0xFFE53935),
                          size: 32.sp,
                        ),
                      ),
                    ),
            ),
          ),

          // TEXT BELOW IMAGE CARD
          Padding(
            padding: EdgeInsets.only(
              top: 6.h,
              left: 4.w,
              right: 4.w,
              bottom: 4.h,
            ),
            child: AppText(
              specialDayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
  final Template template;
  final String specialDayName;

  SpecialDayTemplateItem({
    required this.template,
    required this.specialDayName,
  });
}
