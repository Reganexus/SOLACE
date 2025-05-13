// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/services/validator.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/dropdownfield.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textformfield.dart';
import 'package:solace/themes/textstyle.dart';
import 'package:solace/utility/contact_utility.dart';
import 'package:url_launcher/url_launcher.dart';

class Contacts extends StatefulWidget {
  final String patientId;

  const Contacts({super.key, required this.patientId});

  @override
  ContactsScreenState createState() => ContactsScreenState();
}

class ContactsScreenState extends State<Contacts> {
  final DatabaseService databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LogService _logService = LogService();
  final ContactUtility contactUtil = ContactUtility();
  late final String patientId;
  List<Map<String, dynamic>> nurseContacts = [];
  List<Map<String, dynamic>> relativeContacts = [];

  String collectionName = 'patient';
  bool isLoading = true;
  late String patientName = '';

  @override
  void initState() {
    super.initState();
    patientId = widget.patientId;
    _initializeContacts();
    _loadPatientName();
  }

  Future<void> _loadPatientName() async {
    final name = await databaseService.fetchUserName(widget.patientId);
    if (mounted) {
      setState(() {
        patientName = name ?? 'Unknown';
      });
    }
    //     debugPrint("Patient Name: $patientName");
  }

  Future<void> _initializeContacts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final contacts = await contactUtil.getContacts(widget.patientId);

      setState(() {
        nurseContacts = contacts['nurse'] ?? [];
        relativeContacts = contacts['relative'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      //       debugPrint("Error initializing contacts: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await Permission.phone.request().isGranted) {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        //         debugPrint('Could not launch $launchUri');
      }
    } else {
      //       debugPrint('Phone permission denied');
    }
  }

  Widget _buildContactsList(List<dynamic> contacts) {
    if (contacts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.gray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "No contacts available",
          textAlign: TextAlign.center,
          style: Textstyle.body,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final contactData = Map<String, dynamic>.from(contacts[index]);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.gray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${contactData['name']}",
                      style: Textstyle.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(contactData['phoneNumber'], style: Textstyle.body),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  _showContactDialog(contactData);
                },
                child: const Icon(
                  Icons.more_vert,
                  size: 24,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryContacts(String title, List<dynamic> contacts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Textstyle.subheader),
        const SizedBox(height: 10),
        _buildContactsList(contacts), // Use your existing method here
      ],
    );
  }

  Widget _buildContactsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryContacts("Nurse Contacts", nurseContacts),
          if (nurseContacts.isEmpty || relativeContacts.isEmpty)
            SizedBox(height: 10),
          _buildCategoryContacts("Relative Contacts", relativeContacts),
        ],
      ),
    );
  }

  void _showContactDialog(Map<String, dynamic> contactData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            contactData['name'] ?? "Unknown Contact",
            style: Textstyle.subheader,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _makeCall(contactData['phoneNumber']);
                },
                child: Row(
                  children: [
                    const Icon(Icons.phone, color: AppColors.black, size: 24),
                    const SizedBox(width: 10),
                    Text('Call', style: Textstyle.body),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _editContact(contactData);
                },
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: AppColors.black, size: 24),
                    const SizedBox(width: 10),
                    Text('Edit Contact', style: Textstyle.body),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _deleteContact(contactData);
                },
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: AppColors.red, size: 24),
                    const SizedBox(width: 10),
                    Text('Delete Contact', style: Textstyle.error),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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

  void _addContact() async {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController numberController = TextEditingController();
    final FocusNode nameFocusNode = FocusNode();
    final FocusNode numberFocusNode = FocusNode();
    final FocusNode categoryFocusNode = FocusNode();
    String category = "relative";
    bool isSaving = false; // Add saving state

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Add Contact", style: Textstyle.subheader),
                        Text(
                          "Fields marked with * are required.",
                          style: Textstyle.body,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: nameController,
                          focusNode: nameFocusNode,
                          labelText: 'Name *',
                          enabled: !isSaving,
                          validator: (val) => Validator.name(val?.trim()),
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          controller: numberController,
                          focusNode: numberFocusNode,
                          labelText: 'Phone Number *',
                          enabled: !isSaving,
                          validator:
                              (val) => Validator.phoneNumber(val?.trim()),
                        ),
                        const SizedBox(height: 10),
                        CustomDropdownField<String>(
                          value: category,
                          focusNode: categoryFocusNode,
                          labelText: 'Category *',
                          enabled: !isSaving,
                          items: const ['relative', 'nurse'],
                          onChanged: (val) {
                            if (val != null) {
                              category = val;
                            }
                          },
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Select a category'
                                      : null,
                          displayItem: (item) => item.capitalize(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed:
                                    !isSaving
                                        ? () => Navigator.pop(context)
                                        : null,
                                style:
                                    isSaving
                                        ? Buttonstyle.buttonGray
                                        : Buttonstyle.buttonRed,
                                child: Text(
                                  "Cancel",
                                  style: Textstyle.smallButton,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextButton(
                                style: Buttonstyle.buttonNeon,
                                onPressed:
                                    !isSaving
                                        ? () async {
                                          final confirmed =
                                              await showConfirmationDialog(
                                                context,
                                                'add',
                                              );
                                          if (confirmed) {
                                            if (formKey.currentState
                                                    ?.validate() ??
                                                false) {
                                              setState(() {
                                                isSaving = true; // Start saving
                                              });
                                              final String name =
                                                  nameController.text.trim();
                                              final String phoneNumber =
                                                  numberController.text.trim();

                                              final cleanedName = name
                                                  .replaceAll(
                                                    RegExp(r'\s+'),
                                                    ' ',
                                                  );

                                              final isDuplicate =
                                                  await contactUtil
                                                      .isDuplicateContact(
                                                        userId:
                                                            widget.patientId,
                                                        phoneNumber:
                                                            phoneNumber,
                                                        name: cleanedName,
                                                        category: category,
                                                      );

                                              if (isDuplicate) {
                                                setState(() {
                                                  isSaving =
                                                      false; // Stop saving
                                                });
                                                showToast(
                                                  "A contact with the same details already exists.",
                                                  backgroundColor:
                                                      AppColors.red,
                                                );
                                                return;
                                              }

                                              Map<String, dynamic> contactData =
                                                  {
                                                    "name": cleanedName,
                                                    "phoneNumber": phoneNumber,
                                                    "category": category,
                                                    "createdAt": DateTime.now(),
                                                  };

                                              try {
                                                await contactUtil.addContact(
                                                  userId: widget.patientId,
                                                  category: category,
                                                  contactData: contactData,
                                                );
                                                showToast(
                                                  "Contact added successfully.",
                                                );
                                                _initializeContacts();
                                                Navigator.pop(context);
                                              } catch (e) {
                                                showToast(
                                                  "Failed to add contact: $e",
                                                  backgroundColor:
                                                      AppColors.red,
                                                );
                                              } finally {
                                                setState(() {
                                                  isSaving =
                                                      false; // Stop saving
                                                });
                                              }
                                            }
                                          }
                                        }
                                        : null,
                                child:
                                    isSaving
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation(
                                              AppColors.white,
                                            ),
                                          ),
                                        )
                                        : Text(
                                          "Add Contact",
                                          style: Textstyle.smallButton,
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editContact(Map<String, dynamic> contactData) async {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(
      text: contactData['name'],
    );
    final TextEditingController numberController = TextEditingController(
      text: contactData['phoneNumber'],
    );
    final FocusNode nameFocusNode = FocusNode();
    final FocusNode numberFocusNode = FocusNode();
    final FocusNode categoryFocusNode = FocusNode();
    String category = contactData['category'];
    String oldPhoneNumber = contactData['phoneNumber'];
    bool isSaving = false; // Add saving state

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Edit Contact", style: Textstyle.subheader),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: nameController,
                          focusNode: nameFocusNode,
                          labelText: 'Name',
                          enabled: !isSaving,
                          validator: (val) => Validator.name(val?.trim()),
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          controller: numberController,
                          focusNode: numberFocusNode,
                          labelText: 'Phone Number',
                          enabled: !isSaving,
                          validator:
                              (val) => Validator.phoneNumber(val?.trim()),
                        ),
                        const SizedBox(height: 10),
                        CustomDropdownField<String>(
                          value: category,
                          focusNode: categoryFocusNode,
                          labelText: 'Category',
                          enabled: !isSaving,
                          items: const ['relative', 'nurse'],
                          onChanged: (val) {
                            if (val != null) {
                              category = val;
                            }
                          },
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Select a category'
                                      : null,
                          displayItem: (item) => item.capitalize(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed:
                                    !isSaving
                                        ? () => Navigator.pop(context)
                                        : null,
                                style:
                                    isSaving
                                        ? Buttonstyle.buttonGray
                                        : Buttonstyle.buttonRed,
                                child: Text(
                                  "Cancel",
                                  style: Textstyle.smallButton,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextButton(
                                style: Buttonstyle.buttonNeon,
                                onPressed:
                                    !isSaving
                                        ? () async {
                                          final confirmed =
                                              await showConfirmationDialog(
                                                context,
                                                'save',
                                              );
                                          if (confirmed) {
                                            if (formKey.currentState
                                                    ?.validate() ??
                                                false) {
                                              setState(() {
                                                isSaving = true; // Start saving
                                              });
                                              final String name =
                                                  nameController.text.trim();
                                              final String phoneNumber =
                                                  numberController.text.trim();

                                              final cleanedName = name
                                                  .replaceAll(
                                                    RegExp(r'\s+'),
                                                    ' ',
                                                  );

                                              final isDuplicate =
                                                  await contactUtil
                                                      .isDuplicateContact(
                                                        userId:
                                                            widget.patientId,
                                                        phoneNumber:
                                                            phoneNumber,
                                                        name: cleanedName,
                                                        category: category,
                                                        excludePhoneNumber:
                                                            oldPhoneNumber,
                                                      );

                                              if (isDuplicate) {
                                                setState(() {
                                                  isSaving =
                                                      false; // Stop saving
                                                });
                                                showToast(
                                                  "A contact with the same number already exists.",
                                                  backgroundColor:
                                                      AppColors.red,
                                                );
                                                return;
                                              }

                                              final updatedContact = {
                                                'name': cleanedName,
                                                'phoneNumber': phoneNumber,
                                                'category': category,
                                              };

                                              try {
                                                await contactUtil.editContact(
                                                  userId: widget.patientId,
                                                  category:
                                                      contactData['category'],
                                                  updatedContact:
                                                      updatedContact,
                                                  oldPhoneNumber:
                                                      oldPhoneNumber,
                                                );
                                                Navigator.pop(context);
                                                showToast(
                                                  "Contact updated successfully.",
                                                );
                                                _initializeContacts();
                                              } catch (e) {
                                                showToast(
                                                  "Failed to update contact.",
                                                  backgroundColor:
                                                      AppColors.red,
                                                );
                                              } finally {
                                                setState(() {
                                                  isSaving =
                                                      false; // Stop saving
                                                });
                                              }
                                            }
                                          }
                                        }
                                        : null,
                                child:
                                    isSaving
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation(
                                              AppColors.white,
                                            ),
                                          ),
                                        )
                                        : Text(
                                          "Save",
                                          style: Textstyle.smallButton,
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteContact(Map<String, dynamic> contactData) async {
    final String name = contactData['name'] ?? 'Contact';
    final String category = contactData['category'] ?? '';
    final String phoneNumber = contactData['phoneNumber'] ?? '';
    bool isDeleting = false; // Add deleting state

    if (category.isEmpty || phoneNumber.isEmpty) {
      showToast("Invalid contact data.", backgroundColor: AppColors.red);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text("Delete Contact", style: Textstyle.subheader),
              content: Text(
                "Are you sure you want to delete $name?",
                style: Textstyle.body,
              ),
              actions: [
                TextButton(
                  style:
                      isDeleting
                          ? Buttonstyle.buttonGray
                          : Buttonstyle.buttonNeon,
                  onPressed: !isDeleting ? () => Navigator.pop(context) : null,
                  child: Text("Cancel", style: Textstyle.smallButton),
                ),
                TextButton(
                  style: Buttonstyle.buttonRed,
                  onPressed:
                      !isDeleting
                          ? () async {
                            setState(() {
                              isDeleting = true; // Start deleting
                            });
                            try {
                              final user = _auth.currentUser;

                              if (user == null) {
                                showToast(
                                  "Current user is not authenticated",
                                  backgroundColor: AppColors.red,
                                );
                                return;
                              }

                              await contactUtil.deleteContact(
                                userId: widget.patientId,
                                category: category,
                                phoneNumberToDelete: phoneNumber,
                              );

                              await _logService.addLog(
                                userId: user.uid,
                                action:
                                    "Deleted contact $phoneNumber from patient $patientName",
                              );
                              Navigator.pop(context);
                              showToast("$name deleted successfully.");
                              _initializeContacts();
                            } catch (e) {
                              showToast(
                                "Failed to delete contact.",
                                backgroundColor: AppColors.red,
                              );
                            } finally {
                              setState(() {
                                isDeleting = false; // Stop deleting
                              });
                            }
                          }
                          : null,
                  child:
                      isDeleting
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.white,
                              ),
                            ),
                          )
                          : Text("Delete", style: Textstyle.smallButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> showConfirmationDialog(
    BuildContext context,
    String action,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text('Confirm $action', style: Textstyle.subheader),
              content: Text(
                'Are you sure you want to $action this contact?',
                style: Textstyle.body,
              ),
              actions: <Widget>[
                TextButton(
                  style:
                      action == "delete"
                          ? Buttonstyle.buttonNeon
                          : Buttonstyle.buttonRed,
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel', style: Textstyle.smallButton),
                ),
                TextButton(
                  style:
                      action == "delete"
                          ? Buttonstyle.buttonRed
                          : Buttonstyle.buttonNeon,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    action.capitalize(),
                    style: Textstyle.smallButton,
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContact,
        backgroundColor: AppColors.neon,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        centerTitle: true,
        title: Text('Contacts', style: Textstyle.subheader),
      ),
      body:
          isLoading ? Center(child: Loader.loaderPurple) : _buildContactsView(),
    );
  }
}
