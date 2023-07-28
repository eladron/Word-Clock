import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'globals.dart';

class AlarmScreen extends StatefulWidget {
  final String deviceName;
  const AlarmScreen({Key? key, required this.deviceName}) : super(key: key);
  @override
  _AlarmScreenState createState() => _AlarmScreenState();

}

class _AlarmScreenState extends State<AlarmScreen> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  int daySelected = 0;
  bool isLoading = false;
  bool _selected = false;


  final hours = List.generate(24, (index) => index);
  final minutes = List.generate(60, (index) => index);
  final days = [0, 1, 2, 3, 4, 5, 6];
  final List<String> daysOfWeek = <String>[
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];


  int compareAlarm(String a1, String a2) {
    final splitA1 = a1.split("-");
    final splitA2 = a2.split("-");
    final day1 = splitA1[0].trim();
    final day2 = splitA2[0].trim();
    final index1 = daysOfWeek.indexOf(day1);
    final index2 = daysOfWeek.indexOf(day2);
    if (index1.compareTo(index2) != 0) {
      return index1.compareTo(index2);
    }
    final Time1 = splitA1[1].split(":");
    final Time2 = splitA2[1].split(":");
    final hour1 = int.parse(Time1[0].trim());
    final hour2 = int.parse(Time2[0].trim());
    if (hour1.compareTo(hour2) != 0){
      return hour1.compareTo(hour2);
    }

    final minute1 = int.parse(Time1[1].trim());
    final minute2 = int.parse(Time2[1].trim());
    return minute1.compareTo(minute2);
  }

  String preetyAlarm(String alarmStr) {
    List<String> parts = alarmStr.split(' - ');
    String dayName = parts[0].trim();
    String time = parts[1].trim();
    List<String> timeParts = time.split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    String formattedHour = hour.toString().padLeft(2, '0');
    String formattedMinute = minute.toString().padLeft(2, '0');
    String formattedTime = '$formattedHour:$formattedMinute';
    String formattedString = '$dayName - $formattedTime';
    return formattedString;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.deviceName} Alarms"),
          backgroundColor: Colors.blueGrey[800],
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Your Alarms',),
              Tab(text: 'Add New Alarms'),
            ],
            onTap: (index) {
              setState(() {
                daySelected = 0;
                _selected = false;
                _selectedTime = TimeOfDay.now();
              });
            },
          ),
        ),
        backgroundColor: Colors.blueGrey[300],
        body: TabBarView(
          children: [
            Stack(
            children: [
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('devices')
                      .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
                      .where('Name', isEqualTo: widget.deviceName)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final alarms = List<String>.from(snapshot.data!.docs.first.get('Alarms') ?? []);
                    if (alarms.isEmpty) {
                      return Center(
                        child: Text(
                          'No alarms in ${widget.deviceName}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: alarms.length,
                            itemBuilder: (context, index) {
                              final alarm = alarms[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                                child: ListTile(
                                  leading: const Icon(Icons.alarm),
                                  title: Text(preetyAlarm(alarm)),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'Stop':
                                        _stopAlarm(alarm);
                                          break;
                                        case 'Delete':
                                          setState(() {
                                            isLoading = true;
                                          });
                                          _showDeleteAlarmDialog(alarms, alarm);
                                          break;
                                      }
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return {'Stop', 'Delete'}.map((String choice) {
                                        return PopupMenuItem<String>(
                                          value: choice,
                                          child: Text(choice),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    const SizedBox(height: 10,),
                  ElevatedButton(
                    onPressed: () async {
                      final selectedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (selectedTime != null) {
                        setState(() {
                          _selected = true;
                          _selectedTime = selectedTime;
                        });
                      }
                    },
                    child: const Text('Pick Alarm Time'),
                  ),
                  if (_selected)
                    Text('Alarm Time: ${_selectedTime!.format(context)}'),
                  const SizedBox(height: 16),
                  Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(' Day', style: TextStyle(fontSize: 16)),
                        ),
                        DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.blue),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: daySelected,
                          onChanged: (value) {
                            setState(() {
                              daySelected = value!;
                            });
                          },
                          items: days.map((day) {
                            return DropdownMenuItem<int>(
                              value: day,
                              child: Text(daysOfWeek[day]),
                            );
                          }).toList(),
                        ),
                      ]
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      await _addAlarm();
                    },
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800], // background color
                      foregroundColor: Colors.white, // text color
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 24), // button padding
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // button border radius
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteAlarmDialog(List<String> alarms, String alarm) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Alarm'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Would you like to delete this alarm?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                setState(() {
                  isLoading = false;
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () {
                _deleteAlarm(alarms, alarm);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showAlertDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  void _stopAlarm(String alarm) {
    final message = "StopAlarm=$alarm";
    sendString(message);
  }

  void _deleteAlarm(List<String> alarms, String alarm) async {
    alarms.remove(alarm);
    final userDoc = FirebaseFirestore.instance
        .collection('devices')
        .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .where('Name', isEqualTo: widget.deviceName)
        .limit(1);
    final userDocSnapshot = await userDoc.get();
    final userDocRef = userDocSnapshot.docs.first.reference;
    final message = "RemoveAlarm=$alarm";
    int res = await sendString(message);
    setState(() {
      isLoading = false;
    });
    if (res != 0) {
        await showAlertDialog("Can't connect to the clock. Make sure the clock is on and Bluetooth is on");
        return;
    }
    await userDocRef.update({'Alarms': alarms});

    setState(() {
      daySelected = 0;
      _selected = false;
      _selectedTime = TimeOfDay.now();
    });
  }

  Future<void> _addAlarm() async {

    if (!_selected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("You didn't picked time for the alarm."),
      ));
      return;
    }

    final userDoc = FirebaseFirestore.instance
        .collection('devices')
        .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .where('Name', isEqualTo: widget.deviceName)
        .limit(1);
    final userDocSnapshot = await userDoc.get();
    final userDocRef = userDocSnapshot.docs.first.reference;
    final alarmList = List<String>.from(userDocSnapshot.docs.first.get('Alarms') ?? []);

    if (alarmList.length >= 15) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You cannot add more than 15 alarms. Remove one or more alarms to add new ones.'),
      ));
      return;
    }

    //Send location to the device and see if it is earlier than current time.

    final selectedDay = daysOfWeek[daySelected];
    final selectedHour = _selectedTime.hour;
    final selectedMinute = _selectedTime.minute;

    final alarmStr = "$selectedDay - $selectedHour:$selectedMinute";

    if (!alarmList.contains(alarmStr)) {
      alarmList.add(alarmStr);
      alarmList.sort((a,b) => compareAlarm(a, b));
      await userDocRef.update({'Alarms': alarmList});
      String message = "Alarm=$alarmStr";
      sendString(message);
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You already have an alarm with this time and day.'),
      ));
      return;
    }

    setState(() {
      daySelected = 0;
      _selected = false;
      _selectedTime = TimeOfDay.now();
    });
  }
}