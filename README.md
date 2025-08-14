# Restaurant POS (Flutter)
Features:
- Order types: Dine-in (tables) and Parcel (takeaway).
- Add/remove items mid-order, track status (Placed → KOT Sent → Served → Paid).
- Taxes and discounts per order.
- Print KOT and final bill (stub provided; wire to your printer plugin).
- Daily / Monthly / Yearly summaries.
- Pending transactions saved with customer info and share payment request via WhatsApp link.

## Quick Start
1. Install Flutter (3.16+ recommended) and Android SDK.
2. From project root:
   ```bash
   flutter pub get
   flutter run
   ```
3. Build APK:
   ```bash
   flutter build apk --release
   # Output: build/app/outputs/flutter-apk/app-release.apk
   ```

## Notes on Printing
- The app includes a simple `PrinterService` with stubs for:
  - KOT printing (Kitchen Order Ticket)
  - Final bill receipt
- It currently references `blue_thermal_printer` in `pubspec.yaml`. If your printer requires another plugin, replace usage inside `services/printer_service.dart` with your preferred plugin calls (e.g., esc_pos_bluetooth + esc_pos_utils or Sunmi/V1/V2 SDKs).

## Database
- Local SQLite via `sqflite`.
- Predefined sample menu items populate on first run.

## WhatsApp Share
- Uses `url_launcher` to open a wa.me link with a pre-filled message to request payment.

## Admin / Waiter Access
- Very simple role toggle in the app bar menu for demo purposes.
- Extend with proper auth as needed.

## DISCLAIMER
This is a reference implementation. Adjust to your tax rules, receipt format, and printer model.
