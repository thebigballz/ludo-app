import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'board_component.dart';
import 'pawn_component.dart';
import 'ludo_logic.dart';

class LudoGame extends FlameGame {
  final String roomId;
  final int currentUserId;
  Function(Pawn) onPawnTapped;

  late BoardComponent _board;
  final Map<PlayerColor, List<Pawn>> allPawns = {};

  LudoGame({
    required this.roomId,
    required this.currentUserId,
    required this.onPawnTapped,
    Map<PlayerColor, List<Pawn>>? initialPawns,
  }) {
    if (initialPawns != null) {
      allPawns.addAll(initialPawns);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    _board = BoardComponent();
    await add(_board);

    for (final pawns in allPawns.values) {
      for (final pawn in pawns) {
        _addPawnComponent(pawn);
      }
    }
  }

  void _addPawnComponent(Pawn pawn) {
    final exists = children.whereType<PawnComponent>().any(
          (c) => c.pawn.id == pawn.id && c.pawn.color == pawn.color,
        );
    if (exists) return;

    add(PawnComponent(
      pawn:           pawn,
      onTapped:       () => onPawnTapped(pawn),
      boardComponent: _board,
    ));
  }

  /// Sync pawn positions from Firebase and ensure components exist for all players.
  void syncPlayers(List<LudoPlayer> players) {
    if (!isLoaded) return;

    allPawns.clear();
    for (final player in players) {
      allPawns[player.color] = player.pawns;
      for (final pawn in player.pawns) {
        _addPawnComponent(pawn);
      }
    }

    for (final component in children.whereType<PawnComponent>()) {
      final playerPawns = allPawns[component.pawn.color];
      if (playerPawns == null) continue;

      final updated = playerPawns.firstWhere(
        (p) => p.id == component.pawn.id,
        orElse: () => component.pawn,
      );
      component.pawn.position = updated.position;
      component.pawn.state    = updated.state;
      component.refreshPosition();
    }
  }

  void setValidMoves(List<Pawn> validPawns) {
    final validIds = validPawns.map((p) => '${p.color.name}_${p.id}').toSet();
    for (final component in children.whereType<PawnComponent>()) {
      final key = '${component.pawn.color.name}_${component.pawn.id}';
      component.setHighlighted(validIds.contains(key));
    }
  }

  void clearHighlights() {
    for (final component in children.whereType<PawnComponent>()) {
      component.setHighlighted(false);
    }
  }
}
