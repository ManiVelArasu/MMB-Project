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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => IndustryProvider()),
      ],
      child: const BusinessCategoryChooseView(),
    );
  }
}

class BusinessCategoryChooseView extends StatefulWidget {
  const BusinessCategoryChooseView({super.key});

  @override
  State<BusinessCategoryChooseView> createState() =>
      _BusinessCategoryChooseViewState();
}

class _BusinessCategoryChooseViewState
    extends State<BusinessCategoryChooseView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountProvider = context.read<BusinessProvider>();

      _tabController = TabController(
        length: 2,
        vsync: this,
        initialIndex: accountProvider.currentIndex,
      );

      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          accountProvider.setCurrentIndex(_tabController.index);
        }
      });
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final customColor = context.watch<CustomThemeProvider>().colors;
    final accountProvider = context.watch<BusinessProvider>();
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              const TitleValueWidget(
                title: "Choose your Preferences",
                subTitle: "What brings you here?",
              ),

              if (_tabController != null) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: customColor.borderColor),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: customColor.baseColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: customColor.whiteColor,
                    unselectedLabelColor: customColor.textColor,
                    labelStyle: theme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    unselectedLabelStyle: theme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    indicatorPadding: EdgeInsets.zero,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        text: _tabController.index == 0
                            ? "For My Business"
                            : "Switch to My Business",
                      ),
                      Tab(
                        text: _tabController.index == 1
                            ? "Personal Use"
                            : "Switch to Personal",
                      ),
                    ],
                  ),
                ),
              ],

              height20,
              Text(
                "Find business category that matches your Products/Services",
                style: theme.titleMedium!.copyWith(
                  color: customColor.textColor,
                ),
              ),

              height12,

              TextFormField(
                readOnly: true,
                onTap: () {
                  searchCategorySheet(context);
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
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade400),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void searchCategorySheet(BuildContext context) {
    // Parent context-la irundha provider-a fetch pannikrom
    final industryProvider = context.read<IndustryProvider>();
    industryProvider.fetchAssetCategories();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (modalContext) {
        // 🚀 FIX: Wrap with ChangeNotifierProvider.value so SearchBottomSheet has access to IndustryProvider
        return ChangeNotifierProvider.value(
          value: industryProvider,
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                  child: Container(color: Colors.black.withOpacity(0.2)),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.7,
                  minChildSize: 0.7,
                  maxChildSize: 1.0,
                  builder: (context, scrollController) {
                    return SearchBottomSheet(
                      scrollController: scrollController,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
