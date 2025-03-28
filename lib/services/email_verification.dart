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
    const timeoutDuration = Duration(minutes: 5);
    const checkInterval = Duration(seconds: 5);

    while (DateTime.now().difference(startTime) <= timeoutDuration) {
      await Future.delayed(checkInterval);

      final user = _auth.currentUser;
      if (user == null) {
        return false; // User is logged out
      }

      await user.reload();
      if (user.emailVerified) {
        return true; // Email is verified
      }
    }

    return false; // Timed out
  }
}
