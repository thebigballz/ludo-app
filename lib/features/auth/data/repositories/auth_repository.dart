import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance;

  Future<UserModel> register({
    required String name,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post(
        Endpoints.register,
        data: {
          'name':                  name,
          'phone':                 phone,
          'password':              password,
          'password_confirmation': passwordConfirmation,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final user  = UserModel.fromJson(response.data['user']);
        final token = response.data['token'] as String;

        await SecureStorage.saveToken(token);
        await SecureStorage.saveUser(user.toJsonString());

        return user;
      }

      throw ServerException(
        message:    response.data['message'] ?? AppStrings.error,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      ApiClient.handleError(e);
    }
  }

  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        Endpoints.login,
        data: {
          'phone':       phone,
          'password':    password,
          'device_name': 'flutter_app',
        },
      );

      final user  = UserModel.fromJson(response.data['user']);
      final token = response.data['token'] as String;

      await SecureStorage.saveToken(token);
      await SecureStorage.saveUser(user.toJsonString());

      return user;
    } on DioException catch (e) {
      ApiClient.handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(Endpoints.logout);
    } catch (_) {
      // Clear local storage even if API call fails
    } finally {
      await SecureStorage.clearAll();
    }
  }

  Future<UserModel?> getCachedUser() async {
    final userJson = await SecureStorage.getUser();
    if (userJson == null) return null;
    return UserModel.fromJsonString(userJson);
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getToken();
    return token != null;
  }

  Future<UserModel?> refreshUser() async {
    try {
      final response = await _dio.get(Endpoints.walletBalance);
      final cachedUser = await getCachedUser();
      if (cachedUser == null) return null;

      // Merge fresh wallet data into cached user
      final updatedUser = UserModel(
        id:        cachedUser.id,
        name:      cachedUser.name,
        phone:     cachedUser.phone,
        email:     cachedUser.email,
        kycStatus: cachedUser.kycStatus,
        avatar:    cachedUser.avatar,
        wallet:    response.data['wallet'],
      );

      await SecureStorage.saveUser(updatedUser.toJsonString());
      return updatedUser;
    } catch (e) {
      return null;
    }
  }
}