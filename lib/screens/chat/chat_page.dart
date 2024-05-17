import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatManager {
  void openChatPage(
    BuildContext context,
    {String? friendId, String? friendName, String? groupId, String? groupName}
  ) {
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
                builder: (context, currentUserSnapshot) {
                  if (currentUserSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (currentUserSnapshot.hasData) {
                    List<DocumentSnapshot> messages = currentUserSnapshot.data!.docs;
                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        var message = messages[index];
                        bool isSentMessage = message['senderId'] == FirebaseAuth.instance.currentUser!.uid;
                        // String senderName = isSentMessage ? 'You' : message['senderName'];

                      return Column(
                          crossAxisAlignment: isSentMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8.0), 
                            // const Padding(
                            //   padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                            //   child: Text(
                            //     senderName,
                            //     style: TextStyle(
                            //       fontWeight: FontWeight.bold,
                            //       color: isSentMessage ? Colors.blue : Colors.green,
                            //     ),
                            //   ),
                            // ),
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
                      onPressed: () => _sendMessage(widget.friendId ?? widget.groupId ?? ''),
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

  void _sendMessage(String receiverId,) async {
    String messageContent = _messageController.text.trim();

    if (messageContent.isNotEmpty) {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      DocumentReference currentUserDocRef = 
          FirebaseFirestore.instance.collection('users').doc(userId);

      Map<String, dynamic> currentUserData = (await currentUserDocRef.get()).data() as Map<String, dynamic>;

      String currentUsername = currentUserData['username']; 

      // DocumentReference friendId =
      //     FirebaseFirestore.instance.collection('users').doc(receiverId);

      print(receiverId);
      
      DocumentReference messageRef;
      if (widget.friendId != null) {
        messageRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('friends')
            .doc(widget.friendId)
            .collection('messages')
            .doc();
      } else if (widget.groupId != null) {
        messageRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('groups')
            .doc(widget.groupId)
            .collection('messages')
            .doc();
      } else {
        throw Exception('Both friendId and groupId are null.');
      }

      await messageRef.set({
        'content': messageContent,
        'senderId': userId,
        'senderName': currentUsername,
        // 'receiverId': friendId.id,
        // 'receiverUsername': widget.friendName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    }
  }
}
