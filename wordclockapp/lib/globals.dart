import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';
import 'dart:typed_data';

late BluetoothConnection connection;
late String address;

Future<int> sendString(String message) async
{
    if (!connection.isConnected) {
      try {
        connection = await BluetoothConnection.toAddress(address);
      }
      catch (error) {
        return 0;
      }
    }
    connection.output.add(Uint8List.fromList(utf8.encode(message)));
    return 1;
}
