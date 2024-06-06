import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

  void showQRDialog(BuildContext context, String groupId, String groupName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Group QR Code',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blue[900],
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Group Name: $groupName'),
              SizedBox(height: 10), // Adjust as needed
              FutureBuilder<Uint8List?>(
                future: _generateQrImageData(groupId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  return Image.memory(snapshot.data!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Uint8List> _generateQrImageData(String groupId) async {
    final qrPainter = QrPainter(
      data: groupId,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );
    final imageSize = 200.0;
    final image = await qrPainter.toImageData(imageSize);

    return image?.buffer.asUint8List() ?? Uint8List(0);
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
          String groupId = firestore.collection('groups_list').doc().id;
          List<String> allMembers = [currentUser.uid, ...selectedFriends];

          // Create the group in the main 'groups' collection
          await firestore.collection('groups_list').doc(groupId).set({
            'groupName': groupName,
            'groupId': groupId,
            'creator': currentUser.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'members': allMembers,
          });

          // Add the members to the 'members' subcollection
          for (String memberId in allMembers) {
            await firestore
                .collection('groups_list')
                .doc(groupId)
                .collection('members')
                .doc(memberId)
                .set({
              'joinedAt': FieldValue.serverTimestamp(),
            });
          }

          // Add the group reference to the users' documents
          await _addGroupToUsers(
              groupId, groupName, currentUser.uid, allMembers);

          // Show the QR dialog
          showQRDialog(context, groupId, groupName);
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

  Future<void> _addGroupToUsers(String groupId, String groupName,
      String creatorId, List<String> memberIds) async {
    try {
      for (String memberId in memberIds) {
        await firestore
            .collection('users')
            .doc(memberId)
            .collection('groups')
            .doc(groupId)
            .set({
          'groupId': groupId,
          'groupName': groupName,
          'creator': creatorId,
          'joinedAt': FieldValue.serverTimestamp(),
          'members': memberIds,
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
