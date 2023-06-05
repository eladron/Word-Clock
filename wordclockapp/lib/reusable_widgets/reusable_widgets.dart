import 'package:flutter/material.dart';

TextFormField reusableTextForm(String text, IconData icon, TextEditingController controller, {Color pressedOnColor = Colors.lightBlue })
{
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.grey, width:2)
      ),
      filled: true,
      fillColor: Colors.grey[200],
      labelText: text,
      labelStyle: TextStyle(
        color: pressedOnColor,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: pressedOnColor,
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