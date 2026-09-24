import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:provider/provider.dart';

import '../../component/custom_widget.dart';
import '../../network/provider/business_provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../utils/height_measure.dart';
import '../../widgets/button_widget.dart';
import '../../widgets/title_value_widget.dart';

class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = BusinessProvider();

        // Business selected by default
        provider.setCurrentIndex(0);

        return provider;
      },
      builder: (context, child) {
        final customColor = context.watch<CustomThemeProvider>().colors;

        final theme = Theme.of(context).textTheme;

        return Consumer<BusinessProvider>(
          builder: (context, accountTypeProvider, child) {
            return Scaffold(
              backgroundColor: customColor.whiteColor,

              appBar: AppBar(
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: SvgPicture.asset("assets/icons/back_icon.svg"),
                ),
                backgroundColor: customColor.whiteColor,
                surfaceTintColor: customColor.whiteColor,
                elevation: 0,
              ),

              body: SafeArea(
                child: Column(
                  children: [
                    /// TOP CONTENT
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const TitleValueWidget(
                              title: "Let's personalize your experience",
                              subTitle: "What brings you here?",
                            ),

                            height16,

                            /// BUSINESS
                            _accountTypeCard(
                              context: context,
                              provider: accountTypeProvider,
                              index: 0,
                              title: "BUSINESS",
                              description:
                                  "Create branded designs tailored to your business and industry and unlock the full MMB toolkit.",
                              features: const [
                                "Business Profile & Near Me Listing",
                                "Products & Services showcase",
                                "Industry-matched templates & AI tools",
                              ],
                              iconPath: 'assets/icons/pref_filled.svg',
                              customColor: customColor,
                              theme: theme,
                            ),

                            /// OR TEXT
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              child: Center(
                                child: Text(
                                  "or, if you're just here for yourself",
                                  textAlign: TextAlign.center,
                                  style: theme.bodyMedium?.copyWith(
                                    color: customColor.blackColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),

                            /// PERSONAL
                            _accountTypeCard(
                              context: context,
                              provider: accountTypeProvider,
                              index: 1,
                              title: "PERSONAL",
                              description:
                                  "Create designs for festivals, birthdays, quotes, social posts, and more.",
                              features: const [],
                              iconPath: 'assets/icons/pref_outlined.svg',
                              customColor: customColor,
                              theme: theme,
                            ),

                            SizedBox(height: 20.h),
                          ],
                        ),
                      ),
                    ),

                    /// BOTTOM BUTTON
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                      decoration: BoxDecoration(
                        color: customColor.whiteColor,
                        border: Border(
                          top: BorderSide(color: customColor.borderColor),
                        ),
                      ),
                      child: ButtonWidget(
                        buttonPress: accountTypeProvider.isAccountTypeUpdating
                            ? null
                            : () async {
                                final success = await accountTypeProvider
                                    .updateAccountType();

                                if (!context.mounted) return;

                                if (!success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        accountTypeProvider.errorMessage ??
                                            "Something went wrong. Please try again.",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final selectedTitle = accountTypeProvider
                                    .accountTypeList[accountTypeProvider
                                        .currentIndex]
                                    .title;

                                if (selectedTitle == "Personal Use" ||
                                    selectedTitle == "PERSONAL") {

                                  Navigator.pushNamed(
                                    context,
                                    "/BusinessDetailsScreen",
                                  );
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    "/BusinessCategoryChooseScreen",
                                  );
                                }
                              },
                        title: accountTypeProvider.isAccountTypeUpdating
                            ? "UPDATING..."
                            : "CONTINUE",
                        textStyle: theme.titleLarge!.copyWith(
                          color: customColor.whiteColor,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.r),
                          color: customColor.redColor,
                        ),
                        height: 56.h,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _accountTypeCard({
    required BuildContext context,
    required BusinessProvider provider,
    required int index,
    required String title,
    required String description,
    required List<String> features,
    required String iconPath,
    required dynamic customColor,
    required TextTheme theme,
  }) {
    final bool isSelected = provider.currentIndex == index;

    return GestureDetector(
      onTap: () {
        provider.setCurrentIndex(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isSelected
              ? customColor.redColor.withAlpha(25)
              : customColor.whiteColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? customColor.redColor : customColor.borderColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOP ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// ICON
                SvgPicture.asset(
                  isSelected
                      ? 'assets/icons/pref_filled.svg'
                      : 'assets/icons/pref_outlined.svg',
                  width: 28.w,
                  height: 28.w,
                ),

                SizedBox(width: 10.w),

                /// TITLE

                /// RADIO BUTTON
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? customColor.redColor
                          : customColor.borderColor,
                      width: 1.2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 16.w,
                            height: 16.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: customColor.redColor,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),

            SizedBox(height: 8.h),

            AppText(
              title,
              style: theme.bodyLarge!.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: customColor.blackColor,
              ),
            ),

            /// DESCRIPTION
            AppText(
              description,
              style: theme.bodyMedium!.copyWith(
                fontSize: 15.sp,
                height: 1.35,
                fontWeight: FontWeight.w400,
                color: customColor.blackColor,
              ),
            ),

            /// BUSINESS FEATURES
            if (features.isNotEmpty) ...[
              SizedBox(height: 8.h),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: features.map((feature) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 7.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 20,
                          width: 20,
                          child: Image.asset("assets/images/tick_circle.png"),
                        ),
                        SizedBox(width: 7.w),
                        Expanded(
                          child: Text(
                            feature,
                            style: theme.bodyMedium?.copyWith(
                              fontSize: 14.sp,
                              height: 1.25,
                              color: customColor.blackColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SelectableItem {
  final String title;
  final String description;
  final String iconPath;

  SelectableItem({
    required this.title,
    required this.description,
    required this.iconPath,
  });
}
