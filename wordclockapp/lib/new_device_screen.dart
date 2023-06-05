// AddDeviceScreen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reusable_widgets/reusable_widgets.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';


class AddDeviceScreen extends StatefulWidget {
  @override
  _AddDeviceScreenState createState() => _AddDeviceScreenState();

}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late bool _isLoading = false;


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
                      ),
                      if (_isLoading)
                        const CircularProgressIndicator(),
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
    String address = codeToAddress(deviceCode);
    print(codeToAddress(deviceCode));

    bool? isAvailable = await FlutterBluetoothSerial.instance.isAvailable;
    if (!isAvailable!) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth is not available on this device!')));
      return;
    }

    bool? isOn = await FlutterBluetoothSerial.instance.isEnabled;
    if (!isOn!) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth is not turned on!')));
      return;
    }

    try{
      BluetoothConnection connection = await BluetoothConnection.toAddress(address);
      if (connection.isConnected) {
        print("Connected!");
        connection.close();
        connection.dispose();
        await devicesCollection.add({
          'Code': deviceCode,
          'Name': deviceName,
          'email': FirebaseAuth.instance.currentUser?.email,
        });

        Navigator.pop(context);
      }
    }
    catch (exception)
    {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Device haven't been found!")));
      return;
    }
  }
}
