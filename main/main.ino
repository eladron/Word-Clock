//#include "bluetooth_utils.h"
#include "neopixel_utils.h"
#include "time_utils.h"
#include "weather_utils.h"

#define DELAYVAL 500 // Time (in milliseconds) to pause between pixels

/* Bluetooth
 
 */
#include "BluetoothSerial.h"
BluetoothSerial SerialBT;
String device_name = "ESP32-BT-Slave-ABCD";
#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

#if !defined(CONFIG_BT_SPP_ENABLED)
#error Serial Bluetooth not available or not enabled. It is only available for the ESP32 chip.
#endif

/* Wifi includes and globals */
#include <WiFi.h>
String ssid       = "176-19";
String password   = "1234567890";

void getNameandPass(String output)
{
  int index = output.indexOf("+");
  ssid = output.substring(5, index);
  password = output.substring(index+10);
}

void getCity(String output){
  city = output.substring(5);
  Serial.println(city);
}

void bluetooth_loop()
{
  if (SerialBT.available()) {
    String output = SerialBT.readString();
    Serial.println(output);
    if (output.indexOf(F("SSID")) == 0) {
      getNameandPass(output);
    }
    if (output.indexOf((F("City")) == 0)) {
      getCity(output);
      weather_timer = 0;
    }
  }
}

/* End Bluetooth */
void setup() {
  
  // END of Trinket-specific code.
  Serial.begin(9600);
  setup_neopixel();
  SerialBT.begin(device_name);
  setup_time();
}

void time_loop()
{
  pixels.clear(); // Set all pixel colors to 'off'
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    return;
  }
  if ((millis() - time_timer) > time_timer_delay) {
    printLocalTime();
    int hour = timeinfo.tm_hour;
    int minute = round_minute_to_nearest_five(timeinfo.tm_min);
    time_timer=millis();
  }
  /*
  if ((millis() - time_timer) > time_timer_delay) {
    for(int i=0; i<hour; i++) { // For each pixel...
    
        // pixels.Color() takes RGB values, from 0,0,0 up to 255,255,255
        // Here we're using a moderately bright green color:
      pixels.setPixelColor(i, pixels.Color(0, 150, 0));
    }
    pixels.show();   // Send the updated pixel colors to the hardware.
  }
  */
}

void weather_loop()
{
  if (city.isEmpty()) {
    return;
  }
  if ((millis() - weather_timer) > 60000) {
    if(WiFi.status()== WL_CONNECTED){
      String serverPath = "http://api.openweathermap.org/data/2.5/weather?q=" + city + "&APPID=" + openWeatherMapApiKey + "&units=metric";
      
      jsonBuffer = httpGETRequest(serverPath.c_str());
      //Serial.println(jsonBuffer);
      JSONVar myObject = JSON.parse(jsonBuffer);
  
       if (JSON.typeof(myObject) == "undefined") {
        return;
      }
      Serial.print(F("Temperature: "));
      Serial.println(myObject["main"]["temp"]);
    }
    weather_timer = millis();
  }
}

void loop() {
  bluetooth_loop();
  if (WiFi.status() == WL_CONNECTED)
  {
    //time_loop();
    weather_loop();
  }
  else{
    Serial.println("Not Connected to WIFI");
    if (!ssid.isEmpty() && !password.isEmpty()) {
      WiFi.begin(ssid.c_str(), password.c_str());
    }
    delay(1000);
    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("Connected!");
    }
    // Light that we are not connected to wifi
  }
}
