class User {
  final int id;
  final String cardNumber;
  final String pin;
  final double currentBalance;
  final double savingsBalance;

  User({
    required this.id,
    required this.cardNumber,
    required this.pin,
    required this.currentBalance,
    required this.savingsBalance,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      cardNumber: json['card_number'],
      pin: json['pin'],
      currentBalance: double.parse(json['current_balance'].toString()),
      savingsBalance: double.parse(json['savings_balance'].toString()),
    );
  }
}