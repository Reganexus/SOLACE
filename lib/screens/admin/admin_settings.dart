// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:solace/shared/widgets/edit_settings.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildSettings() {
    final List<String> exportOptions = [
      'Cases',
      'Interventions',
      'Vital Thresholds',
      'Medicines',
    ];

    Widget buildSettingOption(String docName) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditSettings(docName: docName),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.gray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(child: Text(docName, style: Textstyle.body)),
              Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('lib/assets/images/auth/solace.png', height: 130),
              SizedBox(height: 10),
              Text("SOLACE", style: Textstyle.heading),
              Text("© Team RES, 2025", style: Textstyle.bodySmall),
            ],
          ),
        ),
        SizedBox(height: 20),
        Divider(),
        const SizedBox(height: 10),

        Text('Edit System Variables', style: Textstyle.subheader),
        const SizedBox(height: 10),
        Text(
          'Change and modify thresholds and variables in the system',
          style: Textstyle.body,
        ),
        const SizedBox(height: 20),
        for (var option in exportOptions) ...[
          buildSettingOption(option),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _buildSettings(),
      ),
    );
  }
}
