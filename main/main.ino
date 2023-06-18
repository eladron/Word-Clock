//#include "bluetooth_utils.h"
#include "neopixel_utils.h"
#include "time_utils.h"
#include "weather_utils.h"


#define DELAYVAL 500 // Time (in milliseconds) to pause between pixels

/* Bluetooth
 
 */
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

/* Preferences */
#include <Preferences.h>
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

void putAlarm(int index, String alarm)
{
  preferences.putString(("alarm" + String(index)).c_str(), alarm);
}

String getAlarm(int index) {
  return preferences.getString(("alarm" + String(index)).c_str());
}

int findAlarm(String alarm) {
  if (alarmCount == 0) {
    return -1;
  }
  for (int i = 0; i< alarmCount; i++) {
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
  putAlarm(alarmCount, alarm);
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
  if (index != alarmCount -1) {
    String lastAlarm = getAlarm(alarmCount-1);
    putAlarm(index, lastAlarm);
  }
  alarmCount--;
  preferences.putInt("alarmCount", alarmCount);
  printAlarmCount();
}

void stopAlarm(String alarm)
{
  if (indexAlarm == -1) {
    return;
  }
  String currentAlarm = getAlarm(indexAlarm);
  if (currentAlarm != alarm) {
    return;
  }
  stopIndex = indexAlarm;
}

void bluetooth_loop()
{
  if (SerialBT.available()) {
    String output = SerialBT.readString();
    Serial.println(output);
    if (output.indexOf(F("SSID")) == 0) {
      getNameandPass(output);
      preferences.putString("ssid", ssid);
      preferences.putString("password", password);
    }
    else if (output.indexOf(F("City")) == 0) {
      getCity(output);
      preferences.putString("city", city);
      preferences.putString("countryCode", countryCode);
      weather_timer = 0;
    }
    else if (output.indexOf(F("Alarm")) == 0) {
      addAlarm(output.substring(6));
    }
    else if (output.indexOf(F("RemoveAlarm")) == 0) {
      removeAlarm(output.substring(12));
    }
    else if (output.indexOf(F("StopAlarm")) == 0) {
      stopAlarm(output.substring(10));
    }
  }
}

/* End Bluetooth */

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

void time_loop()
{
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    return;
  }
  int hour = timeinfo.tm_hour;
  int minute = timeinfo.tm_min;
  String day = dayNames[timeinfo.tm_wday];
  if ((millis() - time_timer) > time_timer_delay) {
    //clear_time_lights(); // TURN OF THE TIME LIGHTS
    time_timer=millis();
    if (last_hour != hour || last_minute != minute) {
      last_hour = hour;
      last_minute = minute;
      printLocalTime();
      light_time(hour, minute);  
    }
  }
  if (alarmCount > 0) {
    for (int i = 0; i < alarmCount; i++) {
      String alarmKey = "alarm" + String(i);
      String alarm = preferences.getString(alarmKey.c_str());
      int sub_index = alarm.indexOf("-");
      String alarmDay = alarm.substring(0, sub_index-1);
      if (day != alarmDay) {
        continue;
      }
      int index = alarm.indexOf(":");
      int alarmHour = alarm.substring(sub_index+2,index).toInt();
      if (hour!= alarmHour) {
        continue;
      }
      int alarmMinute = alarm.substring(index+1).toInt();
      if (minute!= alarmMinute) {
        continue;
      }
      indexAlarm = i;
      if (stopIndex != indexAlarm && stopIndex != -1) {
        stopIndex = -1;
      }
      if (stopIndex == indexAlarm) {
        if (isAlarmOn) {
          clear_alarm();
        }
        return;
      }
      if (isAlarmOn) {
        clear_alarm();
      }
      else {
        light_alarm();
      }
      return;
    }
    if (indexAlarm != -1) {
      indexAlarm = -1;
      stopIndex = -1;
      clear_alarm();
    }
  }
}

void weather_loop()
{
  if (city.isEmpty() || countryCode.isEmpty()) {
    return;
  }
  if ((millis() - weather_timer) > 60000) {
      String serverPath = "http://api.openweathermap.org/data/2.5/weather?q=" + city +"," + countryCode +"&APPID=" + openWeatherMapApiKey + "&units=metric";
      jsonBuffer = httpGETRequest(serverPath.c_str());
      //Serial.println(jsonBuffer);
      JSONVar myObject = JSON.parse(jsonBuffer);
  
       if (JSON.typeof(myObject) == "undefined") {
        return;
      }
      Serial.print("Country: ");
      Serial.print(countryCode);
      Serial.print(", City: ");
      Serial.println(city);
      Serial.print(F("Temperature: "));
      Serial.println(myObject["main"]["temp"]);
      int tmp = myObject["timezone"];
      if (gmtOffset_sec != tmp) {
        gmtOffset_sec = tmp;
        preferences.putInt("gmtOffset", gmtOffset_sec);
        configTime(gmtOffset_sec, 0, "pool.ntp.org", "time.nist.gov");
      }
      temperature_to_color(myObject["main"]["temp"]);
      weather_timer = millis();
  }
}

void loop() {
  bluetooth_loop();
  if (WiFi.status() == WL_CONNECTED)
  {
    time_loop();
    weather_loop();
    delay(1000);
  }
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
