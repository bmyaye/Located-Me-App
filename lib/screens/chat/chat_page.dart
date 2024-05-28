import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String? friendId;
  final String? friendName;
  final String? groupId;
  final String? groupName;

  ChatPage({
    this.friendId,
    this.friendName,
    this.groupId,
    this.groupName,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friendName ?? widget.groupName ?? 'Chat'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: widget.friendId != null
                    ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection('friends')
                        .doc(widget.friendId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection('groups')
                        .doc(widget.groupId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasData) {
                    List<DocumentSnapshot> messages = snapshot.data!.docs;
                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        var message = messages[index];
                        bool isSentMessage = message['senderId'] == FirebaseAuth.instance.currentUser!.uid;

                        return Column(
                          crossAxisAlignment: isSentMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8.0), 
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: isSentMessage ? Colors.blue.withOpacity(0.2) : Colors.yellow.withOpacity(0.2),
                                  borderRadius: isSentMessage
                                      ? const BorderRadius.only(
                                          topLeft: Radius.circular(12.0),
                                          bottomLeft: Radius.circular(12.0),
                                          bottomRight: Radius.circular(12.0),
                                        )
                                      : const BorderRadius.only(
                                          topRight: Radius.circular(12.0),
                                          bottomLeft: Radius.circular(12.0),
                                          bottomRight: Radius.circular(12.0),
                                        ),
                                ),
                                child: Text(
                                  message['content'],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: Text('No messages available.'),
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.lightBlue),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _sendMessage(widget.friendId, widget.groupId),
                      color: Colors.lightBlue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String? friendId, String? groupId) async {
    String messageContent = _messageController.text.trim();

    if (messageContent.isNotEmpty) {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      Map<String, dynamic> messageData = {
        'senderId': userId,
        'content': messageContent,
        // 'timestamp': FieldValue.serverTimestamp(),
        'timestamp': timestamp,
      };

      if (friendId != null) {
        await _sendMessageToFriend(userId, friendId, messageData);
      } else if (groupId != null) {
        await _sendMessageToGroup(userId, groupId, messageData);
      }

      _messageController.clear();
    }
  }

  Future<void> _sendMessageToFriend(String userId, String friendId, Map<String, dynamic> messageData) async {
    try {
      // Add message to the sender's 'friends' subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendId)
          .collection('messages')
          .add(messageData);

      // Add message to the recipient's 'friends' subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(userId)
          .collection('messages')
          .add(messageData);

      print('Message sent to friend successfully');
    } catch (e) {
      print('Error sending message to friend: $e');
    }
  }

  Future<void> _sendMessageToGroup(String userId, String groupId, Map<String, dynamic> messageData) async {
    try {
      // Retrieve the group's member list
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('groups')
          .doc(groupId)
          .get();

      if (groupSnapshot.exists) {
        List<dynamic> members = groupSnapshot['members'];

        // Add message to each member's 'groups' subcollection
        for (String memberId in members) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(memberId)
              .collection('groups')
              .doc(groupId)
              .collection('messages')
              .add(messageData);
        }

        print('Message sent to group successfully');
      } else {
        print('Group not found');
      }
    } catch (e) {
      print('Error sending message to group: $e');
    }
  }
}
