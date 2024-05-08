import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location_app/screens/chat/chat_page.dart';

class buildUserList extends StatefulWidget {
  @override
  UserListBuilderState createState() => UserListBuilderState();
}

class UserListBuilderState extends State<buildUserList> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('friends')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Check if there are no friends
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('You have no friends yet.'),
          );
        }

        return ListView(
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildUserListItem(doc))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(DocumentSnapshot document) {
    String friendId = document.id; // Extract friendId (document ID)
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    print('Document data: $data');
    String friendUsername = data['username'] ?? ''; // Extract friendName from document

    // Check if friendId is not empty before fetching the document
    if (friendId.isNotEmpty) {
      print('Friend ID: $friendId'); // Debugging statement
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(friendId).get(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData && snapshot.data != null) {
              var friendUsername = data['username'];
              print('Friend username: $friendUsername'); // Debugging statement
              return ListTile(
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    ChatManager().openChatPage(context, friendId, friendUsername);
                  },
                ),
                title: Text(friendUsername),
              );
            } else {
              print('Friend data snapshot is empty'); // Debugging statement
              return const Text("Friend data not found");
            }
          }
          return const CircularProgressIndicator();
        },
      );
    } else {
      print('Friend ID is empty'); // Debugging statement
      return const SizedBox(); // Return an empty SizedBox if friendId is empty
    }
  }

}

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
      // Get the current user
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Get the current user's ID
        String userId = currentUser.uid;

        // Reference to the Firestore instance
        FirebaseFirestore firestore = FirebaseFirestore.instance;

        // Reference to the current user's document
        DocumentReference currentUserDocRef = firestore.collection('users').doc(userId);

        // Check if the friend's email exists in the "users" collection
        QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .where('username', isEqualTo: username)
            .get();

        if (usersSnapshot.docs.isNotEmpty) {
          // Friend's email found in the "users" collection
          // Access the first document in the snapshot
          DocumentSnapshot friendDoc = usersSnapshot.docs.first;

          // Reference to the friend's document
          DocumentReference friendDocRef = firestore.collection('users').doc(friendDoc.id);

          // Get the data of the friend
          Map<String, dynamic> friendData = friendDoc.data() as Map<String, dynamic>;

          // Exclude sensitive information like password before adding to friend list
          friendData.remove('password');

          // Get the data of the current user
          Map<String, dynamic> currentUserData = (await currentUserDocRef.get()).data() as Map<String, dynamic>;

          // Add the friend to the current user's friend list with all friend data
          await currentUserDocRef.collection('friends').doc(friendDoc.id).set(friendData);

          // Exclude sensitive information like password before adding to friend list
          currentUserData.remove('password');

          // Add the current user to the friend's friend list with all current user data
          await friendDocRef.collection('friends').doc(userId).set(currentUserData);

          print('Friend added successfully!');
        } else {
          // Friend's email not found in the "users" collection
          _showFriendNotRegisteredDialog(email);
        }
      } else {
        print('User is not authenticated');
        // Handle error appropriately, e.g., display error message to the user
      }
    } catch (e) {
      print('Error adding friend: $e');
      // Handle error appropriately, e.g., display error message to the user
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
