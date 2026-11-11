import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/appbar_widget.dart';
import 'package:mmb_app/component/custom_searchbar.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/ui/screens/search_screen.dart';
import 'package:mmb_app/ui/screens/template_detail_screen.dart';
import 'package:mmb_app/ui/screens/widget/template_popup.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:provider/provider.dart';

import '../../Api Model/special_days.dart';
import '../../Repository/home_repository.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/special_days_provider.dart';
import '../shimmer/app_loading.dart';

const Color _kRed = Color(0xFFE53935);
const Color _kRedSoft = Color(0xFFFFECEE);

class SpecialDaysScreen extends StatelessWidget {
  const SpecialDaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SpecialDaysProvider()..loadSpecialDays(showLoader: true),
      child: const _SpecialDaysScreenView(),
    );
  }
}

class _SpecialDaysScreenView extends StatelessWidget {
  const _SpecialDaysScreenView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<CustomThemeProvider>().isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: CustomAppBar(
        showTitle: true,
        title: "Special Days",
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
            child: Consumer<SpecialDaysProvider>(
              builder: (context, provider, _) {
                // First open (no data yet) -> shimmer.
                // Date filter (data already there) -> loader on top.
                final bool isFirstLoad =
                    provider.isLoading && provider.specialDays == null;
                final bool isFilterLoading =
                    provider.isLoading && provider.specialDays != null;

                final specialDays = provider.specialDays?.data ?? [];

                final List<SpecialDayTemplateItem> templates = [];

                for (final specialDay in specialDays) {
                  for (final template in specialDay.templates) {
                    templates.add(
                      SpecialDayTemplateItem(
                        template: template,
                        specialDayName: template.name ?? '',
                      ),
                    );
                  }
                }

                // Header (title + search + calendar) is ALWAYS visible, so the
                // user can change the date even when the result is empty.
                final Widget content = Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
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
                              prefixAsset: "assets/images/search.png",
                              suffixAsset: "assets/images/mic.png",
                              borderColor: const Color(0xFFFFCDD2),
                              showSuffixIcon: false,
                              onChanged: (query) {},
                              onSubmitted: (query) {
                                final q = query.trim();
                                if (q.length < 2) return;

                                FocusManager.instance.primaryFocus?.unfocus();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SearchScreen(initialQuery: q),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 10.w),
                          _CalendarButton(isDark: isDark),
                        ],
                      ),

                      SizedBox(height: 15.h),

                      Expanded(
                        child: templates.isEmpty
                            ? _EmptyState(
                          isDark: isDark,
                          message: 'No special days found for these dates',
                        )
                            : RefreshIndicator(
                          color: _kRed,
                          onRefresh: () {
                            // Refresh-ல் full screen loader வராது
                            return provider.loadSpecialDays(
                              showLoader: false,
                            );
                          },
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

                // First open: shimmer. Date filter: screen stays and a normal
                // loader shows on top. Pull-to-refresh uses its own spinner.
                return AppLoadingView(
                  isInitialLoading: isFirstLoad,
                  isRefreshing: isFilterLoading,
                  isDark: isDark,
                  skeleton: AppShimmerGrid(
                    isDark: isDark,
                    padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 30.h),
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
// CALENDAR BUTTON + DATE FILTER
// ============================================================

class _CalendarButton extends StatelessWidget {
  final bool isDark;

  const _CalendarButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF3A2929) : _kRedSoft,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final range = await _pickSpecialDaysRange(context, isDark: isDark);
          if (range == null || !context.mounted) return;

          await context.read<SpecialDaysProvider>().loadSpecialDays(
            fromDate: _formatApiDate(range.start),
            toDate: _formatApiDate(range.end),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Image.asset(
            'assets/images/calender.png',
            width: 28.w,
            height: 28.w,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

String _formatApiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

String _prettyDate(DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${m[d.month - 1]}';
}

class _Preset {
  final String label;
  final IconData icon;
  final DateTimeRange range;

  const _Preset(this.label, this.icon, this.range);
}

const String _customKey = 'custom';

/// Bottom sheet with quick options (Today, Tomorrow, Next 7 days,
/// Rest of this month) + "Pick custom range" that opens the calendar.
/// Returns the chosen range, or null if dismissed.
Future<DateTimeRange?> _pickSpecialDaysRange(
    BuildContext context, {
      required bool isDark,
    }) async {
  final today = DateUtils.dateOnly(DateTime.now());
  final monthEnd = DateTime(today.year, today.month + 1, 0);

  DateTime clamp(DateTime d) => d.isAfter(monthEnd) ? monthEnd : d;

  final presets = <_Preset>[
    _Preset(
      'Today',
      Icons.today_rounded,
      DateTimeRange(start: today, end: today),
    ),
    if (today.isBefore(monthEnd))
      _Preset(
        'Tomorrow',
        Icons.wb_sunny_outlined,
        DateTimeRange(
          start: today.add(const Duration(days: 1)),
          end: today.add(const Duration(days: 1)),
        ),
      ),
    if (today.isBefore(monthEnd))
      _Preset(
        'Next 7 days',
        Icons.date_range_rounded,
        DateTimeRange(
          start: today,
          end: clamp(today.add(const Duration(days: 6))),
        ),
      ),
    if (today.isBefore(monthEnd))
      _Preset(
        'Rest of this month',
        Icons.calendar_month_rounded,
        DateTimeRange(start: today, end: monthEnd),
      ),
  ];

  final Object? choice = await showModalBottomSheet<Object>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
      final fg = isDark ? Colors.white : Colors.black87;
      final sub = isDark ? Colors.white54 : Colors.black45;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // handle
              Center(
                child: Container(
                  height: 4,
                  width: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // title + close
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select dates',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(sheetContext),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A1A1C) : _kRedSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: _kRed, size: 20),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'Special days are available till ${_prettyDate(monthEnd)}',
                style: TextStyle(fontSize: 12.sp, color: sub),
              ),

              SizedBox(height: 18.h),

              // quick options
              Wrap(
                spacing: 10.w,
                runSpacing: 12.h,
                children: presets.map((p) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(30.r),
                    onTap: () => Navigator.pop(sheetContext, p.range),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : _kRedSoft,
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(color: _kRed, width: 1.1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(p.icon, size: 16.sp, color: _kRed),
                          SizedBox(width: 6.w),
                          Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: fg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 20.h),
              Divider(
                height: 1,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              SizedBox(height: 8.h),

              // custom range
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A1A1C) : _kRedSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_calendar_rounded,
                    color: _kRed,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Pick custom range',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                subtitle: Text(
                  'Choose start and end date',
                  style: TextStyle(fontSize: 12.sp, color: sub),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: sub),
                onTap: () => Navigator.pop(sheetContext, _customKey),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      );
    },
  );

  if (choice is DateTimeRange) return choice;
  if (choice != _customKey || !context.mounted) return null;

  // ---------------- custom calendar ----------------
  return showDateRangePicker(
    context: context,
    firstDate: today,
    lastDate: monthEnd,
    initialDateRange: DateTimeRange(start: today, end: today),
    helpText: 'SELECT DATE RANGE',
    saveText: 'APPLY',
    builder: (ctx, child) => _themedPicker(ctx, child, isDark),
  );
}

Widget _themedPicker(BuildContext context, Widget? child, bool isDark) {
  final base = Theme.of(context);
  final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
  final onSurface = isDark ? Colors.white : Colors.black87;

  return Theme(
    data: base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: _kRed,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: onSurface,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _kRed),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: _kRed,
        headerForegroundColor: Colors.white,
        rangeSelectionBackgroundColor: _kRed.withValues(alpha: 0.15),
        rangeSelectionOverlayColor: WidgetStatePropertyAll(
          _kRed.withValues(alpha: 0.10),
        ),
        todayBorder: const BorderSide(color: _kRed, width: 1.2),
        todayForegroundColor: const WidgetStatePropertyAll(_kRed),
        dayShape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    child: child!,
  );
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
        final uid = (template.uid?.toString().trim()) ?? '';

        if (uid.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: AppText('Template UID not available')),
          );
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
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFEAEAEA),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 7,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            Expanded(
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: imageUrl.isEmpty
                        ? Container(
                      color: const Color(0xFFFFE5E5),
                      child: Icon(
                        Icons.image_outlined,
                        color: _kRed,
                        size: 38.sp,
                      ),
                    )
                        : CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) {
                        return Container(
                          color: isDark
                              ? const Color(0xFF292929)
                              : const Color(0xFFF3F3F3),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _kRed,
                            ),
                          ),
                        );
                      },
                      errorWidget: (_, __, ___) {
                        return Container(
                          color: const Color(0xFFFFE5E5),
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: _kRed,
                            size: 32.sp,
                          ),
                        );
                      },
                    ),
                  ),

                  // crown (left, locked only) + popup (always right)
                  Positioned(
                    top: 5.h,
                    left: 5.w,
                    right: 5.w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (template.isLocked)
                          Image.asset(
                            "assets/images/crown.png",
                            width: 20.w,
                            height: 20.w,
                          )
                        else
                          const SizedBox.shrink(),
                        TemplateActionPopup(
                          isFavorite: true,
                          showDownload: false,
                          showDelete: false,
                          onCustomize: () {
                            final uid = (template.uid?.toString().trim()) ?? '';

                            if (uid.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: AppText('Template UID not available'),
                                ),
                              );
                              return;
                            }

                            int? categoryId;
                            try {
                              final dynamic raw = template.categoryId;
                              categoryId = raw is int
                                  ? raw
                                  : int.tryParse('$raw');
                            } catch (_) {
                              categoryId = null;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TemplateDetailScreen(
                                  templateUid: uid,
                                  categoryId: categoryId,
                                ),
                              ),
                            );
                          },
                          onDownload: () async {},
                          onFavorite: () async {
                            final uid = template.uid?.trim() ?? '';
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              barrierColor: Colors.black45,
                              useRootNavigator: true,
                              builder: (_) => const PopScope(
                                canPop: false,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: _kRed,
                                  ),
                                ),
                              ),
                            );

                            try {
                              await HomeRepository.instance.favorite(uid);
                            } catch (e) {
                              debugPrint('Favorite Template Error: $e');
                            } finally {
                              // close loader
                              if (context.mounted) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // SPECIAL DAY NAME
            Padding(
              padding: EdgeInsets.fromLTRB(6.w, 7.h, 6.w, 8.h),
              child: Center(
                child: AppText(
                  specialDayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
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
            Icon(Icons.event_busy_rounded, size: 46.sp, color: _kRed),

            SizedBox(height: 10.h),

            AppText(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),

            SizedBox(height: 14.h),

            // Quick way back to today's data
            TextButton.icon(
              onPressed: () => context
                  .read<SpecialDaysProvider>()
                  .loadSpecialDays(showLoader: true),
              icon: const Icon(Icons.refresh_rounded, color: _kRed),
              label: const Text(
                'Reset dates',
                style: TextStyle(color: _kRed, fontWeight: FontWeight.w700),
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