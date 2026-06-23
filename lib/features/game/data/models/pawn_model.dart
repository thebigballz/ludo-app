class PawnModel {
  final String id;
  final String color;
  int position;

  PawnModel({
    required this.id,
    required this.color,
    required this.position,
  });

  bool get isHome     => position == -1;
  bool get isFinished => position == 57;
  bool get isActive   => !isHome && !isFinished;
}