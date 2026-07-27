import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/utils/height_measure.dart';
import 'package:project_mmb/widgets/button_widget.dart';
import 'package:provider/provider.dart';

import 'package:project_mmb/network/provider/industry_provider.dart'; // Unga IndustryProvider import


import '../../Api Model/industries.dart';

class SearchBottomSheet extends StatefulWidget {
  final ScrollController scrollController;

  const SearchBottomSheet({super.key, required this.scrollController});

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customColor = Provider.of<CustomThemeProvider>(context).colors;
    final theme = Theme.of(context).textTheme;

    return Consumer<IndustryProvider>(
      builder: (context, provider, child) {
        final categoriesList = provider.categories; // API Filtered List
        final selectedCategory = provider.selectedCategory; // Selected Object

        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              color: customColor.whiteColor,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          height: 4.h,
                          width: 100.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            color: customColor.greyColor.withAlpha(50),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "Choose your Preferences",
                            style: theme.bodyLarge!.copyWith(
                              color: customColor.blackColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: SvgPicture.asset("assets/icons/close_ic.svg"),
                          ),
                        ],
                      ),
                      Text(
                        "Find business category that matches your\nProducts/Services",
                        style: theme.bodyMedium!.copyWith(
                          color: customColor.blackColor,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // SEARCH BOX
                      TextFormField(
                        controller: _searchController,
                        onChanged: (value) {
                          provider.filterCategories(value);
                        },
                        decoration: InputDecoration(
                          hintText: "Find your Industry",
                          hintStyle: theme.bodyMedium!.copyWith(
                            color: customColor.greyColor.withAlpha(50),
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SvgPicture.asset(
                              "assets/icons/search.svg",
                              width: 24,
                              height: 24,
                            ),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              provider.clearSearch();
                            },
                          )
                              : Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SvgPicture.asset(
                              "assets/icons/mic.svg",
                              width: 24,
                              height: 24,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),

                  // LIST OF ITEMS (DYNAMIC FROM API)
                  Expanded(
                    child: provider.isLoading
                        ? Center(
                      child: CircularProgressIndicator(
                        color: customColor.redColor,
                      ),
                    )
                        : provider.errorMessage != null
                        ? Center(
                      child: Text(
                        provider.errorMessage!,
                        style: TextStyle(color: customColor.redColor),
                      ),
                    )
                        : categoriesList.isEmpty
                        ? Center(
                      child: Text(
                        "No Categories Found",
                        style: theme.bodyMedium!.copyWith(
                          color: customColor.greyColor,
                        ),
                      ),
                    )
                        : ListView.builder(
                      controller: widget.scrollController,
                      itemCount: categoriesList.length,
                      itemBuilder: (context, index) {
                        final Industries item = categoriesList[index];
                        final isSelected = selectedCategory?.id == item.id;

                        return ListTile(
                          title: Text(
                            item.name ?? "",
                            style: theme.bodyMedium!.copyWith(
                              color: isSelected
                                  ? customColor.redColor
                                  : customColor.blackColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                          trailing: SvgPicture.asset(
                            'assets/icons/arrow_top_right_ic.svg',
                            colorFilter: isSelected
                                ? ColorFilter.mode(
                              customColor.redColor,
                              BlendMode.srcIn,
                            )
                                : null,
                          ),
                          tileColor: isSelected
                              ? customColor.redColor.withAlpha(20)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () {
                            provider.selectCategory(item);
                            _searchController.text = item.name ?? "";
                          },
                        );
                      },
                    ),
                  ),

                  height12,

                  // CONTINUE BUTTON
                  ButtonWidget(
                    buttonPress: () {
                      if (selectedCategory != null) {
                        Navigator.pop(context); // Close BottomSheet
                        Navigator.pushNamed(context, "/BusinessDetailsScreen");
                      }
                    },
                    title: "CONTINUE",
                    textStyle: theme.titleLarge!.copyWith(
                      color: customColor.whiteColor,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: selectedCategory != null
                          ? customColor.redColor
                          : customColor.greyColor.withAlpha(100),
                    ),
                    height: 54.h,
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}