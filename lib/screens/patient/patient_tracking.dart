// ignore_for_file: use_build_context_synchronously, unused_import, avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solace/controllers/notification_service.dart';
import 'package:solace/services/database.dart';
import 'package:solace/screens/patient/patient_input_summary.dart';
import 'package:solace/shared/globals.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:solace/controllers/messaging_service.dart';
import 'package:solace/themes/inputdecoration.dart';
import 'package:solace/themes/textstyle.dart';

class PatientTracking extends StatefulWidget {
  final String patientId;
  const PatientTracking({super.key, required this.patientId});

  @override
  PatientTrackingState createState() => PatientTrackingState();
}

class PatientTrackingState extends State<PatientTracking> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService databaseService = DatabaseService();
  final notificationService = NotificationService();
  late PageController _pageController;
  int _currentPage = 0;

  bool isCooldownActive = false;
  int remainingCooldownTime = 0;
  Timer? _countdownTimer;

  final Map<String, String> _vitalInputs = {
    'Heart Rate': '',
    'Systolic': '',
    'Diastolic': '',
    'Oxygen Saturation': '',
    'Respiration': '',
    'Temperature': '',
    'Pain': '0',
  };

  final Map<String, TextEditingController> _controllers = {
    'Heart Rate': TextEditingController(),
    'Systolic': TextEditingController(),
    'Diastolic': TextEditingController(),
    'Oxygen Saturation': TextEditingController(),
    'Respiration': TextEditingController(),
    'Temperature': TextEditingController(),
    'Pain': TextEditingController(),
  };

  final Map<String, dynamic> _algoInputs = {
    "Gender": null,
    "Age": null,
    "Temperature": null,
    "Oxygen Saturation": null,
    "Heart Rate": null,
    "Respiration": null,
    "Systolic": null,
    "Diastolic": null,
  };

  final Map<String, FocusNode> _focusNodes = {
    'Heart Rate': FocusNode(),
    'Systolic': FocusNode(),
    'Diastolic': FocusNode(),
    'Oxygen Saturation': FocusNode(),
    'Respiration': FocusNode(),
    'Temperature': FocusNode(),
    'Pain': FocusNode(),
  };

  int _diarrheaValue = 0;
  int _constipationValue = 0;
  int _fatigueValue = 0;
  int _shortnessOfBreathValue = 0;
  int _poorAppetiteValue = 0;
  int _coughingValue = 0;
  int _nauseaValue = 0;
  int _depressionValue = 0;
  int _anxietyValue = 0;
  int _confusionValue = 0;
  int _insomniaValue = 0;

  late Map<String, dynamic> _combinedInputs;

  @override
  void initState() {
    super.initState();
    _initializeCooldown();
    _loadCachedData();
    _pageController = PageController(initialPage: _currentPage);

    // Add navigation listener
    _pageController.addListener(() {
      final newPage = _pageController.page?.round() ?? 0;
      if (newPage != _currentPage) {
        setState(() {
          _currentPage = newPage;
        });

        // Log or handle page change
        debugPrint('Navigated to page: $_currentPage');
      }
    });

    debugPrint('Tracking patient id: ${widget.patientId}');
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
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load cached vital inputs
    for (var key in _vitalInputs.keys) {
      String cachedValue = prefs.getString('${key}_${widget.patientId}') ?? '';

      // Check if the key is not related to the Pain slider before updating the text controller
      if (key != 'Pain') {
        setState(() {
          _vitalInputs[key] = cachedValue;
          _controllers[key]?.text =
              cachedValue; // Set value to the text controller
        });
      }
    }

    // Load cached symptom slider values
    setState(() {
      // Reset Pain slider value to 0, but do not change the text controller
      _diarrheaValue = prefs.getInt('Diarrhea_${widget.patientId}') ?? 0;
      _constipationValue =
          prefs.getInt('Constipation_${widget.patientId}') ?? 0;
      _fatigueValue = prefs.getInt('Fatigue_${widget.patientId}') ?? 0;
      _shortnessOfBreathValue =
          prefs.getInt('Shortness of Breath_${widget.patientId}') ?? 0;
      _poorAppetiteValue =
          prefs.getInt('Poor Appetite_${widget.patientId}') ?? 0;
      _coughingValue = prefs.getInt('Coughing_${widget.patientId}') ?? 0;
      _nauseaValue = prefs.getInt('Nausea_${widget.patientId}') ?? 0;
      _depressionValue = prefs.getInt('Depression_${widget.patientId}') ?? 0;
      _anxietyValue = prefs.getInt('Anxiety_${widget.patientId}') ?? 0;
      _confusionValue = prefs.getInt('Confusion_${widget.patientId}') ?? 0;
      _insomniaValue = prefs.getInt('Insomnia_${widget.patientId}') ?? 0;

      if (_controllers.containsKey('Pain')) {
        _controllers['Pain']?.text = '';
      }
    });

    FocusScope.of(context).unfocus();

    debugPrint("Loaded cached vitals: $_vitalInputs");
    debugPrint(
      "Loaded cached symptoms: $_diarrheaValue, $_constipationValue, $_fatigueValue",
    );
  }

  void checkAndResetOptions() {
    setState(() {
      for (var controller in _controllers.values) {
        controller.clear();
      }

      _diarrheaValue = 0;
      _constipationValue = 0;
      _fatigueValue = 0;
      _shortnessOfBreathValue = 0;
      _poorAppetiteValue = 0;
      _coughingValue = 0;
      _nauseaValue = 0;
      _depressionValue = 0;
      _anxietyValue = 0;
      _confusionValue = 0;
      _insomniaValue = 0;
    });
  }

  Future<void> _initializeCooldown() async {
    final lastSubmitted = await getLastSubmittedTime(widget.patientId);
    debugPrint("Last submitted: $lastSubmitted");

    if (!mounted) return;

    if (lastSubmitted == 0) {
      setState(() {
        isCooldownActive = false;
      });
    } else {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeDifference = currentTime - lastSubmitted;

      // Set the cooldown period to 1 minute (60 seconds)
      final cooldownDuration = 60 * 1000; // 1 minute in milliseconds

      if (timeDifference < cooldownDuration) {
        setState(() {
          isCooldownActive = true;
          remainingCooldownTime =
              (cooldownDuration / 1000).round() -
              (timeDifference / 1000).round(); // Remaining time in seconds
        });
        debugPrint("Remaining Cooldown: $remainingCooldownTime");
        _startCountdown();

        // Call the async method outside setState
        await databaseService.clearTrackingCache(widget.patientId);
        checkAndResetOptions();
      } else {
        setState(() {
          isCooldownActive = false;
        });
      }
    }
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
      final userDoc =
          await FirebaseFirestore.instance
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

  void _sendCooldownLiftedNotification() async {
    debugPrint("Running send cooldown lifted notification");
    try {
      final String? targetToken = await FirebaseMessaging.instance.getToken();

      if (targetToken == null) {
        print(
          'Error: FCM token is null. Ensure Firebase is initialized properly.',
        );
        return;
      }

      DocumentSnapshot doc =
          await _firestore.collection('patient').doc(widget.patientId).get();
      String fName = doc.get('firstName');
      String lName = doc.get('lastName');
      String patientName = '$fName $lName';

      await notificationService.sendNotificationToTaggedUsers(
        widget.patientId,
        "Cooldown Lifted",
        "You can track patient $patientName now.",
      );

      debugPrint("Cooldown lifted notification sent successfully.");
    } catch (e, stackTrace) {
      print('Failed to send notification: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Widget _buildVitalsInputs() {
    return Column(
      children: [
        _buildVitalInputField('Heart Rate'),
        Row(
          children: [
            Expanded(child: _buildVitalInputField('Systolic')),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(' / ', style: Textstyle.body),
            ),
            Expanded(child: _buildVitalInputField('Diastolic')),
          ],
        ),
        _buildVitalInputField('Oxygen Saturation'),
        _buildVitalInputField('Respiration'),
        _buildVitalInputField('Temperature'),
        _buildVitalInputField('Pain'),
      ],
    );
  }

  Widget _buildVitalInputField(String key) {
    final controller = _controllers[key]!;
    final focusNode = _focusNodes[key]!;

    String unitLabel = '';
    List<String? Function(String?)> validators = [
      FormBuilderValidators.required(),
    ];

    List<TextInputFormatter> inputFormatters = [];

    switch (key) {
      case 'Temperature':
        unitLabel = '°C';
        validators.addAll([
          FormBuilderValidators.numeric(),
          FormBuilderValidators.between(
            minPossibleTemperature,
            maxPossibleTemperature,
          ),
          FormBuilderValidators.maxLength(5),
        ]);
        inputFormatters.add(
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}$')),
        );
        break;
      case 'Heart Rate':
        unitLabel = 'bpm';
        validators.addAll([
          FormBuilderValidators.integer(),
          FormBuilderValidators.between(
            minPossibleHeartRate,
            maxPossibleHeartRate,
          ),
          FormBuilderValidators.maxLength(3),
        ]);
        inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
        break;
      case 'Systolic':
        unitLabel = 'mmHg';
        validators.addAll([
          FormBuilderValidators.integer(),
          FormBuilderValidators.between(
            minPossibleBloodPressureSystolic,
            maxPossibleBloodPressureSystolic,
          ),
        ]);
        inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
        break;
      case 'Diastolic':
        unitLabel = 'mmHg';
        validators.addAll([
          FormBuilderValidators.integer(),
          FormBuilderValidators.between(
            minPossibleBloodPressureDiastolic,
            maxPossibleBloodPressureDiastolic,
          ),
        ]);
        inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
        break;
      case 'Oxygen Saturation':
        unitLabel = '%';
        validators.addAll([
          FormBuilderValidators.numeric(),
          FormBuilderValidators.between(
            minPossibleOxygenSaturation,
            maxPossibleOxygenSaturation,
          ),
          FormBuilderValidators.maxLength(5),
        ]);
        inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
        break;
      case 'Respiration':
        unitLabel = 'b/min';
        validators.addAll([
          FormBuilderValidators.integer(),
          FormBuilderValidators.between(
            minPossibleRespirationRate,
            maxPossibleRespirationRate,
          ),
          FormBuilderValidators.maxLength(3),
        ]);
        inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
        break;
      case 'Pain':
        int painValue = double.tryParse(_vitalInputs[key] ?? '0')?.round() ?? 0;
        return Column(
          children: [
            SizedBox(height: 10.0),
            _buildSlider('Pain', painValue, (newValue) {
              setState(() {
                _vitalInputs[key] = newValue.round().toString();
                debugPrint("Updated Pain value: ${_vitalInputs[key]}");
                debugPrint("Current _vitalInputs: $_vitalInputs");
              });
            }),
          ],
        );

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
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecorationStyles.build(
                    key,
                    focusNode,
                  ).copyWith(
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.neon,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: FormBuilderValidators.compose(validators),
                  inputFormatters: inputFormatters,
                  onChanged: (value) {
                    setState(() {});
                    _vitalInputs[key] = value;
                  },
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
        return Colors.amber; // Moderate intensity
      } else if (value <= 8) {
        return Colors.orange; // High intensity
      } else {
        return Colors.red; // Very high intensity
      }
    }

    Color sliderColor = getIndicatorColor(value);

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
                  thumbColor: sliderColor,
                  activeTrackColor: sliderColor.withValues(alpha: 0.8),
                  inactiveTrackColor: sliderColor.withValues(alpha: 0.3),
                  valueIndicatorColor: sliderColor,
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  trackHeight: 20,
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 10,
                  ),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 13,
                  ),
                  valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                ),
                child: Slider(
                  value: value.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: value.toString(),
                  onChanged: (val) => onChanged(val.toInt()),
                ),
              ),
            ),
            const SizedBox(width: 20),
            DropdownButton<int>(
              dropdownColor: AppColors.white,
              value: value,
              items:
                  List.generate(11, (index) => index).map((val) {
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
        Text('Physical', style: Textstyle.subheader),
        const SizedBox(height: 10),
        _buildSlider('Diarrhea', _diarrheaValue, (val) {
          setState(() => _diarrheaValue = val);
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
        _buildSlider('Poor Appetite', _poorAppetiteValue, (val) {
          setState(() => _poorAppetiteValue = val);
        }),
        _buildSlider('Coughing', _coughingValue, (val) {
          setState(() => _coughingValue = val);
        }),
        _buildSlider('Nausea', _nauseaValue, (val) {
          setState(() => _nauseaValue = val);
        }),
        const SizedBox(height: 10),
        const Divider(thickness: 1.0),
        const SizedBox(height: 10),
        Text('Emotional', style: Textstyle.subheader),
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
        _buildSlider('Insomnia', _insomniaValue, (val) {
          setState(() => _insomniaValue = val);
        }),
      ],
    );
  }

  void _submit(String uid) async {
    if (!_formKey.currentState!.saveAndValidate()) {
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
    final patientData = await DatabaseService().getPatientData(
      widget.patientId,
    );
    if (patientData == null) {
      debugPrint('Submit Algo Input No User Data');
      return;
    }

    // Blood Pressure Parsing and Classification
    final systolic = int.tryParse(_vitalInputs['Systolic'] ?? '');
    final diastolic = int.tryParse(_vitalInputs['Diastolic'] ?? '');

    debugPrint('Systolic value: ${_vitalInputs['Systolic']}');
    debugPrint('Diastolic value: ${_vitalInputs['Diastolic']}');
    debugPrint('Parsed systolic: $systolic');
    debugPrint('Parsed diastolic: $diastolic');

    if (systolic == null || diastolic == null) {
      debugPrint("Invalid blood pressure inputs.");
      return;
    }

    // Set algo inputs
    _algoInputs['Gender'] = patientData.gender;
    _algoInputs['Age'] = patientData.age;
    _algoInputs['Temperature'] = _vitalInputs['Temperature'];
    _algoInputs['Oxygen Saturation'] = _vitalInputs['Oxygen Saturation'];
    _algoInputs['Heart Rate'] = _vitalInputs['Heart Rate'];
    _algoInputs['Respiration'] = _vitalInputs['Respiration'];
    _algoInputs['Systolic'] = systolic;
    _algoInputs['Diastolic'] = diastolic;

    _combinedInputs = {
      'Vitals': _vitalInputs,
      'Symptom Assessment': {
        'Diarrhea': _diarrheaValue,
        'Constipation': _constipationValue,
        'Fatigue': _fatigueValue,
        'Shortness of Breath': _shortnessOfBreathValue,
        'Poor Appetite': _poorAppetiteValue,
        'Coughing': _coughingValue,
        'Nausea': _nauseaValue,
        'Depression': _depressionValue,
        'Anxiety': _anxietyValue,
        'Confusion': _confusionValue,
        'Insomnia': _insomniaValue,
      },
    };

    // Cache the data
    await databaseService.cacheTrackingData(
      userId: uid,
      vitalInputs: _vitalInputs,
      symptomValues: {
        'Diarrhea': _diarrheaValue,
        'Constipation': _constipationValue,
        'Fatigue': _fatigueValue,
        'Shortness of Breath': _shortnessOfBreathValue,
        'Poor Appetite': _poorAppetiteValue,
        'Coughing': _coughingValue,
        'Nausea': _nauseaValue,
        'Depression': _depressionValue,
        'Anxiety': _anxietyValue,
        'Confusion': _confusionValue,
        'Insomnia': _insomniaValue,
      },
    );

    // Navigate to the summary screen
    try {
      FocusScope.of(context).unfocus();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ReceiptScreen(
                uid: uid,
                inputs: _combinedInputs,
                algoInputs: _algoInputs,
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    }
  }

  Future<void> _showConfirmationDialog() async {
    bool shouldSubmit =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text('Confirm Submission', style: Textstyle.subheader),
              content: Text(
                'Are you sure you want to submit the data?',
                style: Textstyle.body,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: Buttonstyle.buttonRed,
                        child: Text('Cancel', style: Textstyle.smallButton),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: Buttonstyle.buttonNeon,
                        child: Text('Submit', style: Textstyle.smallButton),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldSubmit) {
      _submit(widget.patientId);
    }
  }

  bool _hasValues() {
    bool vitalInputsHaveValues = _vitalInputs.values.every((value) {
      bool isNotEmpty = value.isNotEmpty;
      return isNotEmpty;
    });

    bool hasValues = vitalInputsHaveValues;
    return hasValues;
  }

  Widget _buildCooldownContainer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: AppColors.gray,
      ),
      child: Column(
        children: [
          Text(
            'You cannot input vitals and assessment at the moment.',
            textAlign: TextAlign.center,
            style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            _formatCooldownTime(remainingCooldownTime),
            textAlign: TextAlign.center,
            style: Textstyle.body,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientNotAvailable() {
    return Container(
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
              children: [
                Text(
                  'Patient is not Available',
                  textAlign: TextAlign.center,
                  style: Textstyle.body,
                ),
                SizedBox(height: 10),
                Text(
                  'Go to "Patient" at Home',
                  textAlign: TextAlign.center,
                  style: Textstyle.bodySmall,
                ),
              ],
            ),
          ),
          SizedBox(height: 20.0),
        ],
      ),
    );
  }

  Widget _buildVitalsInfo() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/images/auth/notes.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(color: AppColors.black.withValues(alpha: 0.4)),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Vital Assessment',
                style: Textstyle.subheader.copyWith(color: AppColors.white),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Assess patient vitals. Fill in all the tracked vital inputs',
                style: Textstyle.body.copyWith(color: AppColors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomManagementInfo() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/images/auth/task.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(color: AppColors.black.withValues(alpha: 0.4)),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Symptom Assessment',
                style: Textstyle.subheader.copyWith(color: AppColors.white),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Assess patient symptoms through Physical and Emotional Assessment',
                style: Textstyle.body.copyWith(color: AppColors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationCircles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap:
                  _hasValues()
                      ? () {
                        setState(() {
                          _currentPage = 0;
                          _pageController.jumpToPage(_currentPage);
                        });
                      }
                      : null,
              child: Container(
                color: AppColors.white,
                child: Column(
                  children: [
                    Text(
                      "Step 1: Vitals",
                      style:
                          _currentPage == 0
                              ? Textstyle.bodySmall.copyWith(
                                color: AppColors.neon,
                                fontWeight: FontWeight.bold,
                              )
                              : Textstyle.bodySmall.copyWith(
                                color: AppColors.blackTransparent,
                              ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color:
                            _currentPage == 0
                                ? AppColors.neon
                                : AppColors.blackTransparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 5),
          Expanded(
            child: GestureDetector(
              onTap:
                  _hasValues()
                      ? () {
                        setState(() {
                          _currentPage = 1;
                          _pageController.jumpToPage(_currentPage);
                        });
                      }
                      : null,
              child: Container(
                color: AppColors.white,
                child: Column(
                  children: [
                    Text(
                      "Step 2: Symptoms",
                      style:
                          _currentPage == 1
                              ? Textstyle.bodySmall.copyWith(
                                color: AppColors.neon,
                                fontWeight: FontWeight.bold,
                              )
                              : Textstyle.bodySmall.copyWith(
                                color: AppColors.blackTransparent,
                              ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color:
                            _currentPage == 1
                                ? AppColors.neon
                                : AppColors.blackTransparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingForm(bool hasData) {
    return Expanded(
      child: PageView(
        controller: _pageController,
        children: [
          // First Page
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVitalsInfo(),
                const SizedBox(height: 20.0),
                Text('Vitals', style: Textstyle.subheader),
                const SizedBox(height: 10.0),
                _buildVitalsInputs(),
                const SizedBox(height: 10.0),
                const Divider(),
                const SizedBox(height: 10.0),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed:
                        _hasValues()
                            ? () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            }
                            : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor:
                          hasData && _hasValues()
                              ? AppColors.neon
                              : AppColors.blackTransparent,
                    ),
                    child: Text('Next', style: Textstyle.largeButton),
                  ),
                ),
              ],
            ),
          ),
          // Second Page
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSymptomManagementInfo(),
                const SizedBox(height: 20.0),
                _buildSliders(),
                const SizedBox(height: 20.0),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed:
                        hasData && _hasValues()
                            ? () => _showConfirmationDialog()
                            : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor:
                          hasData && _hasValues()
                              ? AppColors.neon
                              : AppColors.blackTransparent,
                    ),
                    child: Text('Submit', style: Textstyle.largeButton),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          title: Text('Patient Tracking', style: Textstyle.subheader),
          centerTitle: true,
          backgroundColor: AppColors.white,
          scrolledUnderElevation: 0.0,
        ),
        body: FormBuilder(
          key: _formKey,
          child: StreamBuilder<DocumentSnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('patient')
                    .doc(widget.patientId)
                    .snapshots(),
            builder: (context, snapshot) {
              final hasData = snapshot.hasData && snapshot.data!.exists;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCooldownActive) _buildCooldownContainer(),
                  if (!isCooldownActive)
                    Expanded(
                      child:
                          hasData
                              ? Column(
                                children: [
                                  _buildNavigationCircles(),
                                  SizedBox(height: 20),
                                  _buildTrackingForm(hasData),
                                ],
                              )
                              : _buildPatientNotAvailable(),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
