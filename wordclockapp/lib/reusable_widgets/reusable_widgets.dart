import 'package:flutter/material.dart';
import 'package:flag/flag.dart';
import 'package:text_scroll/text_scroll.dart';

TextFormField reusableTextForm(String text, IconData icon, TextEditingController controller)
{
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      prefixIcon: Icon(icon,
          color: Colors.grey
      ),

      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.grey, width:2)
      ),

      filled: true,
      fillColor: Colors.grey[200],
      hintText: text,
      hintStyle: const TextStyle(
        color: Colors.black54,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: Colors.grey,
          width: 2,
        ),
      ),
    ),
    validator: (val) {
      if (val != null && val.isEmpty) {
        return '$text is required';
      }
      return null;
    },
  );
}


Card deviceSettingButton(String text, IconData icon, VoidCallback onPressedFunction)
{
  return Card(
    elevation: 4.0,
    color: Colors.blueGrey[800], // Change the button color
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
    child: ElevatedButton.icon(
      onPressed: onPressedFunction,
      icon: Icon(icon),
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 16.0, // Change the font size
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey[800], // Change the button color
        foregroundColor: Colors.white, // Change the text color
      ),
    ),
  );
}


String codeToAddress(String code)
{
  String newString = code.replaceAllMapped(
    RegExp(r".."),
        (match) => "${match.group(0)}:",
  );
  newString = newString.substring(0, newString.length - 1); // remove the last dash
  print(newString);
  return newString;
}

class ThemeClass {
  late final String name;
  late final Color color1;
  late final Color color2;
  late final Color color3;

  ThemeClass({
    required this.name,
    required this.color1,
    required this.color2,
    required this.color3,
  });
}
