import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/db_service.dart';
import '../models/order.dart';
import 'new_order_screen.dart';
import 'orders_screen.dart';
import 'summary_screen.dart';
import '../providers/app_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant POS'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => ref.read(isAdminProvider.notifier).state = (v == 'admin'),
            itemBuilder: (c) => [
              const PopupMenuItem(value: 'admin', child: Text('Admin Mode')),
              const PopupMenuItem(value: 'waiter', child: Text('Waiter Mode')),
            ],
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _Tile(
            icon: Icons.playlist_add,
            label: 'New Order',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewOrderScreen())),
          ),
          _Tile(
            icon: Icons.list_alt,
            label: 'Orders',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
          ),
          _Tile(
            icon: Icons.summarize,
            label: 'Summary',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryScreen())),
          ),
          _Tile(
            icon: Icons.restaurant,
            label: 'Menu',
            onTap: () async {
              final menu = await DBService().getMenu();
              if (context.mounted) {
                showDialog(context: context, builder: (_) => AlertDialog(
                  title: const Text('Menu Items'),
                  content: SizedBox(
                    width: 320,
                    child: ListView(
                      shrinkWrap: true,
                      children: menu.map((m) => ListTile(
                        leading: Icon(m.isVeg ? Icons.eco : Icons.set_meal),
                        title: Text(m.name),
                        trailing: Text(m.price.toStringAsFixed(2)),
                      )).toList(),
                    ),
                  ),
                ));
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Mode: ${isAdmin ? "Admin" : "Waiter"}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
