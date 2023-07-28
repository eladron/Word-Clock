import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flag/flag.dart';
import 'package:text_scroll/text_scroll.dart';

class LocationSettingsScreen extends StatefulWidget {
  @override
  _LocationSettingsScreenState createState() => _LocationSettingsScreenState();

}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  final _searchController = TextEditingController();
  List<String> _cityList = [];



  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Your Locations"),
          backgroundColor: Colors.blueGrey[800],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Add New Location'),
              Tab(text: 'Your Locations'),
            ],
          ),
        ),
        backgroundColor: Colors.blueGrey[300],
        body: TabBarView(
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _cityList = [];
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.grey, width:2)
                      ),

                      filled: true,
                      fillColor: Colors.grey[200],
                      hintText: 'Search For City',
                      labelStyle: const TextStyle(
                        color: Colors.grey,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color:  Colors.grey,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _searchCity,
                    child: const Text('Search'),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cityList.length,
                      itemBuilder: (context, index) {
                        final city = _cityList[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                          child: ListTile(
                            title: Row(
                              children: [
                                Flag.fromString(_getCountryCode(city), height: 20, width: 30),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextScroll(city,
                                    pauseBetween: const Duration(seconds:3),
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              onPressed: () async {
                                await _addLocation(city);
                              },
                              icon: const Icon(Icons.add),
                            ),
                            onTap: () {},
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('user_preferences')
                  .where('email',
                  isEqualTo: FirebaseAuth.instance.currentUser?.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final locations = snapshot.data!.docs;
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 16), // add this SizedBox widget
                      ...locations.map((location) {
                        final List<String> locationsList =
                        List<String>.from(location.get('locations') ?? []);
                        return Column(
                          children: locationsList.map((locationItem) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                              child: ListTile(
                                title: Row(
                                  children: [
                                    Flag.fromString(_getCountryCode(locationItem), height: 20, width: 30),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextScroll(locationItem,
                                        pauseBetween: const Duration(seconds:3),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  onPressed: () {
                                    _showRemoveLocationDialog(
                                        location, locationItem);
                                  },
                                  icon: const Icon(Icons.remove),
                                ),
                                onTap: () {},
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<dynamic>> getCityData(String cityName) async {
    final url =
        'https://api.openweathermap.org/data/2.5/find?q=$cityName&appid=e72268ec08f5eda7ba7481dc1118bb45';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final cityData = jsonData['list'];
      return cityData;
    } else {
      print('Failed to load city data');
      return [];
    }
  }

  String _getCountryCode(String city) {
    final parts = city.split(', ');
    return parts.last;
  }

  void _searchCity() async {
    final cityName = _searchController.text;
    final cityData = await getCityData(cityName);
    final List<String> cityList = [];
    if (cityData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No results found. Please try again.'),
        ),
      );
      setState(() {
        _cityList = [];
      });
      return;
    }
    for (final city in cityData) {
      final cityName = city['name'];
      final countryCode = city['sys']['country'];
      cityList.add('$cityName, $countryCode');
    }
    setState(() {
      _cityList = cityList.toSet().toList();
    });
  }

  Future<void> _showRemoveLocationDialog(
      QueryDocumentSnapshot<Map<String, dynamic>> location, String locationItem) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Location'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Would you like to remove this location?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () {
                _removeLocation(location, locationItem);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _removeLocation(
      QueryDocumentSnapshot<Map<String, dynamic>> location, String locationItem) async {
    final List<String> locationsList =
    List<String>.from(location.get('locations') ?? []);
    locationsList.remove(locationItem);
    await FirebaseFirestore.instance
        .collection('user_preferences')
        .doc(location.id)
        .update({'locations': locationsList});
    // Update the 'devices' collection with the new 'location' field value
    final batch = FirebaseFirestore.instance.batch();
    final devices = await FirebaseFirestore.instance
        .collection('devices')
        .where('email',
        isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .get();
    for (final device in devices.docs) {
      batch.update(device.reference, {'Location': 'Auto'});
    }
    await batch.commit();
  }

  Future<void> _addLocation(String locationItem) async {
    final userDoc = FirebaseFirestore.instance
        .collection('user_preferences')
        .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .limit(1);
    final userDocSnapshot = await userDoc.get();
    final userDocRef = userDocSnapshot.docs.first.reference;
    final locationsList = List<String>.from(userDocSnapshot.docs.first.get('locations') ?? []);
    if (!locationsList.contains(locationItem)) {
      locationsList.add(locationItem);
      await userDocRef.update({'locations': locationsList});
    }
  }
}