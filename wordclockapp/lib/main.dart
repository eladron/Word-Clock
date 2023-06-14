import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }
  
  Future<void> _requestPermission(Permission permission , String title, String content, String error) async {
    final status = await permission.request();
    if (status.isGranted) {
      // Permission granted, continue with the app
      print('$title granted');
    } else {
      // Permission denied, show an explanation and request again
      if (await permission.shouldShowRequestRationale) {
        // Show a dialog explaining why the permission is needed
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OK'),
              ),
            ],
          ),
        ).then((confirmed) async {
          if (confirmed ?? false) {
            // Request the permission again
            await _requestPermission( permission, title, content,error);
          }
        });
      } else {
        // Permission denied permanently, show a dialog directing to app settings
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(error),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _requestPermissions() async {
    // Request the permission
    await _requestPermission(
      Permission.bluetoothScan,
      'Bluetooth Scan Permission',
      'This app needs the Bluetooth Scan permission to scan for nearby devices.',
      'Please grant the Bluetooth Scan permission in the app settings.',
    );

    await _requestPermission(
      Permission.location,
      'Location Permission',
      'This app needs the Location permission to scan for nearby devices.',
      'Please grant the Location permission in the app settings.',
    );

    await _requestPermission(
      Permission.bluetoothConnect,
      'Bluetooth Connect Permission',
      'This app needs the Bluetooth Connect permission to connect to nearby devices.',
      'Please grant the Bluetooth Connect permission in the app settings.',
    );

    }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Word Clock',
      home: LoginScreen(ignoreRememberMe: false,),
    );
  }
}
