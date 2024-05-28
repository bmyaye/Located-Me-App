import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:user_repository/user_repository.dart';
import 'package:location_app/app.dart';
import 'package:location_app/map.dart';
import 'package:location_app/screens/chat/group_page.dart';
import 'package:location_app/simple_bloc_observer.dart';
import 'screens/auth/blocs/sign_in_bloc/sign_in_bloc.dart';
import 'screens/chat/chat_list.dart';
import 'screens/chat/friends_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Bloc.observer = SimpleBlocObserver();

  runApp(MyApp(FirebaseUserRepo()));
}

class AppBarApp extends StatelessWidget {
  const AppBarApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color.fromARGB(255, 145, 209, 255),
        ),
        useMaterial3: true,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            widget.title,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 145, 209, 255),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color.fromARGB(255, 145, 209, 255),
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        // indicatorColor: Colors.amber,
        indicatorColor: Colors.blue,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(
              Icons.home_outlined,
              color: Colors.white,
            ),
            // icon: Icon(Icons.home_outlined),
            icon: Icon(
              Icons.home,
              color: Colors.blue,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(
              Icons.message_outlined,
              color: Colors.white,
            ),
            // icon: Icon(Icons.message_outlined),
            icon: Icon(
              Icons.message,
              color: Colors.blue,
            ),
            label: 'Messages'
          ),
          NavigationDestination(
            selectedIcon: Icon(
              Icons.account_box_outlined,
              color: Colors.white,
            ),
            // icon: Icon(Icons.account_box_outlined),
            icon: Icon(
              Icons.account_box,
              color: Colors.blue,
            ),
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
        return _HomePage(theme);
      case 1:
        return _MessagesPage(context);
      case 2:
        return _ProfilePage(context);
      default:
        return Container(); // Placeholder, you can replace it with an error page or something else.
    }
  }

  Widget _HomePage(ThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;
    final double width = MediaQuery.of(context).size.width;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    return Scaffold(
      backgroundColor: Colors.blue[40],
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: users.doc(user!.uid).get(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("User data not found"));
            } else {
              var userData = snapshot.data!.data() as Map<String, dynamic>;
              var username = userData['username'];
              return Column(
                children: <Widget>[
                  Container(
                    height: 150,
                    width: width,
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 145, 209, 255),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30.0),
                          bottomRight: Radius.circular(30.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ]),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 0.0
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                    child: Text(
                                      username,
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontSize: 50.0,
                                        color: Colors.blue[900],
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: const Text(
                                      'Application User',
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Card(
                        elevation: 60,
                        shadowColor: Colors.black,
                        color: Colors.blueAccent[50],
                        child: SizedBox(
                          width: 400,
                          height: 575,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  radius: 100,
                                  child: Center(
                                    child: Text(
                                      '📍',
                                      style: TextStyle(
                                        fontSize: 100,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 145, 209, 255),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 50),
                                Text(
                                  'Welcome to Locate Me Application',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'test',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: user != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapsPage(firestoreUserID: user.uid),
                  ),
                );
              },
              tooltip: 'Open Maps',
              child: const Icon(Icons.near_me),
            )
          : null,
    );
  }

  Widget _MessagesPage(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: UserList(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                FriendManager(context).showAddFriendDialog();
              },
              child: const Text('Add Friends'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                GroupManager(context).showCreateGroupDialog();
              },
              child: const Text('Create Group'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ProfilePage(BuildContext context) {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    User? user = FirebaseAuth.instance.currentUser;

    return Center(
      child: Column(
        children: <Widget>[
          FutureBuilder<DocumentSnapshot>(
            future: users.doc(user!.uid).get(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  var userData = snapshot.data!.data() as Map<String, dynamic>;
                  var username = userData['username'];
                  return ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: const Text('My Account'),
                    subtitle: Text(username),
                  );
                } else {
                  return const Text("No user data found");
                }
              }
              return const CircularProgressIndicator();
            },
          ),
          const ListTile(
            leading: Icon(Icons.location_on_outlined),
            title: Text('Location'),
          ),
          const ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
          ),
          const ListTile(
            leading: Icon(Icons.help_center_outlined),
            title: Text('Help Center'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<SignInBloc>().add(SignOutRequired());
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}