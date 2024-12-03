import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InterventionsView extends StatelessWidget {
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Map to match user symptoms with Firestore document names
  final Map<String, String> symptomMapping = {
    'Low heart rate': 'lowHeartRate',
    'High heart rate': 'highHeartRate',
    'Low oxygen saturation': 'lowOxygenSaturation',
    'Low respiration rate': 'lowRespirationRate',
    'High respiration rate': 'highRespirationRate',
    'Low temperature': 'lowTemperature',
    'High temperature': 'highTemperature',
    'Diarrhea': 'diarrhea',
    'Fatigue': 'fatigue',
    'Shortness of Breath': 'dsypnea',
    'Appetite': 'appetite',
    'Nausea': 'nauseaOrVomiting',
    'Depression': 'depression',
    'Anxiety': 'anxietyOrAgitation',
    'Drowsiness': 'drowsiness',
  };

  InterventionsView({super.key, required this.uid});

  Future<Map<String, List<String>>> _fetchInterventions() async {
    Map<String, List<String>> symptomInterventions = {};

    try {
      // Fetch the symptoms array from the user's Firestore document
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists || !(userDoc.data()! as Map<String, dynamic>).containsKey('symptoms')) {
        return {};
      }

      List<String> symptoms = List<String>.from(userDoc['symptoms']);

      // Fetch interventions for each symptom
      for (String symptom in symptoms) {
        String? mappedName = symptomMapping[symptom];
        if (mappedName == null) continue;

        DocumentSnapshot interventionDoc = await _firestore.collection('interventions').doc(mappedName).get();
        if (interventionDoc.exists) {
          List<String> interventions = List<String>.from(interventionDoc['interventions'] ?? []);
          symptomInterventions[symptom] = interventions;
        } else {
          symptomInterventions[symptom] = ['No interventions found'];
        }
      }
    } catch (e) {
      // Handle any errors that occur during retrieval
      debugPrint('Error fetching interventions: $e');
    }

    return symptomInterventions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Interventions'),
      ),
      body: FutureBuilder<Map<String, List<String>>>(
        future: _fetchInterventions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading interventions'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No interventions found'));
          }

          Map<String, List<String>> symptomInterventions = snapshot.data!;
          return ListView.builder(
            itemCount: symptomInterventions.length,
            itemBuilder: (context, index) {
              String symptom = symptomInterventions.keys.elementAt(index);
              List<String> interventions = symptomInterventions[symptom]!;
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text(symptom),
                  children: interventions.map((intervention) => ListTile(title: Text(intervention))).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
