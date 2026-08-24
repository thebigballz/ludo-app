import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/game_room_model.dart';

class GameRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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

  /// Requests a dice roll from the authoritative Firebase Function.
  /// The client never supplies the dice value.
  Future<int> requestDiceRoll(String roomId) async {
    final callable = _functions.httpsCallable('rollDice');
    final result = await callable.call(<String, dynamic>{
      'roomId': roomId,
    });

    final data = result.data;
    if (data is! Map || data['diceRoll'] is! int) {
      throw StateError('Invalid dice-roll response from server.');
    }

    return data['diceRoll'] as int;
  }

  @Deprecated('Use requestDiceRoll(). Direct state writes will be removed in Phase 2.')
  Future<void> setDiceRoll(String roomId, int roll) async {
    await _roomRef(roomId).child('state').update({
      'dice_roll': roll,
      'phase': 'moving',
      'roll_request': false,
    });
  }

  @Deprecated('State transitions will become server-authoritative in Phase 2.')
  Future<void> clearDiceRoll(String roomId) async {
    await _roomRef(roomId).child('state').update({
      'dice_roll': null,
      'phase': 'rolling',
    });
  }

  @Deprecated('Pawn validation will move to the authoritative server in Phase 2.')
  Future<void> movePawn(
      String roomId,
      int userId,
      String pawnId,
      int newPosition,
      ) async {
    await _roomRef(roomId)
        .child('pawns/user_$userId/$pawnId')
        .set(newPosition);
  }

  @Deprecated('Move recording will move to the authoritative server in Phase 2.')
  Future<void> recordMove(
      String roomId,
      int userId,
      int diceRoll,
      String pawnId,
      int from,
      int to,
      ) async {
    await _roomRef(roomId).child('moves').push().set({
      'user_id': userId,
      'dice_roll': diceRoll,
      'pawn': pawnId,
      'from': from,
      'to': to,
      'timestamp': ServerValue.timestamp,
    });
  }

  @Deprecated('Turn advancement will become server-authoritative in Phase 2.')
  Future<void> advanceTurn(String roomId, int nextUserId) async {
    await _roomRef(roomId).child('state').update({
      'current_turn': 'user_$nextUserId',
    });
  }

  @Deprecated('Winner declaration will become server-authoritative in Phase 2.')
  Future<void> setWinner(String roomId, int userId) async {
    await _roomRef(roomId).update({
      'meta/status': 'finished',
      'state/phase': 'finished',
      'state/winner': 'user_$userId',
    });
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
