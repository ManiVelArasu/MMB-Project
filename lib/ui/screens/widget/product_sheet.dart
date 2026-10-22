import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:mmb_app/network/provider/product_provider.dart';

class AddProductServiceSheet extends StatefulWidget {
  const AddProductServiceSheet({
    super.key,

  });



  @override
  State<AddProductServiceSheet> createState() =>
      _AddProductServiceSheetState();
}
class _AddProductServiceSheetState extends State<AddProductServiceSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _offerPriceController = TextEditingController();

  String _selectedType = 'product';
  bool _isLoading = false;

  static const Color primaryRed = Color(0xFFFF202B);
  static const Color lightPink = Color(0xFFFFF0F1);
  static const Color borderColor = Color(0xFFE5E5E5);

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _offerPriceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProductsProvider>();

    setState(() => _isLoading = true);

    try {
      final success = await provider.addProductService(
        type: _selectedType,
        name: _nameController.text.trim(),
        unit: _unitController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _priceController.text.trim(),
        offerPrice: _offerPriceController.text.trim(),
      );

      if (!mounted) return;

      debugPrint('4. SHEET SUCCESS: $success');

      if (success) {
        debugPrint('5. CLOSING SHEET');
        Navigator.of(context).pop(true);
      } else {
        debugPrint('5. SHEET NOT CLOSED');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Product creation failed',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add item: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final isProduct = _selectedType == 'product';

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
      
                  // Header
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Add New Products/Services',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF202020),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: lightPink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: primaryRed,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
      
                  // Product / Service selection
                  Row(
                    children: [
                      Expanded(
                        child: _typeCard(
                          type: 'product',
                          title: 'Add Product',
                          subtitle:
                              'A physical item you sell cakes, paint, hardware, apparel.',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _typeCard(
                          type: 'service',
                          title: 'Add Services',
                          subtitle:
                              'Work you provide legal consulting, wall painting, repairs.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
      
                  _inputField(
                    controller: _nameController,
                    label: 'Product Name',
                    hint: 'Enter name',
                  ),
                  const SizedBox(height: 10),
      
                  _inputField(
                    controller: _unitController,
                    label: 'Unit/Weight',
                    hint: 'e.g. 1 Kg',
                  ),
                  const SizedBox(height: 10),
      
                  _inputField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Enter description',
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 10),
      
                  // Prices
                  Row(
                    children: [
                      Expanded(
                        child: _inputField(
                          controller: _priceController,
                          label: 'Actual Price',
                          hint: '0',
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _inputField(
                          controller: _offerPriceController,
                          label: 'Offer Price',
                          hint: '0',
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
      
                  // Upload button - UI only
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connect your image picker here'),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: lightPink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC9CC),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.image, color: primaryRed),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isProduct
                                ? 'Upload Product Picture'
                                : 'Upload Service Picture',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
      
                  // Bottom buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Color(0xFF444444)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 46),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isProduct ? 'ADD PRODUCT' : 'ADD SERVICE',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeCard({
    required String type,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 116,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFE9EA) : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? primaryRed : const Color(0xFFFFE1E3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? primaryRed : const Color(0xFFFFD9DC),
                size: 21,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.35,
                        color: Color(0xFF333333),
                      ),
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        if (isNumber && num.tryParse(value.trim()) == null) {
          return 'Enter a valid number';
        }
        return null;
      },
      style: const TextStyle(fontSize: 13, color: Color(0xFF252525)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
        counterText: '',
        labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryRed),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryRed),
        ),
      ),
    );
  }
}
