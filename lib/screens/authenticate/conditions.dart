import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';

class ConditionsScreen extends StatefulWidget {
  final Function onAcceptConditions;

  const ConditionsScreen({super.key, required this.onAcceptConditions});

  @override
  ConditionsScreenState createState() => ConditionsScreenState();
}

class ConditionsScreenState extends State<ConditionsScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  Map<String, dynamic> _termsData = {};
  Map<String, dynamic> _privacyData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContent();
    debugPrint("Terms Data: $_termsData");
    debugPrint("{} Data: $_termsData");
  }

  Future<void> _fetchContent() async {
    try {
      final termsRef = FirebaseStorage.instance.ref(
        'terms_privacy/terms_and_conditions.json',
      );
      final privacyRef = FirebaseStorage.instance.ref(
        'terms_privacy/privacy_notice.json',
      );

      final termsData = await termsRef.getData();
      final privacyData = await privacyRef.getData();

      setState(() {
        _termsData = jsonDecode(utf8.decode(termsData ?? []));
        _privacyData = jsonDecode(utf8.decode(privacyData ?? []));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _termsData = {'error': 'Failed to load terms and conditions.'};
        _privacyData = {'error': 'Failed to load privacy notice.'};
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // If they accepted the terms
      showToast('Terms and Conditions accepted');
      widget.onAcceptConditions();
      Navigator.pop(context, true);
    }
  }

  void showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  Widget _buildTermsAndConditions() {
    if (_termsData.containsKey('error')) {
      return Center(child: Text(_termsData['error']));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          _termsData['terms']['title']?.toString() ?? '',
          style: Textstyle.subheader,
        ),
        const SizedBox(height: 10),

        // Last Updated
        Text(
          'Last Updated: ${_termsData['terms']['lastUpdated']?.toString() ?? ''}',
          style: Textstyle.body,
        ),
        const SizedBox(height: 20),

        // Welcome Message
        Text(
          _termsData['terms']['welcomeMessage']?.toString() ?? '',
          style: Textstyle.body,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 10),

        // Sub Message
        Text(
          _termsData['terms']['subMessage']?.toString() ?? '',
          style: Textstyle.body,
          textAlign: TextAlign.justify,
        ),

        const SizedBox(height: 20),
        Divider(),
        const SizedBox(height: 20),

        // Sections
        ..._buildSections(_termsData['terms']['sections'] ?? {}),
      ],
    );
  }

  Widget _buildUserConductContent(String content) {
    // Split content into lines and process each line.
    final lines = content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          lines.map((line) {
            if (line.startsWith('-')) {
              return Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•   ', style: Textstyle.body),
                    Expanded(child: _buildStyledText(line.substring(1).trim())),
                  ],
                ),
              );
            }
            return _buildStyledText(line);
          }).toList(),
    );
  }

  Widget _buildStyledText(String text) {
    // Match text enclosed by "**" and style it as bold
    final RegExp pattern = RegExp(r'\*\*(.*?)\*\*');
    final spans = <TextSpan>[];
    int start = 0;

    for (final match in pattern.allMatches(text)) {
      if (start < match.start) {
        // Add normal text before the match
        spans.add(
          TextSpan(
            text: text.substring(start, match.start),
            style: Textstyle.body,
          ),
        );
      }
      // Add bold text
      spans.add(
        TextSpan(
          text: match.group(1),
          style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
        ),
      );
      start = match.end;
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: Textstyle.body));
    }

    return RichText(
      textAlign: TextAlign.justify,
      text: TextSpan(style: Textstyle.body, children: spans),
    );
  }

  List<Widget> _buildSections(Map<String, dynamic> sections) {
    final widgets = <Widget>[];

    sections.forEach((key, section) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Text(
              section['numberHeader']?.toString() ?? '',
              style: Textstyle.subheader,
            ),
            const SizedBox(height: 5),
            key == 'userConduct'
                ? _buildUserConductContent(section['content'] ?? '')
                : Text(
                  section['content']?.toString() ?? '',
                  style: Textstyle.body,
                  textAlign: TextAlign.justify,
                ),
            const SizedBox(height: 20),
          ],
        ),
      );
    });

    return widgets;
  }

  Widget _buildTracker() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  'Terms and Conditions',
                  style:
                      _currentPage == 0
                          ? Textstyle.bodySmall.copyWith(
                            color: AppColors.neon,
                            fontWeight: FontWeight.bold,
                          )
                          : Textstyle.bodySmall,
                ),
                SizedBox(height: 10),
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
          SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Privacy Notice',
                  style:
                      _currentPage == 1
                          ? Textstyle.bodySmall.copyWith(
                            color: AppColors.neon,
                            fontWeight: FontWeight.bold,
                          )
                          : Textstyle.bodySmall,
                ),
                SizedBox(height: 10),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text("SOLACE by Team RES", style: Textstyle.subheader),
        centerTitle: true,
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: Column(
        children: [
          _buildTracker(),
          SizedBox(height: 20),
          Flexible(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              physics:
                  _currentPage == 0
                      ? NeverScrollableScrollPhysics()
                      : null, // Disable swipe if it's on the first page
              children: [
                _buildPage(
                  content:
                      _termsData.isEmpty
                          ? Container()
                          : _buildTermsAndConditions(),
                  title: 'Terms and Conditions',
                ),
                _buildPage(
                  content:
                      _privacyData.isEmpty
                          ? Container()
                          : _buildPrivacyNotice(),
                  title: 'Privacy Notice',
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: TextButton(
          onPressed: _isLoading ? null : _nextPage,
          style: _isLoading ? Buttonstyle.buttonGray : Buttonstyle.buttonNeon,
          child: Text(
            _currentPage == 0
                ? 'Accept Terms and Conditions'
                : 'I Agree and Sign Up',
            style: Textstyle.smallButton,
          ),
        ),
      ),
    );
  }

  Widget _buildPage({required Widget content, required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child:
          _isLoading
              ? Center(child: Loader.loaderPurple)
              : SingleChildScrollView(child: content),
    );
  }

  Widget _buildPrivacyNotice() {
    if (_privacyData == null || _privacyData.isEmpty) {
      return Center(child: Loader.loaderPurple);
    }

    var privacyNotice = _privacyData['privacyNotice'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(privacyNotice['title'] ?? '', style: Textstyle.subheader),
        const SizedBox(height: 10),

        // Last Updated
        Text(
          'Last Updated: ${privacyNotice['lastUpdated'] ?? ''}',
          style: Textstyle.body,
        ),
        const SizedBox(height: 20),

        // Introduction Section
        _buildSection(privacyNotice['sections']['introduction']),

        _buildInformationWeCollect(),
        _buildHowWeUseYourInformation(),

        // Data Security, Your Rights, and Other Sections
        _buildSection(privacyNotice['sections']['dataSecurity']),
        _buildSection(privacyNotice['sections']['yourRights']),
        _buildSection(privacyNotice['sections']['changesToNotice']),
        _buildSection(privacyNotice['sections']['contactInformation']),
      ],
    );
  }

  Widget _buildSection(Map<String, dynamic> section) {
    if (section == null) {
      return const SizedBox.shrink(); // Return nothing if the section is null
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(section['title'] ?? '', style: Textstyle.subheader),
        const SizedBox(height: 5),

        // Content or Items
        if (section.containsKey('content'))
          Text(
            section['content'] ?? '',
            style: Textstyle.body,
            textAlign: TextAlign.justify,
          ),
        if (section.containsKey('items'))
          ...List<Widget>.from(
            section['items'].map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•   ',
                      style: Textstyle.body,
                      textAlign: TextAlign.justify,
                    ), // Bullet Point
                    Expanded(child: _buildStyledItem(item)), // Styled Item
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStyledItem(String item) {
    final parts = item.split(':');
    final spans = <TextSpan>[];

    if (parts.length > 1) {
      // Bold text before the colon
      spans.add(
        TextSpan(
          text: '${parts[0]}: ',
          style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
        ),
      );
      // Regular text after the colon
      spans.add(
        TextSpan(
          text: parts.sublist(1).join(':').trim(),
          style: Textstyle.body,
        ),
      );
    } else {
      // No colon, add the whole text as normal
      spans.add(TextSpan(text: item, style: Textstyle.body));
    }

    return RichText(
      text: TextSpan(children: spans, style: Textstyle.body),
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildInformationWeCollect() {
    var infoCollect =
        _privacyData['privacyNotice']['sections']['informationWeCollect'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(infoCollect['title'] ?? '', style: Textstyle.subheader),
        const SizedBox(height: 10),

        // Patient Information Section
        _buildSection(infoCollect['sections']['patientInformation']),

        // User Information Section
        _buildSection(infoCollect['sections']['userInfo']),

        // Device Information Section
        _buildSection(infoCollect['sections']['deviceInformation']),

        // Usage Information Section
        _buildSection(infoCollect['sections']['usageInformation']),
      ],
    );
  }

  Widget _buildHowWeUseYourInformation() {
    var usageInfo =
        _privacyData['privacyNotice']['sections']['howWeUseYourInformation'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(usageInfo['title'] ?? '', style: Textstyle.subheader),
        const SizedBox(height: 10),

        // Patient Data Usage Section
        _buildSection(usageInfo['sections']['patientDataUsage']),

        // User Data Usage Section
        _buildSection(usageInfo['sections']['userDataUsage']),

        // Device and Usage Data Section
        _buildSection(usageInfo['sections']['deviceAndUsageData']),
      ],
    );
  }
}
