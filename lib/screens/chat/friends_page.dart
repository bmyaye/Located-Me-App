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
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchFriendsAndGroups(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No data available.'),
          );
        }

        Map<String, dynamic> data = snapshot.data!;
        List<DocumentSnapshot> friends = data['friends'];
        List<DocumentSnapshot> groups = data['groups'];

        return ListView(
          children: [
            ...friends.map((doc) => _buildUserListItem(doc, 'friend')).toList(),
            ...groups.map((doc) => _buildUserListItem(doc, 'group')).toList(),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchFriendsAndGroups() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated');
    }

    QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('friends')
        .get();

    QuerySnapshot groupsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('groups')
        .get();

    return {
      'friends': friendsSnapshot.docs,
      'groups': groupsSnapshot.docs,
    };
  }

  Widget _buildUserListItem(DocumentSnapshot document, String type) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    if (type == 'friend') {
      String friendUsername = data['username'];
      return ListTile(
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () {
            ChatManager().openChatPage(context,
              friendId: document.id,
              friendName: friendUsername,
            );
          },
        ),
        title: Text(friendUsername),
      );
    } else if (type == 'group') {
      String groupName = data['group name'];
      return ListTile(
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () {
            ChatManager().openChatPage(context,
              groupId: document.id,
              groupName: groupName,
            );
          },
        ),
        title: Text(groupName),
      );
    } else {
      return const SizedBox();
    }
  }

}


class FriendManager {
  final BuildContext context;

  FriendManager(this.context);

  // final databaseReference = FirebaseDatabase.instance.ref("StoreData");

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

class GroupList extends StatefulWidget {
  @override
  _GroupListState createState() => _GroupListState();
}

class _GroupListState extends State<GroupList> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('groups')
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

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('You have no groups yet.'),
          );
        }

        return ListView(
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildGroupListItem(doc))
              .toList(),
        );
      },
    );
  }

  Widget _buildGroupListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    String groupId = document.id;
    String groupName = data['name'];

    return ListTile(
      title: Text(groupName),
      trailing: IconButton(
        icon: const Icon(Icons.arrow_forward_ios),
        onPressed: () {
          // Navigate to ChatPage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                friendId: '',
                friendName: '',
                groupId: groupId,
                groupName: groupName,
              ),
            ),
          );
        },
      ),
    );
  }
}
