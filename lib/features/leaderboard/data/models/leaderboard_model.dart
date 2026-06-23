class LeaderboardEntry {
  final int rank;
  final int id;
  final String name;
  final String? avatar;
  final int totalWins;
  final int totalGames;
  final int totalLosses;
  final double totalEarned;
  final double winRate;

  const LeaderboardEntry({
    required this.rank,
    required this.id,
    required this.name,
    this.avatar,
    required this.totalWins,
    required this.totalGames,
    required this.totalLosses,
    required this.totalEarned,
    required this.winRate,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank:         json['rank'],
      id:           json['id'],
      name:         json['name'],
      avatar:       json['avatar'],
      totalWins:    json['total_wins'],
      totalGames:   json['total_games'],
      totalLosses:  json['total_losses'],
      totalEarned:  double.tryParse(
          json['total_earned'].toString()) ?? 0.0,
      winRate:      (json['win_rate'] as num).toDouble(),
    );
  }
}