import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupManager {
  final BuildContext context;

  GroupManager(this.context);

  FirebaseFirestore firestore = FirebaseFirestore.instance;

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
              onPressed: () async {
                Navigator.of(context).pop();
                await _createGroup(groupNameController.text);
              },
              child: const Text('Next'),
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

  Future<void> _createGroup(String groupName) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        List<String>? selectedFriends = await showDialog(
          context: context,
          builder: (context) => FriendSelectionDialog(),
        );

        if (selectedFriends != null && selectedFriends.isNotEmpty) {
          String groupId = firestore.collection('users').doc(currentUser.uid).collection('groups').doc().id;
          
          await firestore.collection('users').doc(currentUser.uid).collection('groups').doc(groupId).set({
            'groupName': groupName,
            'creator': currentUser.uid,
            'members': [currentUser.uid, ...selectedFriends],
          });

          await _addGroupToUsers(groupId, groupName, currentUser.uid, selectedFriends);
        } else {
          print('No friends selected.');
        }
      } else {
        print('User is not authenticated');
      }
    } catch (e) {
      print('Error creating group: $e');
    }
  }

  Future<void> _addGroupToUsers(String groupId, String groupName, String creatorId, List<String> memberIds) async {
    try {
      for (String memberId in memberIds) {
        await firestore.collection('users').doc(memberId).collection('groups').doc(groupId).set({
          'groupId': groupId,
          'groupName': groupName,
          'creator': creatorId,
          'members': [creatorId, ...memberIds],
        }, SetOptions(merge: true));
      }
      print('Group data added to all members\' databases.');
    } catch (e) {
      print('Error adding group to members: $e');
    }
  }
}

class FriendSelectionDialog extends StatefulWidget {
  @override
  _FriendSelectionDialogState createState() => _FriendSelectionDialogState();
}

class _FriendSelectionDialogState extends State<FriendSelectionDialog> {
  final List<String> selectedFriends = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Friends'),
      content: Container(
        width: double.maxFinite,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .collection('friends')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No friends available.'));
            }

            final friends = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                final friendId = friend.id;
                final friendUsername = friend['username'];

                return ListTile(
                  title: Text(friendUsername),
                  onTap: () {
                    setState(() {
                      if (selectedFriends.contains(friendId)) {
                        selectedFriends.remove(friendId);
                      } else {
                        selectedFriends.add(friendId);
                      }
                    });
                  },
                  trailing: Icon(
                    selectedFriends.contains(friendId)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, selectedFriends);
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}
