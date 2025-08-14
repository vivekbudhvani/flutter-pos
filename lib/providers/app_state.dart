import 'package:flutter_riverpod/flutter_riverpod.dart';

final isAdminProvider = StateProvider<bool>((ref) => true); // toggle waiter/admin for demo
final currentTableProvider = StateProvider<String?>((ref) => null);
