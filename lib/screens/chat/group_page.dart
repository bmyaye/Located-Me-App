import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location_app/screens/chat/chat_page.dart';

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
        // Navigate to friend selection dialog
        List<String>? selectedFriends = await showDialog(
          context: context,
          builder: (context) => FriendSelectionDialog(),
        );

        if (selectedFriends != null && selectedFriends.isNotEmpty) {
          // Create group with selected friends
          DocumentReference groupRef = await firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('groups')
              .add({
            'group name': groupName,
            'creator': currentUser.uid ,
            'friends': selectedFriends,
          });

          print('Group created successfully with ID: ${groupRef.id}');

          // Show AddMemberPopup
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AddMemberPopup(groupRef.id);
            },
          );
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
}

class AddMemberPopup extends StatefulWidget {
  final String groupId;

  AddMemberPopup(this.groupId);

  @override
  _AddMemberPopupState createState() => _AddMemberPopupState();
}

class _AddMemberPopupState extends State<AddMemberPopup> {
  late List<String> friendIds = [];

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  void _fetchFriends() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        Map<String, dynamic>? userData = snapshot.data() as Map<String, dynamic>?;

        if (userData != null && userData.containsKey('friends')) {
          dynamic friendsData = userData['friends'];
          if (friendsData is List) {
            setState(() {
              friendIds = List<String>.from(friendsData);
            });
            print('Fetched ${friendIds.length} friends');
          } else {
            print('Friends data is not a list.');
          }
        } else {
          print('User data does not contain friends list.');
        }
      }
    } catch (e) {
      print('Error fetching friends: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Members'),
      content: ListView.builder(
        shrinkWrap: true,
        itemCount: friendIds.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(friendIds[index]),
            onTap: () {
              // Add friend to group logic
              _addMemberToGroup(friendIds[index]);
            },
          );
        },
      ),
    );
  }

  void _addMemberToGroup(String friendId) {
    try {
      FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('groups')
          .doc(widget.groupId)
          .set({'member': true}, SetOptions(merge: true))
          .then((_) {
        print('Added $friendId to group ${widget.groupId}');
        Navigator.pop(context);
      });
    } catch (e) {
      print('Error adding member to group: $e');
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
                final friendUsername = friend['username'];

                return ListTile(
                  title: Text(friendUsername),
                  onTap: () {
                    setState(() {
                      if (selectedFriends.contains(friendUsername)) {
                        selectedFriends.remove(friendUsername);
                      } else {
                        selectedFriends.add(friendUsername);
                      }
                    });
                  },
                  trailing: Icon(
                    selectedFriends.contains(friendUsername)
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