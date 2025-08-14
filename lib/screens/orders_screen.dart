import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';
import '../models/order.dart';
import '../services/printer_service.dart';
import '../services/whatsapp_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    orders = await DBService().listOrders();
    if (mounted) setState(() {});
  }

  Future<void> updateStatus(Order o, OrderStatus s) async {
    final updated = Order(
      id: o.id,
      type: o.type,
      tableNumber: o.tableNumber,
      customerName: o.customerName,
      customerPhone: o.customerPhone,
      items: o.items,
      taxPercent: o.taxPercent,
      discountPercent: o.discountPercent,
      status: s,
      createdAt: o.createdAt,
    );
    await DBService().updateOrder(updated);
    await _load();
  }

  Future<void> printBill(Order o) async {
    await PrinterService().printBill(o);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill sent to printer')));
    }
  }

  Future<void> sendWhatsApp(Order o) async {
    if ((o.customerPhone ?? '').isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No customer phone on order')));
      return;
    }
    final msg = 'Hello ${o.customerName ?? ""}, your total is INR ${o.grandTotal.toStringAsFixed(2)} for order #${o.id}. Please pay at your convenience.';
    await WhatsAppService().requestPayment(o.customerPhone!, msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: orders.map((o) => Card(
            child: ListTile(
              leading: Icon(o.type == OrderType.dineIn ? Icons.restaurant : Icons.local_shipping),
              title: Text('Order #${o.id} • ${o.type.name.toUpperCase()} ${o.tableNumber ?? ""}'),
              subtitle: Text('Total: ₹${o.grandTotal.toStringAsFixed(2)} • ${DateFormat("dd/MM HH:mm").format(o.createdAt)} • ${o.status.name}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  switch (v) {
                    case 'kot': await updateStatus(o, OrderStatus.kotSent); break;
                    case 'served': await updateStatus(o, OrderStatus.served); break;
                    case 'paid': await updateStatus(o, OrderStatus.paid); break;
                    case 'bill': await printBill(o); break;
                    case 'wa': await sendWhatsApp(o); break;
                  }
                },
                itemBuilder: (c) => [
                  const PopupMenuItem(value: 'kot', child: Text('Mark KOT Sent')),
                  const PopupMenuItem(value: 'served', child: Text('Mark Served')),
                  const PopupMenuItem(value: 'paid', child: Text('Mark Paid')),
                  const PopupMenuItem(value: 'bill', child: Text('Print Bill')),
                  const PopupMenuItem(value: 'wa', child: Text('WhatsApp Payment Link')),
                ],
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }
}
