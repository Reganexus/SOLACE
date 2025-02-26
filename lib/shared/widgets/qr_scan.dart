import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solace/services/database.dart';

import '../../themes/colors.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  Barcode? _barcode;
  bool _isPermissionGranted = false;
  bool _isProcessing = false; // To throttle detection\
  bool _borderFlag = false;
  final MobileScannerController _cameraController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    debugPrint('Requesting camera permission...');
    _requestCameraPermission().then((granted) {
      if (granted) {
        debugPrint('Camera permission granted.');
        setState(() {
          _isPermissionGranted = true;
        });
      } else {
        debugPrint('Camera permission denied.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required.')),
        );
        Navigator.pop(context);
      }
    }).catchError((error) {
      debugPrint('Error while requesting camera permission: $error');
    });
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    debugPrint('Camera permission status: $status');
    return status == PermissionStatus.granted;
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (_isProcessing) return; // Skip processing if already in progress

    if (barcodes.barcodes.isNotEmpty) {
      _borderFlag = true;
      setState(() {
        _isProcessing = true;
      });

      final Barcode barcode = barcodes.barcodes.first;
      debugPrint('Barcode detected: ${barcode.rawValue}');

      if (mounted) {
        // Pause the camera feed
        _cameraController.stop();

        // Show processing indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.white,),
            );
          },
        );

        // Simulate processing delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context); // Close the progress dialog

            // Update the barcode display with user details
            setState(() {
              _barcode = barcode; // Save the scanned barcode
            });
          }
        });
      }
    } else {
      debugPrint('No barcode detected.');
    }

    // Reset the processing flag after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  Future<void> _fetchAndDisplayUserDetails(String userId) async {
    try {
      DatabaseService db = DatabaseService();

      // Fetch the user's role
      String? userRole = await db.getTargetUserRole(userId);

      if (userRole == null) {
        debugPrint('User role not found.');
        return;
      }

      // Determine the collection name
      final userCollection =
          userRole; // Add 's' to pluralize the role name

      // Fetch user data from the collection
      final DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection(userCollection)
          .doc(userId)
          .get();

      if (!snapshot.exists) {
        debugPrint('No document found for user ID: $userId');
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;

      // Extract user details
      final String profileImageUrl = data['profileImageUrl'] ?? '';
      final String firstName = data['firstName'] ?? '';
      final String middleName = data['middleName'] ?? '';
      final String lastName = data['lastName'] ?? '';

      // Construct the full name
      final String friendName =
      '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName'
          .trim();

      // Update the display widget
      setState(() {
        _profileImageUrl = profileImageUrl;
        _friendName = friendName.isEmpty ? 'Unknown' : friendName;
      });
    } catch (e) {
      debugPrint('Error fetching user details: $e');
    }
  }

  String _profileImageUrl = ''; // Stores the profile image URL
  String _friendName = ''; // Stores the user's name

  Widget _buildBarcodeDisplay(Barcode? barcode) {
    if (barcode == null) {
      return const Text(
        'Scan QR Code!',
        overflow: TextOverflow.fade,
        style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontFamily: 'Inter',
            fontWeight: FontWeight.normal),
      );
    }

    // Fetch and display user details when a barcode is detected
    _fetchAndDisplayUserDetails(barcode.rawValue!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ensures height matches content
        crossAxisAlignment: CrossAxisAlignment.start, // Left-aligns children
        children: [
          Text(
            "Send request to this user?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              fontSize: 20.0,
            ),
          ),
          const SizedBox(height: 20), // Adds spacing between text and row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: _profileImageUrl.isNotEmpty
                    ? NetworkImage(_profileImageUrl)
                    : const AssetImage(
                    'lib/assets/images/shared/placeholder.png')
                as ImageProvider,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _friendName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.neon, // Background color for the icon
                  shape: BoxShape.circle, // Circular shape
                ),
                child: IconButton(
                  icon: const Icon(Icons.person_add,
                      color: Colors.white), // Icon with white color
                  onPressed: () {
                    // Trigger the "Add Friend" action and navigate back
                    Navigator.pop(
                        context, barcode.rawValue); // Return the scanned value
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: AppColors.white, // Change your color here
        ),
        title: const Text(
          'QR Code Scanner',
          style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.normal,
              color: AppColors.white),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: _isPermissionGranted
          ? Stack(
        children: [
          MobileScanner(
            controller: _cameraController, // Attach the camera controller
            onDetect: (barcodes) {
              debugPrint('Camera initialized and scanning...');
              _handleBarcode(barcodes);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 250,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: _buildBarcodeDisplay(
                          _barcode), // Updated display
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Border overlay: Show only if user details are not yet displayed
          if (!_borderFlag)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.neon,
                        width: 5.0,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
            ),
        ],
      )
          : const Center(
        child: CircularProgressIndicator(color: AppColors.white,),
      ),
    );
  }
}