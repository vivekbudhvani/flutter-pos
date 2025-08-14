import 'package:intl/intl.dart';
import '../models/order.dart';

class PrinterService {
  // Replace with actual bluetooth discovery/connection via your chosen plugin.
  Future<void> printKOT(Order order) async {
    final content = _kotText(order);
    // TODO: Send 'content' to printer using plugin API.
    // For demo, we just simulate delay.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> printBill(Order order) async {
    final content = _billText(order);
    // TODO: Send to printer
    await Future.delayed(const Duration(milliseconds: 500));
  }

  String _kotText(Order o) {
    final b = StringBuffer();
    b.writeln('*** KOT ***');
    b.writeln('Type: ${o.type.name.toUpperCase()}  Table: ${o.tableNumber ?? "-"}');
    b.writeln('Time: ${DateFormat("dd/MM/yyyy HH:mm").format(o.createdAt)}');
    b.writeln('------------------------------');
    for (final it in o.items) {
      b.writeln('${it.name}  x${it.quantity}');
    }
    b.writeln('------------------------------');
    b.writeln('Notes: Send to kitchen');
    return b.toString();
  }

  String _billText(Order o) {
    final b = StringBuffer();
    b.writeln('*** TAX INVOICE ***');
    b.writeln('Customer: ${o.customerName ?? "-"}  ${o.customerPhone ?? ""}');
    b.writeln('Type: ${o.type.name.toUpperCase()}  Table: ${o.tableNumber ?? "-"}');
    b.writeln('Date: ${DateFormat("dd/MM/yyyy HH:mm").format(o.createdAt)}');
    b.writeln('------------------------------');
    for (final it in o.items) {
      final line = (it.unitPrice * it.quantity).toStringAsFixed(2);
      b.writeln('${it.name} x${it.quantity}  ${it.unitPrice.toStringAsFixed(2)}  =  $line');
    }
    b.writeln('------------------------------');
    b.writeln('SubTotal:  ${o.subTotal.toStringAsFixed(2)}');
    b.writeln('Discount (${o.discountPercent.toStringAsFixed(0)}%):  -${o.discountAmount.toStringAsFixed(2)}');
    b.writeln('Tax (${o.taxPercent.toStringAsFixed(0)}%):  +${o.taxAmount.toStringAsFixed(2)}');
    b.writeln('Grand Total:  ${o.grandTotal.toStringAsFixed(2)}');
    b.writeln('Thank you!');
    return b.toString();
  }
}
