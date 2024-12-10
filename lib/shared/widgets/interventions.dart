import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/shared/widgets/doctor_list.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCheckedStates();
  }

  Future<void> _loadCheckedStates() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('checkedStates')
          .doc(widget.uid)
          .get();
      if (doc.exists) {
        Map<String, dynamic> rawData = doc.data() as Map<String, dynamic>;
        setState(() {
          persistentCheckedStates = rawData.map((key, value) {
            List<bool> boolList = (value as List<dynamic>)
                .map((item) => item as bool)
                .toList();
            return MapEntry(key, boolList);
          });
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
    'Fatigue': 'fatigue',
    'Shortness of Breath': 'dyspnea',
    'Appetite': 'appetite',
    'Coughing': 'cough'
  };

// Emotional Symptoms Mapping
  final Map<String, String> emotionalMapping = {
    'Nausea': 'nauseaOrVomiting',
    'Depression': 'depression',
    'Anxiety': 'anxietyOrAgitation',
    'Drowsiness': 'drowsiness',
  };

  Future<Map<String, List<String>>> _fetchInterventions() async {
    Map<String, List<String>> symptomInterventions = {};

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.uid).get();
      if (!userDoc.exists ||
          !(userDoc.data()! as Map<String, dynamic>).containsKey('symptoms')) {
        return {};
      }

      List<String> symptoms = List<String>.from(userDoc['symptoms']);

      // Combine all mappings into one for lookup
      final allMappings = {
        ...vitalsMapping,
        ...physicalMapping,
        ...emotionalMapping,
      };

      for (String symptom in symptoms) {
        String? mappedName = allMappings[symptom];
        if (mappedName == null) continue;
        DocumentSnapshot interventionDoc =
            await _firestore.collection('interventions').doc(mappedName).get();
        if (interventionDoc.exists) {
          List<String> interventions =
              List<String>.from(interventionDoc['interventions'] ?? []);
          symptomInterventions[symptom] = interventions;
        } else {
          symptomInterventions[symptom] = ['No interventions found'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching interventions: $e');
    }

    return symptomInterventions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: FutureBuilder<Map<String, List<String>>>(
          future: _fetchInterventions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading interventions'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No interventions found'));
            }

            Map<String, List<String>> symptomInterventions = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30.0, 10, 30.0, 30.0),
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
            );
          },
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
                'No Intervention Needed',
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
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 5),
                                backgroundColor: AppColors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                bool confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Action'),
                                    content: const Text(
                                        'Do you want to call a doctor?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DoctorList(
                                        uid: widget.uid,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Call a Doctor',
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
                ),
              );
            },
          );
        }),
      ],
    );
  }
}
