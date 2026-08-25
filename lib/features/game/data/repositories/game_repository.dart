import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../models/game_room_model.dart';

class GameRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final Dio _dio = ApiClient.instance;

  DatabaseReference _roomRef(String roomId) =>
      _db.ref('games/$roomId');

  Stream<GameRoomModel?> watchRoom(String roomId) {
    return _roomRef(roomId).onValue.map((event) {
      if (!event.snapshot.exists) return null;
      final data = event.snapshot.value;
      if (data == null || data is! Map) return null;
      try {
        return GameRoomModel.fromJson(data as Map<dynamic, dynamic>);
      } catch (e) {
        return null;
      }
    });
  }

  Stream<GameRoomState?> watchState(String roomId) {
    return _roomRef(roomId).child('state').onValue.map((event) {
      if (!event.snapshot.exists) return null;
      final data = event.snapshot.value;
      if (data == null || data is! Map) return null;
      try {
        return GameRoomState.fromJson(data as Map<dynamic, dynamic>);
      } catch (e) {
        return null;
      }
    });
  }

  Stream<Map<String, PawnPositions>> watchPawns(String roomId) {
    return _roomRef(roomId).child('pawns').onValue.map((event) {
      if (!event.snapshot.exists) return {};
      final raw = event.snapshot.value;
      if (raw == null || raw is! Map) return {};
      final result = <String, PawnPositions>{};
      try {
        (raw as Map<dynamic, dynamic>).forEach((key, value) {
          result[key.toString()] = PawnPositions.fromJson(
            value is Map ? value as Map<dynamic, dynamic> : null,
          );
        });
      } catch (_) {}
      return result;
    });
  }

  /// Ask the Laravel API to generate the authoritative dice roll.
  Future<int> requestDiceRoll(int gameId) async {
    final response = await _dio.post(Endpoints.rollDice(gameId));
    final data = response.data;

    if (data is! Map || data['dice_roll'] is! int) {
      throw StateError('Invalid dice-roll response from server.');
    }

    return data['dice_roll'] as int;
  }

  /// Ask the Laravel API to validate and apply a pawn move.
  Future<void> movePawn(int gameId, int pawnIndex) async {
    await _dio.post(
      Endpoints.movePawn(gameId),
      data: {'pawn_index': pawnIndex},
    );
  }

  /// Ask the Laravel API to advance the turn when no legal pawn move exists.
  Future<void> skipTurn(int gameId) async {
    await _dio.post(Endpoints.skipTurn(gameId));
  }

  Future<void> setPlayerConnected(
      String roomId,
      int userId,
      bool connected,
      ) async {
    await _roomRef(roomId).child('players/user_$userId').update({
      'is_connected': connected,
      'last_seen': ServerValue.timestamp,
    });
  }
}
