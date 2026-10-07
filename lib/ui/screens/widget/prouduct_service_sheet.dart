import 'package:flutter/material.dart';
import 'package:mmb_app/ui/screens/widget/product_commom_field.dart';
import 'package:provider/provider.dart';
import '../../../network/provider/my_product_provider.dart';
import '../../../network/provider/my_upload_provider.dart';
import 'type_selection_card.dart';

class AddProductServiceSheet extends StatefulWidget {
  const AddProductServiceSheet({super.key});

  @override
  State<AddProductServiceSheet> createState() => _AddProductServiceSheetState();
}

class _AddProductServiceSheetState extends State<AddProductServiceSheet> {
  final nameController = TextEditingController();
  final unitController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final offerPriceController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    unitController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    offerPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductsProvider>(
      builder: (context, provider, child) {
        final isProduct = provider.selectedType == ProductType.product;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(14),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Add New Products/Services",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.red, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TypeSelectionCard(
                  type: ProductType.product,
                  selected: isProduct,
                  title: "Add Product",
                  subtitle: "A physical item you sell such as paint, hardware, apparel.",
                  onTap: () => provider.selectType(ProductType.product),
                ),
                const SizedBox(height: 8),
                TypeSelectionCard(
                  type: ProductType.service,
                  selected: !isProduct,
                  title: "Add Services",
                  subtitle: "Work you provide legal consulting, wall painting, repairs.",
                  onTap: () => provider.selectType(ProductType.service),
                ),
                const SizedBox(height: 12),
                CommonInputField(
                  label: isProduct ? "Product Name" : "Service Name",
                  hint: isProduct ? "Enter product name" : "Enter service name",
                  controller: nameController,
                ),
                const SizedBox(height: 10),
                CommonInputField(
                  label: isProduct ? "Unit/Weight" : "Service Area (optional)",
                  hint: isProduct ? "1 Kg" : "Enter service area",
                  controller: unitController,
                ),
                const SizedBox(height: 10),
                CommonInputField(
                  label: "Description",
                  hint: "Enter description",
                  controller: descriptionController,
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CommonInputField(
                        label: "Actual Price",
                        hint: "800",
                        controller: priceController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CommonInputField(
                        label: "Offer Price",
                        hint: "750",
                        controller: offerPriceController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Consumer<UploadProvider>(
                  builder: (context, uploadProvider, child) {
                    return InkWell(
                      onTap: uploadProvider.isUploading
                          ? null
                          : () => uploadProvider.pickImage(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8E8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_camera_outlined, size: 17, color: Colors.red),
                            const SizedBox(width: 6),
                            Text(
                              uploadProvider.isUploading
                                  ? "Uploading..."
                                  : "Upload Product Picture",
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: provider.isLoading
                            ? null
                            : () async {
                          if (nameController.text.trim().isEmpty) return;

                          final name = nameController.text.trim();
                          final unit = unitController.text.trim();
                          final description = descriptionController.text.trim();
                          final price = priceController.text.trim();
                          final offerPrice = offerPriceController.text.trim();

                          if (isProduct) {
                            await provider.addProduct(
                              name: name,
                              unit: unit,
                              description: description,
                              price: price,
                              offerPrice: offerPrice,
                            );
                          } else {
                            await provider.addService(
                              name: name,
                              unit: unit,
                              description: description,
                              price: price,
                              offerPrice: offerPrice,
                            );
                          }

                          if (context.mounted) Navigator.pop(context);
                        },
                        child: provider.isLoading
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(isProduct ? "ADD PRODUCT" : "ADD SERVICE"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
