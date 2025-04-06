import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SmsAuthService {
  static Future<void> verifyPhoneNumber(BuildContext context, String phoneNumber, {required Function(PhoneAuthCredential) onVerificationCompleted, required Function(String verificationId) onCodeSent, required Function(String errorMessage) onVerificationFailed}) async {
    try {
      String formattedPhoneNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
      if (formattedPhoneNumber.startsWith('0')) {
        formattedPhoneNumber = '+63${formattedPhoneNumber.substring(1)}'; // Convert to E.164 format
      }

      if (formattedPhoneNumber.length < 10 || !formattedPhoneNumber.startsWith('+')) {
        throw Exception('bibibi Invalid phone number format.');
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(e.message ?? 'bibibi Failed to verify phone number');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId); // Send the verificationId to be used later
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('bibibi Code auto-retrieval timeout.');
        },
      );
    } catch (e) {
      onVerificationFailed('bibibi Error during SMS authentication: $e');
    }
  }

  static Future<void> verifyCode(String verificationId, String code, {required Function() onVerified, required Function(String errorMessage) onError}) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code);
      await FirebaseAuth.instance.signInWithCredential(credential);
      onVerified(); // Successfully verified
    } catch (e) {
      onError('bibibi Failed to verify code: $e');
    }
  }

  // Show the dialog where users input the verification code
  static Future<void> showVerificationDialog(BuildContext context, String verificationId, {required Function(String enteredCode) onCodeVerified}) async {
    if (!context.mounted) {
      debugPrint('Context is not mounted. Cannot show dialog.');
      return;
    }

    TextEditingController codeController = TextEditingController();

    try {
      debugPrint('Showing verification dialog...');
      await showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
        builder: (context) {
          return AlertDialog(
            title: const Text('Enter Verification Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(hintText: 'Enter the code'),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  final enteredCode = codeController.text.trim();
                  if (enteredCode.isNotEmpty) {
                    Navigator.of(context).pop(); // Close the dialog
                    onCodeVerified(enteredCode); // Trigger the callback
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter the verification code.')),
                    );
                  }
                },
                child: const Text('Verify'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing verification dialog: $e');
    }
  }
}
