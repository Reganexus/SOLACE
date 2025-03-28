import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/services/alert_handler.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';

class RatingWidget extends StatefulWidget {
  const RatingWidget({super.key});

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  int _selectedRating = 0;
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _hasExistingRating = false;

  // Labels for each rating value
  final Map<int, String> _ratingLabels = {
    1: 'Not Good',
    2: 'Below Average',
    3: 'Average',
    4: 'Good',
    5: 'Excellent',
  };

  @override
  void initState() {
    super.initState();
    _fetchUserRating();
  }

  // Fetch user's existing rating from Firestore
  Future<void> _fetchUserRating() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      final ratingDoc =
          await FirebaseFirestore.instance
              .collection('ratings')
              .doc(user.uid)
              .get();

      if (ratingDoc.exists) {
        final ratingData = ratingDoc.data();
        setState(() {
          _selectedRating = ratingData?['rating'] ?? 0;
          _hasExistingRating = true; // Set flag if rating exists
        });
      }
    } catch (error) {
      showToast('Failed to fetch rating: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to submit rating to Firebase
  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      showToast('Please select a rating before submitting.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      final ratingDoc = FirebaseFirestore.instance
          .collection('ratings')
          .doc(user.uid);

      await ratingDoc.set({'rating': _selectedRating});

      setState(() {
        _hasExistingRating = true; // Hide submit button after rating
      });

      // Show the AlertHandler
      showDialog(
        context: context,
        builder:
            (context) => AlertHandler(
              title: "Thank You",
              messages: [
                "Thank you for your response, it means a lot to us to improve SOLACE better.",
              ],
            ),
      );
    } catch (error) {
      showToast('Failed to submit rating: $error');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: Loader.loaderWhite)
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                'Rate SOLACE',
                style: Textstyle.subheader,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: double.infinity,
              child: Text(
                !_hasExistingRating
                    ? 'Your feedback means to us. It will us make SOLACE better.'
                    : "Thanks for your feedback, you've rated SOLACE",
                style: Textstyle.body,
                textAlign:
                    !_hasExistingRating ? TextAlign.left : TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final ratingValue = index + 1;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRating = ratingValue;
                              });
                            },
                            child: Icon(
                              Icons.star,
                              size: 36,
                              color:
                                  _selectedRating >= ratingValue
                                      ? AppColors.purple
                                      : AppColors.blackTransparent,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _ratingLabels[_selectedRating] ??
                            'Please select a rating',
                        style: Textstyle.bodySmall.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                // Show submit button only if there's no existing rating
                if (!_hasExistingRating)
                  Column(
                    children: [
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 140,
                        child: TextButton(
                          onPressed: _isSubmitting ? null : _submitRating,
                          style:
                              !_hasExistingRating
                                  ? Buttonstyle.buttonNeon
                                  : _isSubmitting
                                  ? Buttonstyle.buttonDarkGray
                                  : Buttonstyle.buttonNeon,
                          child: Text(
                            'Submit',
                            style: Textstyle.smallButton.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        );
  }
}
