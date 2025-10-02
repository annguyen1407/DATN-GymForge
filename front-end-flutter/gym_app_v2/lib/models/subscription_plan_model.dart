class SubscriptionPlanModel {
  final String id;
  final String name;
  final int durationMonths;
  final int
  price; // in smallest currency unit if needed (here appears plain VND)
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.durationMonths,
    required this.price,
    required this.currency,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      durationMonths: json['durationMonths'] ?? 0,
      price: json['price'] ?? 0,
      currency: json['currency'] ?? 'VND',
      isActive: json['isActive'] ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
