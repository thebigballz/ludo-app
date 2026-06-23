import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/message_model.dart';
import '../data/repositories/chat_repository.dart';
import '../../auth/providers/auth_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

// Stream of messages for a room
final chatMessagesProvider =
StreamProvider.family<List<MessageModel>, String>(
      (ref, String roomId) {
    final repo = ref.watch(chatRepositoryProvider);
    return repo.watchMessages(roomId);
  },
);

// Send message action
class ChatNotifier extends StateNotifier<bool> {
  final ChatRepository _repository;
  final String _roomId;
  final int _userId;
  final String _userName;

  ChatNotifier(
      this._repository,
      this._roomId,
      this._userId,
      this._userName,
      ) : super(false);

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    state = true; // sending

    try {
      await _repository.sendMessage(
        roomId:  _roomId,
        userId:  _userId,
        name:    _userName,
        message: message.trim(),
      );
    } finally {
      state = false;
    }
  }
}

final chatProvider =
StateNotifierProvider.family<ChatNotifier, bool, String>(
      (ref, String roomId) {
    final repo   = ref.watch(chatRepositoryProvider);
    final user   = ref.watch(authProvider).user;
    return ChatNotifier(
      repo,
      roomId,
      user?.id ?? 0,
      user?.name ?? 'Player',
    );
  },
);