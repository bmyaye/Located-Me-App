import 'package:flutter/material.dart';
import 'package:location_app/app.dart';
import 'package:location_app/map.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location_app/simple_bloc_observer.dart';
import 'package:user_repository/user_repository.dart';
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

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => MapsPage()));
        },
        tooltip: 'Increment',
        child: const Icon(Icons.near_me),
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
        return _buildMessagesPage(theme);
      // case 2:
      //   return _buildNotificationsPage(theme);
      case 2:
        return _ProfilePage(theme);
      default:
        return Container(); // Placeholder, you can replace it with an error page or something else.
    }
  }

  Widget _buildHomePage(ThemeData theme) {
    return Card(
      shadowColor: Colors.transparent,
      margin: const EdgeInsets.all(5.0),
      child: SizedBox.expand(
        child: Center(
          child: Text(
            'Welcome to Locate Me Application',
            style: theme.textTheme.titleLarge!,
          ),
        ),
      ),
    );
  }

  // @override
  Widget _buildMessagesPage(ThemeData theme) {
    return ListView.builder(
      reverse: true,
      itemCount: 2,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.all(8.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Hello',
                style: theme.textTheme.bodyLarge!
                    .copyWith(color: theme.colorScheme.onPrimary),
              ),
            ),
          );
        }
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              'Hi!',
              style: theme.textTheme.bodyLarge!
                  .copyWith(color: theme.colorScheme.onPrimary),
            ),
          ),
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
          const Card(
            child: ListTile(
              leading: Icon(Icons.account_box),
              title: Text('My Account'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.location_city),
              title: Text('Location'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
            ),
          ),
          const Card(
            child: ListTile(
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
      ));
  }
}