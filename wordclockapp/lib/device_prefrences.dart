import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordclockapp/globals.dart';
import 'reusable_widgets/reusable_widgets.dart';

class PreferencesScreen extends StatefulWidget {
  final String deviceName;
  const PreferencesScreen({Key? key, required this.deviceName}) : super(key: key);
  @override
  _PreferencesScreenState createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  List<ThemeClass> themes = []; // List to store the retrieved themes
  int dayThemeSelected = 0; // Variable to store the selected day theme
  int nightThemeSelected = 0; // Variable to store the selected night theme
  bool enableNightTheme = false; // Variable to track if the night theme is enabled
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;
  List<int> index = [];

  @override
  void initState() {
    super.initState();
    retrieveThemesFromFirebase();
  }

  void retrieveThemesFromFirebase() async {
    CollectionReference userPreferencesCollection =
    FirebaseFirestore.instance.collection('user_preferences');

    QuerySnapshot querySnapshot = await userPreferencesCollection
        .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .get();

    DocumentSnapshot documentSnapshot = querySnapshot.docs[0];
    Map<String, List<dynamic>> themesMap =
    Map<String, List<dynamic>>.from(documentSnapshot['Themes']);

    List<ThemeClass> fetchedThemes = themesMap.entries.map((entry) {
      String themeName = entry.key;
      List<dynamic> colors = entry.value;

      Color color1 = Color.fromRGBO(colors[0], colors[1], colors[2], 1);
      Color color2 = Color.fromRGBO(colors[3], colors[4], colors[5], 1);
      Color color3 = Color.fromRGBO(colors[6], colors[7], colors[8], 1);

      return ThemeClass(
        name: themeName,
        color1: color1,
        color2: color2,
        color3: color3,
      );
    }).toList();

    setState(() {
      themes = fetchedThemes; // Assign the fetched themes to the 'themes' list
      index = List.generate(themes.length, (index) => index);
    });
    retrieveDevicePreference();
  }

  Future<void> retrieveDevicePreference() async
  {
    CollectionReference devicesCollection = FirebaseFirestore.instance
        .collection('devices');
    await devicesCollection
        .where('Name', isEqualTo: widget.deviceName).where(
        'email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .get().then((QuerySnapshot querySnapshot) {
      String dayTheme = querySnapshot.docs.first['Day Theme'];
      if (dayTheme != "") {
        for (ThemeClass t in themes) {
          if (t.name==dayTheme) {
            dayThemeSelected = themes.indexOf(t);
          }
        }
      }
      if (querySnapshot.docs.first['Night Mode']){
        enableNightTheme = true;
        String nightTheme = querySnapshot.docs.first['Night Theme'];
        for (ThemeClass t in themes) {
          if (t.name==nightTheme) {
            nightThemeSelected = themes.indexOf(t);
          }
        }
        String startTime = querySnapshot.docs.first['Start Time'];
        List<String> startTimeSplit = startTime.split(":");
        selectedStartTime = TimeOfDay(hour: int.parse(startTimeSplit.first), minute: int.parse(startTimeSplit.last));
        String endTime = querySnapshot.docs.first['End Time'];
        List<String> endTimeSplit = endTime.split(":");
        selectedEndTime = TimeOfDay(hour: int.parse(endTimeSplit.first), minute: int.parse(endTimeSplit.last));
      }
      setState(() {

      });
    });
  }

  String colorToJo(Color c) {
      return '{\"Red\":${c.red},\"Green\":${c.green},\"Blue\":${c.blue}}';

    }

  String themeToJo(ThemeClass t) {
    return "{ \"Words\":${colorToJo(t.color1)}, \"Asc\":${colorToJo(t.color2)}, \"Dsc\":${colorToJo(t.color3)} }";
  }
  void updateThemePreference() async {
    final userDoc = FirebaseFirestore.instance
        .collection('devices')
        .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .where('Name', isEqualTo: widget.deviceName)
        .limit(1);
    final userDocSnapshot = await userDoc.get();
    final userDocRef = userDocSnapshot.docs.first.reference;
    await userDocRef.update({'Day Theme': themes[dayThemeSelected].name});
    await userDocRef.update({'Night Mode': enableNightTheme});
    if (enableNightTheme) {
      await userDocRef.update({'Night Theme': themes[nightThemeSelected].name});
      String st = "${selectedStartTime?.hour}:${selectedStartTime?.minute}";
      String et = "${selectedEndTime?.hour}:${selectedEndTime?.minute}";
      await userDocRef.update({'Start Time': st});
      await userDocRef.update({'End Time': et});
    }

    // Send Message About Preferences
    String message = "Theme=";

    message += "{ \"Day\":${themeToJo(themes[dayThemeSelected])}, \"NightOn\":$enableNightTheme";
    if (enableNightTheme) {
      String st = "${selectedStartTime?.hour}:${selectedStartTime?.minute}";
      String et = "${selectedEndTime?.hour}:${selectedEndTime?.minute}";
      message += ", \"StartHour\":${selectedStartTime?.hour}, \"StartMinute\":${selectedStartTime?.minute},";
      message += "\"EndHour\":${selectedEndTime?.hour}, \"EndMinute\":${selectedEndTime?.minute},";
      message += " \"Night\":${themeToJo(themes[nightThemeSelected])}";
    }
    message += "}";
    print(message);
    await sendString(message);
    Navigator.pop(context);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
      ),
      body: ListView(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Day Theme'),
                    trailing: DropdownButton<int>(
                      value: dayThemeSelected,
                      onChanged: (int? newValue) {
                        setState(() {
                          dayThemeSelected = newValue!;
                        });
                      },
                      items: index.reversed.toList().map((i) {
                        return DropdownMenuItem<int>(
                          value: i,
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                color: themes[i].color1,
                              ),
                              SizedBox(width: 10),
                              Container(
                                width: 20,
                                height: 20,
                                color: themes[i].color2,
                              ),
                              SizedBox(width: 10),
                              Container(
                                width: 20,
                                height: 20,
                                color: themes[i].color3,
                              ),
                              const SizedBox(width: 10),
                              Text(themes[i].name),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Enable Night Mode'),
                    trailing: Checkbox(
                      value: enableNightTheme,
                      onChanged: (bool? newValue) {
                        setState(() {
                          enableNightTheme = newValue ?? false;
                        });
                      },
                    ),
                  ),
                  if (enableNightTheme)
                    ElevatedButton(
                      onPressed: () async {
                        final selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (selectedTime != null) {
                          setState(() {
                            selectedStartTime = selectedTime;
                          });
                        }
                      },
                      child: const Text('Pick Start Time'),
                    ),
                    if (enableNightTheme && selectedStartTime != null)
                      Text('Start Time: ${selectedStartTime!.format(context)}'),
                    if (enableNightTheme)
                      ElevatedButton(
                      onPressed: () async {
                        final selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (selectedTime != null) {
                          setState(() {
                            selectedEndTime = selectedTime;
                          });
                        }
                      },
                      child: const Text('Pick End Time'),
                    ),
                    if (enableNightTheme && selectedEndTime != null)
                      Text('End Time: ${selectedEndTime!.format(context)}'),
                    if (enableNightTheme) // Only show the night theme card if the checkbox is checked
                      ListTile(
                        title: const Text('Night Theme'),
                        trailing: DropdownButton<int>(
                          value: nightThemeSelected,
                          onChanged: (int? newValue) {
                            setState(() {
                              nightThemeSelected = newValue!;
                            });
                          },
                          items: index.reversed.toList().map((i) {
                            return DropdownMenuItem<int>(
                              value: i,
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    color: themes[i].color1,
                                  ),
                                  SizedBox(width: 10),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    color: themes[i].color2,
                                  ),
                                  SizedBox(width: 10),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    color: themes[i].color3,
                                  ),
                                  SizedBox(width: 10),
                                  Text(themes[i].name),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ElevatedButton.icon(
                      onPressed: () {
                        updateThemePreference();
                      },
                      icon: const Icon(Icons.save),
                      label: const Text("Save")
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
