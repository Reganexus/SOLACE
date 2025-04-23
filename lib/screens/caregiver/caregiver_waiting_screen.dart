import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/controllers/notification_service.dart';
import 'package:solace/screens/wrapper.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class CaregiverWaitingScreen extends StatefulWidget {
  final String userId;
  final String userRole;

  const CaregiverWaitingScreen({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  CaregiverWaitingScreenState createState() => CaregiverWaitingScreenState();
}

class CaregiverWaitingScreenState extends State<CaregiverWaitingScreen> {
  final DatabaseService db = DatabaseService();
  final NotificationService notificationService = NotificationService();
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> userStream;

  @override
  void initState() {
    super.initState();
    userStream =
        FirebaseFirestore.instance
            .collection(widget.userRole)
            .doc(widget.userId)
            .snapshots();

    // Add the user to the "requests" collection in Firestore
    _addUserToRequestsCollection();
  }

  void showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _addUserToRequestsCollection() async {
    try {
      final name = await db.fetchUserName(widget.userId);
      final requestsCollection = FirebaseFirestore.instance.collection(
        'requests',
      );

      final docSnapshot = await requestsCollection.doc(widget.userId).get();

      if (docSnapshot.exists) {
        return;
      }

      await requestsCollection.doc(widget.userId).set({});
      await notificationService.sendNotificationToAllAdmins(
        "Access Request",
        "User $name is requesting access to the app",
      );
    } catch (e) {
      showToast('Error adding user to requests collection: $e');
    }
  }

  void _navigateToWrapper() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Wrapper()),
      (route) => false,
    );
  }

  Widget _buildWaitingList() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/assets/images/auth/waiting.png',
                  fit: BoxFit.cover,
                  width: 150,
                  height: 150,
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Your Account is Pending Approval",
                      style: Textstyle.subheader,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Admin will review your account to ensure that you are eligible to access SOLACE.",
                      style: Textstyle.body,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_active_rounded,
                        size: 16,
                        color: AppColors.black,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "SOLACE will notify you once you have given access.",
                        style: Textstyle.bodySuperSmall.copyWith(
                          color: AppColors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text("Information", style: Textstyle.subheader),
          content: Text(
            "Your account is under review. This is needed to ensure that users accessing the app are eligible and validated.",
            style: Textstyle.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: Buttonstyle.buttonNeon,
              child: Text("Okay", style: Textstyle.smallButton),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    SystemNavigator.pop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (canPop, result) {
        if (canPop) {
          _onWillPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Pending Approval", style: Textstyle.subheader),
          centerTitle: true,
          backgroundColor: AppColors.white,
          scrolledUnderElevation: 0.0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: _showInfoDialog,
              icon: Icon(
                Icons.info_outline_rounded,
                size: 24,
                color: AppColors.black,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.white,
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final data = snapshot.data?.data();
              if (data != null && data['hasAccess'] == true) {
                Future.microtask(() => _navigateToWrapper());
              }
            }

            return _buildWaitingList();
          },
        ),
      ),
    );
  }
}
