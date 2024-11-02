import 'package:flutter/material.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/caregiver/caregiver_view_status.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';

class CaregiverPatients extends StatefulWidget {
  const CaregiverPatients({super.key});

  @override
  CaregiverPatientsState createState() => CaregiverPatientsState();
}

class CaregiverPatientsState extends State<CaregiverPatients> {
  String _sortOrder = 'A-Z';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<UserData> filteredPatients = [];
  List<UserData> allPatients = []; // Store all patients for searching

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredPatients = List.from(allPatients); // Reset to all patients
      } else {
        filteredPatients = allPatients.where((patient) {
          String fullName = '${patient.firstName ?? ''} ${patient.lastName ?? ''}';
          return fullName.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _sortPatients() {
    setState(() {
      if (_sortOrder == 'A-Z') {
        filteredPatients.sort((a, b) =>
            (a.firstName ?? '').compareTo(b.firstName ?? '')
        );
      } else {
        filteredPatients.sort((a, b) =>
            (b.firstName ?? '').compareTo(a.firstName ?? '')
        );
      }
    });
  }

  void _toggleSortOrder() {
    setState(() {
      _sortOrder = _sortOrder == 'A-Z' ? 'Z-A' : 'A-Z';
      _sortPatients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseService databaseService = DatabaseService();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: StreamBuilder<List<UserData>>(
        stream: databaseService.patients,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading patients"));
          }

          allPatients = snapshot.data ?? [];
          if (filteredPatients.isEmpty) {
            filteredPatients = List.from(allPatients);
          }

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50.0, // Set height for the TextField
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            onSubmitted: (value) {
                              _filterPatients(value);
                              FocusScope.of(context).unfocus(); // Unfocus after submitting
                            },
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: const TextStyle(color: AppColors.blackTransparent),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.blackTransparent), // Default border color
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.blackTransparent), // Remove border color when focused
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.blackTransparent), // Border color when not focused
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.search,
                                  color: _focusNode.hasFocus ? AppColors.neon : Colors.grey, // Change color based on focus
                                ),
                                onPressed: () {
                                  _filterPatients(_searchController.text);
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5.0),
                  TextButton(
                    onPressed: _toggleSortOrder,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      padding: const EdgeInsets.all(10.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _sortOrder,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 5.0),
                        Icon(
                          _sortOrder == 'A-Z' ? Icons.arrow_downward : Icons.arrow_upward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredPatients.length,
                      itemBuilder: (context, index) {
                        final patient = filteredPatients[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CaregiverViewStatus(
                                  username: patient.firstName ?? 'Unknown',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                            margin: const EdgeInsets.symmetric(vertical: 5.0),
                            decoration: BoxDecoration(
                              color: AppColors.gray,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: AssetImage('lib/assets/images/shared/placeholder.png'),
                                  radius: 18.0,
                                ),
                                const SizedBox(width: 10.0),
                                Text(
                                  '${patient.firstName ?? 'No name'} ${patient.lastName ?? ''}',
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
          );
        },
      ),
    );
  }
}
