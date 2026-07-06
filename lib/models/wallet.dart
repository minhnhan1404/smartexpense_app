class Wallet {
  final int id;
  final int userId;
  final String name;
  final double balance;
  final String color;
  final String icon;

  Wallet({
    required this.id,
    required this.userId,
    required this.name,
    required this.balance,
    required this.color,
    required this.icon,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      color: json['color'] ?? '#4F46E5',
      icon: json['icon'] ?? 'account_balance_wallet',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'balance': balance,
      'color': color,
      'icon': icon,
    };
  }
}
