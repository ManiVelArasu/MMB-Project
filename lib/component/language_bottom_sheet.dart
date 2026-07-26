import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LanguagesBottomSheet extends StatefulWidget {
  const LanguagesBottomSheet({super.key});

  @override
  State<LanguagesBottomSheet> createState() => _LanguagesBottomSheetState();
}

class _LanguagesBottomSheetState extends State<LanguagesBottomSheet> {
  // Master Languages List
  final List<String> _languages = [
    "English",
    "தமிழ்",
    "हिंदी",
    "മലയാളം",
    "கன்னட",
    "తెలుగు",
  ];

  // Currently Selected Languages
  final Set<String> _selectedLanguages = {
    "English",
    "தமிழ்",
    "हिंदी",
  };

  void _toggleLanguage(String lang) {
    setState(() {
      if (_selectedLanguages.contains(lang)) {
        _selectedLanguages.remove(lang);
      } else {
        _selectedLanguages.add(lang);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------------
            // 1. TOP DRAG HANDLE
            // -------------------------------------------------------------
            Center(
              child: Container(
                height: 4.h,
                width: 80.w,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // -------------------------------------------------------------
            // 2. HEADER: "Languages" Title & Close Button
            // -------------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Languages",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 28.h,
                    width: 28.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFECEE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: const Color(0xFFE53935),
                      size: 16.sp,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // -------------------------------------------------------------
            // 3. SELECTED LANGUAGES COUNT BADGE
            // -------------------------------------------------------------
            Row(
              children: [
                Text(
                  "Selected Languages",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935), // Red Count Badge
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    "${_selectedLanguages.length}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            // Subtitle Description
            Text(
              "Your post, their language - connect better, reach wider!",
              style: TextStyle(
                fontSize: 12.5.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 20.h),

            // -------------------------------------------------------------
            // 4. LANGUAGE PILLS (GRID / WRAP)
            // -------------------------------------------------------------
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: _languages.map((lang) {
                final isSelected = _selectedLanguages.contains(lang);

                return GestureDetector(
                  onTap: () => _toggleLanguage(lang),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFDCDA) // Light Pink fill for Selected
                          : Colors.white,
                      borderRadius: BorderRadius.circular(30.r),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : const Color(0xFFFFCDD2), // Soft Pink Border for Unselected
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      lang,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}