## Word Clock by : Elad Ron, Eilon Tal & Ofir Feder.

In this project we have built a word clock.
The clocks display the time with words within minute. The clock also have alarms and display the current weather within the location of the clock. 
The clock is controlled by an app that allows the user to change the clock settings and to control the clock.

## Our Project in details :
First, the user sign in the app.
Then, the user can add the new clocks he owns, he enters the name of the clock and a unique code that is printed on the clock.
Inside the app the user can do the following things:
1. Add new locations: The user can add new locations and the clock will display the weather in one of those locations.
2. Add new themes: The user can add new themes and the clock will display the time with the new theme. Each theme control the color of the words, the color of the minutes ascending and the color of the minutes descending.
3. Device Settings: The user can change the settings of each device:
    - Network Settings: The user set the credentials of the his network so the clock will be connected to the internet and fetch the time and weather.
    - Location Settings: The user can choose the location of the clock from the locations set he created in his new locations.
    - Alarms: The user can add alarms to each clock (up to 15 alarms), each alarms is periodicly and is set by name of day, and start time.
    - Preferences: The user can set the theme for the day time, and if he wants he can set night mode in the clock and set the theme for the night time.

## Folder description :
* ESP32: source code for the esp side (firmware).
* wordclockapp : dart code for our Flutter app.
* Parameters: contains description of configurable parameters 

## Arduino/ESP32 libraries used in this project:
* Wifi
* BluetoothSerial
* Preferences
* Adafruit_NeoPixel
* Arduino_JSON
* HTTPClient

## Project Poster:

This project is part of ICST - The Interdisciplinary Center for Smart Technologies, Taub Faculty of Computer Science, Technion
https://icst.cs.technion.ac.il/

Enjoy your word clock experience!
