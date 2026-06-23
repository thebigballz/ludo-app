import 'package:dio/dio.dart';
import '../constants/app_config.dart';
import '../constants/app_strings.dart';
import '../errors/exceptions.dart';
import 'api_interceptor.dart';

class ApiClient {
  static Dio? _dio;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl:        AppConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.add(ApiInterceptor());

    return dio;
  }

  static Never handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message    = e.response?.data?['message']
        ?? AppStrings.error;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        throw const NetworkException();

      case DioExceptionType.badResponse:
        if (statusCode == 401) throw const UnauthorizedException();
        if (statusCode == 422) throw ServerException(message: message, statusCode: statusCode);
        throw ServerException(message: message, statusCode: statusCode);

      default:
        throw ServerException(message: e.message ?? AppStrings.error);
    }
  }
}