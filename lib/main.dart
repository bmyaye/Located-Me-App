import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:location_app/app.dart';
import 'package:location_app/chat_page.dart';
import 'package:location_app/map.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location_app/simple_bloc_observer.dart';
import 'package:user_repository/user_repository.dart';
import 'blocs/authentication_bloc/authentication_bloc.dart';
import 'screens/auth/blocs/sign_in_bloc/sign_in_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Bloc.observer = SimpleBlocObserver();

  runApp(MyApp(FirebaseUserRepo()));
}

class AppBarApp extends StatelessWidget {
  const AppBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: const Color.fromARGB(255, 145, 209, 255),
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: 'Location App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // final ButtonStyle style = ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),

      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },

        indicatorColor: Colors.amber,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.message),
            icon: Icon(Icons.message_outlined), 
            label: 'Messages'
          ),
          // NavigationDestination(
          //   selectedIcon: Icon(Icons.notifications),
          //   icon: Icon(Icons.notifications_outlined),
          //   label: 'Notifications',
          // ),
          NavigationDestination(
            selectedIcon: Icon(Icons.account_box),
            icon: Icon(Icons.account_box_outlined),
            label: 'Account',
          ),
        ],
      ),

      body: _buildPage(currentPageIndex, theme),
    );
  }

  Widget _buildPage(int index, ThemeData theme) {
    switch (index) {
      case 0:
        return _buildHomePage(theme);
      case 1:
        return _MessagesPage(context);
        // return _buildMessagesPage(theme);
      // case 2:
      //   return _buildNotificationsPage(theme);
      case 2:
        return _ProfilePage(theme);
      default:
        return Container(); // Placeholder, you can replace it with an error page or something else.
    }
  }

  // @override
  Widget _buildHomePage(ThemeData theme) {
    return Scaffold(
      body: Center(
        child: Text(
          'Welcome to Locate Me Application',
          style: theme.textTheme.titleLarge!,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => MapsPage()));
        },
        tooltip: 'Increment',
        child: const Icon(Icons.near_me),
      ),
    );
  }

  Widget _MessagesPage(BuildContext context) {
    TextEditingController usernameController = TextEditingController();
    TextEditingController emailController = TextEditingController();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _buildUserList(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                _showAddFriendDialog(context, usernameController, emailController);
              },
              child: const Text('Add Friends'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('friends')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...');
        }

        // Check if there are no friends
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('You have no friends yet.'),
          );
        }

        return ListView(
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildUserListItem(doc))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    return ListTile(
      title: Text(data['username']),
      // subtitle: Text(data['email']),
      trailing: IconButton(
        onPressed: () {
          // Action when you press on a friend's item in the list
        },
        icon: const Icon(Icons.chat),
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context, TextEditingController usernameController, TextEditingController emailController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Friend'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Friend\'s Username'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Friend\'s Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Logic to add the friend
                _addFriend(usernameController.text, emailController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
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

  void _addFriend(String username, String email) async {
    try {
      // Check if the friend's email exists in the "users" collection
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .where('username', isEqualTo: username)
          .get();

      if (usersSnapshot.docs.isNotEmpty) {
        // Friend's email found in the "users" collection
        // Access the first document in the snapshot
        DocumentSnapshot friendDoc = usersSnapshot.docs.first;

        // Get the current user
        User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          // Get a reference to the Firestore instance
          FirebaseFirestore firestore = FirebaseFirestore.instance;

          // Reference to the current user's document
          DocumentReference currentUserDocRef = firestore.collection('users').doc(currentUser.uid);

          // Reference to the friend's document
          DocumentReference friendDocRef = firestore.collection('users').doc(friendDoc.id);

          // Check if the friend is already in the current user's friend list
          bool isFriendAlreadyAdded = await currentUserDocRef.collection('friends')
              .where('email', isEqualTo: email)
              .where('username', isEqualTo: username)
              .get()
              .then((querySnapshot) => querySnapshot.docs.isNotEmpty);

          if (!isFriendAlreadyAdded) {
            // Add friend to the current user's friend list
            await currentUserDocRef.collection('friends').add({
              'username': username, // Ensure username is properly set
              'email': email,
            });
          }

          // Check if the current user is already in the friend's friend list
          bool isCurrentUserAlreadyAdded = await friendDocRef.collection('friends')
              .where('email', isEqualTo: currentUser.email)
              .where('username', isEqualTo: currentUser.displayName)
              .get()
              .then((querySnapshot) => querySnapshot.docs.isNotEmpty);

          if (!isCurrentUserAlreadyAdded) {
            // Add current user to the friend's friend list
            await friendDocRef.collection('friends').add({
              'username': currentUser.displayName ?? 'Unknown',
              'email': currentUser.email ?? 'Unknown',
            });
          }
        } else {
          print('User is not authenticated');
          // Handle error appropriately, e.g., display error message to the user
        }
      } else {
        // Friend's email not found in the "users" collection
        _showFriendNotRegisteredDialog(email);
      }
    } catch (e) {
      print('Error retrieving user snapshot: $e');
      // Handle error appropriately, e.g., display error message to the user
    }
  }

  void _showFriendNotRegisteredDialog(String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Friend Not Registered'),
          content: Text('The friend with email $email is not registered.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  } 

  // // @override
  // Widget _buildNotificationsPage(ThemeData theme) {
  //   return const Padding(
  //     padding: EdgeInsets.all(8.0),
  //     child: Column(
  //       children: <Widget>[
  //         Card(
  //           child: ListTile(
  //             leading: Icon(Icons.notifications_sharp),
  //             title: Text('Notification 1'),
  //             subtitle: Text('This is a notification'),
  //           ),
  //         ),
  //         Card(
  //           child: ListTile(
  //             leading: Icon(Icons.notifications_sharp),
  //             title: Text('Notification 2'),
  //             subtitle: Text('This is a notification'),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // @override
  Widget _ProfilePage(ThemeData theme) {
    return Center(
      child: Column(
        children: <Widget>[
          Container(
            child: const ListTile(
              leading: Icon(Icons.account_box),
              title: Text('My Account'),
            ),
          ),
          Container(
            child: const ListTile(
              leading: Icon(Icons.location_city),
              title: Text('Location'),
            ),
          ),
          Container(
            child: const ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
            ),
          ),
          Container(
            child: const ListTile(
              leading: Icon(Icons.help_center),
              title: Text('Help Center'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<SignInBloc>().add(SignOutRequired());
            },
            child: const Text('Sign Out'),
          ),
        ],
      )
    );
  }
}

