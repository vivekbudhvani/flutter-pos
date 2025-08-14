import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/db_service.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../services/printer_service.dart';

class NewOrderScreen extends ConsumerStatefulWidget {
  const NewOrderScreen({super.key});

  @override
  ConsumerState<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends ConsumerState<NewOrderScreen> {
  OrderType type = OrderType.dineIn;
  String? tableNumber;
  String? customerName;
  String? customerPhone;
  double tax = 5;
  double discount = 0;
  final items = <OrderItem>[];
  List<MenuItem> menu = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    menu = await DBService().getMenu();
    if (mounted) setState(() {});
  }

  void addItem(MenuItem m) {
    final idx = items.indexWhere((it) => it.menuItemId == m.id);
    if (idx >= 0) {
      final it = items[idx];
      items[idx] = OrderItem(
        id: it.id,
        menuItemId: it.menuItemId,
        name: it.name,
        quantity: it.quantity + 1,
        unitPrice: it.unitPrice,
      );
    } else {
      items.add(OrderItem(menuItemId: m.id ?? -1, name: m.name, quantity: 1, unitPrice: m.price));
    }
    setState(() {});
  }

  void removeItem(OrderItem it) {
    final idx = items.indexOf(it);
    if (idx >= 0) {
      final q = it.quantity - 1;
      if (q <= 0) {
        items.removeAt(idx);
      } else {
        items[idx] = OrderItem(menuItemId: it.menuItemId, name: it.name, quantity: q, unitPrice: it.unitPrice);
      }
      setState(() {});
    }
  }

  double get subTotal => items.fold(0.0, (s, it) => s + it.lineTotal);
  double get discountAmount => subTotal * (discount / 100);
  double get taxedBase => subTotal - discountAmount;
  double get taxAmount => taxedBase * (tax / 100);
  double get grandTotal => taxedBase + taxAmount;

  Future<void> saveOrder({bool sendKot = false}) async {
    if (items.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item.')));
      }
      return;
    }
    final order = Order(
      type: type,
      tableNumber: type == OrderType.dineIn ? tableNumber : null,
      customerName: customerName,
      customerPhone: customerPhone,
      items: items,
      taxPercent: tax,
      discountPercent: discount,
      status: sendKot ? OrderStatus.kotSent : OrderStatus.placed,
    );
    final id = await DBService().createOrder(order);
    if (sendKot) {
      await PrinterService().printKOT(order);
    }
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order #$id saved${sendKot ? " & KOT sent" : ""}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Order')),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    children: [
                      ChoiceChip(
                        label: const Text('Dine-in'),
                        selected: type == OrderType.dineIn,
                        onSelected: (_) => setState(() => type = OrderType.dineIn),
                      ),
                      ChoiceChip(
                        label: const Text('Parcel'),
                        selected: type == OrderType.parcel,
                        onSelected: (_) => setState(() => type = OrderType.parcel),
                      ),
                    ],
                  ),
                  if (type == OrderType.dineIn)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Table No.'),
                        onChanged: (v) => tableNumber = v,
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Customer Name'), onChanged: (v) => customerName = v)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Phone (E.164)'), onChanged: (v) => customerPhone = v)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _numField('Tax %', tax, (v) => setState(() => tax = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _numField('Discount %', discount, (v) => setState(() => discount = v))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 4,
                      children: [
                        for (final m in menu) OutlinedButton(
                          onPressed: () => addItem(m),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(m.name, overflow: TextOverflow.ellipsis),
                              Text(m.price.toStringAsFixed(0)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Text('Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: items.map((it) => ListTile(
                        title: Text(it.name),
                        subtitle: Text('x${it.quantity} @ ${it.unitPrice.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(onPressed: () => removeItem(it), icon: const Icon(Icons.remove_circle_outline)),
                            IconButton(onPressed: () => addItem(MenuItem(id: it.menuItemId, name: it.name, price: it.unitPrice)), icon: const Icon(Icons.add_circle_outline)),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                  const Divider(),
                  _row('SubTotal', subTotal),
                  _row('Discount', -discountAmount),
                  _row('Tax', taxAmount),
                  const SizedBox(height: 4),
                  _row('Grand Total', grandTotal, isBold: true),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: ElevatedButton(onPressed: () => saveOrder(sendKot: true), child: const Text('Save + KOT'))),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton(onPressed: () => saveOrder(), child: const Text('Save'))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numField(String label, double value, void Function(double) onChanged) {
    final c = TextEditingController(text: value.toStringAsFixed(0));
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
    );
  }

  Widget _row(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(amount.toStringAsFixed(2), style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
