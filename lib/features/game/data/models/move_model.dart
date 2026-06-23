class MoveModel {
  final int userId;
  final int diceRoll;
  final String pawn;
  final int from;
  final int to;
  final int timestamp;

  const MoveModel({
    required this.userId,
    required this.diceRoll,
    required this.pawn,
    required this.from,
    required this.to,
    required this.timestamp,
  });

  factory MoveModel.fromJson(Map<dynamic, dynamic> json) {
    return MoveModel(
      userId:    json['user_id'] as int,
      diceRoll:  json['dice_roll'] as int,
      pawn:      json['pawn'] as String,
      from:      json['from'] as int,
      to:        json['to'] as int,
      timestamp: json['timestamp'] as int,
    );
  }
}