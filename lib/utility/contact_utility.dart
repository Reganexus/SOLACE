import 'package:cloud_firestore/cloud_firestore.dart';

class ContactUtility {
  Future<void> manageContactSubcollection({
    required String userId,
    required String category,
    required String operation,
    Map<String, dynamic>? contactData,
    String? oldPhoneNumber,
  }) async {
    assert(
      category == "relative" || category == "nurse",
      "Invalid category. Allowed values are 'relative' and 'nurse'.",
    );

    final categoryCollectionRef = FirebaseFirestore.instance
        .collection('patient')
        .doc(userId)
        .collection('contacts')
        .doc(category);

    if (operation == "add") {
      // Add a new contact
      await categoryCollectionRef.set({
        contactData!['phoneNumber']: contactData,
      }, SetOptions(merge: true));
    } else if (operation == "edit") {
      // Edit an existing contact
      if (oldPhoneNumber == null || contactData == null) {
        throw ArgumentError(
          "Both oldPhoneNumber and contactData must be provided for editing.",
        );
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(categoryCollectionRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() ?? {};
        data.remove(oldPhoneNumber); // Remove the old phone number
        data[contactData['phoneNumber']] = contactData; // Add the updated data

        transaction.set(categoryCollectionRef, data);
      });
    } else if (operation == "delete") {
      // Delete a contact
      if (oldPhoneNumber == null) {
        throw ArgumentError("oldPhoneNumber must be provided for deletion.");
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(categoryCollectionRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() ?? {};
        data.remove(oldPhoneNumber);

        transaction.set(categoryCollectionRef, data);
      });
    } else {
      throw ArgumentError(
        "Invalid operation. Allowed values are 'add', 'edit', or 'delete'.",
      );
    }
  }

  Future<void> addContact({
    required String userId,
    required String category,
    required Map<String, dynamic> contactData,
  }) async {
    await manageContactSubcollection(
      userId: userId,
      category: category,
      operation: "add",
      contactData: contactData,
    );
  }

  Future<void> editContact({
    required String userId,
    required String category,
    required Map<String, dynamic> updatedContact,
    required String oldPhoneNumber,
  }) async {
    await deleteContact(
      userId: userId,
      category: category,
      phoneNumberToDelete: oldPhoneNumber,
    );

    await addContact(
      userId: userId,
      category: updatedContact['category'],
      contactData: updatedContact,
    );
  }

  Future<void> deleteContact({
    required String userId,
    required String category,
    required String phoneNumberToDelete,
  }) async {
    await manageContactSubcollection(
      userId: userId,
      category: category,
      operation: "delete",
      oldPhoneNumber: phoneNumberToDelete,
    );
  }

  Future<bool> isDuplicateContact({
    required String userId,
    required String phoneNumber,
    required String name,
    required String category,
    String? excludePhoneNumber,
  }) async {
    // Define the categories to check for duplicates
    final categories = ['relative', 'nurse'];

    for (final cat in categories) {
      final categoryDocRef = FirebaseFirestore.instance
          .collection('patient')
          .doc(userId)
          .collection('contacts')
          .doc(cat);

      final snapshot = await categoryDocRef.get();
      if (!snapshot.exists) continue;

      final data = snapshot.data() ?? {};

      for (final entry in data.entries) {
        final contact = Map<String, dynamic>.from(entry.value);

        // Skip the current contact being edited
        if (excludePhoneNumber != null && entry.key == excludePhoneNumber) {
          continue;
        }

        // Check for duplicate phone number
        if (contact['phoneNumber'] == phoneNumber) {
          return true;
        }
      }
    }

    return false;
  }

  Future<Map<String, List<Map<String, dynamic>>>> getContacts(
    String userId,
  ) async {
    try {
      // Fetch the contacts subcollection
      final snapshot =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(userId)
              .collection('contacts')
              .get();

      // Initialize categorized contacts
      final Map<String, List<Map<String, dynamic>>> categorizedContacts = {
        'nurse': [],
        'relative': [],
      };

      for (final doc in snapshot.docs) {
        final category = doc.id; // 'nurse' or 'relative'
        final data = doc.data();

        if (data.isNotEmpty) {
          final List<Map<String, dynamic>> categoryContacts =
              data.entries.map((entry) {
                final contactData = Map<String, dynamic>.from(entry.value);
                contactData['phone'] = entry.key; // Assign the phone number key
                return contactData;
              }).toList();

          // Assign contacts to the appropriate category
          categorizedContacts[category] = categoryContacts;
        }
      }

      return categorizedContacts;
    } catch (e) {
      //       debugPrint("Error fetching contacts: $e");
      return {'nurse': [], 'relative': []};
    }
  }
}
