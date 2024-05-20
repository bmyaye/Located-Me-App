import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:location_app/app.dart';
import 'package:location_app/map.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location_app/screens/chat/group_page.dart';
import 'package:location_app/simple_bloc_observer.dart';
import 'package:user_repository/user_repository.dart';
// import 'blocs/authentication_bloc/authentication_bloc.dart';
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
      // home: const MyHomePage(title: 'Location App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState('');
}

class _MyHomePageState extends State<MyHomePage> {
  int currentPageIndex = 0;

  final String username;

  _MyHomePageState(this.username);
  
  // String get currentUsername => username;

  final user = FirebaseAuth.instance.currentUser;

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
        return _HomePage(theme);
      case 1:
        return _MessagesPage(context);
      // case 2:
      //   return _buildNotificationsPage(theme);
      case 2:
        return _ProfilePage(context);
      default:
        return Container(); // Placeholder, you can replace it with an error page or something else.
    }
  }

  Widget _HomePage(ThemeData theme) {
    return Scaffold(
      body: Center(
        child: Text(
          'Welcome to Locate Me Application',
          style: theme.textTheme.titleLarge,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MapsPage()),
          );
        },
        tooltip: 'Increment',
        child: const Icon(Icons.near_me),
      ),
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
