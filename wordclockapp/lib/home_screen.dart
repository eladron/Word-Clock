import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'new_device_screen.dart';
import 'login_screen.dart';
import 'device_control_screen.dart';
import 'locations_settings.dart';
import 'user_themes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _displayName;
  late String _email;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _displayName = currentUser.displayName ?? "";
      _email = currentUser.email ?? "";
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) =>
        const LoginScreen(ignoreRememberMe: true,)), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: signOut,
            ),
          ],
        ),
          body: TabBarView(
          controller: _tabController,
          children: [
            // TODO: Add the HomePage content here
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(height: 30),
                  const Text("My Devices",
                    style: TextStyle(
                      fontSize: 20
                    )),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('devices')
                        .where('email', isEqualTo: _email)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final devices = snapshot.data!.docs;
                      return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Card(
                            margin: const EdgeInsets.all(16.0),
                            child: Column(
                              children: devices.map((device) {
                                final deviceName = device['Name'];
                                return ListTile(
                                  title: Text(deviceName),
                                  onTap: () {
                                    // Handle click event for device
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => DeviceControlScreen(deviceName: deviceName)),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          )
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddDeviceScreen()));
                      },
                      label: const Text('Add new device'),
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Center the buttons vertically
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 200, // Set the desired width
                              height: 48, // Set the desired height
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.location_on),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => LocationSettingsScreen()));
                                },
                                label: const Text(
                                  'Your Locations',
                                  style: TextStyle(fontSize: 16.0),
                                ),
                                style: ElevatedButton.styleFrom(
                                  elevation: 2,
                                  padding: const EdgeInsets.all(12.0),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 200, // Set the desired width
                              height: 48, // Set the desired height
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.palette),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => ThemesScreen()));
                                },
                                label: const Text(
                                  'Your Themes',
                                  style: TextStyle(fontSize: 16.0),
                                ),
                                style: ElevatedButton.styleFrom(
                                  elevation: 2,
                                  padding: const EdgeInsets.all(12.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _tabController.index,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() {});
            _tabController.animateTo(index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.devices_other),
              label: 'Devices',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
    );
  }
}
