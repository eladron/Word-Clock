import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AlarmScreen extends StatefulWidget {
  final String deviceName;
  const AlarmScreen({Key? key, required this.deviceName}) : super(key: key);
  @override
  _AlarmScreenState createState() => _AlarmScreenState();

}

String parseAlarmString(String alarmStr) {
  final inputFormat = DateFormat('dd/MM/yyyy/HH/mm');
  final date = inputFormat.parse(alarmStr);
  final outputFormat = DateFormat('dd/MM/yyyy - HH:mm');
  return outputFormat.format(date);
}

int compareDate(String d1, String d2){
  final inputFormat = DateFormat('dd/MM/yyyy/HH/mm');
  final date1 = inputFormat.parse(d1);
  final date2 = inputFormat.parse(d2);
  return date1.compareTo(date2);
}

class _AlarmScreenState extends State<AlarmScreen> {
  DateTime? _selectedDate = DateTime.now();
  int _selectedHour = 0;
  int _selectedMinute = 0;

  final hours = List.generate(24, (index) => index);
  final minutes = List.generate(60, (index) => index);


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.deviceName} Alarms"),
          backgroundColor: Colors.blueGrey[800],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Your Alarms',),
              Tab(text: 'Add New Alarms'),
            ],
            onTap: (index) {
              setState(() {
                _selectedDate = DateTime.now();
                _selectedHour = 0;
                _selectedMinute = 0;
              });
            },
          ),
        ),
        backgroundColor: Colors.blueGrey[300],
        body: TabBarView(
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
                alarms.sort((a,b) => compareDate(a, b));
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
                              title: Text(parseAlarmString(alarm)),
                              trailing: IconButton(
                                onPressed: () {
                                  _showDeleteAlarmDialog(alarms, alarm);
                                },
                                icon: const Icon(Icons.delete),
                              ),
                              onTap: () {},
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    const SizedBox(height: 10,),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                              children: [
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(' Hour', style: TextStyle(fontSize: 16)),
                                ),
                                DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.blue),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  value: _selectedHour,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedHour = value!;
                                    });
                                  },
                                  items: hours.map((hour) {
                                    return DropdownMenuItem<int>(
                                      value: hour,
                                      child: Text(hour.toString()),
                                    );
                                  }).toList(),
                                ),
                              ]
                          ),
                        ),
                        const SizedBox(width: 40,),
                        Expanded(
                          child: Column(
                              children: [
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(' Minute', style: TextStyle(fontSize: 16)),
                                ),
                                DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.blue),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  value: _selectedMinute,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedMinute = value!;
                                    });
                                  },
                                  items: minutes.map((minute) {
                                    return DropdownMenuItem<int>(
                                      value: minute,
                                      child: Text(minute.toString()),
                                    );
                                  }).toList(),
                                ),
                              ]
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final initialDate = DateTime.now();
                      final newDate = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: initialDate,
                        lastDate: DateTime(initialDate.year + 1),
                      );
                      setState(() {
                        _selectedDate = newDate;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800], // background color
                      foregroundColor: Colors.white, // text color
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24), // button padding
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // button border radius
                    ),
                    label: const Text('Select Date'),
                    icon: const Icon(Icons.date_range)
                  ),
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 16),
                    Text('Selected Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}'),
                  ],
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
                Text('Would you like to delete this location?'),
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
              child: Text('Remove'),
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


  void _deleteAlarm(List<String> alarms, String alarm) async {

    alarms.remove(alarm);
    final userDoc = FirebaseFirestore.instance
        .collection('devices')
        .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .where('Name', isEqualTo: widget.deviceName)
        .limit(1);
    final userDocSnapshot = await userDoc.get();
    final userDocRef = userDocSnapshot.docs.first.reference;
    await userDocRef.update({'Alarms': alarms});
    setState(() {
      _selectedDate = null;
      _selectedHour = 0;
      _selectedMinute = 0;
    });
  }

  Future<void> _addAlarm() async {

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

    final selectedDate = _selectedDate ?? DateTime.now();
    final selectedHour = _selectedHour;
    final selectedMinute = _selectedMinute;
    final alarmDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedHour,
      selectedMinute,
    );
    final outputFormat = DateFormat('dd/MM/yyyy/HH/mm');
    final alarmStr = outputFormat.format(alarmDateTime);
    if (!alarmList.contains(alarmStr)) {
      alarmList.add(alarmStr);
      await userDocRef.update({'Alarms': alarmList});
    }

    setState(() {
      _selectedDate = DateTime.now();
      _selectedHour = 0;
      _selectedMinute = 0;
    });
  }
}