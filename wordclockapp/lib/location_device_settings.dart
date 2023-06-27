import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'locations_settings.dart';
import 'package:flag/flag.dart';
import 'package:text_scroll/text_scroll.dart';

class DeviceLocationsSettingScreen extends StatefulWidget {
  final String deviceName;
  const DeviceLocationsSettingScreen({Key? key, required this.deviceName}) : super(key: key);

  @override
  _DeviceLocationsSettingScreen createState() => _DeviceLocationsSettingScreen();
}

class _DeviceLocationsSettingScreen extends State<DeviceLocationsSettingScreen> {
  bool _enableChoose = false;
  double _elevation = 0;
  int _selectedCardIndex = -1;
  String _selecetedCity = "";
  bool isStart = true;

  @override
  void initState() {
    super.initState();
    _get_location_preferences();
  }

  void _get_location_preferences() async {
    CollectionReference devicesCollection = FirebaseFirestore.instance
        .collection('devices');
    await devicesCollection
        .where('Name', isEqualTo: widget.deviceName).where(
        'email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .get().then((QuerySnapshot querySnapshot) {
      String location = querySnapshot.docs.first['Location'];
      setState(() {
        if (location != 'Auto') {
          setState(() {
              isStart = false;
            _enableChoose = true;
            _selecetedCity = location;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Settings'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                    elevation: _elevation,
                    margin: const EdgeInsets.only(top: 16, left:16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CheckboxListTile(
                      title: const Text('Customize Location'),
                      value: _enableChoose,
                      onChanged: (value) {
                        setState(() {
                          _enableChoose = value!;
                          _selecetedCity = '';
                          _elevation = _enableChoose ? 4 : 0;
                          _selectedCardIndex = 0;
                        });
                      },
                      activeColor: Colors.blueGrey[800], // Change the color of the check when the checkbox is selected
                      checkColor: Colors.white, // Change the color of the check icon
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 16, right: 16),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LocationSettingsScreen()),
                        );
                      },
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                      color: Colors.blueGrey[800],
                      iconSize: 24,
                    ),
                  ),
                ),
              ]
          ),
          const SizedBox(height: 16),
          Visibility(
            visible: _enableChoose,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user_preferences')
                  .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final locations = snapshot.data!.docs;
                if (isStart) {
                  _selecetedCity = locations.first['locations'].first;
                }
                return Expanded(
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final location = locations[index];
                      final List<String> locationsList =
                      List<String>.from(location['locations']);
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: locationsList.length,
                        itemBuilder: (context, index) {
                          final locationItem = locationsList[index];
                          if (_selecetedCity == locationItem) {
                            _selectedCardIndex = index;
                          }
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCardIndex = index;
                                isStart = false;
                              });
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                              color: _selectedCardIndex == index ? Colors.blue : null,
                              child: ListTile(
                                title: Row(
                                  children: [
                                    Flag.fromString((locationItem.split(", ").last), height: 20, width: 30),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextScroll(locationItem,
                                        pauseBetween: const Duration(seconds:3),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedCardIndex = index;
                                    _selecetedCity = locationItem;
                                    isStart = false;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(16),
          child: TextButton(
            onPressed: () async {
              // Save the selected location and navigate back to the previous screen
              final currentUser = FirebaseAuth.instance.currentUser;
              String location = _enableChoose ? _selecetedCity : "Auto";
              if (currentUser != null) {
                await FirebaseFirestore.instance
                    .collection('devices')
                    .where('email', isEqualTo: currentUser.email)
                    .get()
                    .then((querySnapshot) {
                  querySnapshot.docs.forEach((documentSnapshot) {
                    documentSnapshot.reference.update({'Location': location});
                  });
                });
              }
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.blueGrey[800], // Change the text color
              padding: const EdgeInsets.symmetric(vertical: 16), // Add some padding
              minimumSize: const Size(double.infinity, 0), // Set the minimum size to full width
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Save'),
          ),
        ),
    );
  }
}



