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
//   List<String> _messages = []; // List to hold messages

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
//                 return ListTile(
//                   title: Text(_messages[index]),
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
//                     padding: EdgeInsets.symmetric(horizontal: 10.0),
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
//                 SizedBox(width: 8.0),
//                 IconButton(
//                   icon: Icon(Icons.send),
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
//     String message = _messageController.text.trim();
//     if (message.isNotEmpty) {
//       // Add message to the list of messages
//       setState(() {
//         _messages.add(message);
//       });

//       // Clear the input field
//       _messageController.clear();
//     }
//   }
// }

import 'package:flutter/material.dart';


class ChatManager {
  void openChatPage(BuildContext context, String friendId, String friendName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          friendId: friendId,
          friendName: friendName, 
          userId: '',
          username: '',
        ),
      ),
    );
  }

  void showSendMessageDialog(BuildContext context, String friendId) {
    TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _sendMessage(friendId, messageController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Send'),
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

  void _sendMessage(String friendId, String messageContent) async {
    // Logic to send message to friendId
  }
}

class Message {
  final String content;
  final String senderId;
  final String senderName;

  Message({
    required this.content,
    required this.senderId,
    required this.senderName,
  });
}

class ChatPage extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String userId;
  final String username;

  ChatPage({
    required this.friendId,
    required this.friendName,
    required this.userId,
    required this.username,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatManager chatManager = ChatManager(); // Create an instance of ChatManager
  final TextEditingController _messageController = TextEditingController();
  List<Message> _messages = []; // List to hold messages

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friendName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                Message message = _messages[index];
                // Check if the message is from the current friend
                bool isFromFriend = message.senderId == widget.friendId;
                return ListTile(
                  title: Text(
                    message.content,
                    textAlign: isFromFriend ? TextAlign.end : TextAlign.start,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                  onPressed: () {
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    String messageContent = _messageController.text.trim();
    if (messageContent.isNotEmpty) {
      // Create a new Message instance with sender information
      Message message = Message(
        content: messageContent,
        senderId: widget.userId, // Current user's ID
        senderName: widget.username, // Current user's name
      );

      // Add the message to the list of messages
      setState(() {
        _messages.add(message);
      });

      // Clear the input field
      _messageController.clear();
    }
  }
}