import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupManager {
  final BuildContext context;

  GroupManager(this.context);

  void showCreateGroupDialog() {
    TextEditingController groupNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Group'),
          content: TextField(
            controller: groupNameController,
            decoration: const InputDecoration(labelText: 'Group Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _createGroup(groupNameController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Create'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _createGroup(String groupName) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        FirebaseFirestore firestore = FirebaseFirestore.instance;

        DocumentReference groupRef = await firestore.collection('users').doc(currentUser.uid).collection('groups').add({
          'name': groupName,
          'creator': currentUser.uid,
          // 'creatorUsername': currentUser.displayName,
        });

        print('Group created successfully with ID: ${groupRef.id}');
      } else {
        print('User is not authenticated');
      }
    } catch (e) {
      print('Error creating group: $e');
    }
  }

}
