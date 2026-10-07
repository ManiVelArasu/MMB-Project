import 'package:flutter/material.dart';

enum ProductType { product, service }

class ProductItem {
  final String id, name, description, unit, price, offerPrice, image;
  final ProductType type;
  bool isActive;

  ProductItem({
    required this.id,
    required this.name,
    required this.description,
    required this.unit,
    required this.price,
    required this.offerPrice,
    required this.image,
    required this.type,
    this.isActive = true,
  });
}

class ProductsProvider extends ChangeNotifier {
  final List<ProductItem> _products = [];

  List<ProductItem> get products => List.unmodifiable(_products);

  ProductType _selectedType = ProductType.product;
  ProductType get selectedType => _selectedType;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _selectedFilter = "ALL";
  String get selectedFilter => _selectedFilter;

  void selectType(ProductType type) {
    _selectedType = type;
    notifyListeners();
  }

  void changeFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  List<ProductItem> get filteredProducts {
    switch (_selectedFilter) {
      case "PRODUCTS":
        return _products.where((e) => e.type == ProductType.product).toList();
      case "SERVICES":
        return _products.where((e) => e.type == ProductType.service).toList();
      default:
        return _products;
    }
  }

  Future<void> addProduct({
    required String name,
    required String unit,
    required String description,
    required String price,
    required String offerPrice,
    String image = "",
  }) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _products.insert(
      0,
      ProductItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        unit: unit,
        description: description,
        price: price,
        offerPrice: offerPrice,
        image: image,
        type: ProductType.product,
      ),
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addService({
    required String name,
    required String unit,
    required String description,
    required String price,
    required String offerPrice,
    String image = "",
  }) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _products.insert(
      0,
      ProductItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        unit: unit,
        description: description,
        price: price,
        offerPrice: offerPrice,
        image: image,
        type: ProductType.service,
      ),
    );
    _isLoading = false;
    notifyListeners();
  }

  void deleteProduct(String id) {
    _products.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void toggleActive(String id) {
    final index = _products.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _products[index].isActive = !_products[index].isActive;
    notifyListeners();
  }
}
