import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/appbar_widget.dart';
import 'package:mmb_app/component/custom_searchbar.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:provider/provider.dart';

import '../../Api Model/special_days.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/special_days_provider.dart';

class SpecialDaysScreen extends StatelessWidget {
  const SpecialDaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SpecialDaysProvider()..loadSpecialDays(),
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
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F8F8),

      appBar: CustomAppBar(
        showTitle: true,
        title: "Special Days",
        showRightIcon: false,
      ),

      body: SafeArea(
        child: Consumer<SpecialDaysProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE53935)),
              );
            }

            final specialDays = provider.specialDays?.data ?? [];

            if (specialDays.isEmpty) {
              return _EmptyState(isDark: isDark);
            }

            // Template + Special Day Name
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
              return _EmptyState(isDark: isDark, message: 'No templates found');
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 30.h),
              child: Column(
                children: [
                  AppText(
                    "Find the Right Festival Templates",
                    style: TextStyle(
                      color: AppColors.appBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: AppFontSize.fontSize18,
                    ),
                  ),
                  AppText(
                    "Choose the festival to discover ready-to-edit designs for promotions, offers, announcements, and everyday marketing.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: AppFontSize.fontSize14,
                    ),
                  ),
                  SizedBox(height: 10),
                  CustomSearchBar(hintText: 'Find your festival'),
                  SizedBox(height: 15),
                  Expanded(
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10.w,
                        mainAxisSpacing: 10.h,

                        // Image + nameக்கு space
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
      child: Container(
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

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            Expanded(
              child: SizedBox(
                width: double.infinity,
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
                        placeholder: (_, __) {
                          return Container(
                            color: isDark
                                ? const Color(0xFF292929)
                                : const Color(0xFFF3F3F3),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          );
                        },
                        errorWidget: (_, __, ___) {
                          return Container(
                            color: const Color(0xFFFFE5E5),
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: const Color(0xFFE53935),
                              size: 32.sp,
                            ),
                          );
                        },
                      ),
              ),
            ),

            // SPECIAL DAY NAME
            Padding(
              padding: EdgeInsets.fromLTRB(6.w, 7.h, 6.w, 8.h),
              child: Center(
                child: Text(
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
