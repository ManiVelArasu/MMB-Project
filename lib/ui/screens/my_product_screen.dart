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
        title: const Text(
          "My Products",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Icons.add, size: 15),
              label: const Text(
                "ADD NEW",
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<ProductsProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Everything you offer, in one place, shown on your page and New Listing.",
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _filterChip("ALL", provider),
                    const SizedBox(width: 6),
                    _filterChip("PRODUCTS", provider),
                    const SizedBox(width: 6),
                    _filterChip("SERVICES", provider),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: provider.filteredProducts.isEmpty
                      ? const Center(child: Text("No products found"))
                      : GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: .68,
                    ),
                    itemCount: provider.filteredProducts.length,
                    itemBuilder: (context, index) {
                      return ProductCard(
                        item: provider.filteredProducts[index],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip(String text, ProductsProvider provider) {
    final selected = provider.selectedFilter == text;
    return GestureDetector(
      onTap: () => provider.changeFilter(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.red : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.red,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
