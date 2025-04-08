import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class CasePickerWidget extends StatefulWidget {
  final List<String> selectedCases;
  final void Function(String) onAddCase;
  final void Function(String) onRemoveCase;
  final FormFieldValidator<List<String>>? validator;
  final bool enabled;

  const CasePickerWidget({
    super.key,
    required this.selectedCases,
    required this.onAddCase,
    required this.onRemoveCase,
    required this.validator,
    required this.enabled,
  });

  @override
  CasePickerWidgetState createState() => CasePickerWidgetState();
}

class CasePickerWidgetState extends State<CasePickerWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool showDropdown = false;

  final List<String> allCases = [];
  List<String> filteredCases = [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        showDropdown = _searchFocusNode.hasFocus;
      });
    });
    _fetchCasesFromFirestore();
    _updateFilteredCases();
  }

  void _fetchCasesFromFirestore() async {
    try {
      DocumentSnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('globals')
              .doc('cases')
              .get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        // Combine all arrays into one flat list
        List<String> combinedCases = [];

        for (var value in data.values) {
          if (value is List) {
            combinedCases.addAll(List<String>.from(value));
          }
        }

        setState(() {
          allCases.clear();
          allCases.addAll(combinedCases);
          _updateFilteredCases();
        });
      }
    } catch (e) {
      debugPrint('Error fetching cases: $e');
    }
  }

  String _getBaseCaseName(String caseItem) {
    return caseItem.split('(')[0].trim();
  }

  void _updateFilteredCases() {
    setState(() {
      List<String> selectedBaseNames =
          widget.selectedCases.map(_getBaseCaseName).toSet().toList();
      filteredCases =
          allCases.where((c) {
            String baseName = _getBaseCaseName(c);
            return !selectedBaseNames.contains(baseName);
          }).toList();
    });
  }

  void _addCase(String caseItem) {
    String baseName = _getBaseCaseName(caseItem);

    // Remove all existing cases with the same base name
    List<String> toRemove =
        widget.selectedCases
            .where((c) => _getBaseCaseName(c) == baseName)
            .toList();
    for (String c in toRemove) {
      widget.onRemoveCase(c);
    }

    // Add the selected case
    widget.onAddCase(caseItem);

    _searchController.clear();
    _updateFilteredCases();
  }

  void _removeCase(String caseItem) {
    widget.onRemoveCase(caseItem);
    _updateFilteredCases(); // Restore all variants when removed
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      validator: widget.validator,
      initialValue: widget.selectedCases, // Ensure initial value is passed
      builder: (FormFieldState<List<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8.0,
              children:
                  widget.selectedCases
                      .map(
                        (caseItem) => Chip(
                          backgroundColor: AppColors.gray,
                          label: Text(caseItem, style: Textstyle.bodySmall),
                          deleteIcon: Icon(Icons.close),
                          onDeleted: () => _removeCase(caseItem),
                        ),
                      )
                      .toList(),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              enabled: widget.enabled,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Add Case',
                filled: true,
                fillColor: AppColors.gray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.neon, width: 2),
                ),
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color:
                      _searchFocusNode.hasFocus
                          ? AppColors.neon
                          : AppColors.black,
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty || showDropdown == true
                        ? IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                              showDropdown = false;
                            });
                          },
                        )
                        : null,
              ),
            ),

            const SizedBox(height: 5),

            if (showDropdown && filteredCases.isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredCases.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(filteredCases[index]),
                      onTap: () => _addCase(filteredCases[index]),
                    );
                  },
                ),
              ),

            // Display validation error if any
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text(
                  state.errorText ?? '',
                  style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Filters the dropdown list based on search query
  void _onSearchChanged(String query) {
    setState(() {
      List<String> selectedBaseNames =
          widget.selectedCases.map(_getBaseCaseName).toSet().toList();
      filteredCases =
          allCases
              .where(
                (caseItem) =>
                    caseItem.toLowerCase().contains(query.toLowerCase()) &&
                    !selectedBaseNames.contains(_getBaseCaseName(caseItem)),
              )
              .toList();
    });
  }
}
