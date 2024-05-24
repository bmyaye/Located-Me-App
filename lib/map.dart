import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapsPage extends StatefulWidget {
  final String firestoreUserID;

  MapsPage({required this.firestoreUserID});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  Position? userLocation;
  late GoogleMapController mapController;
  late DatabaseReference userRef;
  Timer? locationUpdateTimer;
  Map<String, LatLng> friendsLocations = {};
  Map<String, String> friendsUsernames = {};
  bool hasActiveLocations = true;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  @override
  void dispose() {
    locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.firestoreUserID)
          .get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        var userName = userData['username'];
        var userId = userData['userId'];
        hasActiveLocations = userData['hasActiveLocations'] ?? true;

        userRef = FirebaseDatabase.instance.ref('users/$userId');

        await setLocation(userName, userId);

        await _getFriendsLocations();
      } else {
        print("No user data found");
      }
    } catch (e) {
      print("Error initializing user: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> setLocation(String userName, String userId) async {
    final position = await _getLocation();
    if (position != null) {
      if (mounted) {
        setState(() {
          userLocation = position;
        });
      }

      locationUpdateTimer =
          Timer.periodic(const Duration(seconds: 5), (timer) async {
        final updatedPosition = await _getLocation();
        if (updatedPosition != null) {
          if (hasActiveLocations) {
            print(
                'Updating location for $userId: (${updatedPosition.latitude}, ${updatedPosition.longitude})');
            userRef.update({
              'username': userName,
              'userId': userId,
              'latitude': updatedPosition.latitude,
              'longitude': updatedPosition.longitude,
              'hasActiveLocations': true,
            });
          } else {
            print('User $userId has deactivated location sharing');
            userRef.update({
              'username': userName,
              'userId': userId,
              'hasActiveLocations': false,
            });
          }
          if (mounted) {
            setState(() {
              userLocation = updatedPosition;
            });
          }
        }
      });
    }
  }

  Future<void> _getFriendsLocations() async {
    try {
      QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.firestoreUserID)
          .collection('friends')
          .get();

      for (var doc in friendsSnapshot.docs) {
        var friendId = doc['userId'];
        var friendUsername = doc['username'];
        print('Friend ID: $friendId');

        DatabaseReference friendRef =
            FirebaseDatabase.instance.ref('users/$friendId');
        friendRef.onValue.listen((event) {
          var friendData = event.snapshot.value as Map<dynamic, dynamic>;
          print('Friend Data for $friendId: $friendData');

          var friendHasActiveLocations =
              friendData['hasActiveLocations'] ?? true;
          if (friendHasActiveLocations) {
            var latitude = friendData['latitude'];
            var longitude = friendData['longitude'];
            print('Friend $friendId is visible at ($latitude, $longitude)');

            if (mounted) {
              setState(() {
                friendsLocations[friendId] = LatLng(latitude, longitude);
                friendsUsernames[friendId] = friendUsername;
              });
            }
          } else {
            print('Friend $friendId is not visible');
            if (mounted) {
              setState(() {
                friendsLocations.remove(friendId);
              });
            }
          }
        });
      }
    } catch (e) {
      print("Error getting friend locations: $e");
    }
  }

  Future<Position?> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServicesDialog();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to continue.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Set<Marker> _createFriendMarkers() {
    return friendsLocations.entries.map((entry) {
      // 
      String friendId = entry.key;
      LatLng position = entry.value;
      String? username = friendsUsernames[friendId];

      print('Creating marker for friend $friendId at ${position.latitude}, ${position.longitude}');
      return Marker(
        markerId: MarkerId('friend_marker_$friendId'),
        position: entry.value,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: username ?? 'Unknown',
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps'),
        actions: [
          Switch(
            value: hasActiveLocations,
            onChanged: (value) {
              setState(() {
                hasActiveLocations = value;
              });
              print(
                  'Updating hasActiveLocations for user: $hasActiveLocations');
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.firestoreUserID)
                  .update({'hasActiveLocations': hasActiveLocations});
            },
          ),
        ],
      ),
      body: userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              mapType: MapType.normal,
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(userLocation!.latitude, userLocation!.longitude),
                zoom: 18,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('user_marker'),
                  position:
                      LatLng(userLocation!.latitude, userLocation!.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue),
                ),
                ..._createFriendMarkers(),
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (userLocation != null) {
            mapController.animateCamera(CameraUpdate.newLatLng(
              LatLng(userLocation!.latitude, userLocation!.longitude),
            ));
          }
        },
        child: const Icon(Icons.my_location),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
