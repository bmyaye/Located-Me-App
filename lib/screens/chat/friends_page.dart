import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendManager {
  final BuildContext context;

  FriendManager(this.context);

  void showAddFriendDialog() {
    TextEditingController usernameController = TextEditingController();
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Friend'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Friend\'s Username'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Friend\'s Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _addFriend(usernameController.text, emailController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
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

  void _addFriend(String username, String email) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        String userId = currentUser.uid;
        FirebaseFirestore firestore = FirebaseFirestore.instance;
        DocumentReference currentUserDocRef = firestore.collection('users').doc(userId);

        QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .where('username', isEqualTo: username)
            .get();

        if (usersSnapshot.docs.isNotEmpty) {
          DocumentSnapshot friendDoc = usersSnapshot.docs.first;
          DocumentReference friendDocRef = firestore.collection('users').doc(friendDoc.id);
          Map<String, dynamic> friendData = friendDoc.data() as Map<String, dynamic>;
          friendData.remove('password');

          Map<String, dynamic> currentUserData = (await currentUserDocRef.get()).data() as Map<String, dynamic>;
          currentUserData.remove('password');

          await currentUserDocRef.collection('friends').doc(friendDoc.id).set(friendData);
          await friendDocRef.collection('friends').doc(userId).set(currentUserData);

          print('Friend added successfully!');
        } else {
          _showFriendNotRegisteredDialog(email);
        }
      } else {
        print('User is not authenticated');
      }
    } catch (e) {
      print('Error adding friend: $e');
    }
  }

  void _showFriendNotRegisteredDialog(String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Friend Not Registered'),
          content: Text('The friend with email $email is not registered.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}