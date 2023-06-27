import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:wordclockapp/reusable_widgets/reusable_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomColorPicker extends StatefulWidget {
  final void Function(Color) onColorChanged;
  final Color selectedColor;
  final String selectedDescription;

  const CustomColorPicker({Key? key, required this.onColorChanged, required this.selectedColor, required this.selectedDescription}) : super(key: key);

  @override
  _CustomColorPickerState createState() => _CustomColorPickerState();
}

class _CustomColorPickerState extends State<CustomColorPicker> {

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: widget.selectedColor,
              onColorChanged: (color) {
                setState(() {});
                widget.onColorChanged(color);
              },
              showLabel: false,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showColorPickerDialog,
      child: Stack(
        children: [
          Container(
            width: 200,
            height: 200,
            color: widget.selectedColor,
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 200,
              color: Colors.white,
              padding: const EdgeInsets.all(8.0),
              child: Text( widget.selectedDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddNewThemeScreen extends StatefulWidget {
  @override
  _AddNewThemeScreenState createState() => _AddNewThemeScreenState();
}

class _AddNewThemeScreenState extends State<AddNewThemeScreen> {
  TextEditingController _themeNameController = TextEditingController();
  Color _color1 = Colors.white;
  Color _color2 = Colors.white;
  Color _color3 = Colors.white;
  int _selectedContainer = 1;
  Color _lastPressedColor = Colors.white;


  void saveTheme() async {

    final userDoc = FirebaseFirestore.instance
        .collection('user_preferences')
        .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .limit(1);
    final userDocSnapshot = await userDoc.get();
    final userDocRef = userDocSnapshot.docs.first.reference;
    final themesMap = Map<String, dynamic>.from(userDocSnapshot.docs.first.get('Themes') ?? {});
    print(themesMap.keys);
    if (themesMap.containsKey(_themeNameController.text)) {
      // Key exists in the map, display error message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("Theme already exists. Please choose another name."),
            actions: [
              ElevatedButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      // Key does not exist in the map
      themesMap[_themeNameController.text] = [_color1.red, _color1.green, _color1.blue, _color2.red, _color2.green, _color2.blue, _color3.red, _color3.green, _color3.blue];
      await userDocRef.update({'Themes': themesMap});
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Theme'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            reusableTextForm('Theme Name', Icons.palette, _themeNameController),
            const SizedBox(height: 16),
            if (_selectedContainer == 1)
              CustomColorPicker(
                onColorChanged: (color) {
                  setState(() {
                    _color1 = color;
                    _lastPressedColor = color;
                  });
                },
                selectedColor: _lastPressedColor,
                selectedDescription: "Words",
              ),
            if (_selectedContainer == 2)
              CustomColorPicker(
                onColorChanged: (color) {
                  setState(() {
                    _color2 = color;
                    _lastPressedColor = color;
                  });
                },
                selectedColor: _lastPressedColor,
                selectedDescription: "Minutes Ascending",
              ),
            if (_selectedContainer == 3)
              CustomColorPicker(
                onColorChanged: (color) {
                  setState(() {
                    _color3 = color;
                    _lastPressedColor = color;
                  });
                },
                selectedColor: _lastPressedColor,
                selectedDescription: "Minutes Descending",
              ),
            const SizedBox(height: 16,),
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedContainer = 1;
                        _lastPressedColor = _color1;
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _color1,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          width: 50,
                          height: 50,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Words',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16,),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedContainer = 2;
                        _lastPressedColor = _color2;
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _color2,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          width: 50,
                          height: 50,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Minutes\nAscending',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16,),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedContainer = 3;
                        _lastPressedColor = _color3;
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _color3,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          width: 50,
                          height: 50,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Minutes\nDescending',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: saveTheme,
              child: const Text('Save Theme'),
            ),
          ],
        ),
      ),
    );
  }
}
