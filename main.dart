// import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/get_started.dart';
import 'package:solace/services/auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
<<<<<<< Updated upstream
// import 'package:solace/shared/accountflow/requirements.dart';
// import 'package:http/http.dart' as http;
=======
>>>>>>> Stashed changes

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Activate Firebase App Check for development (using debug token)
  FirebaseAppCheck appCheck = FirebaseAppCheck.instance;

  // Use a debug token for testing (remove this for production)
  await appCheck.activate();

  // Optionally sign out any user (if you need this)
  await AuthService().signOut();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

<<<<<<< Updated upstream
  // List<dynamic>? algoInputs = [false, false, false, false, 27, 'Male', 'Normal', 'Normal'];
  // getPrediction(algoInputs);
=======
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar
      statusBarIconBrightness: Brightness.dark, // Black text/icons
      statusBarBrightness: Brightness.light, // For iOS: light background
    ),
  );

>>>>>>> Stashed changes

  runApp(const MyApp());
}

// Future<void> getPrediction(List<dynamic> algoInputs) async {
//   // choose from these depending on testing device
//   // final localHostAddress = '127.0.0.1'; // default
//   final virtualAddress = '10.0.2.2';    // if using virtual device
//   // if using physical device, use computer’s IP address instead of 127.0.0.1 or localhost.

//   final url = Uri.parse('http://$virtualAddress:5000/predict');
//   final headers = {"Content-Type": "application/json"};

//   // Define mappings for Blood Pressure and Cholesterol Level
//   const severityMapping = {
//     "Low": 0,
//     "Normal": 1,
//     "High": 2,
//   };

//   // Format algoInputs to match the input size expected by the model (8 features)
//   List<int>? formattedInputs;
//   try {
//     formattedInputs = [
//       algoInputs[0] == true ? 1 : 0, // Fever
//       algoInputs[1] == true ? 1 : 0, // Cough
//       algoInputs[2] == true ? 1 : 0, // Fatigue
//       algoInputs[3] == true ? 1 : 0, // Difficulty Breathing
//       (algoInputs[4] ?? 0) as int, // Age
//       algoInputs[5] == 'Male' ? 1 : 0, // Gender
//       severityMapping[algoInputs[6]] ?? 0, // Blood Pressure
//       severityMapping[algoInputs[7]] ?? 0, // Cholesterol Level
//     ];

//     debugPrint('Formatted Inputs: $formattedInputs');
//   } catch (e, stackTrace) {
//     debugPrint('Error formatting inputs: $e');
//     debugPrint('StackTrace: $stackTrace');
//   }

//   try {
//     // Wrap formattedInputs in a JSON object with the 'data' key
//     final body = json.encode({'data': [formattedInputs]});

//     final response = await http.post(
//       url,
//       headers: headers,
//       body: body,
//     );

//     debugPrint("Json body: $body");

//     if (response.statusCode == 200) {
//       final responseData = json.decode(response.body);
//       debugPrint("Status: ${responseData['prediction']}  Type: ${(responseData['prediction']).runtimeType}");
//       // set status to either stable or unstable here
//     } else {
//       debugPrint("Error: ${response.statusCode}");
//     }
//   } catch (e) {
//     debugPrint("Error: $e");
//   }
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<MyUser?>.value(
      catchError: (_, __) =>
          null, // Catch errors and return null (safe fallback)
      initialData: null, // Initial value when the stream is not yet available
      value: AuthService().user, // Stream of user authentication state
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SOLACE',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const GetStarted(), // Main entry point widget
        // home: const RoleChooser(),
        // home: const RequirementsScreen(),
      ),
    );
  }
}
