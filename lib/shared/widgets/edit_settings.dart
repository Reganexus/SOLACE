import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textformfield.dart';
import 'package:solace/themes/textstyle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class EditSettings extends StatefulWidget {
  const EditSettings({super.key, required this.docName});
  final String docName;

  @override
  State<EditSettings> createState() => _EditSettingsState();
}

class _EditSettingsState extends State<EditSettings> {
  List<String> arrName = [];
  String docName = '';
  String itemName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.docName == 'Cases') {
      docName = 'cases';
      itemName = 'Case';
    } else if (widget.docName == 'Interventions') {
      docName = 'interventions';
      itemName = 'Intervention';
    } else if (widget.docName == 'Vital Thresholds') {
      docName = 'thresholds';
    } else if (widget.docName == 'Medicines') {
      docName = 'medicines';
      itemName = 'Medicine';
    } else {
      itemName = '';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildSections() {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('globals').doc(docName).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading data', style: Textstyle.body),
          );
        }
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return Center(child: Text('No data found', style: Textstyle.body));
        }

        Map<String, dynamic> data =
            snapshot.data!.data() as Map<String, dynamic>;

        List<String> settingOptions = data.keys.toList();

        if (docName == 'thresholds') {
          const List<String> customOrder = [
            'heartRate',
            'systolic',
            'diastolic',
            'oxygenSaturation',
            'respirationRate',
            'temperature',
            'scale',
          ];

          settingOptions.sort((a, b) {
            final aIndex = customOrder.indexOf(a);
            final bIndex = customOrder.indexOf(b);
            if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
            if (aIndex == -1) return 1;
            if (bIndex == -1) return -1;
            return aIndex.compareTo(bIndex);
          });
        } else {
          // Default alphabetical sort for other documents
          settingOptions.sort(
            (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
          );
          if (settingOptions.contains('others')) {
            settingOptions.remove('others');
            settingOptions.add('others');
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              settingOptions.map((sectionName) {
                final String camelCaseSectionName = sectionName;
                final String displaySectionName = toProperLabel(sectionName);

                return ExpansionTile(
                  title: Text(
                    displaySectionName,
                    style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                  collapsedBackgroundColor: AppColors.white,
                  collapsedIconColor: AppColors.black,
                  shape: Border(),
                  iconColor: AppColors.black,
                  children: [
                    if (widget.docName == 'Vital Thresholds')
                      _buildVitalThresholdEditor(
                        data[camelCaseSectionName] as Map<String, dynamic>,
                        camelCaseSectionName,
                      )
                    else
                      FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('globals')
                                .doc(docName)
                                .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading data',
                                style: Textstyle.body,
                              ),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data?.data() == null) {
                            return Center(
                              child: Text(
                                'No data found',
                                style: Textstyle.body,
                              ),
                            );
                          }

                          Map<String, dynamic> sectionData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          List<String> items = List<String>.from(
                            sectionData[camelCaseSectionName] ?? [],
                          );

                          if (items.isEmpty) {
                            return Column(
                              children: [
                                ElevatedButton(
                                  onPressed:
                                      () => showAddItemDialog(
                                        camelCaseSectionName,
                                      ),
                                  child: Text(
                                    'Add New $itemName',
                                    style: Textstyle.body,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: Text(
                                    '$displaySectionName list is empty',
                                    style: Textstyle.body,
                                  ),
                                ),
                              ],
                            );
                          }

                          items.sort(
                            (a, b) =>
                                a.toLowerCase().compareTo(b.toLowerCase()),
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...items.asMap().entries.map((entry) {
                                int index = entry.key;
                                String value = entry.value;
                                return ListTile(
                                  title: Text(value, style: Textstyle.body),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap:
                                            () => showEditItemDialog(
                                              camelCaseSectionName,
                                              index,
                                              value,
                                            ),
                                        child: Icon(
                                          Icons.edit,
                                          color: AppColors.black.withValues(
                                            alpha: 0.8,
                                          ),
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () async {
                                          final confirm =
                                              await showConfirmationDialog(
                                                context: context,
                                                title: 'Delete Confirmation',
                                                content:
                                                    'Are you sure you want to delete this $itemName?',
                                              );
                                          if (confirm) {
                                            deleteItem(
                                              camelCaseSectionName,
                                              index,
                                            );
                                          }
                                        },
                                        child: Icon(
                                          Icons.delete,
                                          color: AppColors.red,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed:
                                        () => showAddItemDialog(
                                          camelCaseSectionName,
                                        ),
                                    style: Buttonstyle.buttonNeon,
                                    child: Text(
                                      'Add New $displaySectionName',
                                      style: Textstyle.smallButton,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildVitalThresholdEditor(
    Map<String, dynamic> thresholdsMap,
    String vitalName,
  ) {
    final orderedKeys = [
      'maxSevere',
      'maxMild',
      'maxNormal',
      'minNormal',
      'minMild',
      'minSevere',
    ];

    if (vitalName == 'scale') {
      return Column(
        children:
            ['maxMild', 'maxNormal'].map((key) {
              final int? current = (thresholdsMap[key] as num?)?.toInt();
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(key, style: Textstyle.body),
                    DropdownButton<int>(
                      dropdownColor: AppColors.white,
                      value: current,
                      items:
                          List.generate(10, (i) => i + 1)
                              .map(
                                (val) => DropdownMenuItem(
                                  value: val,
                                  child: Text(
                                    val.toString(),
                                    style: Textstyle.body,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (newValue) async {
                        if (newValue == null) return;

                        thresholdsMap[key] = newValue;
                        final mild = thresholdsMap['maxMild'];
                        final normal = thresholdsMap['maxNormal'];

                        if (mild != null && normal != null && mild <= normal) {
                          showToast(
                            'maxMild ($mild) must be greater than maxNormal ($normal)',
                            backgroundColor: AppColors.red,
                          );
                          return;
                        }

                        await FirebaseFirestore.instance
                            .collection('globals')
                            .doc('thresholds')
                            .update({'$vitalName.$key': newValue});

                        setState(() {});
                        showToast('$key updated!');
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
      );
    }

    // Default: other vital thresholds with edit dialogs
    return Column(
      children:
          orderedKeys.where((key) => thresholdsMap.containsKey(key)).map((key) {
            final value = thresholdsMap[key];

            return ListTile(
              title: Text(key, style: Textstyle.body),
              subtitle: Text(value.toString(), style: Textstyle.body),
              trailing: IconButton(
                icon: Icon(Icons.edit, color: AppColors.neon),
                onPressed:
                    () =>
                        _showThresholdEditDialog(vitalName, key, thresholdsMap),
              ),
            );
          }).toList(),
    );
  }

  void _showThresholdEditDialog(
    String vitalName,
    String key,
    Map<String, dynamic> thresholdsMap,
  ) {
    final controller = TextEditingController(
      text: thresholdsMap[key].toString(),
    );
    final sectionName = vitalName;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.white,
            title: Text('Edit $key', style: Textstyle.subheader),
            content: CustomTextField(
              controller: controller,
              focusNode: FocusNode(),
              labelText: sectionName,
              enabled: true,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: _getInputFormatters(sectionName),
              maxLines: 1,
            ),

            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: Buttonstyle.buttonRed,
                      child: Text('Cancel', style: Textstyle.smallButton),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        try {
                          final num parsedValue = num.parse(controller.text);

                          // Validate input for scale bounds
                          if (sectionName == 'scale') {
                            if (parsedValue < 1 || parsedValue > 10) {
                              showToast(
                                '$key must be between 1 and 10',
                                backgroundColor: AppColors.red,
                              );
                              return;
                            }
                          }

                          // Apply value to local copy before checking logic
                          thresholdsMap[key] = parsedValue;

                          if (sectionName == 'scale') {
                            final num mild = thresholdsMap['maxMild'];
                            final num normal = thresholdsMap['maxNormal'];
                            if (mild <= normal) {
                              showToast(
                                'maxMild ($mild) must be greater than maxNormal ($normal)',
                                backgroundColor: AppColors.red,
                              );
                              return;
                            }
                          } else {
                            // Standard order validation for full thresholds
                            final keys = [
                              'maxSevere',
                              'maxMild',
                              'maxNormal',
                              'minNormal',
                              'minMild',
                              'minSevere',
                            ];
                            final values =
                                keys
                                    .map((k) => thresholdsMap[k] as num)
                                    .toList();

                            for (int i = 0; i < values.length - 1; i++) {
                              if (values[i] <= values[i + 1]) {
                                final errorMsg =
                                    '${keys[i]} (${values[i]}) must be greater than ${keys[i + 1]} (${values[i + 1]})';
                                showToast(
                                  errorMsg,
                                  backgroundColor: AppColors.red,
                                );
                                return;
                              }
                            }
                          }

                          // If passed all validation, commit to Firestore
                          await FirebaseFirestore.instance
                              .collection('globals')
                              .doc('thresholds')
                              .update({'$vitalName.$key': parsedValue});

                          setState(() {});
                          Navigator.pop(context);
                          showToast('$key updated!');
                        } catch (e) {
                          showToast(
                            'Invalid input!',
                            backgroundColor: AppColors.red,
                          );
                        }
                      },
                      style: Buttonstyle.buttonNeon,
                      child: Text('Save', style: Textstyle.smallButton),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  String toProperLabel(String camelCase) {
    return camelCase
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
        .capitalize();
  }

  void showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  void showAddItemDialog(String sectionName) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text('Add New $itemName', style: Textstyle.subheader),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: controller,
                  focusNode: FocusNode(),
                  labelText: 'Enter new $itemName',
                  enabled: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                  maxLength: _getCharacterLimit(sectionName),
                  keyboardType: TextInputType.text,
                  readOnly: false,
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: Buttonstyle.buttonRed,
                    child: Text('Cancel', style: Textstyle.smallButton),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      if (controller.text.isNotEmpty) {
                        final confirm = await showConfirmationDialog(
                          context: context,
                          title: 'Add Confirmation',
                          content:
                              'Are you sure you want to add this $itemName?',
                        );
                        if (confirm) {
                          await addItem(sectionName, controller.text);
                          Navigator.pop(context);
                        }
                      }
                    },
                    style: Buttonstyle.buttonNeon,
                    child: Text('Add', style: Textstyle.smallButton),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void showEditItemDialog(String sectionName, int index, String currentValue) {
    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text('Edit $itemName', style: Textstyle.subheader),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: controller,
                  focusNode: FocusNode(),
                  labelText: 'Edit $itemName',
                  enabled: true,
                  validator: (value) {
                    if (controller.text.isEmpty) {
                      showToast(
                        'This cannot be empty.',
                        backgroundColor: AppColors.red,
                      );
                    }
                    return null;
                  },
                  keyboardType: TextInputType.text,
                  readOnly: false,
                  maxLength: _getCharacterLimit(sectionName),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: Buttonstyle.buttonRed,
                    child: Text('Cancel', style: Textstyle.smallButton),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      if (controller.text.isNotEmpty) {
                        final confirm = await showConfirmationDialog(
                          context: context,
                          title: 'Edit Confirmation',
                          content:
                              'Are you sure you want to save changes to this $itemName?',
                        );
                        if (confirm) {
                          await editItem(sectionName, index, controller.text);
                          Navigator.pop(context);
                        }
                      }
                    },
                    style: Buttonstyle.buttonNeon,
                    child: Text('Save', style: Textstyle.smallButton),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text(title, style: Textstyle.subheader),
              content: Text(content, style: Textstyle.body),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        style: Buttonstyle.buttonRed,
                        child: Text('Cancel', style: Textstyle.smallButton),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        style: Buttonstyle.buttonNeon,
                        child: Text('Confirm', style: Textstyle.smallButton),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> addItem(String sectionName, String newItem) async {
    try {
      // Fetch the entire document from Firestore
      final doc =
          await FirebaseFirestore.instance
              .collection('globals')
              .doc(docName)
              .get();

      // Convert the new item to lowercase for comparison
      newItem = newItem.trim(); // Remove leading/trailing spaces
      final String newItemLower = newItem.toLowerCase();
      final Map<String, dynamic> allSections = doc.data() ?? {};

      // Check for duplicates across all sections
      if (widget.docName == 'Cases' || widget.docName == 'Medicines') {
        for (final section in allSections.values) {
          final List<String> sectionItems = List<String>.from(section ?? []);
          if (sectionItems
              .map((item) => item.toLowerCase())
              .contains(newItemLower)) {
            showToast(
              '$itemName already exists!',
              backgroundColor: AppColors.red,
            );
            return;
          }
        }
      }

      // Initialize arrName with the current section's data
      arrName = List<String>.from(allSections[sectionName] ?? []);

      // Add the new item and sort alphabetically
      arrName.add(newItem);
      arrName.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('globals')
          .doc(docName)
          .update({sectionName: arrName});

      setState(() {});
      showToast('$itemName added!');
    } catch (e) {
      //       debugPrint('Error adding item: $e');
    }
  }

  Future<void> editItem(
    String sectionName,
    int index,
    String updatedValue,
  ) async {
    try {
      // Fetch the entire document from Firestore
      final doc =
          await FirebaseFirestore.instance
              .collection('globals')
              .doc(docName)
              .get();

      // Convert the updated value to lowercase for comparison
      updatedValue = updatedValue.trim();
      final String updatedValueLower = updatedValue.toLowerCase();

      final Map<String, dynamic> allSections = doc.data() ?? {};

      // Check for duplicates across all sections
      if (widget.docName == 'Cases' || widget.docName == 'Medicines') {
        for (final section in allSections.entries) {
          final List<String> sectionItems = List<String>.from(
            section.value ?? [],
          );
          if (section.key == sectionName) {
            // Exclude the current item from the duplicate check
            sectionItems.removeAt(index);
          }
          if (sectionItems
              .map((item) => item.toLowerCase())
              .contains(updatedValueLower)) {
            showToast(
              '$itemName already exists!',
              backgroundColor: AppColors.red,
            );
            return;
          }
        }
      }

      // Initialize arrName with the current section's data
      arrName = List<String>.from(allSections[sectionName] ?? []);

      // Update the item and sort alphabetically
      arrName[index] = updatedValue;
      arrName.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('globals')
          .doc(docName)
          .update({sectionName: arrName});

      setState(() {});
      showToast('$itemName successfully edited!');
    } catch (e) {
      //       debugPrint('Error editing item: $e');
    }
  }

  Future<void> deleteItem(String sectionName, int index) async {
    try {
      // Fetch the current list from Firestore
      final doc =
          await FirebaseFirestore.instance
              .collection('globals')
              .doc(docName)
              .get();

      // Initialize arrName with the current data
      arrName = List<String>.from(doc.data()?[sectionName] ?? []);

      // Check if the index is valid
      if (index < 0 || index >= arrName.length) {
        showToast('Invalid item index!', backgroundColor: AppColors.red);
        return;
      }

      final String itemToDelete = arrName[index]; // Get the item to delete

      // Show confirmation dialog
      final bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Delete $itemName', style: Textstyle.subheader),
            content: Text(
              'Are you sure you want to delete "$itemToDelete"?',
              style: Textstyle.body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // Cancel
                child: Text('Cancel', style: Textstyle.body),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true), // Confirm
                child: Text(
                  'Delete',
                  style: Textstyle.body.copyWith(color: AppColors.red),
                ),
              ),
            ],
          );
        },
      );

      // If the user confirms, proceed with deletion
      if (confirmDelete == true) {
        // Remove the item
        arrName.removeAt(index);

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('globals')
            .doc(docName)
            .update({sectionName: arrName});

        setState(() {}); // Trigger UI rebuild
        showToast('$itemName deleted!');
      }
    } catch (e) {
      //       debugPrint('Error deleting item: $e');
    }
  }

  List<TextInputFormatter> _getInputFormatters(String sectionName) {
    if (widget.docName == 'Vital Thresholds') {
      if (sectionName == 'scale') {
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ]; // 1-10 allowed by validation logic later
      }

      if (sectionName == 'temperature') {
        return [
          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?')),
          LengthLimitingTextInputFormatter(5), // max 5 characters total
        ];
      }
      return [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3), // max 3-digit integer
      ];
    }
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-\(\)\[\]\.,]')),
    ];
  }

  int _getCharacterLimit(String sectionName) {
    if (widget.docName == 'Cases' || widget.docName == 'Medicines') {
      return 50; // Shorter limit for cases and medicine
    } else if (widget.docName == 'Interventions') {
      return 100; // Longer limit for intervention steps
    } else if (widget.docName == 'Vital Thresholds') {
      return 5; // Limit for numeric inputs
    }
    return 30; // Default limit
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.docName}', style: Textstyle.subheader),
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        backgroundColor: AppColors.white,
      ),
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(child: _buildSections()),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
