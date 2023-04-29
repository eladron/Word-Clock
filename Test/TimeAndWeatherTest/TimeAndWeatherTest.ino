// Neo Pixel includes and global

#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
 #include <avr/power.h> // Required for 16 MHz Adafruit Trinket
#endif


#define PIN        5 // On Trinket or Gemma, suggest changing this to 1
#define NUMPIXELS 30 // Popular NeoPixel ring size
Adafruit_NeoPixel pixels(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);

#define DELAYVAL 500 // Time (in milliseconds) to pause between pixels

// Networks includes and Global
#include <WiFi.h>
#include <HTTPClient.h>
const char* ssid       = "OnePlus Nord";
const char* password   = "eladeladronron";

// Time includes and Global
#include "time_utils.h"
unsigned long time_timer = 0;
unsigned long time_timer_delay = 60000;

// Weather includes and Global
#include <Arduino_JSON.h>
String openWeatherMapApiKey = "87d845b0b6cf29baa1a73cc34b067a95";
unsigned long weather_timer = 0;
unsigned long weather_timer_delay = 86400;
String city = "Haifa";
String countryCode = "IL";
String jsonBuffer;

String httpGETRequest(const char* serverName) {
  WiFiClient client;
  HTTPClient http;
    
  // Your Domain name with URL path or IP address with path
  http.begin(client, serverName);
  
  // Send HTTP POST request
  int httpResponseCode = http.GET();
  
  String payload = "{}"; 
  
  if (httpResponseCode>0) {
    Serial.print("HTTP Response code: ");
    Serial.println(httpResponseCode);
    payload = http.getString();
  }
  else {
    Serial.print("Error code: ");
    Serial.println(httpResponseCode);
  }
  // Free resources
  http.end();

  return payload;
}


void setup() {
  // These lines are specifically to support the Adafruit Trinket 5V 16 MHz.
  // Any other board, you can remove this part (but no harm leaving it):
#if defined(__AVR_ATtiny85__) && (F_CPU == 16000000)
  clock_prescale_set(clock_div_1);
#endif
  // END of Trinket-specific code.
  Serial.begin(9600);
  pixels.begin(); // INITIALIZE NeoPixel strip object (REQUIRED)
  setup_time();
  
  //connect to WiFi
  Serial.printf("Connecting to %s ", ssid);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
      delay(500);
      Serial.print(".");
  }
  Serial.println(" CONNECTED");
}

void time_loop()
{
  pixels.clear(); // Set all pixel colors to 'off'
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    Serial.println("Failed to obtain time");
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
  if ((millis() - weather_timer) > weather_timer_delay) {
    // Check WiFi connection status
    if(WiFi.status()== WL_CONNECTED){
      String serverPath = "http://api.openweathermap.org/data/2.5/weather?q=" + city + "," + countryCode + "&APPID=" + openWeatherMapApiKey + "&units=metric";
      
      jsonBuffer = httpGETRequest(serverPath.c_str());
      Serial.println(jsonBuffer);
      JSONVar myObject = JSON.parse(jsonBuffer);
  
      // JSON.typeof(jsonVar) can be used to get the type of the var
      if (JSON.typeof(myObject) == "undefined") {
        Serial.println("Parsing input failed!");
        return;
      }
    
      Serial.print("JSON object = ");
      Serial.println(myObject);
      Serial.print("Temperature: ");
      Serial.println(myObject["main"]["temp"]);
      Serial.print("Pressure: ");
      Serial.println(myObject["main"]["pressure"]);
      Serial.print("Humidity: ");
      Serial.println(myObject["main"]["humidity"]);
      Serial.print("Wind Speed: ");
      Serial.println(myObject["wind"]["speed"]);
    }
    else {
      Serial.println("WiFi Disconnected");
    }
    weather_timer = millis();
  }
}

void loop() {
  time_loop();
  weather_loop();
}
