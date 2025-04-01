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

  Future<void> _loadData() async {
    try {
      await _loadCheckedStates();
      symptomInterventions = await _fetchInterventions();

      if (!mounted) return; // Ensure the widget is still in the tree

      // Determine the initial section after data is loaded
      setState(() {
        Map<String, List<String>> initialSections = {};

        if (vitalsMapping.keys.any(
          (symptom) => symptomInterventions.containsKey(symptom),
        )) {
          initialSections['Vitals'] = vitalsMapping.keys.toList();
        }
        if (physicalMapping.keys.any(
          (symptom) => symptomInterventions.containsKey(symptom),
        )) {
          initialSections['Physical Symptoms'] = physicalMapping.keys.toList();
        }
        if (emotionalMapping.keys.any(
          (symptom) => symptomInterventions.containsKey(symptom),
        )) {
          initialSections['Emotional Symptoms'] =
              emotionalMapping.keys.toList();
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
      debugPrint('Error loading persistent states: $e');
    }
  }

  Future<void> _saveCheckedStates() async {
    try {
      await _firestore
          .collection('checkedStates')
          .doc(widget.patientId)
          .set(persistentCheckedStates);
    } catch (e) {
      debugPrint('Error saving persistent states: $e');
    }
  }

  final Map<String, String> vitalsMapping = {
    'Low Heart Rate': 'lowHeartRate',
    'High Heart Rate': 'highHeartRate',
    'Low Blood Pressure': 'lowBloodPressure',
    'High Blood Pressure': 'highBloodPressure',
    'Low Oxygen Saturation': 'lowOxygenSaturation',
    'Low Respiration Rate': 'lowRespirationRate',
    'High Respiration Rate': 'highRespirationRate',
    'Low Temperature': 'lowTemperature',
    'High Temperature': 'highTemperature',
    'Extremely Low Heart Rate': 'extremelyLowHeartRate',
    'Extremely High Heart Rate': 'extremelyhighHeartRate',
    'Extremely Low Blood Pressure': 'extremelyLowBloodPressure',
    'Extremely High Blood Pressure': 'extremelyHighBloodPressure',
    'Extremely Low Oxygen Saturation': 'extremelyLowOxygenSaturation',
    'Extremely Low Respiration Rate': 'extremelyLowRespirationRate',
    'Extremely High Respiration Rate': 'extremelyHighRespirationRate',
    'Extremely Low Temperature': 'extremelyLowTemperature',
    'Extremely High Temperature': 'extremelyHighTemperature',
    'Pain': 'pain',
  };

  final Map<String, String> physicalMapping = {
    'Diarrhea': 'diarrhea',
    'Bowel Obstruction': 'bowelObstruction',
    'Constipation': 'constipation',
    'Fatigue': 'fatigue',
    'Shortness of Breath': 'cough',
    'Appetite': 'appetite',
    'Weight Loss': 'anorexia',
    'Coughing': 'cough',
    'Nausea': 'nauseaOrVomiting',
    'Drowsiness': 'drowsiness',
  };

  final Map<String, String> emotionalMapping = {
    'Depression': 'depression',
    'Anxiety': 'anxietyOrAgitation',
    'Confusion': 'delirium',
  };

  Future<Map<String, List<String>>> _fetchInterventions() async {
    Map<String, List<String>> interventions = {};
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('patient').doc(widget.patientId).get();
      if (userDoc.exists && userDoc['symptoms'] != null) {
        List<String> symptoms = List<String>.from(userDoc['symptoms']);
        final allMappings = {
          ...vitalsMapping,
          ...physicalMapping,
          ...emotionalMapping,
        };
        for (String symptom in symptoms) {
          String? mappedName = allMappings[symptom];
          if (mappedName != null) {
            DocumentSnapshot interventionDoc =
                await _firestore
                    .collection('interventions')
                    .doc(mappedName)
                    .get();
            if (interventionDoc.exists) {
              interventions[symptom] = List<String>.from(
                interventionDoc['interventions'] ?? [],
              );
            } else {
              interventions[symptom] = ['No interventions found'];
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching interventions: $e');
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

                // Debug: Log each document
                for (var doc in contactSnapshot.docs) {
                  debugPrint("Relative Document (${doc.id}): ${doc.data()}");
                }

                var relativeDocs =
                    contactSnapshot.docs
                        .where((doc) => doc.id == 'relative')
                        .toList();
                if (relativeDocs.isNotEmpty) {
                  Map<String, dynamic> relatives =
                      relativeDocs.first.data() as Map<String, dynamic>;
                  return relatives.values.map((relative) {
                    return {
                      'name': relative['name'] ?? '',
                      'phone': relative['phoneNumber'] ?? '',
                      'category': relative['category'] ?? '',
                    };
                  }).toList();
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

                // Debug: Log each document
                for (var doc in contactSnapshot.docs) {
                  debugPrint("Nurse Document (${doc.id}): ${doc.data()}");
                }

                var nurseDocs =
                    contactSnapshot.docs
                        .where((doc) => doc.id == 'nurse')
                        .toList();
                if (nurseDocs.isNotEmpty) {
                  Map<String, dynamic> nurses =
                      nurseDocs.first.data() as Map<String, dynamic>;
                  return nurses.values.map((nurse) {
                    return {
                      'name': nurse['name'] ?? '',
                      'phone': nurse['phoneNumber'] ?? '',
                      'category': nurse['category'] ?? '',
                    };
                  }).toList();
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

                // Debug: Log each document
                for (var doc in doctorSnapshot.docs) {
                  debugPrint("Doctor Document (${doc.id}): ${doc.data()}");
                }

                return doctorSnapshot.docs.map((doc) {
                  return {
                    'name': '${doc['firstName']} ${doc['lastName']}'.trim(),
                    'phone': doc['phoneNumber'] ?? '',
                    'profileImageUrl': doc['profileImageUrl'] ?? '',
                  };
                }).toList();
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

  @override
  Widget build(BuildContext context) {
    Map<String, List<String>> sections = {};

    // Populate sections based on available data
    if (vitalsMapping.keys.any(
      (symptom) => symptomInterventions.containsKey(symptom),
    )) {
      sections['Vitals'] = vitalsMapping.keys.toList();
    }
    if (physicalMapping.keys.any(
      (symptom) => symptomInterventions.containsKey(symptom),
    )) {
      sections['Physical Symptoms'] = physicalMapping.keys.toList();
    }
    if (emotionalMapping.keys.any(
      (symptom) => symptomInterventions.containsKey(symptom),
    )) {
      sections['Emotional Symptoms'] = emotionalMapping.keys.toList();
    }

    return isLoading
        ? Center(child: Loader.loaderPurple)
        : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Interventions', style: Textstyle.subheader),
                    const SizedBox(height: 10),
                    Text(
                      'Select a section to view the checklist of interventions based on the patient\'s current status.',
                      style: Textstyle.body,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              // Display Interventions or No Interventions Widget
              if (selectedSection != null)
                sections[selectedSection]!.isNotEmpty
                    ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          // Buttons for Sections
                          SizedBox(
                            height: 60, // Ensure this matches your design
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
                                              selectedSection =
                                                  isSelected ? section : null;
                                            });
                                          },
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
