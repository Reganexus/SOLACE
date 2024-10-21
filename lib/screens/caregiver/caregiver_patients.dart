import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';
import 'caregiver_view_status.dart';

class CaregiverPatientsScreen extends StatefulWidget {
  const CaregiverPatientsScreen({super.key});

  @override
  CaregiverPatientsScreenState createState() => CaregiverPatientsScreenState();
}

class CaregiverPatientsScreenState extends State<CaregiverPatientsScreen> {
  String _sortOrder = 'A-Z'; // Sorting state
  final TextEditingController _searchController = TextEditingController();

  // Example list of patients
  List<Map<String, String>> patients = [
    {
      'name': 'Patient A',
      'profilePic': 'lib/assets/images/shared/placeholder.png'
    },
    {
      'name': 'Patient B',
      'profilePic': 'lib/assets/images/shared/placeholder.png'
    },
    {
      'name': 'Patient C',
      'profilePic': 'lib/assets/images/shared/placeholder.png'
    },
    {
      'name': 'Patient D',
      'profilePic': 'lib/assets/images/shared/placeholder.png'
    },
    {
      'name': 'Patient E',
      'profilePic': 'lib/assets/images/shared/placeholder.png'
    },
    {
      'name': 'Patient F',
      'profilePic': 'lib/assets/images/shared/placeholder.png'
    },
    {
      'name': 'Patient G',
      'profilePic': 'lib/assets/images/shared/placeholder.png'
    },
    {
      'name': 'Patient H',
      'profilePic': 'lib/assets/images/shared/placeholder.png'
    },
    {
      'name': 'Patient I',
      'profilePic': 'lib/assets/images/shared/placeholder.png'
    },
    {
      'name': 'Patient J',
      'profilePic': 'lib/assets/images/shared/placeholder.png'
    },
    {
      'name': 'Patient K',
      'profilePic': 'lib/assets/images/shared/placeholder.png'
    },
    {
      'name': 'Patient L',
      'profilePic': 'lib/assets/images/shared/placeholder.png'
    },
  ];

  // This will hold the filtered patient list
  List<Map<String, String>> filteredPatients = [];

  @override
  void initState() {
    super.initState();
    // Initially, show all patients
    filteredPatients = patients;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPatients(String query) {
    // Filter the patient list based on the search query
    setState(() {
      if (query.isEmpty) {
        filteredPatients = patients; // Show all if the query is empty
      } else {
        filteredPatients = patients
            .where((patient) =>
                patient['name']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Function to sort the patient list based on name
  void _sortPatients() {
    setState(() {
      if (_sortOrder == 'A-Z') {
        filteredPatients.sort((a, b) => a['name']!.compareTo(b['name']!));
      } else {
        filteredPatients.sort((a, b) => b['name']!.compareTo(a['name']!));
      }
    });
  }

  void _toggleSortOrder() {
    setState(() {
      _sortOrder = _sortOrder == 'A-Z' ? 'Z-A' : 'A-Z';
      _sortPatients(); // Call sorting after toggling
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(30.0),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Patients',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 20.0),

            // Search Bar and Search Button Row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40.0, // Same height as the buttons
                    child: TextField(
                      controller: _searchController,
                      onChanged:
                          _filterPatients, // Update the filter on text change
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle:
                            const TextStyle(color: AppColors.blackTransparent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(
                              color: AppColors.blackTransparent),
                        ),
                        contentPadding: const EdgeInsets.all(10.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                TextButton(
                  onPressed: () {
                    // Implement search functionality if needed
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.neon,
                    padding: const EdgeInsets.all(10.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    'Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 5.0,
            ),

            // Sort Radio Button (A-Z, Z-A)
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
                  const SizedBox(width: 5.0), // Space between text and icon
                  Icon(
                    _sortOrder == 'A-Z'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10.0),

            // Patient List (Scrollable)
            Expanded(
              child: ListView.builder(
                itemCount: filteredPatients.length, // Use filtered list
                itemBuilder: (context, index) {
                  final patient = filteredPatients[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to caregiver view status
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CaregiverViewStatus(
                            username:
                                patient['name']!, // Pass patient name here
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
                            backgroundImage: AssetImage(patient['profilePic']!),
                            radius: 16.0,
                          ),
                          const SizedBox(width: 10.0),
                          Text(
                            patient['name']!,
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
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
  }
}
