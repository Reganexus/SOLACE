import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/doctor/view_patient_medicine.dart';
import 'package:solace/themes/colors.dart';

class DoctorMedicine extends StatefulWidget {
  const DoctorMedicine({super.key, required this.currentUserId});
  final String currentUserId;

  @override
  DoctorMedicineState createState() => DoctorMedicineState();
}

class DoctorMedicineState extends State<DoctorMedicine> {
  bool _isAscending = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<UserData> filteredUsers = [];
  List<UserData> allUsers = [];

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Stream<List<UserData>> _fetchCaregivers() {
    return FirebaseFirestore.instance.collection('caregiver').snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserData.fromDocument(doc)).toList(),
        );
  }

  void _filterUsers(String query) {
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          filteredUsers = List.from(allUsers);
        } else {
          filteredUsers = allUsers.where((user) {
            final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
            return fullName.contains(query.toLowerCase());
          }).toList();
        }
        _sortUsers(); // Apply sorting after filtering
      });
    }
  }

  void _sortUsers() {
    if (mounted) {
      setState(() {
        filteredUsers.sort((a, b) => _isAscending
            ? a.firstName.compareTo(b.firstName) // Ascending order
            : b.firstName.compareTo(a.firstName)); // Descending order
      });
    }
  }

  void _toggleSortOrder() {
    if (mounted) {
      setState(() {
        _isAscending = !_isAscending; // Toggle the sort order
        _sortUsers(); // Reapply sorting
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        title: const Text(
          'Prescribe Medicine',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _toggleSortOrder, // Toggle sort order when tapped
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Image.asset(
                _isAscending
                    ? 'lib/assets/images/shared/navigation/ascending.png' // Path to ascending icon
                    : 'lib/assets/images/shared/navigation/descending.png', // Path to descending icon
                height: 24, // Adjust size as needed
                width: 24,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<UserData>>(
        stream: _fetchCaregivers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading caregivers"));
          }

          allUsers = snapshot.data ?? [];
          if (filteredUsers.isEmpty) {
            filteredUsers = List.from(allUsers);
          }

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Container(
              color: AppColors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: _filterUsers,
                      decoration: InputDecoration(
                        hintText: 'Search Caregivers',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            _filterUsers(_searchController.text);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final caregiver = filteredUsers[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewPatientMedicine(
                                    patientId: caregiver.uid,
                                    patientName:
                                        '${caregiver.firstName} ${caregiver.lastName}',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 15.0),
                              margin: const EdgeInsets.symmetric(vertical: 5.0),
                              decoration: BoxDecoration(
                                color: AppColors.gray,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: (caregiver
                                            .profileImageUrl.isNotEmpty)
                                        ? NetworkImage(
                                            caregiver.profileImageUrl)
                                        : const AssetImage(
                                                'lib/assets/images/shared/placeholder.png')
                                            as ImageProvider,
                                    radius: 24.0,
                                  ),
                                  const SizedBox(width: 10.0),
                                  Text(
                                    '${caregiver.firstName} ${caregiver.lastName}',
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
