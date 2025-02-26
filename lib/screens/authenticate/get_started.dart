// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solace/screens/wrapper.dart';
import 'package:solace/themes/colors.dart';

class GetStarted extends StatefulWidget {
  const GetStarted({super.key});

  @override
  State<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends State<GetStarted> {
  @override
  void initState() {
    super.initState();
    // Request permissions after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await requestPermissions(context);
    });
  }

  // Navigate with swipe left animation
  void navigateWithSwipeLeftAnimation() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Wrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  // Request necessary permissions for the app
  Future<void> requestPermissions(BuildContext context) async {
    // Check the statuses of all required permissions
    List<Permission> requiredPermissions = [
      Permission.notification,
      Permission.camera,
      Permission.microphone,
      Permission.location,
      Permission.activityRecognition, // For exact alarm permission
      Permission.storage, // For file read/write permission
    ];

    Map<Permission, PermissionStatus> statuses = await requiredPermissions.request();

    // Check if all permissions are granted
    bool allPermissionsGranted = statuses.values.every((status) => status.isGranted);

    if (!allPermissionsGranted) {
      // Show a dialog explaining why permissions are needed only if some are not granted
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Permissions Required"),
          content: const Text(
            "To ensure all features work smoothly, the app requires access to notifications, camera, microphone, and storage. Please allow these permissions when prompted.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      // Request necessary permissions again after showing the dialog
      statuses = await requiredPermissions.request();

      // Print statuses for debugging
      statuses.forEach((permission, status) {
        print('${permission.toString()} granted: ${status.isGranted}');
      });
    } else {
      print('All permissions already granted.');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with logo and title
              Row(
                children: [
                  Image.asset(
                    'lib/assets/images/auth/solace.png',
                    width: 60,
                  ),
                  const SizedBox(width: 10.0),
                  const Text(
                    'SOLACE',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Image and subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/images/auth/get_started.png',
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Welcome to SOLACE!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Bridging the gap in palliative and hospice care',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Inter',
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Get Started button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: navigateWithSwipeLeftAnimation,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    backgroundColor: AppColors.neon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
