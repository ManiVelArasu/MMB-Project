import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../network/provider/bottom_provider.dart';
import 'package:provider/provider.dart';
import '../ui/screens/custom_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/nearme_screen.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/screens/theme_screen.dart';

class CustomBottomNavScreen extends StatelessWidget {
  const CustomBottomNavScreen({super.key});

  final List<Widget> _screens = const [
    Center(child: CustomCreateScreen()),
    Center(child: ThemesScreen()),
    Center(child: HomeScreen()),
    Center(child: NearMeScreen()),
    Center(child: ProfileScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Consumer<BottomNavProvider>(
      builder: (context, navProvider, child) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,
          body: _screens[navProvider.selectedIndex],
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: isKeyboardOpen
              ? null
              : Container(
                  height: 72.h,
                  width: 72.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFECEE),
                      width: 4.w,
                    ),
                  ),
                  child: FloatingActionButton(
                    onPressed: () {
                      navProvider.updateIndex(2);
                    },
                    backgroundColor: const Color(0xFFE53935),
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/my_pagelogo.png",
                          height: 20.h,
                          width: 20.w,
                          color: Colors.white,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.grid_view_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "MY\nPAGE",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w900,
                            height: 0.9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          bottomNavigationBar: isKeyboardOpen
              ? const SizedBox.shrink()
              : BottomAppBar(
                  color: const Color(0xFF1E2B58),
                  shape: const CircularNotchedRectangle(),
                  notchMargin: 6.r,
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    height: 65.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          context: context,
                          imagePath: "assets/images/edit.png",
                          label: "CUSTOM",
                          index: 0,
                        ),
                        _buildNavItem(
                          context: context,
                          imagePath: "assets/images/themes.png",
                          label: "THEMES",
                          index: 1,
                        ),

                        SizedBox(width: 48.w),

                        _buildNavItem(
                          context: context,
                          imagePath: "assets/images/nearme.png",
                          label: "NEAR ME",
                          index: 3,
                        ),
                        _buildNavItem(
                          context: context,
                          imagePath: "assets/images/you.png",
                          label: "YOU",
                          index: 4,
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String imagePath,
    required String label,
    required int index,
  }) {
    final navProvider = Provider.of<BottomNavProvider>(context, listen: false);
    final selectedIndex = Provider.of<BottomNavProvider>(context).selectedIndex;
    bool isSelected = selectedIndex == index;

    return InkWell(
      onTap: () {
        navProvider.updateIndex(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Image.asset(
              imagePath,
              height: 20.h,
              width: 20.w,
              fit: BoxFit.contain,
              color: isSelected ? const Color(0xFF4ED8F2) : Colors.white,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.grid_view_rounded,
                size: 20.sp,
                color: isSelected ? const Color(0xFF4ED8F2) : Colors.white,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: isSelected ? const Color(0xFF4ED8F2) : Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
