import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/network/api_paths.dart';
import '../models/product_dto.dart';

/// Accès réseau au catalogue de l'API REST.
class CatalogRemoteDataSource {
  CatalogRemoteDataSource(this._dio);

  final Dio _dio;

  /// `GET /products` (et ses variantes `search` / `category`).
  Future<ProductPageDto> fetchProducts({
    required int limit,
    required int skip,
    String? query,
    String? category,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.productsList(
          limit: limit,
          skip: skip,
          query: query,
          category: category,
        ),
      );
      return ProductPageDto.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException(ErrorMapper.map(error));
    }
  }

  /// `GET /products/{id}` — détail complet, avis clients inclus.
  Future<ProductDto> fetchProduct(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.productById(id),
      );
      return ProductDto.fromEnvelope(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException(ErrorMapper.map(error));
    }
  }

  /// `GET /products/categories`
  Future<List<CategoryDto>> fetchCategories() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiPaths.categories());
      final data = response.data;
      if (data == null) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(CategoryDto.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiException(ErrorMapper.map(error));
    }
  }
}
