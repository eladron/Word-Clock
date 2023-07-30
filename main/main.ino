//#include "bluetooth_utils.h"
#include "neopixel_utils.h"
#include "time_utils.h"
#include "weather_utils.h"


#define DELAYVAL 500 // Time (in milliseconds) to pause between pixels
#include "BluetoothSerial.h"
BluetoothSerial SerialBT;
String device_name = "WordClock-ABCD";
#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

#if !defined(CONFIG_BT_SPP_ENABLED)
#error Serial Bluetooth not available or not enabled. It is only available for the ESP32 chip.
#endif

/* Wifi includes and globals */
#include <WiFi.h>
String ssid       = "";
String password   = "";

/* Preferences - Preferences.h is a library provided by the Arduino framework (ESP32 boards in this case)
 that allows you to store and retrieve key-value pairs persistently in the non-volatile memory of the microcontroller (flash memory). 
 This is similar to having a simple key-value database where you can store configuration settings, preferences, 
 or any other data that needs to be preserved even when the device is powered off or reset. */
#include <Preferences.h>


/* This object will be used to interact with the non-volatile memory and perform operations like reading and writing key-value pairs. */
Preferences preferences;


void getNameandPass(String output)
{
  int index = output.indexOf("+");
  ssid = output.substring(5, index);
  password = output.substring(index+10);
}


void getCity(String output){
  int index = output.indexOf("+");
  city = output.substring(5, index);
  countryCode = output.substring(index+6);
  Serial.println(city);
  Serial.println(countryCode);
}


void printAlarmCount() {
  Serial.print("AlarmCount = ");
  Serial.println(alarmCount);
}


void putAlarm(int index, String alarm){
  // Add the new alarm
  preferences.putString(("alarm" + String(index)).c_str(), alarm); 
}


String getAlarm(int index) {
  // Returns the alarm at "index"
  return preferences.getString(("alarm" + String(index)).c_str());
}


int findAlarm(String alarm) {
  for (int i = 0; i < alarmCount; i++) {
    if (alarm == getAlarm(i)) {
      return i;
    }
  }
  return -1;
}


void addAlarm(String alarm) {
  int index = findAlarm(alarm);
  if (index != -1) {
    return;
  }
  putAlarm(alarmCount, alarm); // Add the new alarm

  // Handle the number of alarms
  alarmCount++;
  preferences.putInt("alarmCount", alarmCount);
  printAlarmCount();
  return;
}


void removeAlarm(String alarm)
{
  int index = findAlarm(alarm);
  if (index == -1) {
    return;
  }
  // We want the number of alarms to be 1, 2, 3, 4, ... , N.
  if (index != alarmCount - 1) {
    String lastAlarm = getAlarm(alarmCount - 1);
    putAlarm(index, lastAlarm);
  }

  // Handle number of alarms
  alarmCount--;
  preferences.putInt("alarmCount", alarmCount);
  printAlarmCount();
}


void stopAlarm(String alarm)
{
  // There is no alarm
  if (indexAlarm == -1) {
    return;
  }
  
  String currentAlarm = getAlarm(indexAlarm);

  // The current alarm is not the alarm received
  if (currentAlarm != alarm) {
    return;
  }

  alarmToStop = alarm;
}


void printColor(int r, int g, int b)
{
  Serial.print("R:");
  Serial.print(r);
  Serial.print(" G:");
  Serial.print(g);
  Serial.print(" B:");
  Serial.print(b);
}


void setTheme(String theme)
{
  Serial.println(theme);
  JSONVar my_json = JSON.parse(theme);
  
  // Color for the words
  int day_words_color_red = my_json["Day"]["Words"]["Red"];
  int day_words_color_green = my_json["Day"]["Words"]["Green"];
  int day_words_color_blue = my_json["Day"]["Words"]["Blue"];
  day_words_color = pixels.Color(day_words_color_green,day_words_color_red, day_words_color_blue);

  printColor(day_words_color_red, day_words_color_green, day_words_color_blue);
  
  // Color for the ascending minutes 
  int day_asc_color_red = my_json["Day"]["Asc"]["Red"];
  int day_asc_color_green = my_json["Day"]["Asc"]["Green"];
  int day_asc_color_blue = my_json["Day"]["Asc"]["Blue"];
  day_asc_color = pixels.Color(day_asc_color_green, day_asc_color_red, day_asc_color_blue);

  // Color for decending minutes
  int day_dsc_color_red = my_json["Day"]["Dsc"]["Red"];
  int day_dsc_color_green = my_json["Day"]["Dsc"]["Green"];
  int day_dsc_color_blue = my_json["Day"]["Dsc"]["Blue"];
  day_dsc_color = pixels.Color(day_dsc_color_green, day_dsc_color_red, day_dsc_color_blue);
  
  light_time(last_hour,last_minute);
}


void setup_preferences() {
    preferences.begin("credentials", false);
    ssid = preferences.getString("ssid");
    password = preferences.getString("password");
    city = preferences.getString("city");
    countryCode = preferences.getString("countryCode");
    gmtOffset_sec = preferences.getInt("gmtOffset", 0);
    alarmCount = preferences.getInt("alarmCount", 0);
}

void setup() {
  
  // END of Trinket-specific code.
  Serial.begin(9600);
  setup_neopixel();
  setup_preferences();
  SerialBT.begin(device_name);
  setup_time();
  pixels.clear(); // Set all pixel colors to 'off'
}


void alarm_loop(String day, int hour, int minute)
{
  // If there are alarms.
  if (alarmCount > 0) {

    // Iterate over all the alarms.
    for (int i = 0; i < alarmCount; i++) {
      String alarmKey = "alarm" + String(i);
      String alarm = preferences.getString(alarmKey.c_str());
      int sub_index = alarm.indexOf("-");
      String alarmDay = alarm.substring(0, sub_index-1);

      // Not the right day
      if (day != alarmDay) {
        continue;
      }
      int index = alarm.indexOf(":");
      int alarmHour = alarm.substring(sub_index+2,index).toInt();

      // Not the right hour
      if (hour!= alarmHour) {
        continue;
      }
      int alarmMinute = alarm.substring(index+1).toInt();

      // Not the right minute
      if (minute != alarmMinute) {
        continue;
      }

      // If we arrive here, it means that alarm i is the scheduled for now.
      // indexAlarm is the index of the current alarm (which is scheduled for now).
      indexAlarm = i;
      if (alarm == alarmToStop) {
        if (isAlarmOn) {
          clear_alarm();
        }
        return;
      }
      else {

        // Bliping
        if (isAlarmOn) {
          clear_alarm();
        }
        else {
          light_alarm();
        }
        return;
      }
    }

    // Alarm is stopped
    indexAlarm = -1;
    alarmToStop = "";
    clear_alarm();
  }
}


void bluetooth_loop()
{
  if (SerialBT.available()) {
    String output = SerialBT.readString();
    Serial.println(output);

    // Update WIFI credentials
    if (output.indexOf(F("SSID")) == 0) {
      getNameandPass(output);
      preferences.putString("ssid", ssid);
      preferences.putString("password", password);
      WiFi.disconnect();
      wifi_not_connected();
      delay(1000);
    }

    // Change location
    else if (output.indexOf(F("City")) == 0) {
      getCity(output);
      preferences.putString("city", city);
      preferences.putString("countryCode", countryCode);
      weather_timer = 0;
    }

    // Add alarm
    else if (output.indexOf(F("Alarm")) == 0) {
      addAlarm(output.substring(6));
    }

    // Remove alarm
    else if (output.indexOf(F("RemoveAlarm")) == 0) {
      removeAlarm(output.substring(12));
    }

    // Stop alarm
    else if (output.indexOf(F("StopAlarm")) == 0) {
      stopAlarm(output.substring(10));
    }

    // Set Theme
    else if (output.indexOf(F("Theme")) == 0) {
      setTheme(output.substring(6));
    } 
  }
}


void time_loop()
{
  struct tm timeinfo;

  // Get the local time
  if (!getLocalTime(&timeinfo)) {
    return;
  }
  int hour = timeinfo.tm_hour;
  int minute = timeinfo.tm_min;
  String day = dayNames[timeinfo.tm_wday];

  // If time changed
  if (last_hour != hour || last_minute != minute) {
    last_hour = hour;
    last_minute = minute;
    printLocalTime();
    light_time(hour, minute); // Set the lights according to the new time
  }
  alarm_loop(day, hour, minute); // Check for alarms
}


void weather_loop()
{
  // City is not specified
  if (city.isEmpty() || countryCode.isEmpty()) {
    return;
  }
  // When eniugh time has passed from last update
  if ((millis() - weather_timer) > 60000) {
      String serverPath = "http://api.openweathermap.org/data/2.5/weather?q=" + city +"," + countryCode +"&APPID=" + openWeatherMapApiKey + "&units=metric"; // Create request
      jsonBuffer = httpGETRequest(serverPath.c_str()); // Make the request
      JSONVar myObject = JSON.parse(jsonBuffer);
  
       if (JSON.typeof(myObject) == "undefined") {
        return;
      }
      int temp = myObject["main"]["temp"];

      Serial.print("Country: ");
      Serial.print(countryCode);
      Serial.print(", City: ");
      Serial.println(city);
      Serial.print(F("Temperature: "));
      Serial.println(temp);

      int tz = myObject["timezone"]; // Timezone of the new city

      // If the new timezone is different from the current timezone
      if (gmtOffset_sec != tz) {
        gmtOffset_sec = tz;
        preferences.putInt("gmtOffset", gmtOffset_sec);
        configTime(gmtOffset_sec, 0, "pool.ntp.org", "time.nist.gov");
      }

      int wc = myObject["weather"][0]["id"]; // Weather condition in the new city
      Serial.print("wc = ");
      Serial.println(wc);

      // If weather lights need to be changed, change them
      if (currentTemperature != temp || weatherCondition != wc) {
        currentTemperature = temp;
        weatherCondition = wc;
        setWeatherLights(temp, wc);
      }
      weather_timer = millis();
  }
}


void loop() {
  bluetooth_loop(); // Receive commands from app

  // If device connected to WIFI
  if (WiFi.status() == WL_CONNECTED)
  {
    time_loop(); // Set the current time
    weather_loop(); // Set the current weather
    delay(1000);
  }
  // If device is not connected to WIFI
  else{
    Serial.println("Not Connected to WIFI");
    wifi_not_connected();
    if (!ssid.isEmpty() && !password.isEmpty()) {
      WiFi.begin(ssid.c_str(), password.c_str());
    }
    delay(1000);
    if (WiFi.status() == WL_CONNECTED) {
      wifi_connected();
      Serial.println("Connected!");
    }
  }
}
