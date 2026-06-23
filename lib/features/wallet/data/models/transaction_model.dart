class TransactionModel {
  final int id;
  final String type;
  final String status;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String reference;
  final String? description;
  final String createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.reference,
    this.description,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id:            json['id'],
      type:          json['type'],
      status:        json['status'],
      amount:        double.tryParse(json['amount'].toString()) ?? 0.0,
      balanceBefore: double.tryParse(json['balance_before'].toString()) ?? 0.0,
      balanceAfter:  double.tryParse(json['balance_after'].toString()) ?? 0.0,
      reference:     json['reference'],
      description:   json['description'],
      createdAt:     json['created_at'],
    );
  }

  bool get isCredit =>
      type == 'deposit' || type == 'win' || type == 'refund';

  bool get isDebit =>
      type == 'withdrawal' || type == 'stake' || type == 'fee';
}