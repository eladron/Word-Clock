import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';
import 'dart:typed_data';

late BluetoothConnection connection;
late String address;

Future<int> sendString(String message) async
{
  while (true)
    {
      try {
        if(connection.isConnected) {
          connection.output.add(Uint8List.fromList(utf8.encode(message)));
          break;
        }
        else {
          connection = await BluetoothConnection.toAddress(address);
        }
      }
      catch (error) {
      }
    }
    return 0;
}


Future<void> connect() async
{
  try {
    connection = await BluetoothConnection.toAddress(address);

  }
  catch (error) {

  }
}