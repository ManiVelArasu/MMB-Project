import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:project_mmb/utils/theme/app.colors.dart';
import 'package:project_mmb/widgets/button_widget.dart';
import 'package:provider/provider.dart';

import '../../network/provider/business_provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/industry_provider.dart';

class BusinessCategoryChooseView extends StatelessWidget {
  const BusinessCategoryChooseView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IndustryProvider()..loadSavedCategory(),
      child: const BusinessCategoryView(),
    );
  }
}

// 🚀 2. Your Main View Widget
class BusinessCategoryView extends StatefulWidget {
  const BusinessCategoryView({super.key});

  @override
  State<BusinessCategoryView> createState() => _BusinessCategoryViewState();
}

class _BusinessCategoryViewState extends State<BusinessCategoryView> {
  @override
  Widget build(BuildContext context) {
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
              child: AppText(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                "Select Your Business Category",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              const AppText(
                "Business Category",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: AppText(
                  industryProvider.savedCategoryName,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 4),
              if (industryProvider.childCategories.isEmpty) ...[
                const AppText(
                  "Can't find your business type?",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  "Choose Other and enter your business type. We'll review new requests "
                  "and continuously expand our industry database to improve template "
                  "recommendations.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ] else ...[
                const AppText(
                  "Choose a specialization",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  "Find the category that best matches your business.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...industryProvider.childCategories.map((category) {
                    final name = category.name ?? '';
                    final selected =
                        industryProvider.selectedCategorySlug == category.slug;

                    return ChoiceChip(
                      label: AppText(name),
                      selected: selected,
                      selectedColor: const Color(0xFFFFECEE),
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: selected ? Colors.red : Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: selected
                              ? Colors.red.shade300
                              : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (value) {
                        if (value) {
                          industryProvider.selectSpecialization(category);
                        }
                      },
                    );
                  }),

                  // Always keep Other as the LAST option.
                  industryProvider.childCategories.isNotEmpty
                      ? ChoiceChip(
                          label: const AppText("Other"),
                          selected: industryProvider.showOtherInput,
                          selectedColor: const Color(0xFFFFECEE),
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: industryProvider.showOtherInput
                                ? Colors.red
                                : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: industryProvider.showOtherInput
                                  ? Colors.red.shade300
                                  : Colors.grey.shade300,
                            ),
                          ),
                          onSelected: (value) {
                            if (value) {
                              industryProvider.setSelectedSpecialization(
                                "Other",
                              );
                            }
                          },
                        )
                      : SimpleDialog(),
                ],
              ),
              const SizedBox(height: 20),

              if (industryProvider.showOtherInput) ...[
                TextField(
                  controller: industryProvider.otherController,
                  decoration: InputDecoration(
                    hintText: "Please enter your business type",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 10),

              AppText(
                "We’ll review your industry details and add them to your profile once approved.",
                style: TextStyle(color: AppColors.appGrey),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    "Nothing Matched?",
                    style: TextStyle(
                      color: AppColors.appBlack,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppText(" Skip", style: TextStyle(color: AppColors.appRed)),
                ],
              ),
              const SizedBox(height: 20),
              ButtonWidget(
                buttonPress: () {
                  Navigator.pushNamed(context, "/BusinessDetailsScreen");
                },
                title: "Continue",
                decoration: BoxDecoration(
                  color: AppColors.appRed,
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
