import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../component/custom_widget.dart';
import '../../network/provider/business_provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/industry_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';
import '../../widgets/button_widget.dart';

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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               AppText(
                "Select Your Business Category",
                style: TextStyle(
                  fontSize: AppFontSize.fontSize22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

               AppText(
                "Business Category",
                style: TextStyle(
                  fontSize: AppFontSize.fontSize12,
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
                  style:  TextStyle(
                    color: Colors.red,
                    fontSize: AppFontSize.fontSize16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 4),
              if (industryProvider.childCategories.isEmpty) ...[
                 AppText(
                  "Can't find your business type?",
                  style: TextStyle(
                    fontSize: AppFontSize.fontSize15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  "Choose Other and enter your business type. We'll review new requests "
                  "and continuously expand our industry database to improve template "
                  "recommendations.",
                  style: TextStyle( fontSize: AppFontSize.fontSize12, color: Colors.grey.shade600),
                ),
              ] else ...[
                 AppText(
                  "Choose a specialization",
                  style: TextStyle(
                    fontSize: AppFontSize.fontSize15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  "Find the category that best matches your business.",
                  style: TextStyle( fontSize: AppFontSize.fontSize12, color: Colors.grey.shade600),
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
                        fontSize: AppFontSize.fontSize13,
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
                            fontSize: AppFontSize.fontSize13,
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

                  onChanged: (value) {
                    if (value.trim().isNotEmpty) {
                      industryProvider.clearOtherError();
                    }
                  },

                  decoration: InputDecoration(
                    hintText: "Please enter your business type",

                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: AppFontSize.fontSize13,
                    ),

                    errorText: industryProvider.otherError,

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

                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),

                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 10),

              if (industryProvider.childCategories.isNotEmpty) ...[
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
                    InkWell(
                      onTap: () {
                        accountProvider.skipBusinessUpdateApi(context);
                      },
                      child: AppText(
                        " Skip",
                        style: TextStyle(color: AppColors.appRed),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              ButtonWidget(
                isLoading: accountProvider.isUploading,
                buttonPress: () {
                  // Other selected
                  if (industryProvider.showOtherInput) {
                    final other = industryProvider.otherController.text.trim();

                    if (other.isEmpty) {
                      industryProvider.validateOther(other);
                      return;
                    }
                  }

                  accountProvider.businessUpdateApi(
                    context,
                    industryProvider.selectedCategorySlug ?? '',
                    industryProvider.otherController.text.trim(),
                  );
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
