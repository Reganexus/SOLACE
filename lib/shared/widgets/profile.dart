// ignore_for_file: avoid_print, unused_import, use_build_context_synchronously, library_private_types_in_public_api
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/rating.dart';
import 'package:solace/shared/widgets/help_page.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/shared/accountflow/user_editprofile.dart';
import 'package:solace/screens/patient/patient_contacts.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/themes/textstyle.dart';
import 'package:url_launcher/url_launcher.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  File? _profileImage;
  late Future<UserData?> _userDataFuture;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<MyUser?>(context, listen: false);
    _userDataFuture =
        (user != null
            ? DatabaseService(uid: user.uid)
                .userData
                ?.first // Use null-aware operator
            : Future.value(
              null,
            ))!; // Return a null Future if no user is available
  }

  Widget divider() {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Divider(thickness: 1.0),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget buildHelp() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HelpPage()),
        );
      },
      child: Text("Help", style: Textstyle.bodySmall),
    );
  }

  Widget buildLogOut() {
    return GestureDetector(
      onTap: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Log Out', style: Textstyle.title),
                backgroundColor: AppColors.white,
                contentPadding: const EdgeInsets.all(16),
                content: Text(
                  'Are you sure you want to log out?',
                  style: Textstyle.bodySmall,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: Buttonstyle.buttonNeon,
                    child: Text('Cancel', style: Textstyle.smallButton),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: Buttonstyle.buttonRed,
                    child: Text('Log Out', style: Textstyle.smallButton),
                  ),
                ],
              ),
        );

        if (shouldLogout ?? false) {
          await AuthService().signOut();
          // Navigate back to the Authenticate screen
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Authenticate()),
              (route) => false, // Remove all previous routes
            );
          }
        }
      },
      child: Text(
        "Log Out",
        style: Textstyle.bodySmall.copyWith(color: AppColors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: FutureBuilder<UserData?>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            //     debugPrint("Future error: ${snapshot.error}");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Something went wrong. Please try again.',
                    style: Textstyle.body,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    style: Buttonstyle.neon,
                    onPressed:
                        () => setState(() {
                          final user = Provider.of<MyUser?>(
                            context,
                            listen: false,
                          );
                          _userDataFuture =
                              (user != null
                                  ? DatabaseService(
                                    uid: user.uid,
                                  ).userData?.first
                                  : Future.value(null))!;
                        }),
                    child: Text('Retry', style: Textstyle.bodyWhite),
                  ),
                ],
              ),
            );
          }

          UserData userData =
              snapshot.data ??
              UserData(
                uid: '',
                firstName: 'N/A',
                middleName: 'N/A',
                lastName: 'N/A',
                email: 'N/A',
                phoneNumber: 'N/A',
                address: 'N/A',
                gender: 'N/A',
                birthday: null,
                userRole: UserRole.caregiver,
                isVerified: false,
                newUser: false,
                dateCreated: DateTime.now(),
                profileImageUrl: '',
                status: 'N/A',
                religion: 'N/A',
              );

          if (userData.newUser) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => EditProfileScreen(
                        userData: userData.toMap(),
                        userRole: UserRole.unregistered.name,
                      ),
                ),
              );
            });
            return const SizedBox(); // Return an empty widget while redirecting
          }

          // Main Profile Screen if newUser is false
          return SingleChildScrollView(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      // Full-width rectangular avatar with zoom effect, blur, and border radius
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        child: Transform(
                          transform:
                              Matrix4.identity()..scale(1.3), // Zoom the image
                          alignment: Alignment.center,
                          child: Container(
                            width: double.infinity,
                            height: 250,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image:
                                    _profileImage != null
                                        ? FileImage(_profileImage!)
                                        : (userData.profileImageUrl.isNotEmpty
                                            ? NetworkImage(
                                                  userData.profileImageUrl,
                                                )
                                                as ImageProvider
                                            : const AssetImage(
                                              'lib/assets/images/shared/placeholder.png',
                                            )),
                                fit:
                                    BoxFit
                                        .cover, // Ensure the image fills the container
                              ),
                            ),
                            // Use ImageFiltered instead of BackdropFilter
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 8,
                                sigmaY: 8,
                              ), // Blur effect
                              child: Container(
                                color: AppColors.black.withValues(
                                  alpha: 0.3,
                                ), // Black overlay
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Name and edit profile button overlay
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User name
                            Text(
                              '${userData.firstName} ${{userData.middleName}.isNotEmpty ? '${userData.middleName} ' : ''}${userData.lastName}',
                              style: Textstyle.heading.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(1, 1),
                                    blurRadius: 3,
                                    color: AppColors.black.withValues(
                                      alpha: 0.3,
                                    ), // Black overlay
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              userData.email,
                              style: Textstyle.bodySmall.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                            Text(
                              userData.phoneNumber,
                              style: Textstyle.bodySmall.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 140,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => EditProfileScreen(
                                            userData: userData.toMap(),
                                            userRole: userData.userRole.name,
                                          ),
                                    ),
                                  );
                                },
                                style: Buttonstyle.buttonDarkGray,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Edit Profile',
                                      style: Textstyle.smallButton.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Image.asset(
                                      'lib/assets/images/shared/profile/edit-white.png',
                                      height: 16,
                                      width: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkgray,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.blackTransparent,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            flex: 2, // Takes half of the row (2/4)
                            child: _buildProfileInfoSection(
                              'House Address',
                              userData.address,
                            ),
                          ),
                          const SizedBox(width: 10), // Spacer
                          Flexible(
                            flex: 1, // Takes 1/4 of the row
                            child: _buildProfileInfoSection(
                              'Gender',
                              userData.gender,
                            ),
                          ),
                          const SizedBox(width: 10), // Spacer
                          Flexible(
                            flex: 1, // Takes 1/4 of the row
                            child: _buildProfileInfoSection(
                              'Birthdate',
                              userData.birthday != null
                                  ? '${userData.birthday!.month}/${userData.birthday!.day}/${userData.birthday!.year}'
                                  : '',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  divider(),
                  _aboutPalCollab(),

                  divider(),
                  _rateSolace(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileInfoSection(String header, String data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: Textstyle.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        Text(
          data,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: Textstyle.bodySmall.copyWith(color: AppColors.white),
        ),
      ],
    );
  }

  Widget _goToPalCollab() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage(
                  'lib/assets/images/auth/ruth_backdrop.jpg',
                ),
                fit: BoxFit.cover, // Ensure the image fills the container
              ),
            ),
            // Use ImageFiltered instead of BackdropFilter
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 8,
                sigmaY: 8,
              ), // Blur effect
              child: Container(
                color: AppColors.black.withValues(alpha: 0.2), // Black overlay
              ),
            ),
          ),
        ),

        // Name and button overlay
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Connect with PalCollab',
                style: Textstyle.heading.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: 200,
                child: TextButton(
                  onPressed: _launchPalCollabLink, // Launch external link
                  style: Buttonstyle.buttonDarkGray,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Visit PalCollab',
                        style: Textstyle.smallButton.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.open_in_new, size: 16, color: AppColors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aboutPalCollab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About PalCollab', style: Textstyle.subheader),
        SizedBox(height: 10),
        Image.asset('lib/assets/images/auth/palcollab.png'),
        SizedBox(height: 20),
        Text(
          "The Ruth Foundation's PalCollab is an approach created for advocates of Palliative Care in the Philippines which works toward providing:",
          style: Textstyle.body,
          textAlign: TextAlign.justify,
        ),
        SizedBox(height: 20),
        _goToPalCollab(),
      ],
    );
  }

  void _launchPalCollabLink() async {
    final Uri url = Uri.parse('https://www.ruth.ph/palcollab');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _rateSolace() {
    return RatingWidget();
  }
}
