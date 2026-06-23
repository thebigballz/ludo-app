import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

class WalletRepository {
  final Dio _dio = ApiClient.instance;

  Future<WalletModel> getBalance() async {
    try {
      final response = await _dio.get(Endpoints.walletBalance);
      return WalletModel.fromJson(response.data['wallet']);
    } on DioException catch (e) {
      ApiClient.handleError(e);
    }
  }

  Future<List<TransactionModel>> getTransactions({int page = 1}) async {
    try {
      final response = await _dio.get(
        Endpoints.walletTransactions,
        queryParameters: {'page': page},
      );

      final data = response.data['transactions']['data'] as List<dynamic>;
      return data.map((e) => TransactionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      ApiClient.handleError(e);
    }
  }

  Future<String> deposit({
    required String phone,
    required double amount,
  }) async {
    try {
      final response = await _dio.post(
        Endpoints.deposit,
        data: {
          'phone':  phone,
          'amount': amount,
        },
      );
      return response.data['message'] as String;
    } on DioException catch (e) {
      ApiClient.handleError(e);
    }
  }

  Future<String> withdraw({
    required String phone,
    required double amount,
  }) async {
    try {
      final response = await _dio.post(
        Endpoints.withdraw,
        data: {
          'phone':  phone,
          'amount': amount,
        },
      );
      return response.data['message'] as String;
    } on DioException catch (e) {
      ApiClient.handleError(e);
    }
  }
}