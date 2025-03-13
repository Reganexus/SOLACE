// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class Contacts extends StatefulWidget {
  final String patientId;

  const Contacts({super.key, required this.patientId});

  @override
  ContactsScreenState createState() => ContactsScreenState();
}

class ContactsScreenState extends State<Contacts> {
  final DatabaseService db = DatabaseService();
  late final String patientId;
  String collectionName = 'patient';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    patientId = widget.patientId;

    debugPrint("Current user id is: $patientId");
    _initializeCollectionName();
  }

  Future<void> _initializeCollectionName() async {
    try {
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching collection name: $e");
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
        debugPrint('Could not launch $launchUri');
      }
    } else {
      debugPrint('Phone permission denied');
    }
  }

  void _addContact() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController firstNameController =
            TextEditingController();
        final TextEditingController lastNameController =
            TextEditingController();
        final TextEditingController numberController = TextEditingController();
        final FocusNode firstNameFocusNode = FocusNode();
        final FocusNode lastNameFocusNode = FocusNode();
        final FocusNode numberFocusNode = FocusNode();
        final FocusNode categoryFocusNode = FocusNode();
        String category = "relative";

        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Add Contact",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: firstNameController,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                  focusNode: firstNameFocusNode,
                  decoration:
                      _buildInputDecoration("First Name", firstNameFocusNode),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: lastNameController,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                  focusNode: lastNameFocusNode,
                  decoration:
                      _buildInputDecoration("Last Name", lastNameFocusNode),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: numberController,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                  focusNode: numberFocusNode,
                  decoration:
                      _buildInputDecoration("Phone Number", numberFocusNode),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  items: const [
                    DropdownMenuItem(
                        value: "relative", child: Text("Relative")),
                    DropdownMenuItem(value: "nurse", child: Text("Nurse")),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      category = value;
                    }
                  },
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                  focusNode: categoryFocusNode,
                  decoration:
                      _buildInputDecoration("Category", categoryFocusNode),
                  dropdownColor: AppColors.white,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 5),
                          backgroundColor: AppColors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 5),
                          backgroundColor: AppColors.neon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          if (firstNameController.text.isEmpty ||
                              lastNameController.text.isEmpty ||
                              numberController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("All fields are required")),
                            );
                            return;
                          }

                          // Capitalize first and last names
                          final firstName = firstNameController.text.trim();
                          final lastName = lastNameController.text.trim();
                          final capitalizedFirstName =
                              firstName[0].toUpperCase() +
                                  firstName.substring(1);
                          final capitalizedLastName =
                              lastName[0].toUpperCase() + lastName.substring(1);

                          // Validate phone number
                          final phoneNumber = numberController.text.trim();
                          final phoneRegExp = RegExp(r'^09\d{9}$');
                          if (phoneNumber.isEmpty ||
                              !phoneRegExp.hasMatch(phoneNumber)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Invalid phone number.')),
                            );
                            return;
                          }

                          final contactData = {
                            "firstName": capitalizedFirstName,
                            "lastName": capitalizedLastName,
                            "phone": phoneNumber,
                            "category": category,
                          };

                          try {
                            debugPrint("Add Contact: $patientId");
                            await db.addContact(
                                patientId, category, contactData);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Contact added successfully")),
                            );
                          } catch (e) {
                            debugPrint("Error adding contact: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Failed to add contact")),
                            );
                          }
                        },
                        child: const Text(
                          "Add Contact",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Header for Friends & Requests list
  Widget _buildHeader(String title) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        title,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 24,
          fontFamily: 'Outfit',
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
      ),
    );
  }

  Widget _buildContactsList(List<dynamic> contacts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...contacts.map((contact) {
          final contactData = Map<String, dynamic>.from(contact);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                        "${contactData['firstName']} ${contactData['lastName']}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        contactData['phone'],
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.blackTransparent,
                        ),
                      ),
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
                    size: 30,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showContactDialog(Map<String, dynamic> contactData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            "${contactData['firstName']} ${contactData['lastName']}",
            style: const TextStyle(
              fontSize: 24,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.phone,
                  color: AppColors.black,
                  size: 25,
                ),
                title: const Text(
                  'Call',
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.normal,
                      color: AppColors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _makeCall(contactData['phone']);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.edit,
                  color: AppColors.black,
                  size: 25,
                ),
                title: const Text(
                  'Edit Contact',
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.normal,
                      color: AppColors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editContact(contactData);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete,
                  color: AppColors.black,
                  size: 25,
                ),
                title: const Text(
                  'Delete Contact',
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.normal,
                      color: AppColors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteContact(contactData);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editContact(Map<String, dynamic> contactData) {
    final TextEditingController firstNameController =
        TextEditingController(text: contactData['firstName']);
    final TextEditingController lastNameController =
        TextEditingController(text: contactData['lastName']);
    final TextEditingController numberController =
        TextEditingController(text: contactData['phone']);
    final FocusNode firstNameFocusNode = FocusNode();
    final FocusNode lastNameFocusNode = FocusNode();
    final FocusNode numberFocusNode = FocusNode();
    final FocusNode categoryFocusNode = FocusNode();
    String category = contactData['category']; // Retain the original category

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width *
                0.8, // Adjust width as needed
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Edit Contact",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: firstNameController,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                  focusNode: firstNameFocusNode,
                  decoration:
                      _buildInputDecoration("First Name", firstNameFocusNode),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: lastNameController,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                  focusNode: lastNameFocusNode,
                  decoration:
                      _buildInputDecoration("Last Name", lastNameFocusNode),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: numberController,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                  focusNode: numberFocusNode,
                  decoration:
                      _buildInputDecoration("Phone Number", numberFocusNode),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  items: const [
                    DropdownMenuItem(
                        value: "relative", child: Text("Relative")),
                    DropdownMenuItem(value: "nurse", child: Text("Nurse")),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      category = value;
                    }
                  },
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                  focusNode: categoryFocusNode,
                  decoration:
                      _buildInputDecoration("Category", categoryFocusNode),
                  dropdownColor: AppColors.white,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 5),
                          backgroundColor: AppColors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 5),
                          backgroundColor: AppColors.neon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          if (firstNameController.text.isEmpty ||
                              lastNameController.text.isEmpty ||
                              numberController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("All fields are required")),
                            );
                            return;
                          }

                          final updatedContact = {
                            'firstName': firstNameController.text.trim(),
                            'lastName': lastNameController.text.trim(),
                            'phone': numberController.text.trim(),
                            'category': category, // Update category
                          };

                          try {
                            await db.editContact(
                              widget.patientId,
                              contactData['category'], // Original category
                              updatedContact,
                              contactData['phone'], // Old phone number
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Contact updated successfully")),
                            );
                          } catch (e) {
                            debugPrint("Error updating contact: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Failed to update contact")),
                            );
                          }
                        },
                        child: const Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteContact(Map<String, dynamic> contactData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text(
            "Delete Contact",
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          content: const Text(
            "Are you sure you want to delete this contact?",
            style: TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.normal,
                color: AppColors.black),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 5),
                      backgroundColor: AppColors.neon,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10.0,
                ),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 5),
                      backgroundColor: AppColors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await db.deleteContact(
                          widget.patientId,
                          contactData[
                              'category'], // Category for precise deletion
                          contactData[
                              'phone'], // Unique identifier (phone number)
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Contact deleted successfully")),
                        );
                      } catch (e) {
                        debugPrint("Error deleting contact: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Failed to delete contact")),
                        );
                      }
                    },
                    child: const Text(
                      "Delete",
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(String label, FocusNode focusNode) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.gray,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.neon, width: 2)),
      labelStyle: TextStyle(
        fontSize: 16,
        fontFamily: 'Inter',
        fontWeight: FontWeight.normal,
        color: focusNode.hasFocus ? AppColors.neon : AppColors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        title: const Text(
          'Contacts',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _addContact, // Call the _addContact function when tapped
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: Icon(
                Icons.person_add,
                size: 30,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot?>(
              stream: FirebaseFirestore.instance
                  .collection('patient') // Use dynamic collection name
                  .doc(patientId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.data() == null) {
                  return const Center(
                      child: Text('No contact data available.'));
                }

                final userDoc = snapshot.data!.data() as Map<String, dynamic>;
                final contacts = userDoc['contacts'] as Map<String, dynamic>? ??
                    {'relative': [], 'nurse': []};

                // Safely access relative and nurse contacts
                final relativeContacts =
                    (contacts['relative'] as List<dynamic>? ?? []);
                final nurseContacts =
                    (contacts['nurse'] as List<dynamic>? ?? []);

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader('Relatives'),
                        const SizedBox(height: 10),
                        if (relativeContacts.isNotEmpty)
                          _buildContactsList(relativeContacts)
                        else
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "No relative contacts",
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.normal,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        _buildHeader('Nurses'),
                        const SizedBox(height: 10),
                        if (nurseContacts.isNotEmpty)
                          _buildContactsList(nurseContacts)
                        else
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "No nurse contacts",
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.normal,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
