import 'package:flutter/material.dart';
import 'package:project_mmb/utils/theme/app.colors.dart';
import 'package:project_mmb/widgets/button_widget.dart';
import 'package:provider/provider.dart';

import 'package:project_mmb/network/provider/industry_provider.dart';

class SearchBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final DraggableScrollableController sheetController;

  const SearchBottomSheet({
    super.key,
    required this.scrollController,
    required this.sheetController,
  });

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.sheetController.animateTo(
          0.95,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        widget.sheetController.animateTo(
          0.75,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottom = WidgetsBinding
        .instance
        .platformDispatcher
        .views
        .first
        .viewInsets
        .bottom;

    if (bottom > 0) {
      widget.sheetController.animateTo(
        0.95,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IndustryProvider>();

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),

            Container(
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(30),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Choose your Preferences",
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Find business category that matches your Products/Services",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    onChanged: (value) {
                      provider.filterCategories(value);
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: "Find your Industry",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                provider.clearSearch();
                                setState(() {});
                              },
                            )
                          : const Icon(Icons.mic),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.categories.isEmpty
                  ? Center(
                      child: Text(
                        provider.isSearching
                            ? "No Search Found"
                            : "No Data Found",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      itemCount: provider.categories.length,
                      itemBuilder: (context, index) {
                        final item = provider.categories[index];
                        final isSelected =
                            provider.selectedCategory?.id == item.id;

                        return ListTile(
                          title: Text(item.name ?? ""),
                          selected: isSelected,
                          onTap: () {
                            provider.selectCategory(item);
                            _searchController.text = item.name ?? "";
                            setState(() {});
                          },
                        );
                      },
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ButtonWidget(
                  decoration: BoxDecoration(color: AppColors.appRed,borderRadius: BorderRadius.all(Radius.circular(15))),
                  buttonPress: provider.selectedCategory == null
                      ? null
                      : () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      "/BusinessDetailsScreen",
                    );
                  },
                  title: "CONTINUE",

                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}
