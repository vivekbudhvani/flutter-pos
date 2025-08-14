class OrderItem {
  final int? id;
  final int menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;

  OrderItem({
    this.id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toMap(int orderId) => {
    'id': id,
    'orderId': orderId,
    'menuItemId': menuItemId,
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    id: m['id'] as int?,
    menuItemId: m['menuItemId'] as int,
    name: m['name'] as String,
    quantity: m['quantity'] as int,
    unitPrice: (m['unitPrice'] as num).toDouble(),
  );
}
