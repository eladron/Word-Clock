// AddDeviceScreen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reusable_widgets/reusable_widgets.dart';
import 'package:flutter_blue/flutter_blue.dart';


class AddDeviceScreen extends StatefulWidget {
  @override
  _AddDeviceScreenState createState() => _AddDeviceScreenState();

}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      reusableTextForm("Device Code", Icons.watch_later, _codeController),
                      const SizedBox(height: 16.0),
                      reusableTextForm("Device Name", Icons.abc, _nameController ),
                      ElevatedButton(
                        onPressed: () {
                          if (_form.currentState!.validate()) {
                            _addNewDevice();
                          }
                        },
                        child: const Text('Add Device'),
                      )
                    ],
                  ),
                )
              ]
          ),
        ),
      )
    );
  }

  void _addNewDevice() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    CollectionReference devicesCollection = FirebaseFirestore.instance.collection('devices');

    final deviceCode = _codeController.text.trim();
    final deviceName = _nameController.text.trim();
    final deviceBluetoothName = 'WordClock-$deviceCode';

    // Check if the device is already in the database
    var querySnapshot = await devicesCollection
        .where('Code', isEqualTo: deviceCode)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device already exists!')));
      return;
    }
    querySnapshot = await devicesCollection
        .where('Name', isEqualTo: deviceName)
        .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already have a device with that name!')));
      return;
    }

    // Check if Bluetooth is available on the device
    final flutterBlue = FlutterBlue.instance;
    bool isBluetoothAvailable = await flutterBlue.isAvailable;
    if (!isBluetoothAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth is not available on this device!')));
      return;
    }

    // Check if Bluetooth is turned on
    bool isOn = await flutterBlue.isOn;
    if (!isOn) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth is not turned on!')));
      return;
    }

    print("hello there motherfucker");
    // Scan for nearby Bluetooth devices
    final scanResults = await flutterBlue.scan(timeout: const Duration(seconds: 5));
    final foundDevices = await scanResults
        .map((result) => result.device.name)
        .where((name) => name == deviceBluetoothName)
        .toList();
    print("hello there");
    if (foundDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No Bluetooth devices found!')));
      return;
    }

    // Add the device to the database
    await devicesCollection.add({
      'Code': deviceCode,
      'Name': deviceName,
      'email': FirebaseAuth.instance.currentUser?.email,
    });

    Navigator.pop(context);
  }
}
