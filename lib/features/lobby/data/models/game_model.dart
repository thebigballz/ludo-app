class GamePlayerModel {
  final int userId;
  final String color;
  final String? result;

  const GamePlayerModel({
    required this.userId,
    required this.color,
    this.result,
  });

  factory GamePlayerModel.fromJson(Map<String, dynamic> json) {
    return GamePlayerModel(
      userId: json['user_id'],
      color:  json['color'],
      result: json['result'],
    );
  }
}

class GameModel {
  final int id;
  final String firebaseRoomId;
  final String status;
  final double stakeAmount;
  final double platformFee;
  final int? winnerId;
  final String? startedAt;
  final String? endedAt;
  final List<GamePlayerModel> players;

  const GameModel({
    required this.id,
    required this.firebaseRoomId,
    required this.status,
    required this.stakeAmount,
    required this.platformFee,
    this.winnerId,
    this.startedAt,
    this.endedAt,
    this.players = const [],
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id:             json['id'],
      firebaseRoomId: json['firebase_room_id'],
      status:         json['status'],
      stakeAmount:    double.tryParse(json['stake_amount'].toString()) ?? 0.0,
      platformFee:    double.tryParse(json['platform_fee'].toString()) ?? 0.0,
      winnerId:       json['winner_id'],
      startedAt:      json['started_at'],
      endedAt:        json['ended_at'],
      players: (json['players'] as List<dynamic>? ?? [])
          .map((p) => GamePlayerModel.fromJson(p))
          .toList(),
    );
  }

  int get playerCount  => players.length;
  int get spotsLeft    => 4 - playerCount;
  bool get isFull      => playerCount >= 4;
  bool get isWaiting   => status == 'waiting';
  bool hasPlayer(int userId) {
    return players.any((p) => p.userId == userId);
  }
}