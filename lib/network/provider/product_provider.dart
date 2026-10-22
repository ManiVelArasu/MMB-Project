import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Api Model/product_model.dart';
import '../../Repository/product_repository.dart';

class ProductsProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  List<ProductListData> _products = [];

  ProductCounts? _counts;

  ProductCounts? get counts => _counts;

  String selectedFilter = 'ALL';

  List<ProductListData> get filteredProducts {
    switch (selectedFilter) {
      case 'PRODUCTS':
        return _products
            .where((item) => item.type?.toLowerCase() == 'product')
            .toList();

      case 'SERVICES':
        return _products
            .where((item) => item.type?.toLowerCase() == 'service')
            .toList();

      default:
        return _products;
    }
  }

  Future<void> fetchProducts() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Saved industry details
      final industrySlug = prefs.getString('saved_category_slug') ?? '';

      final savedUid = prefs.getString('business_uid');
      final businessUid = savedUid?.trim();

      if (businessUid == null || businessUid.isEmpty) {
        errorMessage = 'Business UID not found';
        notifyListeners();
        // return false;
      }
      final result = await ProductRepository.instance.productList(
        businessUid ?? '',
      );
      final ProductList? response = result.data;

      if (response?.success == true && response?.data != null) {
        _products = response!.data;
        _counts = response.meta?.counts;
      } else {
        errorMessage = 'Unable to load products';
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProductService({
    required String type,
    required String name,
    required String unit,
    required String description,
    required String price,
    required String offerPrice,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final businessUid = prefs.getString('business_uid')?.trim();

      if (businessUid == null || businessUid.isEmpty) {
        errorMessage = 'Business UID not found';
        return false;
      }

      final parsedPrice = num.tryParse(price.trim());
      final parsedOfferPrice = num.tryParse(offerPrice.trim());

      if (parsedPrice == null || parsedOfferPrice == null) {
        errorMessage = 'Enter valid prices';
        return false;
      }

      final body = <String, dynamic>{
        'business_uid': businessUid,
        'type': type,
        'name': name.trim(),
        'unit': unit.trim(),
        'description': description.trim(),
        'price': parsedPrice,
        'offer_price': parsedOfferPrice,
      };

      debugPrint('1. POST BODY: $body');

      final result = await ProductRepository.instance.addProductService(
        body: body,
      );

      debugPrint('2. POST RESULT DATA: ${result.data}');

      final response = result.data;

      debugPrint('POST RESPONSE: $response');

      final isSuccess = response is Map
          ? response['success'] == true
          : response?.success == true;

      if (isSuccess) {
        debugPrint('POST SUCCESS');

        return true;
      }

      errorMessage = 'Unable to add $type';
      return false;


    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void changeFilter(String filter) {
    selectedFilter = filter;
    notifyListeners();
  }

  int get allCount => int.tryParse(_counts?.all ?? '') ?? _products.length;

  int get productsCount =>
      int.tryParse(_counts?.products ?? '') ??
      _products.where((e) => e.type?.toLowerCase() == 'product').length;

  int get servicesCount =>
      int.tryParse(_counts?.services ?? '') ??
      _products.where((e) => e.type?.toLowerCase() == 'service').length;
}
