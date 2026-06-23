import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../models/leaderboard_model.dart';

class LeaderboardRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    try {
      final response = await _dio.get(Endpoints.leaderboard);
      final data = response.data['players'] as List<dynamic>;
      return data
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList();
    } on DioException catch (e) {
      ApiClient.handleError(e);
    }
  }
}