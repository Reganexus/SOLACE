import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/screens/patient/patient_contact_list.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';

class PatientInterventions extends StatefulWidget {
  final String patientId;

  const PatientInterventions({super.key, required this.patientId});

  @override
  PatientInterventionsState createState() => PatientInterventionsState();
}

class PatientInterventionsState extends State<PatientInterventions> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, List<bool>> persistentCheckedStates = {};
  Map<String, List<String>> symptomInterventions = {};
  bool isLoading = true;
  String? selectedSection;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<String> _getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? '';
  }

  Future<void> _loadData() async {
    try {
      await _loadCheckedStates();
      symptomInterventions = await _fetchInterventions();

      if (!mounted) return;

      setState(() {
        Map<String, List<String>> initialSections = {};

        if (vitals.any(
          (symptom) => symptomInterventions.containsKey(symptom),
        )) {
          initialSections['Vitals'] = vitals;
        }
        if (physicalSymptoms.any(
          (symptom) => symptomInterventions.containsKey(symptom),
        )) {
          initialSections['Physical Symptoms'] = physicalSymptoms;
        }
        if (emotionalSymptoms.any(
          (symptom) => symptomInterventions.containsKey(symptom),
        )) {
          initialSections['Emotional Symptoms'] = emotionalSymptoms;
        }

        if (initialSections.isNotEmpty) {
          selectedSection = initialSections.keys.first;
        }

        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          // Optionally handle the error here (e.g., set an error message)
        });
      }
    }
  }

  Future<void> _loadCheckedStates() async {
    try {
      DocumentSnapshot doc =
          await _firestore
              .collection('checkedStates')
              .doc(widget.patientId)
              .get();
      if (doc.exists) {
        Map<String, dynamic> rawData = doc.data() as Map<String, dynamic>;
        persistentCheckedStates = rawData.map((key, value) {
          List<bool> boolList =
              (value as List<dynamic>).map((item) => item as bool).toList();
          return MapEntry(key, boolList);
        });
      }
    } catch (e) {
      //       debugPrint('Error loading persistent states: $e');
    }
  }

  Future<void> _saveCheckedStates() async {
    try {
      await _firestore
          .collection('checkedStates')
          .doc(widget.patientId)
          .set(persistentCheckedStates);
    } catch (e) {
      //       debugPrint('Error saving persistent states: $e');
    }
  }

  String _toCamelCase(String input) {
    return input.split(' ').mapIndexed((index, word) {
      if (index == 0) {
        return word.toLowerCase();
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join();
  }

  final List<String> vitals = [
    'Low Heart Rate',
    'High Heart Rate',
    'Low Blood Pressure',
    'High Blood Pressure',
    'Low Oxygen Saturation',
    'Low Respiration Rate',
    'High Respiration Rate',
    'Low Temperature',
    'High Temperature',
    'High Pain',
    'Extremely Low Heart Rate',
    'Extremely High Heart Rate',
    'Extremely Low Blood Pressure',
    'Extremely High Blood Pressure',
    'Extremely Low Oxygen Saturation',
    'Extremely Low Respiration Rate',
    'Extremely High Respiration Rate',
    'Extremely Low Temperature',
    'Extremely High Temperature',
    'Extremely High Pain',
  ];

  final List<String> physicalSymptoms = [
    'Diarrhea',
    'Constipation',
    'Fatigue',
    'Shortness of Breath',
    'Poor Appetite',
    'Coughing',
    'Nausea',
    'Vomiting',
  ];

  final List<String> emotionalSymptoms = [
    'Depression',
    'Anxiety',
    'Confusion',
    'Insomnia',
  ];

  Future<Map<String, List<String>>> _fetchInterventions() async {
    Map<String, List<String>> interventions = {};

    try {
      // Fetch the patient document
      DocumentSnapshot userDoc =
          await _firestore.collection('patient').doc(widget.patientId).get();

      if (userDoc.exists && userDoc['symptoms'] != null) {
        List<String> symptoms = List<String>.from(userDoc['symptoms']);

        // Fetch the interventions document from the globals collection
        DocumentSnapshot globalsInterventionsDoc =
            await _firestore.collection('globals').doc('interventions').get();

        if (globalsInterventionsDoc.exists) {
          // Get the data from the interventions document
          Map<String, dynamic> globalsInterventions =
              globalsInterventionsDoc.data() as Map<String, dynamic>;

          for (String symptom in symptoms) {
            // Dynamically generate the mapped name by converting the symptom to camel case
            String mappedName = _toCamelCase(symptom);

            if (globalsInterventions.containsKey(mappedName)) {
              // Retrieve the array of interventions for the mapped name
              List<String> mappedInterventions = List<String>.from(
                globalsInterventions[mappedName] ?? [],
              );
              interventions[symptom] = mappedInterventions;
            } else {
              // If no interventions are found, add a default message
              interventions[symptom] = ['No interventions found'];
            }
          }
        }
      }
    } catch (e) {
      //       debugPrint('Error fetching interventions: $e');
    }

    return interventions;
  }

  Widget buildCallButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildCallButton(
              title: 'Relatives',
              iconColor: AppColors.white,
              buttonStyle: Buttonstyle.buttonNeon,
              fetchContacts: () async {
                QuerySnapshot contactSnapshot =
                    await FirebaseFirestore.instance
                        .collection('patient')
                        .doc(widget.patientId)
                        .collection('contacts')
                        .get();

                var relativeDocs =
                    contactSnapshot.docs
                        .where((doc) => doc.id == 'relative')
                        .toList();
                if (relativeDocs.isNotEmpty) {
                  Map<String, dynamic> relatives =
                      relativeDocs.first.data() as Map<String, dynamic>;

                  // Get current user ID
                  String currentUserId = await _getCurrentUserId();

                  // Filter out the current user from the list
                  return relatives.values
                      .where((relative) {
                        return relative['uid'] != currentUserId;
                      })
                      .map((relative) {
                        return {
                          'name': relative['name'] ?? '',
                          'phone': relative['phoneNumber'] ?? '',
                          'category': relative['category'] ?? '',
                        };
                      })
                      .toList();
                }
                return [];
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCallButton(
              title: 'Nurses',
              iconColor: AppColors.white,
              buttonStyle: Buttonstyle.buttonPurple,
              fetchContacts: () async {
                QuerySnapshot contactSnapshot =
                    await FirebaseFirestore.instance
                        .collection('patient')
                        .doc(widget.patientId)
                        .collection('contacts')
                        .get();
                var nurseDocs =
                    contactSnapshot.docs
                        .where((doc) => doc.id == 'nurse')
                        .toList();
                if (nurseDocs.isNotEmpty) {
                  Map<String, dynamic> nurses =
                      nurseDocs.first.data() as Map<String, dynamic>;

                  // Get current user ID
                  String currentUserId = await _getCurrentUserId();

                  // Filter out the current user from the list
                  return nurses.values
                      .where((nurse) {
                        return nurse['uid'] != currentUserId;
                      })
                      .map((nurse) {
                        return {
                          'name': nurse['name'] ?? '',
                          'phone': nurse['phoneNumber'] ?? '',
                          'category': nurse['category'] ?? '',
                        };
                      })
                      .toList();
                }
                return [];
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCallButton(
              title: 'Doctors',
              iconColor: AppColors.white,
              buttonStyle: Buttonstyle.buttonRed,
              fetchContacts: () async {
                QuerySnapshot doctorSnapshot =
                    await FirebaseFirestore.instance.collection('doctor').get();

                // Get current user ID
                String currentUserId = await _getCurrentUserId();

                // Filter out the current user from the list
                return doctorSnapshot.docs
                    .where((doc) {
                      return doc.id !=
                          currentUserId; // Assuming the doctor ID is the document ID
                    })
                    .map((doc) {
                      return {
                        'name': '${doc['firstName']} ${doc['lastName']}'.trim(),
                        'phone': doc['phoneNumber'] ?? '',
                        'profileImageUrl': doc['profileImageUrl'] ?? '',
                      };
                    })
                    .toList();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required String title,
    required Color iconColor,
    required ButtonStyle buttonStyle,
    required Future<List<Map<String, dynamic>>> Function() fetchContacts,
  }) {
    return TextButton(
      style: buttonStyle,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ContactList(title: title, fetchContacts: fetchContacts),
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.call, color: iconColor, size: 16),
          const SizedBox(width: 5),
          Text(
            title,
            style: Textstyle.bodySmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllCheckedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text("Checklist Done", style: Textstyle.subheader),
          content: Text(
            "Great! You performed all interventions. Watch the patient for symptom flare ups.\n\nIf symptom persists, call functions are provided below.",
            style: Textstyle.body,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: Buttonstyle.buttonNeon,
              child: Text("Okay", style: Textstyle.smallButton),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<String>> sections = {};

    // Populate sections based on available data
    if (vitals.any((symptom) => symptomInterventions.containsKey(symptom))) {
      sections['Vitals'] = vitals;
    }
    if (physicalSymptoms.any(
      (symptom) => symptomInterventions.containsKey(symptom),
    )) {
      sections['Physical Symptoms'] = physicalSymptoms;
    }
    if (emotionalSymptoms.any(
      (symptom) => symptomInterventions.containsKey(symptom),
    )) {
      sections['Emotional Symptoms'] = emotionalSymptoms;
    }

    return isLoading
        ? Center(child: Loader.loaderPurple)
        : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (selectedSection != null)
                sections[selectedSection]!.isNotEmpty
                    ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 60,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children:
                                    sections.keys.map((section) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 10.0,
                                        ),
                                        child: ChoiceChip(
                                          checkmarkColor: AppColors.white,
                                          label: Text(
                                            section,
                                            style: Textstyle.bodySmall.copyWith(
                                              color:
                                                  selectedSection == section
                                                      ? AppColors.white
                                                      : AppColors
                                                          .whiteTransparent,
                                              fontWeight:
                                                  selectedSection == section
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                          selected: selectedSection == section,
                                          onSelected: (isSelected) {
                                            setState(() {
                                              if (selectedSection != section) {
                                                selectedSection = section;
                                              }
                                            });
                                          },
                                          side: BorderSide(
                                            color: Colors.transparent,
                                          ),
                                          selectedColor: AppColors.neon,
                                          backgroundColor: AppColors.darkgray,
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          buildSymptomSection(
                            sections[selectedSection] ?? [],
                            symptomInterventions,
                          ),
                        ],
                      ),
                    )
                    : Center(
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: AppColors.gray,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Text(
                          'No interventions available for this section.',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
              else
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: AppColors.gray,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Text(
                      'Great Job! No interventions as of the moment.',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
  }

  Widget buildSymptomSection(
    List<String> symptoms,
    Map<String, List<String>> interventions,
  ) {
    // Filter symptoms with interventions
    List<String> filteredSymptoms =
        symptoms
            .where((symptom) => interventions.containsKey(symptom))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...filteredSymptoms.map((symptom) {
          List<String> symptomInterventions = interventions[symptom]!;
          List<bool> checkedStates =
              persistentCheckedStates[symptom] ??
              List<bool>.filled(symptomInterventions.length, false);

          return StatefulBuilder(
            builder: (context, setState) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.gray,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                margin: const EdgeInsets.only(bottom: 10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: AppColors.gray),
                    child: ExpansionTile(
                      iconColor: AppColors.black,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
                      backgroundColor: AppColors.gray,
                      title: Row(
                        children: [
                          Text(
                            '${checkedStates.where((state) => state).length}/${symptomInterventions.length}',
                            style: Textstyle.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Text(symptom, style: Textstyle.body),
                        ],
                      ),
                      children: [
                        ...symptomInterventions.asMap().entries.map(
                          (entry) => CheckboxListTile(
                            activeColor: AppColors.neon,
                            title: Text(
                              entry.value,
                              style: Textstyle.bodySmall,
                            ),
                            value: checkedStates[entry.key],
                            onChanged: (bool? value) async {
                              setState(() {
                                checkedStates[entry.key] = value ?? false;
                              });
                              persistentCheckedStates[symptom] = checkedStates;
                              await _saveCheckedStates();

                              // Show dialog when all checkboxes are checked
                              if (checkedStates.every((state) => state)) {
                                _showAllCheckedDialog(context);
                              }
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (checkedStates.every((state) => state))
                          buildCallButtons(),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }
}
