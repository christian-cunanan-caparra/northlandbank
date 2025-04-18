class Transaction {
  final int id;
  final String cardNumber;
  final DateTime date;
  final String type;
  final double amount;
  final double balance;
  final String accountType;


  Transaction({
    required this.id,
    required this.cardNumber,
    required this.date,
    required this.type,
    required this.amount,
    required this.balance,
    required this.accountType,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: int.parse(json['id'].toString()),
      cardNumber: json['card_number'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      amount: double.parse(json['amount'].toString()),
      balance: double.parse(json['balance'].toString()),
      accountType: json['account_type'],
    );
  }
}