import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/network/api_paths.dart';
import '../models/order_dto.dart';

/// Accès réseau aux commandes : `GET /carts/user/{userId}`.
class OrdersRemoteDataSource {
  OrdersRemoteDataSource(this._dio);

  final Dio _dio;

  Future<OrderListDto> fetchOrders(int userId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.cartsByUser(userId),
      );
      return OrderListDto.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException(ErrorMapper.map(error));
    }
  }
}
