import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mmb_app/ui/screens/widget/product_card.dart';
import 'package:mmb_app/ui/screens/widget/product_sheet.dart';
import 'package:provider/provider.dart';
import '../../component/custom_widget.dart';

import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/product_provider.dart';
import '../../Api Model/product_model.dart';
import '../../utils/theme/app.fonts.dart';
import '../../widgets/color_widget.dart';
import '../industry/widgets/scaffold_widget.dart';
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
    final isDark = context.watch<CustomThemeProvider>().isDarkMode;
    final p = AppPalette(isDark);

    return CommonScaffold(
      isDarkMode: isDark,
      appBar: AppBar(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,

        leading: Padding(
          padding: const EdgeInsets.only(left: 10, top: 12, bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: p.backButtonBg,
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
            color: p.title,
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
                Container(
                  width: double.infinity,
                  color: p.surface,
                  padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
                  child: AppText(
                    "Everything you offer, in one place, shown on your store page and Near Me listing.",
                    style: TextStyle(
                      fontSize: AppFontSize.fontSize14,
                      fontWeight: FontWeight.w400,
                      color: p.bodyText,
                      height: 1.25,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: p.filterBar,
                  padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
                  child: Row(
                    children: [
                      _filterChip('ALL', provider, p, count: provider.allCount),
                      const SizedBox(width: 7),
                      _filterChip(
                        'PRODUCTS',
                        provider,
                        p,
                        count: provider.productsCount,
                      ),
                      const SizedBox(width: 7),
                      _filterChip(
                        'SERVICES',
                        provider,
                        p,
                        count: provider.servicesCount,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: provider.filteredProducts.isEmpty
                      ? (provider.allCount == 0
                      ? _EmptyProductsState(
                    p: p,
                    onLater: () => Navigator.pop(context),
                    onAdd: () =>
                        showAddProductServiceSheet(context),
                  )
                      : Center(
                    child: AppText(
                      "No products found",
                      style: TextStyle(
                        color: p.emptyText,
                        fontSize: 13,
                      ),
                    ),
                  ))
                      : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: provider.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final item = provider.filteredProducts[index];

                      return ProductCard(
                        item: item,
                        onToggleActive: (value) async {
                          final id = item.uid?.toString() ?? '';

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
                        onEdit: () {
                          showAddProductServiceSheet(
                            context,
                            product: item,
                          );
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              backgroundColor: p.surface,
                              surfaceTintColor: Colors.transparent,
                              title: Text(
                                'Delete product?',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to delete ${item.name ?? 'this item'}?',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
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
      ProductsProvider provider,
      AppPalette p, {
        required int count,
      }) {
    final selected = provider.selectedFilter == text;

    return GestureDetector(
      onTap: () => provider.changeFilter(text),
      child: Container(
        height: 29,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFED1C24) : p.chipBg,
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
                color: selected ? Colors.white : p.countBg,
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
    if (success == true) {
      await productsProvider.fetchProducts();
    }
  }
}

/// Shown when the user has no products or services at all.
class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState({
    required this.p,
    required this.onAdd,
    required this.onLater,
  });

  final AppPalette p;
  final VoidCallback onAdd;
  final VoidCallback onLater;
  static const String _imageAsset = 'assets/images/add_product_service.png';

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFED1C24);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              _imageAsset,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.storefront_rounded, size: 80, color: red),
            ),
            const SizedBox(height: 24),
            AppText(
              'Add Your Products & Services',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: p.title,
                fontSize: AppFontSize.fontSize18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            AppText(
              'Add your products and services to showcase what your business '
                  'offers and make your marketing content more useful.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: p.bodyText,
                fontSize: AppFontSize.fontSize14,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                OutlinedButton(
                  onPressed: onLater,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: red,
                    side: const BorderSide(color: red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const AppText(
                    'Maybe Later',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const AppText(
                    'Add Products & Services',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
