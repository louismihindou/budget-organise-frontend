import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ReferralField extends StatefulWidget {
  final TextEditingController controller;
  const ReferralField({super.key, required this.controller});

  @override
  State<ReferralField> createState() => _ReferralFieldState();
}

class _ReferralFieldState extends State<ReferralField> {
  void _openScannerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          // title: const Text("Scanner le code parrain"),
          content: SizedBox(
            height: 300,
            width: 300,
            child: MobileScanner(
              onDetect: (BarcodeCapture capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  final code = barcodes.first.rawValue!;
                  debugPrint("Code parrain détecté : $code");

                  // Remplir le champ
                  widget.controller.text = code;

                  // Fermer le scanner
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: "Code Parrain",
        suffixIcon: IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: _openScannerDialog,
        ),
      ),
    );
  }
}
