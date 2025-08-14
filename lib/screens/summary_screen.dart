import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTimeRange? range;
  double ordersCount = 0;
  double revenue = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    range = DateTimeRange(start: startOfDay, end: now);
    _load();
  }

  Future<void> _load() async {
    if (range == null) return;
    final sum = await DBService().summary(range!.start, range!.end);
    setState(() {
      ordersCount = sum['orders'] ?? 0;
      revenue = sum['revenue'] ?? 0;
    });
  }

  void setPreset(String preset) {
    final now = DateTime.now();
    DateTime start;
    if (preset == 'day') {
      start = DateTime(now.year, now.month, now.day);
    } else if (preset == 'month') {
      start = DateTime(now.year, now.month, 1);
    } else {
      start = DateTime(now.year, 1, 1);
    }
    setState(() => range = DateTimeRange(start: start, end: now));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(onPressed: () => setPreset('day'), child: const Text('Today')),
                ElevatedButton(onPressed: () => setPreset('month'), child: const Text('This Month')),
                ElevatedButton(onPressed: () => setPreset('year'), child: const Text('This Year')),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020, 1, 1),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => range = DateTimeRange(start: picked.start, end: picked.end));
                      _load();
                    }
                  },
                  child: const Text('Custom Range'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('From: ${fmt.format(range!.start)}'),
            Text('To:   ${fmt.format(range!.end)}'),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Total Orders'),
                trailing: Text(ordersCount.toStringAsFixed(0)),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Total Revenue (₹)'),
                trailing: Text(revenue.toStringAsFixed(2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
