class User {
  final int id;
  final String cardNumber;
  final String pin;
  final double currentBalance;
  final double savingsBalance;
  final String email;
  final String name; // ✅ Add this

  // Constructor
  User({
    required this.id,
    required this.cardNumber,
    required this.pin,
    required this.currentBalance,
    required this.savingsBalance,
    required this.email,
    required this.name, // ✅ Add this
  });

  // Factory method to create a User object from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id']?.toString() ?? '0'),
      cardNumber: json['card_number']?.toString() ?? '',
      pin: json['pin']?.toString() ?? '',
      currentBalance: double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
      savingsBalance: double.tryParse(json['savings_balance']?.toString() ?? '0') ?? 0.0,
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '', // ✅ Safely parse 'name'
    );
  }

  // Convert User object to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'card_number': cardNumber,
    'pin': pin,
    'current_balance': currentBalance,
    'savings_balance': savingsBalance,
    'email': email,
    'name': name, // ✅ Add this
  };

  // copyWith method for updating fields
  User copyWith({
    int? id,
    String? cardNumber,
    String? pin,
    double? currentBalance,
    double? savingsBalance,
    String? email,
    String? name, // ✅ Add this
  }) {
    return User(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      pin: pin ?? this.pin,
      currentBalance: currentBalance ?? this.currentBalance,
      savingsBalance: savingsBalance ?? this.savingsBalance,
      email: email ?? this.email,
      name: name ?? this.name, // ✅ Add this
    );
  }
}
