import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/utils/height_measure.dart';
import 'package:project_mmb/widgets/button_widget.dart';
import 'package:provider/provider.dart';

class SearchBottomSheet extends StatefulWidget {
  final ScrollController scrollController;

  const SearchBottomSheet({super.key, required this.scrollController});

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  String query = "";
  String? selectedItem;
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

    // Filtered list
    final filteredList = businessCategories
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
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
                  SizedBox(height: 12),
      
                  // SEARCH BOX
                  TextFormField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        query = value;
                      });
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
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: SvgPicture.asset(
                          "assets/icons/mic.svg",
                          width: 24,
                          height: 24,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
      
                  SizedBox(height: 20),
                ],
              ),
      
              // LIST OF ITEMS
              Expanded(
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  child: ListView.builder(
                    itemCount: filteredList.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final isSelected = selectedItem == filteredList[index];
                      return ListTile(
                        title: Text(
                          filteredList[index],
                          style: theme.bodyMedium!.copyWith(
                            color: isSelected
                                ? customColor.redColor
                                : customColor.blackColor,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
                          setState(() {
                            selectedItem = filteredList[index];
                            _searchController.text = filteredList[index];
                            query = filteredList[index];
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
              height12,
              ButtonWidget(
                buttonPress: () {
                  if (selectedItem != null) {
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
                  color: selectedItem != null
                      ? customColor.redColor
                      : customColor.greyColor.withAlpha(100),
                ),
                height: 54.h,
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  final List<String> businessCategories = [
    "Real Estate",
    "Electrical",
    "Mobile Store",
    "Tour and Travels",
    "Automobile",
    "Construction",
    "Clothing & Fashion",
    "Hospitality",
    "Food & Beverage",
    "IT Services",
    "Hardware Store",
    "Furniture",
    "Medical & Pharmacy",
    "Education",
    "Beauty & Wellness",
    "Grocery Store",
    "Home Appliances",
    "Jewellery",
    "Photography",
    "Logistics",
    "Sports & Fitness",
    "Pet Store",
  ];
}