import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:project_mmb/network/provider/business_provider.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/utils/height_measure.dart';
import 'package:project_mmb/widgets/button_widget.dart';
import 'package:project_mmb/widgets/title_value_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BusinessProvider(),
      builder: (context, child) {
        final customColor = context.watch<CustomThemeProvider>().colors;
        final theme = Theme.of(context).textTheme;

        return Consumer<BusinessProvider>(
          builder: (context, accountTypeProvider, child) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: SvgPicture.asset("assets/icons/back_icon.svg"),
                ),
                backgroundColor: customColor.whiteColor,
                surfaceTintColor: customColor.whiteColor,
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const TitleValueWidget(
                        title: "Let's personalize your experience",
                        subTitle: "What brings you here?",
                      ),

                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: accountTypeProvider.accountTypeList.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 24.0.h),
                              child: InkWell(
                                onTap: () {
                                  accountTypeProvider.setCurrentIndex(index);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          accountTypeProvider.currentIndex ==
                                              index
                                          ? customColor.redColor
                                          : customColor.borderColor,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    color:
                                        accountTypeProvider.currentIndex ==
                                            index
                                        ? customColor.redColor.withAlpha(10)
                                        : customColor.whiteColor,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SvgPicture.asset(
                                        accountTypeProvider.currentIndex ==
                                                index
                                            ? 'assets/icons/pref_filled.svg'
                                            : 'assets/icons/pref_outlined.svg',
                                      ),
                                      width8,
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AppText(
                                              accountTypeProvider
                                                  .accountTypeList[index]
                                                  .title,
                                              style: theme.bodyLarge!.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: customColor.blackColor,
                                              ),
                                            ),
                                            height8,
                                            AppText(
                                              accountTypeProvider
                                                  .accountTypeList[index]
                                                  .description,
                                              style: theme.bodyMedium!.copyWith(
                                                fontWeight: FontWeight.w400,
                                                color: customColor.blackColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      ButtonWidget(
                        buttonPress: () async {
                          final selectedTitle = accountTypeProvider
                              .accountTypeList[accountTypeProvider.currentIndex]
                              .title;

                          final prefs = await SharedPreferences.getInstance();

                          await prefs.setString(
                            'selected_account_type',
                            selectedTitle,
                          );
                          if (selectedTitle == "Personal Use") {
                            await prefs.setBool('is_personal_use', true);
                          } else {
                            await prefs.setBool('is_personal_use', false);
                          }

                          if (!context.mounted) return;

                          if (selectedTitle == "Personal Use") {
                            Navigator.pushNamed(
                              context,
                              "/CustomBottomNavScreen",
                            );
                          } else {
                            Navigator.pushNamed(
                              context,
                              "/BusinessCategoryChooseScreen",
                            );
                          }
                        },
                        title: "CONTINUE",
                        textStyle: theme.titleLarge!.copyWith(
                          color: customColor.whiteColor,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: customColor.redColor,
                        ),
                        height: 54.h,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
