import 'package:flutter/material.dart';

class CasePickerWidget extends StatefulWidget {
  final List<String> selectedCases;
  final void Function(String) onAddCase;
  final void Function(String) onRemoveCase;
  final FormFieldValidator<List<String>>? validator;

  const CasePickerWidget({
    super.key,
    required this.selectedCases,
    required this.onAddCase,
    required this.onRemoveCase,
    this.validator,
  });

  @override
  CasePickerWidgetState createState() => CasePickerWidgetState();
}

class CasePickerWidgetState extends State<CasePickerWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool showDropdown = false;

  final List<String> allCases = [
    // **Cancer (AJCC TNM Staging for Solid Tumors)**
    'Lung Cancer (Stage 0)', 'Lung Cancer (Stage I)', 'Lung Cancer (Stage II)', 'Lung Cancer (Stage III)', 'Lung Cancer (Stage IV)',
    'Colon Cancer (Stage 0)', 'Colon Cancer (Stage I)', 'Colon Cancer (Stage II)', 'Colon Cancer (Stage III)', 'Colon Cancer (Stage IV)',
    'Pancreatic Cancer (Stage 0)', 'Pancreatic Cancer (Stage I)', 'Pancreatic Cancer (Stage II)', 'Pancreatic Cancer (Stage III)', 'Pancreatic Cancer (Stage IV)',
    'Breast Cancer (Stage 0)', 'Breast Cancer (Stage I)', 'Breast Cancer (Stage II)', 'Breast Cancer (Stage III)', 'Breast Cancer (Stage IV)',
    'Prostate Cancer (Localized)', 'Prostate Cancer (Locally Advanced)', 'Prostate Cancer (Metastatic)',
    'Ovarian Cancer (Stage I)', 'Ovarian Cancer (Stage II)', 'Ovarian Cancer (Stage III)', 'Ovarian Cancer (Stage IV)',
    'Brain Tumor (WHO Grade 1)', 'Brain Tumor (WHO Grade 2)', 'Brain Tumor (WHO Grade 3)', 'Brain Tumor (WHO Grade 4 - Glioblastoma)',
    'Leukemia (Acute Lymphoblastic)', 'Leukemia (Acute Myeloid)', 'Leukemia (Chronic Lymphocytic)', 'Leukemia (Chronic Myeloid)',
    'Lymphoma (Stage I)', 'Lymphoma (Stage II)', 'Lymphoma (Stage III)', 'Lymphoma (Stage IV)',
    'Skin Cancer (Basal Cell)', 'Skin Cancer (Squamous Cell)', 'Melanoma (Stage I)', 'Melanoma (Stage II)', 'Melanoma (Stage III)', 'Melanoma (Stage IV)',
    'Bladder Cancer (Non-Invasive)', 'Bladder Cancer (Invasive)', 'Bladder Cancer (Metastatic)',
    
    // **Cardiovascular & Pulmonary Diseases**
    'Heart Failure (NYHA Class I)', 'Heart Failure (NYHA Class II)', 'Heart Failure (NYHA Class III)', 'Heart Failure (NYHA Class IV)',
    'Stroke (Ischemic)', 'Stroke (Hemorrhagic)',
    'Atrial Fibrillation (Paroxysmal)', 'Atrial Fibrillation (Persistent)', 'Atrial Fibrillation (Permanent)',
    'Hypertension (Stage 1)', 'Hypertension (Stage 2)', 'Hypertension (Hypertensive Crisis)',
    'COPD (GOLD Stage 1 - Mild)', 'COPD (GOLD Stage 2 - Moderate)', 'COPD (GOLD Stage 3 - Severe)', 'COPD (GOLD Stage 4 - Very Severe)',
    'Pulmonary Fibrosis (Early)', 'Pulmonary Fibrosis (Advanced)',

    // **Neurological Disorders**
    'Alzheimer’s Disease (Mild)', 'Alzheimer’s Disease (Moderate)', 'Alzheimer’s Disease (Severe)',
    'Parkinson’s Disease (Stage 1)', 'Parkinson’s Disease (Stage 2)', 'Parkinson’s Disease (Stage 3)', 'Parkinson’s Disease (Stage 4)', 'Parkinson’s Disease (Stage 5)',
    'ALS (Early Stage)', 'ALS (Middle Stage)', 'ALS (Late Stage)', 'ALS (End-Stage)',
    'Multiple Sclerosis (Relapsing-Remitting)', 'Multiple Sclerosis (Primary Progressive)', 'Multiple Sclerosis (Secondary Progressive)',
    'Epilepsy (Focal)', 'Epilepsy (Generalized)',

    // **Kidney and Liver Diseases**
    'Chronic Kidney Disease (Stage 1)', 'Chronic Kidney Disease (Stage 2)', 'Chronic Kidney Disease (Stage 3)', 'Chronic Kidney Disease (Stage 4)', 'Chronic Kidney Disease (Stage 5 - End-Stage Renal Disease)',
    'Liver Cirrhosis (Compensated)', 'Liver Cirrhosis (Decompensated)',
    'Liver Failure (Acute)', 'Liver Failure (Chronic)',

    // **Endocrine & Metabolic Disorders**
    'Diabetes Mellitus (Type 1)', 'Diabetes Mellitus (Type 2)', 'Diabetes (With Complications)',
    'Thyroid Disease (Hypothyroidism)', 'Thyroid Disease (Hyperthyroidism)', 
    'Cushing’s Syndrome', 'Addison’s Disease',

    // **Autoimmune & Chronic Inflammatory Disorders**
    'HIV/AIDS (Stage 1)', 'HIV/AIDS (Stage 2)', 'HIV/AIDS (Stage 3 - AIDS)',
    'Rheumatoid Arthritis (Early)', 'Rheumatoid Arthritis (Advanced)',
    'Lupus (Mild)', 'Lupus (Severe)',
    'Severe Malnutrition',

    // **Musculoskeletal Disorders**
    'Frailty Syndrome',
    'Severe Osteoarthritis',
    'Chronic Pain Syndrome',

    // **Wound and Skin Conditions**
    'Pressure Ulcers (Stage 1)', 'Pressure Ulcers (Stage 2)', 'Pressure Ulcers (Stage 3)', 'Pressure Ulcers (Stage 4)',
    'Severe Burns (Partial Thickness)', 'Severe Burns (Full Thickness)',

    // **Other Terminal and Chronic Conditions**
    'Dementia (Mild)', 'Dementia (Moderate)', 'Dementia (Severe)',
    'Amyloidosis (Primary)', 'Amyloidosis (Secondary)',
    'Pulmonary Hypertension (Mild)', 'Pulmonary Hypertension (Severe)',
    'Systemic Sclerosis (Limited)', 'Systemic Sclerosis (Diffuse)',
    'Sickle Cell Disease (Chronic)', 'Sickle Cell Disease (Crisis)',
  ];


  List<String> filteredCases = [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        showDropdown = _searchFocusNode.hasFocus;
      });
    });
    _updateFilteredCases();
  }

  /// Extracts the base name of a case (e.g., "Lung Cancer" from "Lung Cancer (Stage 1)")
  String _getBaseCaseName(String caseItem) {
    return caseItem.split('(')[0].trim();
  }

  /// Updates the filtered case list by excluding already selected cases
  void _updateFilteredCases() {
    setState(() {
      List<String> selectedBaseNames = widget.selectedCases.map(_getBaseCaseName).toSet().toList();
      filteredCases = allCases.where((c) {
        String baseName = _getBaseCaseName(c);
        return !selectedBaseNames.contains(baseName);
      }).toList();
    });
  }

  /// Handles adding a case while removing its other severity variants
  void _addCase(String caseItem) {
    String baseName = _getBaseCaseName(caseItem);

    // Remove all existing cases with the same base name
    List<String> toRemove = widget.selectedCases.where((c) => _getBaseCaseName(c) == baseName).toList();
    for (String c in toRemove) {
      widget.onRemoveCase(c);
    }

    // Add the selected case
    widget.onAddCase(caseItem);

    _searchController.clear();
    _updateFilteredCases();
  }

  /// Handles removing a case and restoring its variants
  void _removeCase(String caseItem) {
    widget.onRemoveCase(caseItem);
    _updateFilteredCases(); // Restore all variants when removed
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      validator: widget.validator,
      builder: (FormFieldState<List<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Case Name/s', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8.0,
              children: widget.selectedCases.map((caseItem) => Chip(
                label: Text(caseItem),
                deleteIcon: Icon(Icons.close),
                onDeleted: () => _removeCase(caseItem),
              )).toList(),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Add Case',
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _updateFilteredCases();
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
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
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
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  state.errorText ?? '',
                  style: TextStyle(color: Colors.red),
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
      List<String> selectedBaseNames = widget.selectedCases.map(_getBaseCaseName).toSet().toList();
      filteredCases = allCases
          .where((caseItem) => 
            caseItem.toLowerCase().contains(query.toLowerCase()) &&
            !selectedBaseNames.contains(_getBaseCaseName(caseItem))
          )
          .toList();
    });
  }
}
