import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:solace/themes/colors.dart'; // Assuming you have a custom color theme

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  String? barcode;
  final MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'QR Code Scanner',
          style: TextStyle(color: AppColors.black), // Text color set to black for better visibility
        ),
        backgroundColor: Colors.transparent, // Make AppBar background transparent
        elevation: 0, // Remove shadow from AppBar
      ),
      body: Container(
        color: AppColors.white,
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: MobileScanner(
                controller: controller,
                onDetect: (BarcodeCapture barcodeCapture) async {
                  final String? scannedBarcode = barcodeCapture.barcodes.first.rawValue;
                  if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
                    setState(() {
                      barcode = scannedBarcode;
                    });

                    await Future.delayed(Duration(seconds: 2));

                    Navigator.pop(context, scannedBarcode);
                  } else {
                    // Optionally, show a message if no valid barcode is detected
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invalid QR Code detected')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
