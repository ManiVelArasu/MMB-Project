import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../Api Model/special_days.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/special_days_provider.dart';

class SpecialDaysScreen extends StatelessWidget {
  final String? selectedDate;

  const SpecialDaysScreen({super.key, this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          SpecialDaysProvider(selectedDate: selectedDate)..loadSpecialDays(),
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
      body: Consumer<SpecialDaysProvider>(
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

          final selectedDate = provider.selectedDate;

          String title;

          if (selectedDate != null && selectedDate.isNotEmpty) {
            title = '$selectedDate Special Days';
          } else {
            title = 'This Month Special Days';
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
            physics: const BouncingScrollPhysics(),
            itemCount: specialDays.length + 1,
            separatorBuilder: (_, __) => SizedBox(height: 11.h),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(
                  title,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                );
              }

              return _SpecialDayCard(
                item: specialDays[index - 1],
                isDark: isDark,
              );
            },
          );
        },
      ),
    );
  }
}

class _SpecialDayCard extends StatelessWidget {
  final Datum item;
  final bool isDark;

  const _SpecialDayCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final thumbnail = item.thumbnailS3Key?.trim() ?? '';
    final banner = item.bannerS3Key?.trim() ?? '';

    final key = thumbnail.isNotEmpty ? thumbnail : banner;

    final url = key.isEmpty
        ? ''
        : (key.startsWith('http://') || key.startsWith('https://'))
        ? key
        : '${ApiEndpoints.cdnImageUrl}/$key';

    return Container(
      height: 112.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF0E1E1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 112.w,
            height: double.infinity,
            child: url.isEmpty
                ? Container(
                    color: const Color(0xFFFFE5E5),
                    child: const Icon(
                      Icons.event_rounded,
                      color: Color(0xFFE53935),
                      size: 30,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: const Color(0xFFFFE5E5),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFFFE5E5),
                      child: const Icon(
                        Icons.image_not_supported_rounded,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    _formatDate(item.occursOn),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE53935),
                    ),
                  ),
                  if ((item.description ?? '').trim().isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      item.description ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

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
              'No special days found',
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

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')} '
      '${_monthShort(date.month)} ${date.year}';
}

String _monthShort(int month) => const [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
][month - 1];
