import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Polls for email verification status
  Future<bool> pollEmailVerificationStatus({
    required int timeoutMinutes,
    required int checkIntervalSeconds,
  }) async {
    final startTime = DateTime.now();
    final timeoutDuration = Duration(minutes: timeoutMinutes);
    final checkInterval = Duration(seconds: checkIntervalSeconds);

    while (DateTime.now().difference(startTime) <= timeoutDuration) {
      await Future.delayed(checkInterval);

      try {
        final user = _auth.currentUser;
        if (user == null) {
          return false; // User is logged out
        }

        await user.reload(); // Reload the user's state
        final refreshedUser = _auth.currentUser; // Fetch the updated user state

        if (refreshedUser != null && refreshedUser.emailVerified) {
          return true; // Email is verified
        }
      } catch (e) {
        // Handle potential errors (e.g., network issues)
        // debugPrint('Error while polling email verification status: $e');
        return false; // Exit the loop if an error occurs
      }
    }

    return false; // Timed out
  }
}
