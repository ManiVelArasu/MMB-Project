import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:project_mmb/network/provider/business_provider.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/ui/industry/search_bottom_sheet.dart';
import 'package:project_mmb/utils/height_measure.dart';
import 'package:project_mmb/utils/theme/app.colors.dart';
import 'package:project_mmb/widgets/title_value_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../network/provider/industry_provider.dart';

class BusinessCategoryChooseScreen extends StatelessWidget {
  const BusinessCategoryChooseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IndustryProvider()..fetchAssetCategories(),
      child: const BusinessCategoryChooseView(),
    );
  }
}

class BusinessCategoryChooseView extends StatelessWidget {
  const BusinessCategoryChooseView({super.key});

  @override
  Widget build(BuildContext context) {
    final customColor = context.watch<CustomThemeProvider>().colors;
    final theme = Theme.of(context).textTheme;
    final accountProvider = context.watch<BusinessProvider>();
    final industryProvider = context.watch<IndustryProvider>();

    bool isBusiness = accountProvider.currentIndex == 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                int newIndex = isBusiness ? 1 : 0;
                accountProvider.setCurrentIndex(newIndex);
              },
              child: Text(
                isBusiness ? "SWITCH TO PERSONAL" : "SWITCH TO BUSINESS",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                "Select Your Business Category",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.appBlack,
                ),
              ),
              const SizedBox(height: 8),
              AppText(
                "Find the category that best matches your business.",
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 20),
              TextFormField(
                readOnly: true,
                onTap: () {
                  searchCategorySheet(context);
                },
                decoration: InputDecoration(
                  hintText: "Search your business category",
                  hintStyle: theme.bodyMedium!.copyWith(
                    color: customColor.greyColor.withAlpha(50),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      "assets/icons/search.svg",
                      width: 22,
                      height: 22,
                    ),
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      "assets/icons/mic.svg",
                      width: 22,
                      height: 22,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: customColor.baseColor),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Expanded(
                child: industryProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      )
                    : industryProvider.categories.isEmpty
                    ? Center(
                        child: AppText(
                          industryProvider.errorMessage ??
                              "No categories found",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.separated(
                        itemCount: industryProvider.categories.length > 10
                            ? 10
                            : industryProvider.categories.length,
                        separatorBuilder: (context, index) =>
                            Divider(color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final category = industryProvider.categories[index];
                          final categoryName = category.name ?? "";

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: AppText(
                              categoryName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.north_east,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onTap: () async {
                              industryProvider.selectCategory(category);

                              final prefs =
                                  await SharedPreferences.getInstance();
                              final selectedCat =
                                  industryProvider.selectedCategory;

                              if (selectedCat != null) {
                                await prefs.setString(
                                  'saved_category_id',
                                  selectedCat.id.toString(),
                                );
                                await prefs.setString(
                                  'saved_category_name',
                                  selectedCat.name ?? "",
                                );
                              }

                              if (!context.mounted) return;

                              Navigator.pushNamed(
                                context,
                                "/BusinessCategoryChooseView",
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void searchCategorySheet(BuildContext context) {
    final industryProvider = context.read<IndustryProvider>();
    final DraggableScrollableController sheetController =
        DraggableScrollableController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: industryProvider,
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                  child: Container(
                    color: AppColors.appBlack.withValues(alpha: 0.2),
                  ),
                ),
              ),
              DraggableScrollableSheet(
                controller: sheetController,
                expand: false,
                initialChildSize: 0.75,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return SearchBottomSheet(
                    scrollController: scrollController,
                    sheetController: sheetController,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
