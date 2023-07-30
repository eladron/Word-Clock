// Weather includes and Global
#include <Arduino_JSON.h>
#include <HTTPClient.h>

String openWeatherMapApiKey = "87d845b0b6cf29baa1a73cc34b067a95";
unsigned long weather_timer = -60000;
String city = "";
String countryCode = "";
String jsonBuffer;
int currentTemperature = 0;
int weatherCondition = 0;


String httpGETRequest(const char* serverName) {
  WiFiClient client;
  HTTPClient http;
    
  // Your Domain name with URL path or IP address with path
  http.begin(client, serverName);
  
  // Send HTTP GET request
  int httpResponseCode = http.GET();
  
  String payload = "{}"; 
  
  // Status code OK
  if (httpResponseCode>0) {
    Serial.print("HTTP Response code: ");
    Serial.println(httpResponseCode);
    payload = http.getString();
  }
  // Error
  else {
    Serial.print("Error code: ");
    Serial.println(httpResponseCode);
  }
  // Free resources
  http.end();

  return payload;
}
