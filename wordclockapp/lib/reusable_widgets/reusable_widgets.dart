import 'package:flutter/material.dart';

TextFormField reusableTextForm(String text, IconData icon, TextEditingController controller)
{
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.grey, width:2)
      ),
      labelText: text,
    ),
    validator: (val) {
      if (val != null && val.isEmpty) {
        return '$text is required';
      }
      return null;
    },
  );
}