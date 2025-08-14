import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  Future<void> requestPayment(String phoneE164, String message) async {
    final text = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$phoneE164?text=$text');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not open WhatsApp';
    }
  }
}
