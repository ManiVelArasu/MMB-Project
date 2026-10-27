import '../Api Model/plans_type.dart';
import '../Api Model/product_model.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class ProductRepository {
  ProductRepository._();

  static final ProductRepository instance = ProductRepository._();

  // GET products
  Future<ApiResult<ProductList>> productList(String businessId) {
    return ApiRepository.instance.request<ProductList>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.productList,
        method: ApiMethod.get,
        queryParams: {'business_uid': businessId},
      ),
      fromJson: (json) => ProductList.fromJson(json),
    );
  }

  Future<ApiResult<dynamic>> addProductService({
    required Map<String, dynamic> body,
  }) {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.productList,
        method: ApiMethod.post,
        body: body,
      ),
      fromJson: (json) => json,
    );
  }

  Future<ApiResult<dynamic>> editProductService({
    required Map<String, dynamic> body,
  }) {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.productList,
        method: ApiMethod.patch,
        body: body,
      ),
      fromJson: (json) => json,
    );
  }

  Future<ApiResult<dynamic>> deleteProductService(String id) {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.productList,
        method: ApiMethod.delete,
        queryParams: {'id': id},
      ),
      fromJson: (json) => json,
    );
  }
}
