class MessageModel {
  final String id;
  final int userId;
  final String name;
  final String message;
  final int timestamp;

  const MessageModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.message,
    required this.timestamp,
  });

  factory MessageModel.fromSnapshot(String id, Map<dynamic, dynamic> json) {
    return MessageModel(
      id:        id,
      userId:    json['user_id'] as int,
      name:      json['name'] as String,
      message:   json['message'] as String,
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp);
}