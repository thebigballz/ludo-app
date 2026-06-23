import '../../engine/ludo_logic.dart';

class GameRoomMeta {
  final int gameId;
  final String status;
  final double stakeAmount;

  const GameRoomMeta({
    required this.gameId,
    required this.status,
    required this.stakeAmount,
  });

  factory GameRoomMeta.fromJson(Map<dynamic, dynamic> json) {
    return GameRoomMeta(
      gameId:      json['game_id'] as int? ?? 0,
      status:      json['status'] as String? ?? 'waiting',
      stakeAmount: (json['stake_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GameRoomPlayer {
  final int userId;
  final String name;
  final String color;
  final bool isConnected;
  final bool isReady;

  const GameRoomPlayer({
    required this.userId,
    required this.name,
    required this.color,
    required this.isConnected,
    required this.isReady,
  });

  factory GameRoomPlayer.fromJson(Map<dynamic, dynamic> json) {
    return GameRoomPlayer(
      userId:      json['user_id'] as int? ?? 0,
      name:        json['name'] as String? ?? 'Player',
      color:       json['color'] as String? ?? 'red',
      isConnected: json['is_connected'] as bool? ?? false,
      isReady:     json['is_ready'] as bool? ?? false,
    );
  }

  PlayerColor get playerColor {
    switch (color) {
      case 'red':    return PlayerColor.red;
      case 'green':  return PlayerColor.green;
      case 'yellow': return PlayerColor.yellow;
      case 'blue':   return PlayerColor.blue;
      default:       return PlayerColor.red;
    }
  }
}

class GameRoomState {
  final String? currentTurn;
  final int turnNumber;
  final int? diceRoll;
  final String phase;

  const GameRoomState({
    this.currentTurn,
    required this.turnNumber,
    this.diceRoll,
    required this.phase,
  });

  factory GameRoomState.fromJson(Map<dynamic, dynamic> json) {
    return GameRoomState(
      currentTurn: json['current_turn'] as String?,
      turnNumber:  json['turn_number'] as int? ?? 0,
      diceRoll:    json['dice_roll'] as int?,
      phase:       json['phase'] as String? ?? 'waiting',
    );
  }
}

class PawnPositions {
  final Map<String, int> positions;

  const PawnPositions({required this.positions});

  factory PawnPositions.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) {
      return const PawnPositions(
        positions: {'p1': -1, 'p2': -1, 'p3': -1, 'p4': -1},
      );
    }
    return PawnPositions(
      positions: {
        'p1': json['p1'] as int? ?? -1,
        'p2': json['p2'] as int? ?? -1,
        'p3': json['p3'] as int? ?? -1,
        'p4': json['p4'] as int? ?? -1,
      },
    );
  }
}

class GameRoomModel {
  final GameRoomMeta meta;
  final Map<String, GameRoomPlayer> players;
  final GameRoomState state;
  final Map<String, PawnPositions> pawns;

  const GameRoomModel({
    required this.meta,
    required this.players,
    required this.state,
    required this.pawns,
  });

  factory GameRoomModel.fromJson(Map<dynamic, dynamic> json) {
    // Players
    final playersMap = <String, GameRoomPlayer>{};
    final rawPlayers = json['players'];
    if (rawPlayers != null && rawPlayers is Map) {
      rawPlayers.forEach((key, value) {
        if (value != null && value is Map) {
          playersMap[key.toString()] =
              GameRoomPlayer.fromJson(value as Map<dynamic, dynamic>);
        }
      });
    }

    // Pawns
    final pawnsMap = <String, PawnPositions>{};
    final rawPawns = json['pawns'];
    if (rawPawns != null && rawPawns is Map) {
      rawPawns.forEach((key, value) {
        pawnsMap[key.toString()] = PawnPositions.fromJson(
          value is Map ? value as Map<dynamic, dynamic> : null,
        );
      });
    }

    // Meta
    final rawMeta = json['meta'];
    final meta = rawMeta != null && rawMeta is Map
        ? GameRoomMeta.fromJson(rawMeta as Map<dynamic, dynamic>)
        : const GameRoomMeta(gameId: 0, status: 'waiting', stakeAmount: 0);

    // State
    final rawState = json['state'];
    final state = rawState != null && rawState is Map
        ? GameRoomState.fromJson(rawState as Map<dynamic, dynamic>)
        : const GameRoomState(turnNumber: 0, phase: 'waiting');

    return GameRoomModel(
      meta:    meta,
      players: playersMap,
      state:   state,
      pawns:   pawnsMap,
    );
  }
}