import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/network/provider/common_provider.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:provider/provider.dart';

import '../../network/provider/custom_theme_provider.dart';
import '../utils/theme/app.fonts.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showTitle;

  // Back Button
  final VoidCallback? onBackPressed;

  // Right Icon
  final bool showRightIcon;
  final VoidCallback? onRightIconTap;
  final String? badgeCount;
  final String? rightImage;
  final double rightImageSize;

  // Action Text
  final bool showActionText;
  final String actionText;
  final VoidCallback? onActionTextTap;

  const CustomAppBar({
    super.key,
    this.title = "",
    this.showTitle = true,

    // Back
    this.onBackPressed,

    // Right Icon
    this.showRightIcon = true,
    this.onRightIconTap,
    this.badgeCount = "2",
    this.rightImage,
    this.rightImageSize = 30,

    // Action Text
    this.showActionText = false,
    this.actionText = "",
    this.onActionTextTap,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(60.h);
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _apiCalled = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  // LOAD USER DATA BASED ON ACCOUNT TYPE
  Future<void> _loadUserData() async {
    if (_apiCalled) return;

    _apiCalled = true;

    final provider = CommonProvider.instance;

    try {
      // Load ME API if account type is not available.
      if (provider.accountType == null ||
          provider.accountType!.trim().isEmpty) {
        debugPrint("Account type not available. Calling ME API...");

        final bool meSuccess = await provider.loadMe(forceRefresh: true);

        if (!meSuccess) {
          debugPrint("ME API failed");
          return;
        }
      }

      final String accountType =
          provider.accountType?.trim().toLowerCase() ?? "";

      debugPrint("CUSTOM APP BAR ACCOUNT TYPE: $accountType");

      if (accountType == "personal") {
        await provider.loadMe(forceRefresh: true);
        return;
      }

      if (accountType == "business") {
        await provider.loadBusiness(forceRefresh: true);
        return;
      }

      debugPrint("Unknown account type: $accountType");
    } catch (e, stackTrace) {
      debugPrint("CustomAppBar API error: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // GET DISPLAY NAME
  String _getDisplayName(CommonProvider provider) {
    final String? accountType = provider.accountType?.trim().toLowerCase();

    // PERSONAL ACCOUNT
    if (accountType == "personal") {
      final String? name = provider.me?.data.name?.trim();

      if (name != null && name.isNotEmpty) {
        return name;
      }

      return widget.title;
    }

    // BUSINESS ACCOUNT
    if (accountType == "business") {
      final String? businessName = provider.business?.name?.trim();

      if (businessName != null && businessName.isNotEmpty) {
        return businessName;
      }

      return widget.title;
    }

    return widget.title;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<CustomThemeProvider>();
    final bool isDark = themeProvider.isDarkMode;
    final theme = Theme.of(context).textTheme;

    final provider = CommonProvider.instance;

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final String displayName = widget.title.isNotEmpty
            ? widget.title
            : _getDisplayName(provider);

        return SafeArea(
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            titleSpacing: 16.w,

            title: Row(
              children: [
                // BACK BUTTON
                InkWell(
                  onTap:
                      widget.onBackPressed ??
                      () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                  borderRadius: BorderRadius.circular(24.r),
                  child: Container(
                    height: 42.h,
                    width: 42.w,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A1A1C)
                          : const Color(0xFFFFECEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back,
                        color: Color(0xFFE53935),
                        size: 20,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // TITLE
                if (widget.showTitle)
                  Expanded(
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize22,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.appBlack,
                      ),
                    ),
                  ),
              ],
            ),

            // ACTIONS
            actions: [
              // ACTION TEXT
              if (widget.showActionText)
                Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: InkWell(
                    onTap: widget.onActionTextTap,
                    borderRadius: BorderRadius.circular(8.r),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Text(
                          widget.actionText,
                          style: theme.titleMedium?.copyWith(
                            color: isDark
                                ? Colors.blueAccent
                                : const Color(0xFF1E2E5F),
                            fontWeight: FontWeight.w600,
                            fontSize: AppFontSize.fontSize15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // CUSTOM RIGHT ICON
              // RIGHT IMAGE
              if (widget.showRightIcon)
                Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: InkWell(
                    onTap: widget.onRightIconTap,
                    borderRadius: BorderRadius.circular(24.r),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(6.r),
                          child: widget.rightImage != null
                              ? Image.asset(
                            widget.rightImage!,
                            width: widget.rightImageSize.w,
                            height: widget.rightImageSize.h,
                            fit: BoxFit.contain,
                          )
                              : const SizedBox.shrink(),
                        ),

                        // BADGE
                        if (widget.badgeCount != null)
                          Positioned(
                            top: 2,
                            left: 2,
                            child: Container(
                              padding: EdgeInsets.all(4.r),
                              constraints: BoxConstraints(
                                minWidth: 18.w,
                                minHeight: 18.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.red.shade800
                                    : const Color(0xFF1E293B),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: AppText(
                                  widget.badgeCount!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: AppFontSize.fontSize10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
