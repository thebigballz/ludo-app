import 'package:firebase_database/firebase_database.dart';
import '../models/game_room_model.dart';

class GameRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  DatabaseReference _roomRef(String roomId) =>
      _db.ref('games/$roomId');

  // -------------------------------------------------------
  // Streams
  // -------------------------------------------------------

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

  // -------------------------------------------------------
  // Writes
  // -------------------------------------------------------

  /// Requests a server-generated dice roll.
  ///
  /// The client deliberately does not generate or write the dice value.
  /// Firebase rules only allow the player whose turn it is to create this
  /// request, while the Cloud Function writes the authoritative result.
  Future<void> requestDiceRoll(String roomId) async {
    await _roomRef(roomId).child('state/roll_request').set(true);
  }

  /// Kept private to prevent callers from treating a client-generated dice
  /// value as authoritative. Dice results must come from the server.
  Future<void> clearDiceRoll(String roomId) async {
    await _roomRef(roomId).child('state').update({
      'dice_roll': null,
      'phase': 'rolling',
    });
  }

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

  Future<void> advanceTurn(String roomId, int nextUserId) async {
    await _roomRef(roomId).child('state').update({
      'current_turn': 'user_$nextUserId',
    });
  }

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
