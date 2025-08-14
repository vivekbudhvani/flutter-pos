enum OrderType { dineIn, parcel }
enum OrderStatus { placed, kotSent, served, paid }

class Order {
  final int? id;
  final OrderType type;
  final String? tableNumber; // for dine-in
  final String? customerName;
  final String? customerPhone;
  final List<OrderItem> items;
  final double taxPercent; // e.g., 5, 12, 18
  final double discountPercent; // e.g., 10
  final OrderStatus status;
  final DateTime createdAt;

  Order({
    this.id,
    required this.type,
    this.tableNumber,
    this.customerName,
    this.customerPhone,
    required this.items,
    this.taxPercent = 0,
    this.discountPercent = 0,
    this.status = OrderStatus.placed,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get subTotal => items.fold(0.0, (s, it) => s + it.lineTotal);
  double get discountAmount => subTotal * (discountPercent / 100.0);
  double get taxedBase => subTotal - discountAmount;
  double get taxAmount => taxedBase * (taxPercent / 100.0);
  double get grandTotal => taxedBase + taxAmount;

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.index,
    'tableNumber': tableNumber,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'taxPercent': taxPercent,
    'discountPercent': discountPercent,
    'status': status.index,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Order.fromMap(Map<String, dynamic> m, List<OrderItem> items) => Order(
    id: m['id'] as int?,
    type: OrderType.values[m['type'] as int],
    tableNumber: m['tableNumber'] as String?,
    customerName: m['customerName'] as String?,
    customerPhone: m['customerPhone'] as String?,
    items: items,
    taxPercent: (m['taxPercent'] as num).toDouble(),
    discountPercent: (m['discountPercent'] as num).toDouble(),
    status: OrderStatus.values[m['status'] as int],
    createdAt: DateTime.parse(m['createdAt'] as String),
  );
}
