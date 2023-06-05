import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reusable_widgets/reusable_widgets.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'location_settings_screen.dart';
import 'package:timezone/timezone.dart' as tz;


class DeviceControlScreen extends StatefulWidget {
  final String deviceName;

  const DeviceControlScreen({Key? key, required this.deviceName}) : super(key: key);

  @override
  _DeviceControlScreenState createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  bool _isLoading = true;
  late BluetoothConnection _connection;
  String _deviceCode = '';
  final TextEditingController _wifiNameController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }


  Future<void> _sendLocation() async {

    String location0 = "";
    String? city = "";
    String? countryCode = "";

    CollectionReference devicesCollection = FirebaseFirestore.instance
        .collection('devices');
    await devicesCollection
        .where('Name', isEqualTo: widget.deviceName).where(
        'email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .get().then((QuerySnapshot querySnapshot) {
      String location = querySnapshot.docs.first['Location'];
      setState(() {
        location0 = location;
      });
    });
    if (location0 == 'Auto') {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await placemarkFromCoordinates(
          position!.latitude, position!.longitude)
          .then((List<Placemark> placemarks) {
        Placemark place = placemarks[0];
        setState(() {
          city = place.locality;
          countryCode = place.isoCountryCode;
        });
      }).catchError((e) {
        debugPrint(e);
      });
    }
    else {
      List<String> places = location0.split(',');
      city = places[0].trim();
      countryCode = places[1].trim();
    }
    String message = 'City=$city+Code=$countryCode';
    // Send the message over Bluetooth here
    _connection.output.add(Uint8List.fromList(utf8.encode(message)));
  }

  Future<void> _connectToDevice() async {
    // Retrieve device code from Firebase
    CollectionReference devicesCollection = FirebaseFirestore.instance
        .collection('devices');
    await devicesCollection
        .where('Name', isEqualTo: widget.deviceName).where(
        'email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .get().then((QuerySnapshot querySnapshot) {
      String code = querySnapshot.docs.first['Code'];
      setState(() {
        _deviceCode = code;
      });
    });

    String address = codeToAddress(_deviceCode);
    try {
      _connection = await BluetoothConnection.toAddress(address);
      if (_connection.isConnected) {
        setState(() {
          _isLoading = false;
        });
        _sendLocation();
      }
    }
    catch (exception) {
      print("caught");
      bool retry = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: const Text(
                'Can\'t connect to device. Would you like to try again?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Try Again'),
              ),
            ],
          );
        },
      );
      if (retry) {
        await _connectToDevice();
      }
      else {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _onBackPressed() async {

    if (await _connection.isConnected) {
      // Disconnect from the Bluetooth device
      _connection.close();
      _connection.dispose();
    }
    Navigator.pop(context);
  }

  void _setDeviceNetwork() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Network Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _wifiNameController,
                decoration: const InputDecoration(
                  hintText: 'Wifi Name',
                ),
              ),
              TextField(
                controller: _wifiPasswordController,
                decoration: const InputDecoration(
                  hintText: 'Wifi Password',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                String wifiName = _wifiNameController.text;
                String wifiPassword = _wifiPasswordController.text;
                // Save the wifi settings here
                String message = 'SSID=$wifiName+Password=$wifiPassword';
                // Send the message over Bluetooth here
                _connection.output.add(Uint8List.fromList(utf8.encode(message)));
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _setDeviceTime() {
    print('Set Device Time');
  }

  void _setDeviceLocation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationSettingScreen(deviceName:widget.deviceName)),
    );
    _sendLocation();
  }

  void _setPreferences() {
    print('Preferences');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _onBackPressed();
       return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.deviceName),
          backgroundColor: Colors.blueGrey[800], // Change the background color
        ),
        backgroundColor: Colors.blueGrey[300], // Change the background color
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        )
            : GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16.0),
          mainAxisSpacing: 16.0,
          crossAxisSpacing: 16.0,
          children: [
            deviceSettingButton("Network Settings", Icons.wifi, () { _setDeviceNetwork(); }),
            deviceSettingButton("Alarms", Icons.alarm, () { _setDeviceTime(); }),
            deviceSettingButton("Location Settings", Icons.location_on, () { _setDeviceLocation(); }),
            deviceSettingButton("Preferences ", Icons.settings , () { _setPreferences(); })
          ],
        ),
      ),
    );
  }
}
