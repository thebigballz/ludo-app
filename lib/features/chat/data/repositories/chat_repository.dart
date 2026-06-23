import 'package:firebase_database/firebase_database.dart';
import '../models/message_model.dart';

class ChatRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  DatabaseReference _chatRef(String roomId) =>
      _db.ref('games/$roomId/chat');

  Stream<List<MessageModel>> watchMessages(String roomId) {
    return _chatRef(roomId)
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return [];

      final raw = event.snapshot.value as Map<dynamic, dynamic>;
      final messages = <MessageModel>[];

      raw.forEach((key, value) {
        messages.add(
          MessageModel.fromSnapshot(
            key.toString(),
            value as Map<dynamic, dynamic>,
          ),
        );
      });

      // Sort by timestamp ascending
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  Future<void> sendMessage({
    required String roomId,
    required int userId,
    required String name,
    required String message,
  }) async {
    await _chatRef(roomId).push().set({
      'user_id':   userId,
      'name':      name,
      'message':   message,
      'timestamp': ServerValue.timestamp,
    });
  }
}