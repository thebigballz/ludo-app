import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../models/game_model.dart';

class LobbyRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<GameModel>> getTables({double? stakeAmount}) async {
    try {
      final response = await _dio.get(
        Endpoints.games,
        queryParameters: stakeAmount != null
            ? {'stake_amount': stakeAmount}
            : null,
      );

      // Temporary debug
      print('STATUS: ${response.statusCode}');
      print('DATA: ${response.data}');

      final rawTables = response.data['tables'];
      final data = (rawTables is Map)
          ? rawTables['data'] as List<dynamic>
          : rawTables as List<dynamic>;
      return data.map((e) => GameModel.fromJson(e)).toList();
    } on DioException catch (e) {
      print('DIO ERROR: ${e.message}');
      print('RESPONSE: ${e.response?.data}');
      ApiClient.handleError(e);
    }
  }

  Future<GameModel> joinTable(int gameId) async {
    try {
      final response = await _dio.post(
        Endpoints.joinGame,
        data: {'game_id': gameId},
      );

      return GameModel.fromJson(response.data['game']);
    } on DioException catch (e) {
      ApiClient.handleError(e);
    }
  }

  Future<void> leaveTable(int gameId) async {
    try {
      await _dio.post(Endpoints.leaveGame(gameId));
    } on DioException catch (e) {
      ApiClient.handleError(e);
    }
  }
}

