class WalletModel {
  final double balance;
  final double totalDeposited;
  final double totalWithdrawn;
  final double totalWon;
  final double totalLost;

  const WalletModel({
    required this.balance,
    required this.totalDeposited,
    required this.totalWithdrawn,
    required this.totalWon,
    required this.totalLost,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance:        double.tryParse(json['balance'].toString()) ?? 0.0,
      totalDeposited: double.tryParse(json['total_deposited'].toString()) ?? 0.0,
      totalWithdrawn: double.tryParse(json['total_withdrawn'].toString()) ?? 0.0,
      totalWon:       double.tryParse(json['total_won'].toString()) ?? 0.0,
      totalLost:      double.tryParse(json['total_lost'].toString()) ?? 0.0,
    );
  }
}