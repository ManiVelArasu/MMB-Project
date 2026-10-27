import 'package:flutter/material.dart';
import 'package:mmb_app/ui/screens/widget/product_card.dart';
import 'package:mmb_app/ui/screens/widget/product_sheet.dart';
import 'package:provider/provider.dart';
import '../../component/custom_widget.dart';

import '../../network/provider/my_upload_provider.dart';
import '../../network/provider/product_provider.dart';
import '../../Api Model/product_model.dart';
import '../../utils/theme/app.fonts.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProductsProvider>(
      create: (_) => ProductsProvider()..fetchProducts(),
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
          padding: const EdgeInsets.only(left: 10, top: 12, bottom: 12),
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

        title: AppText(
          "My Products",
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: AppFontSize.fontSize22,
            fontWeight: FontWeight.w500,
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => showAddProductServiceSheet(context),
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
              label: const AppText(
                "ADD NEW",
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Consumer<ProductsProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                // Description
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
                  child: AppText(
                    "Everything you offer, in one place, shown on your store page and Near Me listing.",
                    style: TextStyle(
                      fontSize: AppFontSize.fontSize14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF222222),
                      height: 1.25,
                    ),
                  ),
                ),

                // Filter section
                Container(
                  width: double.infinity,
                  color: const Color(0xFFFFF4F4),
                  padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
                  child: Row(
                    children: [
                      _filterChip('ALL', provider, count: provider.allCount),
                      const SizedBox(width: 7),
                      _filterChip(
                        'PRODUCTS',
                        provider,
                        count: provider.productsCount,
                      ),
                      const SizedBox(width: 7),
                      _filterChip(
                        'SERVICES',
                        provider,
                        count: provider.servicesCount,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: provider.filteredProducts.isEmpty
                      ? Center(
                          child: AppText(
                            "No products found",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: .68,
                              ),
                          itemCount: provider.filteredProducts.length,
                          itemBuilder: (context, index) {
                            final item = provider.filteredProducts[index];

                            return ProductCard(
                              item: item,
                              onToggleActive: (value) async {
                                final id = item.id?.toString() ?? '';

                                if (id.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Product ID not found'),
                                    ),
                                  );
                                  return;
                                }

                                final success = await provider.setProductActive(
                                  id: id,
                                  isActive: value,
                                );

                                if (!context.mounted) return;

                                if (!success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        provider.errorMessage ??
                                            'Unable to update status',
                                      ),
                                    ),
                                  );
                                }
                              },

                              // Edit
                              onEdit: () {
                                showAddProductServiceSheet(
                                  context,
                                  product: item,
                                );
                              },

                              // Delete
                              onDelete: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Delete product?'),
                                    content: Text(
                                      'Are you sure you want to delete ${item.name ?? 'this item'}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm != true || !context.mounted) return;

                                final id = item.id?.toString() ?? '';

                                if (id.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Product ID not found'),
                                    ),
                                  );
                                  return;
                                }

                                final success = await provider.deleteProduct(
                                  id,
                                );

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Product deleted successfully'
                                          : provider.errorMessage ??
                                                'Unable to delete product',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFED1C24) : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFED1C24), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              text,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFFED1C24),
                fontSize: AppFontSize.fontSize14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white : const Color(0xFFFFE5E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppText(
                "$count",
                style: TextStyle(
                  color: const Color(0xFFED1C24),
                  fontSize: AppFontSize.fontSize14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showAddProductServiceSheet(
    BuildContext context, {
    ProductListData? product,
  }) async {
    final productsProvider = context.read<ProductsProvider>();

    debugPrint('6. OPENING ADD SHEET');

    final bool? success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        return ChangeNotifierProvider<ProductsProvider>.value(
          value: productsProvider,
          child: AddProductServiceSheet(product: product),
        );
      },
    );

    debugPrint('7. SHEET RESULT: $success');

    if (success == true) {
      debugPrint('8. CALLING FETCH PRODUCTS');
      await productsProvider.fetchProducts();
      debugPrint('9. FETCH PRODUCTS COMPLETED');
    }
  }
}
