import 'package:flutter/material.dart';
import 'package:mmb_app/ui/screens/widget/product_card.dart';
import 'package:mmb_app/ui/screens/widget/prouduct_service_sheet.dart';
import 'package:provider/provider.dart';

import '../../network/provider/my_product_provider.dart';
import '../../network/provider/my_upload_provider.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductsProvider(),
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatelessWidget {
  const _ProductsView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,

        leading: Padding(
          padding: const EdgeInsets.only(
            left: 10,
            top: 12,
            bottom: 12,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFE5E7),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFFED1C24),
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),

        titleSpacing: 6,

        title: const Text(
          "My Products",
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED1C24),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize:
                MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _showAddSheet(context),
              icon: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  size: 11,
                  color: Color(0xFFED1C24),
                ),
              ),
              label: const Text(
                "ADD NEW",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Consumer<ProductsProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Description
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(
                  10,
                  7,
                  10,
                  9,
                ),
                child: const Text(
                  "Everything you offer, in one place, shown on your store\n"
                      "page and Near Me listing.",
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF222222),
                    height: 1.25,
                  ),
                ),
              ),

              // Filter section
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF4F4),
                padding: const EdgeInsets.fromLTRB(
                  10,
                  7,
                  10,
                  9,
                ),
                child: Row(
                  children: [
                    _filterChip(
                      "ALL",
                      provider,
                      count: 8,
                    ),
                    const SizedBox(width: 7),
                    _filterChip(
                      "PRODUCTS",
                      provider,
                      count: 6,
                    ),
                    const SizedBox(width: 7),
                    _filterChip(
                      "SERVICES",
                      provider,
                      count: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: provider.filteredProducts.isEmpty
                    ? const Center(
                  child: Text(
                    "No products found",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    10,
                    0,
                    10,
                    20,
                  ),
                  physics:
                  const BouncingScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: .68,
                  ),
                  itemCount:
                  provider.filteredProducts.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      item:
                      provider.filteredProducts[index],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(
      String text,
      ProductsProvider provider, {
        required int count,
      }) {
    final selected = provider.selectedFilter == text;

    return GestureDetector(
      onTap: () => provider.changeFilter(text),
      child: Container(
        height: 29,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFED1C24)
              : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: const Color(0xFFED1C24),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : const Color(0xFFED1C24),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white
                    : const Color(0xFFFFE5E5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$count",
                style: TextStyle(
                  color: const Color(0xFFED1C24),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
              value: context.read<ProductsProvider>(),
            ),
            ChangeNotifierProvider(
              create: (_) => UploadProvider(),
            ),
          ],
          child: const AddProductServiceSheet(),
        );
      },
    );
  }
}
