# Word Clock 

This is a simple word clock project that displays the time using words and can be managed through a dedicated app. The app provides an intuitive interface to control various aspects of the clock's functionality.

Group members:
1. Elad Ron
2. Ofir Feder
3. Eilon Tal
## Features

- **Word Time Display**: The clock uses words to represent the time, providing a unique and visually appealing way to read the current time.
- **App Control**: The clock can be easily managed and customized using the dedicated mobile app, which offers a user-friendly interface.
- **Multiple Clock Support**: The app allows you to set up and manage multiple clocks, each with its own unique settings.
- **Flexible Settings**: Customize various aspects of the clock, such as location and brightness.

## Folders
1. **main** - The folder main consists of the code of the esp32.
2. **wordclockapp** - This folder consists the code of the app.
3. **Test** - This folders contains test from the POC.

## Packages and Configurations
1. **Flutter** - The file pubspec.yaml consists of the packages that we have used. Preform flutter pub get to get the packages.
2. **ESP32** - The esp32 board is ESP32 DEV Module and the Partition Scheme is Huge App. The libraries that has been used are:
    - Wifi
    - BluetoothSerial
    - Preferences
    - Adafruit_NeoPixel
    - time.h and sntp.h
    - Arduino_JSON
    - HTTPClient

Enjoy your word clock experience!

-- Group 13
