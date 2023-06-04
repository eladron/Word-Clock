import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'new_device_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
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
      print("im here");
      _displayName = currentUser.displayName ?? "";
      _email = currentUser.email ?? "";
      print(_email);
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          await signOut();
          return true;
        },
        child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // TODO: Add the HomePage content here
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(height: 30),
                  const Text("My Devices"),
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
                      return Card(
                        margin: const EdgeInsets.all(16.0),
                        child: Column(
                          children: devices.map((device) {
                            final deviceName = device['Name'];
                            return ListTile(
                              title: Text(deviceName),
                              onTap: () {
                                // Handle click event for device
                                print(deviceName);
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        print("create new device");
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
            // TODO: Add the Profile content here
            const Center(
              child: Text('Profile'),
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
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      )
    );
  }
}
