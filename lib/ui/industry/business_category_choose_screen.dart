import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_mmb/network/provider/business_provider.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/ui/industry/search_bottom_sheet.dart';
import 'package:project_mmb/utils/height_measure.dart';
import 'package:project_mmb/widgets/title_value_widget.dart';
import 'package:provider/provider.dart';

import '../../network/provider/industry_provider.dart';

class BusinessCategoryChooseScreen extends StatelessWidget {
  const BusinessCategoryChooseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IndustryProvider(),
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
              const Text(
                "Select Your Business Category",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Find the category that best matches your Products/Services",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 24),

              // Search Industry Input Field
              TextFormField(
                readOnly: true,
                onTap: () {
                  // 🚀 Pass current inner context which has access to IndustryProvider
                  searchCategorySheet(context);
                },
                decoration: InputDecoration(
                  hintText: "Find your Industry",
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
            ],
          ),
        ),
      ),
    );
  }

  void searchCategorySheet(BuildContext context) {
    final industryProvider = context.read<IndustryProvider>();
    industryProvider.fetchAssetCategories();
    final DraggableScrollableController _sheetController =
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
                  child: Container(color: Colors.black.withValues(alpha: 0.2)),
                ),
              ),
              DraggableScrollableSheet(
                controller: _sheetController,
                expand: false,
                initialChildSize: 0.75,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return SearchBottomSheet(
                    scrollController: scrollController,
                    sheetController: _sheetController,
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
