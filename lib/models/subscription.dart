/// Simple Subscription Data Model
class Subscription {
  final String id;
  final String name;
  final String category;
  final double monthlyCost;
  final String currency;
  final String renewalDate;
  final String? receiptUrl;
  final String createdAt;

  Subscription({
    required this.id,
    required this.name,
    required this.category,
    required this.monthlyCost,
    this.currency = 'LKR',
    required this.renewalDate,
    this.receiptUrl,
    required this.createdAt,
  });

  // Convert Firebase Map to Subscription object
  factory Subscription.fromMap(String id, Map<dynamic, dynamic> map) {
    return Subscription(
      id: id,
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Other',
      monthlyCost: double.tryParse(map['monthlyCost']?.toString() ?? '0') ?? 0.0,
      currency: map['currency']?.toString() ?? 'LKR',
      renewalDate: map['renewalDate']?.toString() ?? '',
      receiptUrl: map['receiptUrl']?.toString(),
      createdAt: map['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  // Convert Subscription object to Map for Firebase
  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'monthlyCost': monthlyCost,
        'currency': currency,
        'renewalDate': renewalDate,
        'receiptUrl': receiptUrl,
        'createdAt': createdAt,
      };

  Subscription copyWith({
    String? id,
    String? name,
    String? category,
    double? monthlyCost,
    String? currency,
    String? renewalDate,
    String? receiptUrl,
    String? createdAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      monthlyCost: monthlyCost ?? this.monthlyCost,
      currency: currency ?? this.currency,
      renewalDate: renewalDate ?? this.renewalDate,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Calculate days remaining until renewal
  int get daysUntilRenewal {
    try {
      final date = DateTime.parse(renewalDate);
      final now = DateTime.now();
      return DateTime(date.year, date.month, date.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
    } catch (_) {
      return 0;
    }
  }
}
