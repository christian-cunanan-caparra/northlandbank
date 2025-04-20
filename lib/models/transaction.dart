class Transaction {
  final String id;
  final String cardNumber;
  final DateTime date;
  final String type;
  final double amount;
  final double balance;
  final String accountType;
  final String? description;
  final String? recipientCard;
  final String? recipientName;

  Transaction({
    required this.id,
    required this.cardNumber,
    required this.date,
    required this.type,
    required this.amount,
    required this.balance,
    required this.accountType,
    this.description,
    this.recipientCard,
    this.recipientName,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(),
      cardNumber: json['card_number'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      amount: double.parse(json['amount'].toString()),
      balance: double.parse(json['balance'].toString()),
      accountType: json['account_type'],
      description: json['description'],
      recipientCard: json['recipient_card'],
      recipientName: json['recipient_name'],
    );
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}