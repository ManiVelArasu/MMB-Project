import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project_mmb/ui/industry/widgets/Business_frame_bottom_sheet.dart';

import '../../component/appbar_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';

import '../../network/provider/business_provider.dart';

class BusinessFramesScreen extends StatelessWidget {
  const BusinessFramesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚀 FIX: Removed local ChangeNotifierProvider so it reads from the global BusinessProvider properly
    return const BusinessFramesView();
  }
}

class BusinessFramesView extends StatefulWidget {
  const BusinessFramesView({super.key});

  @override
  State<BusinessFramesView> createState() => _BusinessFramesViewState();
}

class _BusinessFramesViewState extends State<BusinessFramesView> {
  int selectedTab = 0;
  int selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    final customColor = Provider.of<CustomThemeProvider>(context).colors;
    final theme = Theme.of(context).textTheme;

    return Consumer<BusinessProvider>(
      builder: (context, businessProvider, child) {
        final savedImageFile =
            businessProvider.selectedImage ?? businessProvider.originalImage;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: const CustomAppBar(
            title: "Business Frames",
            showTitle: true,
            badgeCount: "2",
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 12.h),

                          // 1. MAIN PREVIEW BANNER
                          Container(
                            height: 340.h,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Stack(
                                children: [
                                  if (savedImageFile != null)
                                    Positioned.fill(
                                      child: Image.file(
                                        savedImageFile,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    )
                                  else
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.grey.shade100,
                                        child: Center(
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 48.sp,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // 2. OVERLAY LOGO (Top Left)
                                  Positioned(
                                    top: 20.h,
                                    left: 16.w,
                                    child: Image.asset(
                                      "assets/images/abslogo.png",
                                      height: 40.h,
                                    ),
                                  ),

                                  // 3. BOTTOM CURVED INFO BANNER OVER IMAGE
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    left: 80.w,
                                    child: Container(
                                      height: 36.h,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0066FF),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20.r),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                        children: [
                                          // Phone Number
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.phone,
                                                color: Colors.white,
                                                size: 12.sp,
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                businessProvider
                                                    .mobileNumber
                                                    .isEmpty
                                                    ? "+91 9876543210"
                                                    : businessProvider
                                                    .mobileNumber,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Email Address
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.email,
                                                color: Colors.white,
                                                size: 12.sp,
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                businessProvider.email.isEmpty
                                                    ? "sarahsteve@gmail.com"
                                                    : businessProvider.email,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 16.h),

                          Row(
                            children: [
                              Text(
                                "Free",
                                style: theme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20.sp,
                                  color: customColor.blackColor,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom: MediaQuery.of(
                                          context,
                                        ).viewInsets.bottom,
                                      ),
                                      child: const UpdateBusinessSheet(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFECEE),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    "EDIT",
                                    style: TextStyle(
                                      color: const Color(0xFFE53935),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              // UPDATE BUTTON
                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    "/CustomBottomNavScreen",
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    "UPDATE",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),
                          Row(
                            children: [
                              _buildTabItem("Static Frames", index: 0),
                              SizedBox(width: 20.w),
                              _buildTabItem("Animated Frames", index: 1),
                            ],
                          ),

                          SizedBox(height: 16.h),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildCategoryChip("Branding Frames", index: 0),
                                SizedBox(width: 10.w),
                                _buildCategoryChip(
                                  "Promotional Frames",
                                  index: 1,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20.h),

                          // 5. BOTTOM FRAMES LIST / GRID
                          SizedBox(
                            height: 140.h,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 3,
                              itemBuilder: (context, index) {
                                bool isSolidBanner = index % 2 != 0;

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
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                              width: 1.2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ),
                                            child: Stack(
                                              children: [
                                                if (savedImageFile != null)
                                                  Positioned.fill(
                                                    child: Image.file(
                                                      savedImageFile,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    ),
                                                  )
                                                else
                                                  Positioned.fill(
                                                    child: Container(
                                                      color:
                                                      Colors.grey.shade50,
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
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 4.h,
                                                  left: 4.w,
                                                  right: 4.w,
                                                  child: isSolidBanner
                                                      ? _buildSolidBanner(
                                                    businessProvider,
                                                  )
                                                      : _buildOutlineBanner(
                                                    businessProvider,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                      Text(
                                        index == 0
                                            ? "Free"
                                            : "Rs.0 (Rs.100 Unlocked)",
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
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
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutlineBanner(BusinessProvider businessProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF0066FF), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.phone, color: const Color(0xFF0066FF), size: 6.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
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
                Icon(
                  Icons.facebook,
                  size: 5.sp,
                  color: const Color(0xFF0066FF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolidBanner(BusinessProvider businessProvider) {
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
            child: Text(
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

  Widget _buildTabItem(String title, {required int index}) {
    bool isSelected = selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.black : Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 4.h),
          if (isSelected)
            Container(
              height: 3.h,
              width: 60.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String title, {required int index}) {
    bool isSelected = selectedCategory == index;
    return InkWell(
      onTap: () {
        setState(() {
          selectedCategory = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A4A4A) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade400,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}

/*class CubeLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = const Color(0xFF0066FF);
    final paint2 = Paint()..color = const Color(0xFF29B6F6);
    final paint3 = Paint()..color = const Color(0xFFE3F2FD);

    final path1 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height * 0.3)
      ..lineTo(size.width * 0.5, size.height * 0.5)
      ..lineTo(0, size.height * 0.3)
      ..close();

    final path2 = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.5, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(0, size.height * 0.7)
      ..close();

    final path3 = Path()
      ..moveTo(size.width * 0.5, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.7)
      ..lineTo(size.width * 0.5, size.height)
      ..close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}*/
