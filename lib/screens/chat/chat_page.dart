// import 'package:flutter/material.dart';

// class ChatManager {
//   void openChatPage(BuildContext context, String friendId, String friendName) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ChatPage(
//           friendId: friendId,
//           friendName: friendName, 
//           userId: '',
//           username: '',
//         ),
//       ),
//     );
//   }

//   void showSendMessageDialog(BuildContext context, String friendId) {
//     TextEditingController messageController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Send Message'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: messageController,
//                 decoration: const InputDecoration(labelText: 'Message'),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 _sendMessage(friendId, messageController.text);
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Send'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Cancel'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _sendMessage(String friendId, String messageContent) async {
//     // Logic to send message to friendId
//   }
// }

// class Message {
//   final String content;
//   final String senderId;
//   final String senderName;

//   Message({
//     required this.content,
//     required this.senderId,
//     required this.senderName,
//   });
// }

// class ChatPage extends StatefulWidget {
//   final String friendId;
//   final String friendName;
//   final String userId;
//   final String username;

//   ChatPage({
//     required this.friendId,
//     required this.friendName,
//     required this.userId,
//     required this.username,
//   });

//   @override
//   _ChatPageState createState() => _ChatPageState();
// }

// class _ChatPageState extends State<ChatPage> {
//   final ChatManager chatManager = ChatManager(); // Create an instance of ChatManager
//   final TextEditingController _messageController = TextEditingController();
//   List<Message> _messages = []; // List to hold messages

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.friendName),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 Message message = _messages[index];
//                 // Check if the message is from the current friend
//                 bool isFromFriend = message.senderId == widget.friendId;
//                 return ListTile(
//                   title: Text(
//                     message.content,
//                     textAlign: isFromFriend ? TextAlign.end : TextAlign.start,
//                   ),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 10.0),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(20.0),
//                     ),
//                     child: TextField(
//                       controller: _messageController,
//                       decoration: const InputDecoration(
//                         hintText: 'Type your message...',
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8.0),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   color: Colors.blue,
//                   onPressed: () {
//                     _sendMessage();
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _sendMessage() {
//     String messageContent = _messageController.text.trim();
//     if (messageContent.isNotEmpty) {
//       // Create a new Message instance with sender information
//       Message message = Message(
//         content: messageContent,
//         senderId: widget.userId, // Current user's ID
//         senderName: widget.username, // Current user's name
//       );

//       // Add the message to the list of messages
//       setState(() {
//         _messages.add(message);
//       });

//       // Clear the input field
//       _messageController.clear();
//     }
//   }
// }

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

