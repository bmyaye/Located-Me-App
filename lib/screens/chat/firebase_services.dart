import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initializeUser() async {
    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Check if the 'messages' collection exists for the user
      bool messagesCollectionExists = await _checkMessagesCollection(user.uid);

      // If 'messages' collection doesn't exist, create it
      if (!messagesCollectionExists) {
        await _createMessagesCollection(user.uid);
      }
    }
  }

  Future<bool> _checkMessagesCollection(String userId) async {
    try {
      // Check if the 'messages' collection exists for the user
      var docSnapshot = await _firestore.collection('users').doc(userId).collection('messages').doc('placeholder').get();
      return docSnapshot.exists;
    } catch (e) {
      print('Error checking messages collection: $e');
      return false;
    }
  }

  Future<void> _createMessagesCollection(String userId) async {
    try {
      // Create the 'messages' collection for the user
      await _firestore.collection('users').doc(userId).collection('messages').doc('placeholder').set({});
      print('Messages collection created for user $userId');
    } catch (e) {
      print('Error creating messages collection: $e');
    }
  }
}