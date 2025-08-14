import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/menu_item.dart';
import '../models/order_item.dart';
import '../models/order.dart';

class DBService {
  static final DBService _i = DBService._internal();
  factory DBService() => _i;
  DBService._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final docs = await getApplicationDocumentsDirectory();
    final dbPath = join(docs.path, 'pos.sqlite');
    _db = await openDatabase(dbPath, version: 1, onCreate: _onCreate);
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE menu_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        isVeg INTEGER NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        tableNumber TEXT,
        customerName TEXT,
        customerPhone TEXT,
        taxPercent REAL NOT NULL,
        discountPercent REAL NOT NULL,
        status INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        menuItemId INTEGER NOT NULL,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        FOREIGN KEY(orderId) REFERENCES orders(id) ON DELETE CASCADE
      );
    ''');
    await seedMenu(db);
  }

  Future<void> seedMenu(Database db) async {
    final items = [
      MenuItem(name: 'Masala Dosa', price: 80, isVeg: true),
      MenuItem(name: 'Paneer Tikka', price: 180, isVeg: true),
      MenuItem(name: 'Chicken Biryani', price: 220, isVeg: false),
      MenuItem(name: 'Tandoori Roti', price: 20, isVeg: true),
      MenuItem(name: 'Lassi Sweet', price: 60, isVeg: true),
      MenuItem(name: 'Cold Coffee', price: 120, isVeg: true),
    ];
    for (final it in items) {
      await db.insert('menu_items', it.toMap());
    }
  }

  // Menu CRUD
  Future<List<MenuItem>> getMenu() async {
    final d = await db;
    final rows = await d.query('menu_items', orderBy: 'name ASC');
    return rows.map(MenuItem.fromMap).toList();
  }

  // Order CRUD
  Future<int> createOrder(Order order) async {
    final d = await db;
    final orderId = await d.insert('orders', order.toMap());
    for (final item in order.items) {
      await d.insert('order_items', item.toMap(orderId));
    }
    return orderId;
  }

  Future<void> updateOrder(Order order) async {
    final d = await db;
    if (order.id == null) return;
    await d.update('orders', order.toMap(), where: 'id=?', whereArgs: [order.id]);
    // Simplistic: delete and re-add items
    await d.delete('order_items', where: 'orderId=?', whereArgs: [order.id]);
    for (final item in order.items) {
      await d.insert('order_items', item.toMap(order.id!));
    }
  }

  Future<Order?> getOrder(int id) async {
    final d = await db;
    final rows = await d.query('orders', where: 'id=?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final itemsRows = await d.query('order_items', where: 'orderId=?', whereArgs: [id]);
    final items = itemsRows.map(OrderItem.fromMap).toList();
    return Order.fromMap(rows.first, items);
  }

  Future<List<Order>> listOrders({DateTime? from, DateTime? to, int? status}) async {
    final d = await db;
    String where = '';
    final args = <Object?>[];
    if (from != null) {
      where += (where.isEmpty ? '' : ' AND ') + 'datetime(createdAt) >= datetime(?)';
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where += (where.isEmpty ? '' : ' AND ') + 'datetime(createdAt) <= datetime(?)';
      args.add(to.toIso8601String());
    }
    if (status != null) {
      where += (where.isEmpty ? '' : ' AND ') + 'status = ?';
      args.add(status);
    }
    final rows = await d.query('orders', where: where.isEmpty ? null : where, whereArgs: args, orderBy: 'datetime(createdAt) DESC');
    final orders = <Order>[];
    for (final r in rows) {
      final itemsRows = await d.query('order_items', where: 'orderId=?', whereArgs: [r['id']]);
      final items = itemsRows.map(OrderItem.fromMap).toList();
      orders.add(Order.fromMap(r, items));
    }
    return orders;
  }

  // Summaries
  Future<Map<String, double>> summary(DateTime from, DateTime to) async {
    final orders = await listOrders(from: from, to: to);
    double revenue = 0;
    for (final o in orders) {
      revenue += o.grandTotal;
    }
    return {
      'orders': orders.length.toDouble(),
      'revenue': revenue,
    };
  }
}
