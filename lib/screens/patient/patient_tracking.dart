// ignore_for_file: use_build_context_synchronously, unused_import, avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:solace/controllers/getaccesstoken.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/screens/patient/input_summary.dart';
import 'package:solace/shared/globals.dart';
import 'package:solace/themes/colors.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class PatientTracking extends StatefulWidget {
  const PatientTracking({super.key});

  @override
  PatientTrackingState createState() => PatientTrackingState();
}

class PatientTrackingState extends State<PatientTracking> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DatabaseService databaseService = DatabaseService();

  bool isCooldownActive = false; // Added this variable
  int remainingCooldownTime = 0; // Added this variable
  Timer? _countdownTimer;

  final Map<String, String> _vitalInputs = {
    'Heart Rate': '',
    'Blood Pressure': '',
    'Oxygen Saturation': '',
    'Respiration': '',
    'Temperature': '',
    'Cholesterol Level': '',
    'Pain': '',
  };

  final Map<String, TextEditingController> _controllers = {
    'Heart Rate': TextEditingController(),
    'Blood Pressure': TextEditingController(),
    'Oxygen Saturation': TextEditingController(),
    'Respiration': TextEditingController(),
    'Temperature': TextEditingController(),
    'Cholesterol Level': TextEditingController(),
    'Pain': TextEditingController(),
  };

  final Map<String, dynamic> _algoInputs = {
    "Fever": false,
    "Cough": false,
    "Fatigue": false,
    "Difficulty Breathing": false,
    "Age": null,
    "Gender": null,
    "Blood Pressure": null,
    "Cholesterol Level": null,
  };

  final Map<String, FocusNode> _focusNodes = {
    'Heart Rate': FocusNode(),
    'Blood Pressure': FocusNode(),
    'Oxygen Saturation': FocusNode(),
    'Respiration': FocusNode(),
    'Temperature': FocusNode(),
    'Cholesterol Level': FocusNode(),
    'Pain': FocusNode(),
  };

  int _diarrheaValue = 0;
  int _bowelObstructionValue = 0;
  int _constipationValue = 0;
  int _fatigueValue = 0;
  int _shortnessOfBreathValue = 0;
  int _appetiteValue = 0;
  int _weightLossValue = 0;
  int _coughingValue = 0;
  int _nauseaValue = 0;
  int _depressionValue = 0;
  int _anxietyValue = 0;
  int _drowsinessValue = 0;
  int _confusionValue = 0;

  late Map<String, dynamic> _combinedInputs;
  late final MyUser? user;

  @override
  void initState() {
    super.initState();
    user = Provider.of<MyUser?>(context, listen: false);
    _initializeCooldown();
    checkAndResetOptions();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void checkAndResetOptions() {
    setState(() {
      // Clear form fields
      for (var controller in _controllers.values) {
        controller.clear();
      }

      // Reset symptom values
      _diarrheaValue = 0;
      _bowelObstructionValue = 0;
      _constipationValue = 0;
      _fatigueValue = 0;
      _shortnessOfBreathValue = 0;
      _appetiteValue = 0;
      _weightLossValue = 0;
      _coughingValue = 0;
      _nauseaValue = 0;
      _depressionValue = 0;
      _anxietyValue = 0;
      _drowsinessValue = 0;
      _confusionValue = 0;
      
    });
  }

  Future<void> _initializeCooldown() async {
    if (user == null) return;

    final lastSubmitted = await getLastSubmittedTime(user!.uid);
    debugPrint("Last submitted: $lastSubmitted");

    if (!mounted) return;

    setState(() {
      if (lastSubmitted == 0) {
        isCooldownActive = false;
      } else {
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final timeDifference = currentTime - lastSubmitted;

        if (timeDifference < 1 * 60 * 1000) {
          isCooldownActive = true;
          remainingCooldownTime = (1 * 10) - (timeDifference / 1000).round();
          debugPrint("Remaining Cooldown: $remainingCooldownTime");
          _startCountdown();
        } else {
          isCooldownActive = false;
        }
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingCooldownTime > 0) {
        setState(() => remainingCooldownTime--);
      } else {
        _countdownTimer?.cancel();
        setState(() => isCooldownActive = false);
        _sendCooldownLiftedNotification(); // Send notification when cooldown ends
      }
    });
  }

  Future<int> getLastSubmittedTime(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('tracking')
          .doc(userId)
          .get();

      debugPrint("Last Submitted uid: $userId");

      if (userDoc.exists) {
        final lastTracking = userDoc.data()?['tracking'] as List?;
        if (lastTracking != null && lastTracking.isNotEmpty) {
          final lastEntry = lastTracking.last;
          final lastSubmittedTimestamp =
              (lastEntry['timestamp'] as Timestamp).millisecondsSinceEpoch;
          debugPrint("Last Submitted: $lastSubmittedTimestamp");
          return lastSubmittedTimestamp;
        }
      }
      return 0;
    } catch (e) {
      debugPrint("Error fetching last submission time: $e");
      return 0;
    }
  }

  String _formatCooldownTime(int timeInSeconds) {
    final hours = (timeInSeconds / 3600).floor();
    final minutes = ((timeInSeconds % 3600) / 60).floor();
    final seconds = timeInSeconds % 60;
    return 'Hours: $hours Minutes: $minutes Seconds: $seconds';
  }

  String? _validateInput(String value, {String field = ''}) {
    if (value.isEmpty) {
      return 'This field is required';
    }

    // Specific validations for each field
    switch (field) {
      case 'Temperature':
        // Temperature should be a valid decimal within a certain range
        final temp = double.tryParse(value);
        if (temp == null) {
          return 'Enter a valid temperature (e.g., 36.5)';
        }
        if (temp < 35.0 || temp > 42.0) {
          return 'Temperature should be between 35.0 and 42.0 °C';
        }
        break;

      case 'Heart Rate':
        // Heart rate should be a valid integer within range
        final heartRate = int.tryParse(value);
        if (heartRate == null) {
          return 'Enter a valid heart rate (e.g., 72)';
        }
        if (heartRate < 40 || heartRate > 200) {
          return 'Heart rate should be between 40 and 200 bpm';
        }
        break;

      case 'Cholesterol Level':
        // Cholesterol level should be a valid number within a range
        final cholesterol = double.tryParse(value);
        if (cholesterol == null) {
          return 'Enter a valid cholesterol level';
        }
        if (cholesterol < 150 || cholesterol > 240) {
          return 'Cholesterol level should be between 150 and 240 mg/dL';
        }
        break;

      case 'Oxygen Saturation':
        // Oxygen saturation should be a percentage between 90 and 100
        final oxygenSaturation = int.tryParse(value);
        if (oxygenSaturation == null) {
          return 'Enter a valid oxygen saturation percentage';
        }
        if (oxygenSaturation < 90 || oxygenSaturation > 100) {
          return 'Oxygen saturation should be between 90% and 100%';
        }
        break;

      // Default case for Blood Pressure (already handled earlier)
      case 'Blood Pressure':
        final regex = RegExp(r'^\d{2,3}/\d{2,3}$');
        if (!regex.hasMatch(value)) {
          return 'Enter valid blood pressure (e.g., 120/80)';
        }

        final parts = value.split('/');
        final systolic = int.tryParse(parts[0].trim());
        final diastolic = int.tryParse(parts[1].trim());

        if (systolic == null || diastolic == null) {
          return 'Enter valid blood pressure numbers';
        }

        if (systolic < 50 ||
            systolic > 200 ||
            diastolic < 30 ||
            diastolic > 120) {
          return 'Enter valid blood pressure (systolic 50-200, diastolic 30-120)';
        }
        break;

      default:
        // Generic numeric validation for other fields
        if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
          return 'Enter a valid number';
        }
    }

    return null;
  }

  void _sendCooldownLiftedNotification() async {
    debugPrint("Running send cooldown lifted notification");
    try {
      final String? targetToken = await FirebaseMessaging.instance.getToken();

      if (targetToken == null) {
        print(
            'Error: FCM token is null. Ensure Firebase is initialized properly.');
        return;
      }

      const title = 'Cooldown Lifted';
      const body = 'Your cooldown period has ended. You can submit again!';

      // Send FCM notification
      await FCMHelper.sendFCMMessage(targetToken, title, body);
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SingleChildScrollView(
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('patient')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final hasData = snapshot.hasData && snapshot.data!.exists;
             
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCooldownActive)
                       Container(
                         padding: const EdgeInsets.all(20),
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(10.0),
                           color: AppColors.gray,
                         ),
                         child: Column(
                           children: [
                             const Text(
                               'You cannot input vitals and assessment at the moment.',
                               textAlign: TextAlign.center,
                               style: TextStyle(
                                 fontWeight: FontWeight.bold,
                                 fontSize: 20,
                                 fontFamily: 'Inter',
                               ),
                             ),
                             const SizedBox(height: 10),
                             Text(
                               _formatCooldownTime(remainingCooldownTime),
                               textAlign: TextAlign.center,
                               style: const TextStyle(
                                 fontSize: 16,
                                 fontWeight: FontWeight.normal,
                                 fontFamily: 'Inter',
                               ),
                             ),
                           ],
                         ),
                       ),
                     if (!isCooldownActive)
                       if (!hasData)
                         Container(
                           padding: const EdgeInsets.all(20),
                           decoration: BoxDecoration(
                             borderRadius: BorderRadius.circular(10.0),
                             color: AppColors.gray,
                           ),
                           child: Column(
                             children: [
                               SizedBox(
                                 width: double.infinity,
                                 child: Column(
                                   mainAxisSize: MainAxisSize.max,
                                   children: const [
                                     Text(
                                       'Patient is not Available',
                                       textAlign: TextAlign.center,
                                       style: TextStyle(
                                         fontWeight: FontWeight.bold,
                                         fontSize: 20,
                                         fontFamily: 'Inter',
                                       ),
                                     ),
                                     SizedBox(height: 10),
                                     Text(
                                       'Go to "Patient" at Home',
                                       textAlign: TextAlign.center,
                                       style: TextStyle(
                                         fontSize: 16,
                                         fontWeight: FontWeight.normal,
                                         fontFamily: 'Inter',
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                               SizedBox(height: 20.0),
                             ],
                           ),
                         )
                       else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vitals',
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            _buildVitalsInputs(),
                            const SizedBox(height: 20.0),
                            const Divider(thickness: 1.0),
                            const SizedBox(height: 20.0),
                            const Text(
                              'Symptom Assessment',
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            _buildSliders(),
                            const SizedBox(height: 20.0),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed:
                                    hasData ? () => _submit(user!.uid) : null,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 50,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: hasData
                                      ? AppColors.neon
                                      : AppColors.blackTransparent,
                                ),
                                child: const Text(
                                  'Submit',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, FocusNode focusNode) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.gray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
        borderSide: const BorderSide(
          color: AppColors.neon,
          width: 2,
        ),
      ),
      labelStyle: const TextStyle(color: AppColors.black),
    );
  }

  Widget _buildVitalsInputs() {
    return FormBuilder(
      key: _formKey,
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _focusNodes.keys.length,
        itemBuilder: (context, index) {
          final key = _focusNodes.keys.elementAt(index);
          return _buildVitalInputField(key);
        },
      ),
    );
  }

  Widget _buildVitalInputField(String key) {
    final controller = _controllers[key]!;
    final focusNode = _focusNodes[key]!;

    String unitLabel = '';
    List<String? Function(String?)> validators = [FormBuilderValidators.required()];

    List<TextInputFormatter> inputFormatters = [];

    switch (key) {
      case 'Temperature':
        unitLabel = '°C';
        validators.addAll([
          FormBuilderValidators.numeric(),
          FormBuilderValidators.min(28.0),
          FormBuilderValidators.max(43.0),
        ]);
        inputFormatters.add(FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}$')));
        break;
      case 'Heart Rate':
        unitLabel = 'bpm';
        validators.addAll([
          FormBuilderValidators.integer(),
          FormBuilderValidators.min(30),
          FormBuilderValidators.max(220),
        ]);
        inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
        break;
      case 'Blood Pressure':
        unitLabel = 'mmHg';
        validators.add(FormBuilderValidators.match(
          RegExp(r'^\d{2,3}/\d{2,3}$'),
          errorText: 'Format: 120/80',
        ));
        inputFormatters.add(FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}/?\d{0,3}$')));
        break;
      case 'Oxygen Saturation':
        unitLabel = '%';
        validators.addAll([
          FormBuilderValidators.numeric(),
          FormBuilderValidators.min(50.0),
          FormBuilderValidators.max(100.0),
        ]);
        inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
        break;
      case 'Respiration':
        unitLabel = 'b/min';
        validators.addAll([
          FormBuilderValidators.integer(),
          FormBuilderValidators.min(4),
          FormBuilderValidators.max(80),
        ]);
        inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
        break;
      case 'Cholesterol Level':
        unitLabel = 'mg/dL';
        validators.addAll([
          FormBuilderValidators.numeric(),
          FormBuilderValidators.min(80),
          FormBuilderValidators.max(500),
        ]);
        inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
        break;
      case 'Pain':
        int painValue = int.tryParse(_vitalInputs[key] ?? '0') ?? 0;
        return _buildSlider('Pain', painValue, (newValue) {
          setState(() {
            _vitalInputs[key] = newValue.toString();
          });
        });
      default:
        unitLabel = '';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.gray,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                child: FormBuilderTextField(
                  name: key,
                  controller: controller,
                  focusNode: focusNode,
                  decoration: _inputDecoration(key, focusNode),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose(validators),
                  inputFormatters: inputFormatters,
                  onChanged: (value) => _vitalInputs[key] = value ?? '',
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),
            ),
            Container(
              width: 70,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.darkerGray,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  unitLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.blackTransparent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String title, int value, Function(int) onChanged) {
    Color getIndicatorColor(int value) {
      if (value <= 2) {
        return Colors.green; // Very low intensity
      } else if (value <= 4) {
        return Colors.lightGreen; // Low intensity
      } else if (value <= 6) {
        return Colors.yellow; // Moderate intensity
      } else if (value <= 8) {
        return Colors.orange; // High intensity
      } else {
        return Colors.red; // Very high intensity
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbColor: getIndicatorColor(value), // Thumb color
                  valueIndicatorColor:
                      getIndicatorColor(value), // Indicator color
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.white, // Text color inside the indicator
                    fontWeight: FontWeight.bold,
                  ),
                  trackHeight: 5,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 20),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 10),
                  valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Gradient background
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.green, // Very low intensity
                            Colors.lightGreen, // Low intensity
                            Colors.yellow, // Moderate intensity
                            Colors.orange, // High intensity
                            Colors.red, // Very high intensity
                          ],
                          stops: [
                            0.0,
                            0.25,
                            0.5,
                            0.75,
                            1.0
                          ], // Define stops for each color
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    // Slider overlay
                    Slider(
                      value: value.toDouble(),
                      min: 0,
                      max: 10,
                      divisions: 10,
                      label: value.toString(),
                      onChanged: (val) => onChanged(val.toInt()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            DropdownButton<int>(
              dropdownColor: AppColors.white,
              value: value,
              items: List.generate(11, (index) => index).map((val) {
                return DropdownMenuItem<int>(
                  value: val,
                  child: Text(val.toString()),
                );
              }).toList(),
              onChanged: (val) => onChanged(val!),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Physical',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            fontFamily: "Outfit",
          ),
        ),
        const SizedBox(height: 10),
        _buildSlider('Diarrhea', _diarrheaValue, (val) {
          setState(() => _diarrheaValue = val);
        }),
        _buildSlider('Bowel Obstruction', _bowelObstructionValue, (val) {
          setState(() => _bowelObstructionValue = val);
        }),
        _buildSlider('Constipation', _constipationValue, (val) {
          setState(() => _constipationValue = val);
        }),
        _buildSlider('Fatigue', _fatigueValue, (val) {
          setState(() => _fatigueValue = val);
        }),
        _buildSlider('Shortness of Breath', _shortnessOfBreathValue, (val) {
          setState(() => _shortnessOfBreathValue = val);
        }),
        _buildSlider('Appetite', _appetiteValue, (val) {
          setState(() => _appetiteValue = val);
        }),
        _buildSlider('Weight Loss', _weightLossValue, (val) {
          setState(() => _weightLossValue = val);
        }),
        _buildSlider('Coughing', _coughingValue, (val) {
          setState(() => _coughingValue = val);
        }),
        _buildSlider('Nausea', _nauseaValue, (val) {
          setState(() => _nauseaValue = val);
        }),
        _buildSlider('Drowsiness', _drowsinessValue, (val) {
          setState(() => _drowsinessValue = val);
        }),
        const Divider(thickness: 1.0),
        const Text(
          'Emotional',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            fontFamily: "Outfit",
          ),
        ),
        const SizedBox(height: 10),
        _buildSlider('Depression', _depressionValue, (val) {
          setState(() => _depressionValue = val);
        }),
        _buildSlider('Anxiety', _anxietyValue, (val) {
          setState(() => _anxietyValue = val);
        }),
        _buildSlider('Confusion', _confusionValue, (val) {
          setState(() => _confusionValue = val);
        }),
      ],
    );
  }

  void _submit(String uid) async {
    if (!_formKey.currentState!.validate()) {
      // Validation failed, show error SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please correct the highlighted errors in the vitals form.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userData = await DatabaseService(uid: uid).getUserData();
    if (userData == null) {
      debugPrint('Submit Algo Input No User Data');
      return;
    }

    // Set algo inputs
    _algoInputs['Fever'] =
        (double.parse(_vitalInputs['Temperature']!) > maxTemperature)
            ? true
            : false;
    _algoInputs['Cough'] = (_coughingValue > maxScale) ? true : false;
    _algoInputs['Fatigue'] = (_fatigueValue > maxScale) ? true : false;
    _algoInputs['Difficulty Breathing'] =
        (_shortnessOfBreathValue > maxScale) ? true : false;
    _algoInputs['Age'] = userData.age;
    _algoInputs['Gender'] = userData.gender;

    // Blood Pressure Parsing and Classification
    final parts = _vitalInputs['Blood Pressure']!.split('/');
    final systolic =
        int.tryParse(parts[0].trim()); // Trim spaces before parsing
    final diastolic =
        int.tryParse(parts[1].trim()); // Trim spaces before parsing

    // Check for valid systolic and diastolic values
    if (systolic == null || diastolic == null) {
      debugPrint("Invalid blood pressure input.");
      return;
    }

    // Blood Pressure Classification
    if (systolic < lowBloodPressureSystolic &&
        diastolic < lowBloodPressureDiastolic) {
      _algoInputs['Blood Pressure'] = 'Low';
    } else if (systolic < normalBloodPressureSystolic &&
        diastolic < normalBloodPressureDiastolic) {
      _algoInputs['Blood Pressure'] = 'Normal';
    } else {
      _algoInputs['Blood Pressure'] = 'High';
    }

    double cl = double.parse(_vitalInputs['Cholesterol Level']!);
    if (cl < lowCholesterol) {
      _algoInputs['Cholesterol Level'] = 'Low';
    } else if (cl < normalCholesterol) {
      _algoInputs['Cholesterol Level'] = 'Normal';
    } else {
      _algoInputs['Cholesterol Level'] = 'High';
    }

    // Only after successful validation, prepare data
    _combinedInputs = {
      'Vitals': _vitalInputs,
      'Symptom Assessment': {
        'Diarrhea': _diarrheaValue,
        'Bowel Obstruction': _bowelObstructionValue,
        'Constipation': _constipationValue,
        'Fatigue': _fatigueValue,
        'Shortness of Breath': _shortnessOfBreathValue,
        'Appetite': _appetiteValue,
        'Weight Loss': _weightLossValue,
        'Coughing': _coughingValue,
        'Nausea': _nauseaValue,
        'Drowsiness': _drowsinessValue,
        'Depression': _depressionValue,
        'Anxiety': _anxietyValue,
        'Confusion': _confusionValue,
      },
    };

    // Navigate to the summary screen
    try {
      FocusScope.of(context).unfocus();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptScreen(
            uid: uid,
            inputs: _combinedInputs,
            algoInputs: _algoInputs,
          ),
        ),
      );
      checkAndResetOptions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    }
  }
}
