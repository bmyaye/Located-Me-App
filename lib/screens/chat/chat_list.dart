import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location_app/screens/chat/chat_page.dart';

class UserList extends StatefulWidget {
  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchFriendsAndGroups(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data available.'));
        }

        Map<String, dynamic> data = snapshot.data!;
        List<DocumentSnapshot> friends = data['friends'];
        List<DocumentSnapshot> groups = data['groups'];

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                labelColor: Color.fromARGB(255, 13, 71, 161),
                unselectedLabelColor: Color.fromARGB(255, 145, 209, 255),
                indicatorColor: Colors.lightBlue,
                labelStyle: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.bold,
                ),
                tabs: [
                  Tab(text: 'Friends'),
                  Tab(text: 'Groups'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView(
                      children: [
                        ...friends.map((doc) => _buildUserListItem(doc, 'friend')).toList(),
                      ],
                    ),
                    ListView(
                      children: [
                        ...groups.map((doc) => _buildUserListItem(doc, 'group')).toList(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        .collection('groups_list')
        .where('members', arrayContains: currentUser.uid)
        .get();

    return {
      'friends': friendsSnapshot.docs,
      'groups': groupsSnapshot.docs,
    };
  }

  Widget _buildUserListItem(DocumentSnapshot document, String type) {
    Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;

    if (data == null) { 
      return ListTile(
        title: Text('Unknown $type'),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () {
            // Handle onPressed action appropriately
          },
        ),
      );
    }

    String title = type == 'friend'
        ? data['username'] ?? 'Unknown username'
        : data['groupName'] ?? 'Unknown group';

    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_outlined),
            onPressed: () {
              if (type == 'friend') {
                ChatManager().openChatPage(
                  context,
                  friendId: document.id,
                  friendName: data['username'],
                );
              } else {
                ChatManager().openChatPage(
                  context,
                  groupId: document.id,
                  groupName: data['groupName'],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class ChatManager {
  void openChatPage(
    BuildContext context, {
    String? friendId,
    String? friendName,
    String? groupId,
    String? groupName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          friendId: friendId,
          friendName: friendName,
          groupId: groupId,
          groupName: groupName,
        ),
      ),
    );
  }
}
