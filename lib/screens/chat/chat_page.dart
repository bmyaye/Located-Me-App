import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatManager {
  void openChatPage(BuildContext context, String friendId, String friendName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          friendId: friendId,
          friendName: friendName,
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String friendId;
  final String friendName;

  ChatPage({required this.friendId, required this.friendName});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friendName),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
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
                    List<DocumentSnapshot> currentUserMessages = currentUserSnapshot.data!.docs;
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.friendId)
                          .collection('messages')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> friendSnapshot) {
                        if (friendSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (friendSnapshot.hasData) {
                          List<DocumentSnapshot> friendMessages = friendSnapshot.data!.docs;
                          // Combine and sort messages from both users
                          List<DocumentSnapshot> allMessages = [...currentUserMessages, ...friendMessages];
                          allMessages.sort((a, b) {
                            Timestamp? timestampA = a['timestamp'];
                            Timestamp? timestampB = b['timestamp'];
                            // Check if timestamps are not null before comparing
                            if (timestampA != null && timestampB != null) {
                              return timestampB.compareTo(timestampA);
                            } else {
                              // Handle case where one or both timestamps are null
                              // For example, if timestampA is null but timestampB is not,
                              // we want to prioritize the message with a non-null timestamp
                              if (timestampA == null && timestampB != null) {
                                return 1;
                              } else if (timestampA != null && timestampB == null) {
                                return -1;
                              } else {
                                // If both timestamps are null, consider them equal
                                return 0;
                              }
                            }
                          });

                          return ListView.builder(
                            reverse: true,
                            itemCount: allMessages.length,
                            itemBuilder: (context, index) {
                              var message = allMessages[index];
                              bool isSentMessage = message['senderId'] == FirebaseAuth.instance.currentUser!.uid;

                              // Display the sender's name above each message
                              // String senderName = isSentMessage ? '' : widget.friendName;

                              return Column(
                                crossAxisAlignment: isSentMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  // Display the sender name above each message
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                                    // child: Text(
                                    //   senderName,
                                    //   style: TextStyle(
                                    //     fontWeight: FontWeight.bold,
                                    //     color: isSentMessage ? Colors.blue : Colors.green,
                                    //   ),
                                    // ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: isSentMessage ? Colors.blue.withOpacity(0.2) : Colors.green.withOpacity(0.2),
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
                          // Handle case where friend's messages snapshot has no data
                          return const Center(
                            child: Text('No messages available.'),
                          );
                        }
                      },
                    );
                  } else {
                    // Handle case where current user's messages snapshot has no data
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
                      onPressed: () => _sendMessage(widget.friendId),
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

  void _sendMessage(String receiverId) async {
    String messageContent = _messageController.text.trim();
    if (messageContent.isNotEmpty) {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Reference to the friend's document
      DocumentReference friendDocRef =
          FirebaseFirestore.instance.collection('users').doc(receiverId);

      // Add the message to the friend's "messages" subcollection
      await friendDocRef.collection('messages').add({
        'content': messageContent,
        'senderId': userId,
        'receiverId': receiverId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    }
  }
}

