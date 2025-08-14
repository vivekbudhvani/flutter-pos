class MenuItem {
  final int? id;
  final String name;
  final double price;
  final bool isVeg;

  MenuItem({this.id, required this.name, required this.price, this.isVeg = true});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
    'isVeg': isVeg ? 1 : 0,
  };

  factory MenuItem.fromMap(Map<String, dynamic> m) => MenuItem(
    id: m['id'] as int?,
    name: m['name'] as String,
    price: (m['price'] as num).toDouble(),
    isVeg: (m['isVeg'] as int) == 1,
  );
}
