import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19.sp,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),

        title: Text(
          'Special Days',
          style: TextStyle(
            fontSize: 19.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),

      body: SafeArea(
        child: Consumer<SpecialDaysProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE53935),
                ),
              );
            }
        
            final specialDays =
                provider.specialDays?.data ?? [];
        
            if (specialDays.isEmpty) {
              return _EmptyState(isDark: isDark);
            }
        
            final List<Template> templates = [];
        
            for (final specialDay in specialDays) {
              templates.addAll(specialDay.templates);
            }
        
            if (templates.isEmpty) {
              return _EmptyState(
                isDark: isDark,
                message: 'No templates found',
              );
            }
        
            // FULL SCREEN SCROLL
            return GridView.builder(
              padding: EdgeInsets.fromLTRB(
                12.w,
                12.h,
                12.w,
                30.h,
              ),
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
                return _TemplateCard(
                  template: templates[index],
                  isDark: isDark,
                );
              },
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
  final bool isDark;

  const _TemplateCard({required this.template, required this.isDark});

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
        debugPrint('================================');
        debugPrint('SPECIAL DAY TEMPLATE CLICK');
        debugPrint('Template ID   : ${template.id}');
        debugPrint('Template UID  : ${template.uid}');
        debugPrint('Template Name : ${template.name}');
        debugPrint('Template Type : ${template.templateType}');
        debugPrint('================================');

        // TODO:
        // Navigate to Template Edit screen
        //
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => TemplateEditScreen(
        //       templateUid: template.uid!,
        //     ),
        //   ),
        // );
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
            // =================================================
            // IMAGE
            // =================================================

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

            // =================================================
            // TEMPLATE NAME
            // =================================================
            Padding(
              padding: EdgeInsets.fromLTRB(9.w, 7.h, 9.w, 8.h),

              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      template.name ?? 'Template',

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),

                  // =========================================
                  // PREMIUM
                  // =========================================
                  if (template.isPremium == '1')
                    Padding(
                      padding: EdgeInsets.only(left: 4.w),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 15.sp,
                        color: const Color(0xFFFFB300),
                      ),
                    ),
                ],
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
