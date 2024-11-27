import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/wrapper.dart';
import 'package:solace/services/auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<MyUser?>.value(
      catchError: (_, __) => null, // Catch errors and return null (safe fallback)
      initialData: null, // Initial value when the stream is not yet available
      value: AuthService().user, // Stream of user authentication state
      child: MaterialApp(
        title: 'SOLACE',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const Wrapper(), // Main entry point widget
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text('Flask API Test'),
//         ),
//         body: PredictionScreen(),
//       ),
//     );
//   }
// }

// class PredictionScreen extends StatefulWidget {
//   const PredictionScreen({super.key});

//   @override
//   _PredictionScreenState createState() => _PredictionScreenState();
// }

// class _PredictionScreenState extends State<PredictionScreen> {
//   String _predictionResult = "Press the button to get a prediction";

//   Future<void> getPrediction() async {
//     // choose from these depending on testing device
//     final localHostAddress = '127.0.0.1'; // default
//     final virtualAddress = '10.0.2.2';    // if using virtual device
//     // if using physical device, use computer’s IP address instead of 127.0.0.1 or localhost.

//     final url = Uri.parse('http://$virtualAddress:5000/predict');
//     final headers = {"Content-Type": "application/json"};
    
//     // Example input data (10 time steps, 6 features per step)
//     final inputData = {
//       "data": [
//         [
//           [1, 0, 0, 1, 0.5, -0.7],
//           [0, 1, 1, 0, -0.3, 1.2],
//           [1, 0, 1, 0, 0.1, 0.2],
//           [1, 1, 0, 1, -0.5, 0.4],
//           [0, 0, 1, 1, 0.6, -0.3],
//           [1, 1, 1, 0, -0.4, 0.9],
//           [0, 1, 0, 1, 0.3, -0.2],
//           [1, 0, 1, 0, -0.1, 0.5],
//           [0, 1, 0, 1, 0.4, -0.8],
//           [1, 1, 1, 0, 0.2, 0.6],
//         ]
//       ]
//     };

//     try {
//       final response = await http.post(
//         url,
//         headers: headers,
//         body: json.encode(inputData),
//       );

//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         setState(() {
//           _predictionResult = "Prediction: ${responseData['prediction']}";
//         });
//       } else {
//         setState(() {
//           _predictionResult = "Error: ${response.statusCode}";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _predictionResult = "Error: $e";
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(_predictionResult),
//           SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: getPrediction,
//             child: Text('Get Prediction'),
//           ),
//         ],
//       ),
//     );
//   }
// }

