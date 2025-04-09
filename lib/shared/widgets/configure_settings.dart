import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

class ConfigureSettings extends StatefulWidget {
  const ConfigureSettings({super.key, required this.docName});
  final String docName;

  @override
  State<ConfigureSettings> createState() => _ConfigureSettingsState();
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class _ConfigureSettingsState extends State<ConfigureSettings> {
  List<String> arrName = [];
  String itemName = '';
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
  }

  Widget _buildSections() {
    if (widget.docName == 'Cases') {
      itemName = 'Case';
    } else if (widget.docName == 'Interventions') {
      itemName = 'Intervention';
    } else if (widget.docName == 'Medicines') {
      itemName = 'Medicine';
    } else {
      itemName = '';
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('globals')
          .doc(toCamelCase(widget.docName))
          .get(),
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
          return Center(
            child: Text('No data found', style: Textstyle.body),
          );
        }

        // Extract the keys (array names) from the document
        Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
        List<String> settingOptions = data.keys.toList();

        // Sort the section names alphabetically
        settingOptions.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        // Move "others" to the bottom if it exists
        if (settingOptions.contains('others')) {
          settingOptions.remove('others');
          settingOptions.add('others');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: settingOptions.map((sectionName) {
            final String camelCaseSectionName = sectionName;
            final String displaySectionName = toProperLabel(sectionName);

            return ExpansionTile(
              title: Text(displaySectionName, style: Textstyle.subheader),
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('globals')
                      .doc(toCamelCase(widget.docName))
                      .get(),
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
                      return Center(
                        child: Text('No data found', style: Textstyle.body),
                      );
                    }

                    // Extract the array for the current section
                    Map<String, dynamic> data =
                        snapshot.data!.data() as Map<String, dynamic>;
                    List<String> items =
                        List<String>.from(data[camelCaseSectionName] ?? []);

                    // Check if the list is empty
                    if (items.isEmpty) {
                      return Column(
                        children: [
                          Center(
                            child: Text('$displaySectionName list is empty',
                                style: Textstyle.body),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () =>
                                showAddItemDialog(camelCaseSectionName),
                            child: Text('Add New $itemName',
                                style: Textstyle.body),
                          ),
                        ],
                      );
                    }

                    items.sort((a, b) =>
                        a.toLowerCase().compareTo(b.toLowerCase()));

                    return Column(
                      children: [
                        ...items.asMap().entries.map((entry) {
                          int index = entry.key;
                          String value = entry.value;
                          return ListTile(
                            title: Text(value, style: Textstyle.body),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: AppColors.neon),
                                  onPressed: () => showEditItemDialog(
                                      camelCaseSectionName, index, value),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color: AppColors.red),
                                  onPressed: () =>
                                      deleteItem(camelCaseSectionName, index),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () =>
                              showAddItemDialog(camelCaseSectionName),
                          child: Text('Add New $itemName',
                              style: Textstyle.body),
                        ),
                        const SizedBox(height: 10),
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

  String toProperLabel(String camelCase) {
    return camelCase.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => ' ${match.group(0)}',
    ).capitalize();
  }

  String toCamelCase(String input) {
    return input.split(' ').mapIndexed((index, word) {
      if (index == 0) {
        return word.toLowerCase();
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join();
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
          title: Text('Add New $itemName', style: Textstyle.subheader),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter new $itemName'),
            inputFormatters: _getInputFormatters(sectionName),
            maxLength: _getCharacterLimit(sectionName),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel', style: Textstyle.body),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await addItem(sectionName, controller.text);
                  Navigator.pop(context);
                }
              },
              child: Text('Add', style: Textstyle.body),
            ),
          ],
        );
      },
    );
  }

  void showEditItemDialog(String sectionName, int index, String currentValue) {
    final TextEditingController controller =
        TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $itemName', style: Textstyle.subheader),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Edit $itemName'),
            inputFormatters: _getInputFormatters(sectionName),
            maxLength: _getCharacterLimit(sectionName),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel', style: Textstyle.body),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await editItem(sectionName, index, controller.text);
                  Navigator.pop(context);
                }
              },
              child: Text('Save', style: Textstyle.body),
            ),
          ],
        );
      },
    );
  }

  Future<void> addItem(String sectionName, String newItem) async {
    try {
      // Fetch the entire document from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('globals')
          .doc(toCamelCase(widget.docName))
          .get();

      // Convert the new item to lowercase for comparison
      newItem = newItem.trim(); // Remove leading/trailing spaces
      final String newItemLower = newItem.toLowerCase();
      final Map<String, dynamic> allSections = doc.data() ?? {};

      // Check for duplicates across all sections
      if (widget.docName == 'Cases' || widget.docName == 'Medicine') {
        for (final section in allSections.values) {
          final List<String> sectionItems = List<String>.from(section ?? []);
          if (sectionItems.map((item) => item.toLowerCase()).contains(newItemLower)) {
            showToast('$itemName already exists!', backgroundColor: AppColors.red);
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
          .doc(toCamelCase(widget.docName))
          .update({sectionName: arrName});

      setState(() {});
      showToast('$itemName added!');
    } catch (e) {
      debugPrint('Error adding item: $e');
    }
  }

  Future<void> editItem(String sectionName, int index, String updatedValue) async {
    try {
      // Fetch the entire document from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('globals')
          .doc(toCamelCase(widget.docName))
          .get();

      // Convert the updated value to lowercase for comparison
      updatedValue = updatedValue.trim();
      final String updatedValueLower = updatedValue.toLowerCase();

      final Map<String, dynamic> allSections = doc.data() ?? {};

      // Check for duplicates across all sections
      if (widget.docName == 'Cases' || widget.docName == 'Medicine') {
        for (final section in allSections.entries) {
          final List<String> sectionItems = List<String>.from(section.value ?? []);
          if (section.key == sectionName) {
            // Exclude the current item from the duplicate check
            sectionItems.removeAt(index);
          }
          if (sectionItems.map((item) => item.toLowerCase()).contains(updatedValueLower)) {
            showToast('$itemName already exists!', backgroundColor: AppColors.red);
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
          .doc(toCamelCase(widget.docName))
          .update({sectionName: arrName});

      setState(() {});
      showToast('$itemName successfully edited!');
    } catch (e) {
      debugPrint('Error editing item: $e');
    }
  }

  Future<void> deleteItem(String sectionName, int index) async {
    try {
      // Fetch the current list from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('globals')
          .doc(toCamelCase(widget.docName))
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
                child: Text('Delete', style: Textstyle.body.copyWith(color: AppColors.red)),
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
            .doc(toCamelCase(widget.docName))
            .update({sectionName: arrName});

        setState(() {}); // Trigger UI rebuild
        showToast('$itemName deleted!');
      }
    } catch (e) {
      debugPrint('Error deleting item: $e');
    }
  }

  List<TextInputFormatter> _getInputFormatters(String sectionName) {
    if (widget.docName == 'Vital Thresholds') {
      if (sectionName == 'Oxygen Saturation' || sectionName == 'Temperature') {
        return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]; // Allow decimals
      }
      return [FilteringTextInputFormatter.digitsOnly]; // Allow only integers
    }
    return [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-\(\)\[\]\.,]'))]; // Allow alphanumeric and some special characters
  }

  int _getCharacterLimit(String sectionName) {
    if (widget.docName == 'Cases' || widget.docName == 'Medicines') {
      return 50; // Shorter limit for cases and medicine
    } else if (widget.docName == 'Interventions') {
      return 100; // Longer limit for intervention steps
    } else if (widget.docName == 'Vital Thresholds') {
      return 10; // Limit for numeric inputs
    }
    return 30; // Default limit
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docName, style: Textstyle.subheader),
        backgroundColor: AppColors.white,
      ),
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildSections(),
          ],
        ),
      ),
    );
  }
}