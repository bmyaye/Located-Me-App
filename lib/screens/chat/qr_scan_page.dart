import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location_app/screens/chat/chat_page.dart';

class QRScanPage extends StatefulWidget {
  @override
  _QRScanPageState createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool isCheckingGroup = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      if (await Permission.camera.request().isGranted) {
        // Permission granted, do nothing
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to scan QR codes.'),
            ),
          );
        }
      }
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (result != null)
                  ? Text(
                      'Barcode Type: ${result!.format}   Data: ${result!.code}')
                  : const Text('Scan a code'),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (mounted && !isCheckingGroup) {
        setState(() {
          result = scanData;
          isCheckingGroup = true;
        });
        if (result != null) {
          await _checkGroupId(result!.code);
        }
      }
    });
  }

  Future<void> _checkGroupId(String? groupId) async {
    if (groupId == null) {
      print('Scanned groupId is null');
      setState(() {
        isCheckingGroup = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('groups_list') // Change 'groups' to 'groups_list' here
          .doc(groupId)
          .get();
      if (doc.exists) {
        await joinGroup(groupId);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Group found: $groupId')));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChatPage(groupId: groupId, groupName: doc['groupName']),
            ),
          );
        }
      } else {
        if (mounted) {
          print('Group not found for groupId: $groupId');
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Group not found')));
        }
      }
    } catch (e) {
      if (mounted) {
        print('Error checking groupId: $e');
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Error checking groupId')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isCheckingGroup = false;
        });
      }
    }
  }

  Future<void> joinGroup(String groupId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('User is not authenticated');
      return;
    }
    String userId = currentUser.uid;

    DocumentReference groupRef =
        FirebaseFirestore.instance.collection('groups_list').doc(groupId); // Change 'groups' to 'groups_list' here

    DocumentSnapshot groupSnapshot = await groupRef.get();
    if (groupSnapshot.exists) {
      await groupRef.update({
        'members': FieldValue.arrayUnion([userId]),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('groups')
          .doc(groupId)
          .set({
        'groupId': groupId,
        'groupName': groupSnapshot['groupName'],
        'creator': groupSnapshot['creator'],
        'members': groupSnapshot['members'],
      });

      print('Successfully joined group');
    } else {
      print('Group not found');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}