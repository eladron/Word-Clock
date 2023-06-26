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
  alarmToStop = alarm;
}


void setTheme(String theme)
{
  JSONVar my_json = JSON.parse(theme);
  
  JSONVar day_words_color_json = my_json["Day"]["Words"];
  int day_words_color_red = day_words_color["Red"];
  int day_words_color_green = day_words_color["Green"];
  int day_words_color_blue = day_words_color["Blue"];
  day_words_color = pixels.Color(day_words_color_red, day_words_color_green, day_words_color_blue);
  
  JSONVar day_asc_color_json = my_json["Day"]["Asc"];
  int day_asc_color_red = day_asc_color["Red"];
  int day_asc_color_green = day_asc_color["Green"];
  int day_asc_color_blue = day_asc_color["Blue"];
  day_asc_color = pixels.Color(day_asc_color_red, day_asc_color_green, day_asc_color_blue);
  
  JSONVar day_dsc_color_json = my_json["Day"]["Dsc"];
  int day_dsc_color_red = day_dsc_color["Red"];
  int day_dsc_color_green = day_dsc_color["Green"];
  int day_dsc_color_blue = day_dsc_color["Blue"];
  day_dsc_color = pixels.Color(day_dsc_color_red, day_dsc_color_green, day_dsc_color_blue);

//  bool is_night_on = my_json["NightOn"];
//
//  if (is_night_on){
//    String night_start_time = my_json["StartTime"];
//    String night_end_time = my_json["EndTime"];
//  }
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

  // If time changed
  if (last_hour != hour || last_minute != minute) {
    last_hour = hour;
    last_minute = minute;
    printLocalTime();
    light_time(hour, minute);  
  }
  alarm_loop(day, hour, minute);
}

// Feder
void alarm_loop(String day, int hour, int minute)
{
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

      //Not the right hour
      if (hour!= alarmHour) {
        continue;
      }
      int alarmMinute = alarm.substring(index+1).toInt();

      // Not the right minute
      if (minute!= alarmMinute) {
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
    indexAlarm = -1;
    alarmToStop = "";
    clear_alarm();
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
      int temp = myObject["main"]["temp"];
      Serial.print("Country: ");
      Serial.print(countryCode);
      Serial.print(", City: ");
      Serial.println(city);
      Serial.print(F("Temperature: "));
      Serial.println(temp);
      int tz = myObject["timezone"];
      if (gmtOffset_sec != tz) {
        gmtOffset_sec = tz;
        preferences.putInt("gmtOffset", gmtOffset_sec);
        configTime(gmtOffset_sec, 0, "pool.ntp.org", "time.nist.gov");
      }
      int wc = myObject["weather"][0]["id"];
      Serial.print("wc = ");
      Serial.println(wc);
      if (currentTemperature != temp || weatherCondition != wc) {
        currentTemperature = temp;
        weatherCondition = wc;
        setWeatherLights(temp, wc);
      }
      weather_timer = millis();
  }
}

void loop() {
  //show_all_lights();
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
