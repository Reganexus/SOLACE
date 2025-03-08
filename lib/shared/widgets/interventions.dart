import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/screens/patient/doctor_list.dart';
import 'package:solace/themes/colors.dart';

class InterventionsView extends StatefulWidget {
  final String uid;

  const InterventionsView({super.key, required this.uid});

  @override
  InterventionsViewState createState() => InterventionsViewState();
}

class InterventionsViewState extends State<InterventionsView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, List<bool>> persistentCheckedStates = {};
  Map<String, List<String>> symptomInterventions = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadCheckedStates();
    symptomInterventions = await _fetchInterventions();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadCheckedStates() async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('checkedStates').doc(widget.uid).get();
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
          .doc(widget.uid)
          .set(persistentCheckedStates);
    } catch (e) {
      debugPrint('Error saving persistent states: $e');
    }
  }

  // Map to match user symptoms with Firestore document names
  // Vitals Mapping
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
    'High Cholesterol Level': 'highTemperature',
    'Pain': 'pain',
  };

// Physical Symptoms Mapping
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

// Emotional Symptoms Mapping
  final Map<String, String> emotionalMapping = {
    'Depression': 'depression',
    'Anxiety': 'anxietyOrAgitation',
    'Confusion': 'delirium',
  };

  Future<Map<String, List<String>>> _fetchInterventions() async {
    Map<String, List<String>> interventions = {};
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('patient').doc(widget.uid).get();
      if (userDoc.exists && userDoc['symptoms'] != null) {
        List<String> symptoms = List<String>.from(userDoc['symptoms']);
        final allMappings = {
          ...vitalsMapping,
          ...physicalMapping,
          ...emotionalMapping
        };
        for (String symptom in symptoms) {
          String? mappedName = allMappings[symptom];
          if (mappedName != null) {
            DocumentSnapshot interventionDoc = await _firestore
                .collection('interventions')
                .doc(mappedName)
                .get();
            if (interventionDoc.exists) {
              interventions[symptom] =
                  List<String>.from(interventionDoc['interventions'] ?? []);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Intervention',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildSymptomSection(
                        'Vitals',
                        vitalsMapping.keys.toList(),
                        symptomInterventions,
                      ),
                      const SizedBox(height: 20),
                      buildSymptomSection(
                        'Physical Symptoms',
                        physicalMapping.keys.toList(),
                        symptomInterventions,
                      ),
                      const SizedBox(height: 20),
                      buildSymptomSection(
                        'Emotional Symptoms',
                        emotionalMapping.keys.toList(),
                        symptomInterventions,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget buildSymptomSection(
    String title,
    List<String> symptoms,
    Map<String, List<String>> interventions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 10),
        if (symptoms
            .where((symptom) => interventions.containsKey(symptom))
            .isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            margin: const EdgeInsets.only(bottom: 10.0),
            decoration: BoxDecoration(
              color: AppColors.gray,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: const Center(
              child: Text(
                'Great Job! No Intervention Needed',
                style: TextStyle(
                  fontSize: 18.0,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ...symptoms
            .where((symptom) => interventions.containsKey(symptom))
            .map((symptom) {
          List<String> symptomInterventions = interventions[symptom]!;
          List<bool> checkedStates = persistentCheckedStates[symptom] ??
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
                    data: Theme.of(context).copyWith(
                      dividerColor: AppColors.gray,
                    ),
                    child: ExpansionTile(
                      iconColor: AppColors.black,
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      backgroundColor: AppColors.gray,
                      title: Row(
                        children: [
                          Text(
                            '${checkedStates.where((state) => state).length}/${symptomInterventions.length}',
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Text(
                            symptom,
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      children: [
                        ...symptomInterventions.asMap().entries.map(
                              (entry) => CheckboxListTile(
                                activeColor: AppColors.neon,
                                title: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                value: checkedStates[entry.key],
                                onChanged: (bool? value) async {
                                  setState(() {
                                    checkedStates[entry.key] = value ?? false;
                                  });
                                  persistentCheckedStates[symptom] =
                                      checkedStates;
                                  await _saveCheckedStates();
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                            ),
                        const SizedBox(height: 10),
                        if (checkedStates.every((state) => state))
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 20.0),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 10),
                                      backgroundColor: AppColors.neon,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ContactList(
                                            title: 'Relatives',
                                            fetchContacts: () async {
                                              // Fetch relatives from the current user's contacts field
                                              DocumentSnapshot userSnapshot =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('caregiver')
                                                      .doc(widget.uid)
                                                      .get();
                                              List<dynamic> relatives =
                                                  userSnapshot['contacts']
                                                          ['relative'] ??
                                                      [];
                                              return relatives
                                                  .map((relative) => {
                                                        'name':
                                                            '${relative['firstName']} ${relative['lastName']}'
                                                                .trim(),
                                                        'phone':
                                                            relative['phone'],
                                                        'profileImageUrl': relative[
                                                                'profileImageUrl'] ??
                                                            '',
                                                      })
                                                  .toList();
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Call a Relative',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 10),
                                      backgroundColor: AppColors.purple,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ContactList(
                                            title: 'Nurses',
                                            fetchContacts: () async {
                                              // Fetch nurses from the current user's contacts field
                                              DocumentSnapshot userSnapshot =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('caregiver')
                                                      .doc(widget.uid)
                                                      .get();
                                              List<dynamic> nurses =
                                                  userSnapshot['contacts']
                                                          ['nurse'] ??
                                                      [];
                                              return nurses
                                                  .map((nurse) => {
                                                        'name':
                                                            '${nurse['firstName']} ${nurse['lastName']}'
                                                                .trim(),
                                                        'phone': nurse['phone'],
                                                        'profileImageUrl': nurse[
                                                                'profileImageUrl'] ??
                                                            '',
                                                      })
                                                  .toList();
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Call a Nurse',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 10),
                                      backgroundColor: AppColors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ContactList(
                                            title: 'Doctors',
                                            fetchContacts: () async {
                                              // Fetch doctors from Firestore
                                              QuerySnapshot doctorSnapshot =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('doctor')
                                                      .get();
                                              return doctorSnapshot.docs
                                                  .map((doc) => {
                                                        'name':
                                                            '${doc['firstName']} ${doc['lastName']}'
                                                                .trim(),
                                                        'phone':
                                                            doc['phoneNumber'],
                                                        'profileImageUrl':
                                                            doc['profileImageUrl'] ??
                                                                '',
                                                      })
                                                  .toList();
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Call a Doctor',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}
