import 'package:flutter/material.dart';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart'; // Barcode scanner package
import 'package:solace/services/database.dart'; // Assuming this is where your methods are located

class QRScannerPage extends StatefulWidget {
  final String userId;

  const QRScannerPage({super.key, required this.userId});

  @override
  QRScannerPageState createState() => QRScannerPageState();
}

class QRScannerPageState extends State<QRScannerPage> {
  String barcode = 'Tap to scan';  // Display message initially

  // This will be called when the barcode is detected
  void onBarcodeDetect(String scannedValue) async {
    setState(() {
      barcode = scannedValue;  // Update the displayed barcode value
    });

    if (scannedValue.isNotEmpty) {
      // Call the database method to send the friend request
      await _sendFriendRequest(scannedValue);  // Implement this method

      // Show a SnackBar message to indicate the request was sent
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent to $scannedValue')),
      );

      // Optionally close the scanner page after processing
      Navigator.pop(context);
    }
  }

  // Method to send the friend request
  Future<void> _sendFriendRequest(String targetUserId) async {
    try {
      // Use the sendFriendRequest method from your database service
      await DatabaseService(uid: widget.userId)
          .sendFriendRequest(widget.userId, targetUserId);
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                // Open the barcode scanner when the button is pressed
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AiBarcodeScanner(
                      onDispose: () {
                        debugPrint("Barcode scanner disposed!");
                      },
                      hideGalleryButton: false,  // Optionally hide the gallery button
                      onDetect: (capture) {
                        final String? scannedValue = capture.barcodes.first.rawValue;
                        debugPrint("Scanned value: $scannedValue");
                        if (scannedValue != null) {
                          onBarcodeDetect(scannedValue);  // Pass the scanned value to the handler
                        }
                      },
                      validator: (value) {
                        // Optional: Validation for specific barcodes
                        if (value.barcodes.isEmpty) return false;
                        return value.barcodes.first.rawValue?.isNotEmpty ?? false;
                      },
                    ),
                  ),
                );
              },
              child: const Text('Scan Barcode'),
            ),
            // Display the scanned barcode (or initial message)
            Text(barcode),
          ],
        ),
      ),
    );
  }
}
