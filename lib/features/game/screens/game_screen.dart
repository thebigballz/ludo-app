import 'dart:core';
import 'package:flame/game.dart' as flame;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../chat/screens/chat_screen.dart';
import '../providers/game_provider.dart';
import '../engine/ludo_game.dart';
import '../engine/ludo_logic.dart';
import '../data/models/game_room_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String roomId;
  const GameScreen({super.key, required this.roomId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  LudoGame? _ludoGame;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider(widget.roomId).notifier).setConnected(true);
    });
  }

  @override
  void dispose() {
    ref.read(gameProvider(widget.roomId).notifier).setConnected(false);
    super.dispose();
  }

  void _onPawnTapped(Pawn pawn) {
    final userId    = ref.read(authProvider).user?.id ?? 0;
    final room      = ref.read(gameRoomStreamProvider(widget.roomId)).value;
    final roomState = ref.read(gameStateStreamProvider(widget.roomId)).value;
    final pawns     = ref.read(gamePawnsStreamProvider(widget.roomId)).value ?? {};

    if (room == null || roomState == null) return;

    final diceRoll = roomState.diceRoll;
    if (roomState.phase != 'moving') return;
    if (roomState.currentTurn != 'user_$userId') return;
    if (diceRoll == null) return;

    final players = _sortedPlayers(room, pawns);
    final currentPlayer = _playerForUser(players, userId);
    if (currentPlayer == null) return;
    if (pawn.color != currentPlayer.color) return;

    final validPawns = LudoLogic.validMoves(currentPlayer, diceRoll);
    if (!validPawns.any((p) => p.id == pawn.id)) return;

    ref.read(gameProvider(widget.roomId).notifier).movePawn(
      pawn,
      diceRoll,
      players,
    );
  }

  List<LudoPlayer> _sortedPlayers(
      GameRoomModel room, Map<String, PawnPositions> pawns) {
    final players = _buildPlayers(room, pawns);
    const colorOrder = [
      PlayerColor.red,
      PlayerColor.green,
      PlayerColor.yellow,
      PlayerColor.blue,
    ];
    players.sort((a, b) =>
        colorOrder.indexOf(a.color).compareTo(colorOrder.indexOf(b.color)));
    return players;
  }

  List<LudoPlayer> _buildPlayers(
      GameRoomModel room, Map<String, PawnPositions> pawns) {
    final players = <LudoPlayer>[];

    room.players.forEach((key, roomPlayer) {
      final userId = int.tryParse(key.replaceAll('user_', ''));
      if (userId == null) return;

      final player = LudoPlayer(userId: userId, color: roomPlayer.playerColor);

      final pawnPositions = pawns[key];
      if (pawnPositions != null) {
        pawnPositions.positions.forEach((pawnId, position) {
          final pawn = player.pawns.firstWhere(
                (p) => p.id == pawnId,
            orElse: () => player.pawns.first,
          );
          pawn.position = position;
          pawn.state = position == -1
              ? PawnState.home
              : position == LudoLogic.finishedPosition
              ? PawnState.finished
              : PawnState.active;
        });
      }

      players.add(player);
    });

    return players;
  }

  LudoPlayer? _playerForUser(List<LudoPlayer> players, int userId) {
    for (final player in players) {
      if (player.userId == userId) return player;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String roomId   = widget.roomId;
    final userId          = ref.watch(authProvider).user?.id ?? 0;
    final roomAsync       = ref.watch(gameRoomStreamProvider(widget.roomId));
    final stateAsync      = ref.watch(gameStateStreamProvider(widget.roomId));
    final pawnsAsync      = ref.watch(gamePawnsStreamProvider(widget.roomId) as ProviderListenable<dynamic>);
    final gameActions     = ref.watch(gameProvider(widget.roomId));

    // -------------------------------------------------------
    // FIX: rewritten listener — see game_screen_listener.dart
    // for a detailed explanation of every change.
    // -------------------------------------------------------
    ref.listen(gameStateStreamProvider(widget.roomId), (prev, next) {
      // FIX 1: compare against previous snapshot.
      // Only act when the state has genuinely changed, not on every rebuild.
      final prevState = prev?.value;
      final nextState = next.value;
      if (nextState == null) return;

      // FIX 2: only fire when we just entered 'moving' phase with a fresh roll.
      // If phase or dice_roll hasn't changed since last snapshot, do nothing.
      final phaseChanged = prevState?.phase != nextState.phase;
      final rollChanged  = prevState?.diceRoll != nextState.diceRoll;
      if (!phaseChanged && !rollChanged) return;

      // FIX 3: only the current turn player evaluates valid moves.
      if (nextState.phase != 'moving') return;
      if (nextState.diceRoll == null) return;
      if (nextState.currentTurn != 'user_$userId') return;

      final room = roomAsync.value;
      if (room == null) return;

      final pawns   = pawnsAsync.value ?? {};
      final players = _sortedPlayers(room, pawns);
      final me      = _playerForUser(players, userId);
      if (me == null) return;

      if (LudoLogic.validMoves(me, nextState.diceRoll!).isEmpty) {
        // FIX 4: use skipTurnIfNeeded which has the isSkipping guard.
        ref.read(gameProvider(roomId).notifier).skipTurnIfNeeded(players);
      }
    });

    return PopScope(
      // FIX: replaced deprecated WillPopScope with PopScope
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final phase =
            ref.read(gameStateStreamProvider(roomId)).value?.phase;
        if (phase == 'finished' || phase == 'waiting') {
          if (context.mounted) context.go('/lobby');
          return;
        }

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Leave Game?', style: AppTextStyles.heading3),
            content: const Text(
              'Leaving an active game will count as a loss '
                  'and your stake will be forfeited.',
              style: AppTextStyles.bodySecondary,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
                child: const Text('Leave'),
              ),
            ],
          ),
        );

        if ((confirmed ?? false) && context.mounted) {
          context.go('/lobby');
        }
      },

      child: Scaffold(
        backgroundColor: AppColors.background,
        body: roomAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (room) {
            if (room == null) {
              return const Center(child: Text('Room not found'));
            }

            final roomState = stateAsync.value;
            final pawns     = pawnsAsync.value ?? {};
            final players   = _sortedPlayers(room, pawns);
            final isMyTurn  = roomState?.currentTurn == 'user_$userId';
            final phase     = roomState?.phase ?? 'waiting';
            final diceRoll  = roomState?.diceRoll;

            if (_ludoGame == null && players.isNotEmpty) {
              _ludoGame = LudoGame(
                roomId:        widget.roomId,
                currentUserId: userId,
                onPawnTapped:  _onPawnTapped,
                initialPawns: {
                  for (final p in players) p.color: p.pawns,
                },
              );
            } else if (_ludoGame != null && players.isNotEmpty) {
              _ludoGame!.onPawnTapped = _onPawnTapped;
              _ludoGame!.syncPlayers(players);

              if (phase == 'moving' && isMyTurn && diceRoll != null) {
                final me = players.firstWhere((p) => p.userId == userId);
                _ludoGame!.setValidMoves(LudoLogic.validMoves(me, diceRoll));
              } else {
                _ludoGame!.clearHighlights();
              }
            }

            // FIX: winner check uses the actual winner field from Firebase
            // instead of the fragile toString() search.
            final winnerId = room.state.winner;
            final isWinner = winnerId == 'user_$userId';

            return SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    room:   room,
                    onExit: () => context.go('/lobby'),
                    onChat: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(roomId: widget.roomId),
                      ),
                    ),
                  ),

                  _PlayerIndicators(
                    players:     players,
                    currentTurn: roomState?.currentTurn,
                    userId:      userId,
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _ludoGame != null
                            ? flame.GameWidget(game: _ludoGame!)
                            : const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  _BottomControls(
                    isMyTurn:  isMyTurn,
                    phase:     phase,
                    lastRoll:  diceRoll,
                    isRolling: gameActions.isRolling,
                    isMoving:  gameActions.isMoving,
                    // FIX: also disable roll button while a skip is in progress
                    isSkipping: gameActions.isSkipping,
                    hasValidMoves: phase == 'moving' &&
                        isMyTurn &&
                        diceRoll != null &&
                        _playerForUser(players, userId) != null &&
                        LudoLogic.validMoves(
                          _playerForUser(players, userId)!,
                          diceRoll,
                        ).isNotEmpty,
                    onRoll: () => ref
                        .read(gameProvider(roomId).notifier)
                        .rollDice(players),
                  ),

                  if (phase == 'finished')
                    _WinnerBanner(
                      isWinner: isWinner,
                      onExit:   () => context.go('/lobby'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// -------------------------------------------------------
// Sub-widgets
// -------------------------------------------------------

class _TopBar extends StatelessWidget {
  final GameRoomModel room;
  final VoidCallback onExit;
  final VoidCallback onChat;

  const _TopBar({
    required this.room,
    required this.onExit,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color:   AppColors.surface,
      child: Row(
        children: [
          IconButton(
            icon:      const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: onExit,
          ),
          Expanded(
            child: Text(
              'Stake: ${Formatters.currency(room.meta.stakeAmount)}',
              style:     AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon:      const Icon(Icons.chat, color: AppColors.textPrimary),
            onPressed: onChat,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:        AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${room.players.length}/2',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerIndicators extends StatelessWidget {
  final List<LudoPlayer> players;
  final String? currentTurn;
  final int userId;

  const _PlayerIndicators({
    required this.players,
    required this.currentTurn,
    required this.userId,
  });

  Color _colorForPlayer(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:    return AppColors.red;
      case PlayerColor.green:  return AppColors.green;
      case PlayerColor.yellow: return AppColors.yellow;
      case PlayerColor.blue:   return AppColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color:   AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: players.map((player) {
          final isActive = currentTurn == 'user_${player.userId}';
          final isMe     = player.userId == userId;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? _colorForPlayer(player.color).withValues(alpha: 0.2)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? _colorForPlayer(player.color)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width:  10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _colorForPlayer(player.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isMe ? 'You' : player.color.name,
                  style: AppTextStyles.caption.copyWith(
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.circle, size: 6, color: AppColors.success),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final bool isMyTurn;
  final String phase;
  final int? lastRoll;
  final bool isRolling;
  final bool isMoving;
  final bool isSkipping;   // FIX: new param
  final bool hasValidMoves;
  final VoidCallback onRoll;

  const _BottomControls({
    required this.isMyTurn,
    required this.phase,
    required this.lastRoll,
    required this.isRolling,
    required this.isMoving,
    required this.isSkipping,
    required this.hasValidMoves,
    required this.onRoll,
  });

  // FIX: dice tap is disabled during a skip so the player can't
  // accidentally roll again while the turn-advance write is in flight.
  bool get _canRoll =>
      isMyTurn && phase == 'rolling' && !isRolling && !isSkipping;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color:   AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: _canRoll ? onRoll : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width:  72,
              height: 72,
              decoration: BoxDecoration(
                color: _canRoll ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _canRoll
                    ? [
                  BoxShadow(
                    color:      AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
                    : [],
              ),
              child: (isRolling || isSkipping)
                  ? const Center(
                child: CircularProgressIndicator(
                  color:       Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Center(
                child: Text(
                  lastRoll != null ? _diceEmoji(lastRoll!) : '🎲',
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _statusText(),
                style:     AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _diceEmoji(int roll) {
    const emojis = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];
    return emojis[roll - 1];
  }

  String _statusText() {
    if (phase == 'waiting')  return 'Waiting for players...';
    if (phase == 'finished') return 'Game over!';
    if (!isMyTurn)           return 'Waiting for opponent...';
    if (isSkipping)          return 'No valid moves — passing turn...';
    if (phase == 'rolling')  return 'Your turn — tap dice to roll';
    if (isMoving)            return 'Moving pawn...';
    if (phase == 'moving' && !hasValidMoves) {
      return 'No valid moves — passing turn...';
    }
    if (phase == 'moving') return 'Tap a highlighted pawn to move';
    return '';
  }
}

// FIX: WinnerBanner now receives the resolved isWinner bool instead
// of the room object, removing the fragile toString() check entirely.
class _WinnerBanner extends StatelessWidget {
  final bool isWinner;
  final VoidCallback onExit;

  const _WinnerBanner({
    required this.isWinner,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(20),
      color:   isWinner ? AppColors.success : AppColors.error,
      child: Column(
        children: [
          Text(
            isWinner ? '🏆 You Won!' : '😔 You Lost',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onExit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.background,
            ),
            child: const Text('Back to Lobby'),
          ),
        ],
      ),
    );
  }
}
