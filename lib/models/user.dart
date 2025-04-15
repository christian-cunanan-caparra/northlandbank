class User {
  final int id;
  final String cardNumber;
  final String pin;
  final double currentBalance;
  final double savingsBalance;
  final String email;

  // Constructor to initialize a User object
  User({
    required this.id,
    required this.cardNumber,
    required this.pin,
    required this.currentBalance,
    required this.savingsBalance,
    required this.email,
  });

  // Factory method to create a User object from JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id']?.toString() ?? '0'),  // Safely convert id to int, default to 0
      cardNumber: json['card_number']?.toString() ?? '',  // Default empty string if missing
      pin: json['pin']?.toString() ?? '',  // Default empty string if missing
      currentBalance: double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,  // Default 0.0 if parsing fails
      savingsBalance: double.tryParse(json['savings_balance']?.toString() ?? '0') ?? 0.0,  // Default 0.0 if parsing fails
      email: json['email']?.toString() ?? '',  // Default empty string if missing
    );
  }

  // Method to convert User object to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'card_number': cardNumber,
    'pin': pin,
    'current_balance': currentBalance,
    'savings_balance': savingsBalance,
    'email': email,
  };

  // Method to create a new User object with some fields updated (copy)
  User copyWith({
    int? id,
    String? cardNumber,
    String? pin,
    double? currentBalance,
    double? savingsBalance,
    String? email,
  }) {
    return User(
      id: id ?? this.id,  // Use current value if not provided
      cardNumber: cardNumber ?? this.cardNumber,
      pin: pin ?? this.pin,
      currentBalance: currentBalance ?? this.currentBalance,
      savingsBalance: savingsBalance ?? this.savingsBalance,
      email: email ?? this.email,
    );
  }
}
