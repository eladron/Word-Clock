// Neo Pixel includes and global

#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
 #include <avr/power.h> // Required for 16 MHz Adafruit Trinket
#endif


#define PIN        5 // On Trinket or Gemma, suggest changing this to 1
#define NUMPIXELS 30 // Popular NeoPixel ring size
Adafruit_NeoPixel pixels(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);

#define DELAYVAL 500 // Time (in milliseconds) to pause between pixels


// Time includes and Global

#include <WiFi.h>
#include "time.h"
#include "sntp.h"


const char* ssid       = "StrongOne";
const char* password   = "psagot21";

const char* ntpServer1 = "pool.ntp.org";
const char* ntpServer2 = "time.nist.gov";
const long  gmtOffset_sec = 7200;
const int   daylightOffset_sec = 3600;

//const char* time_zone = "CET-1CEST,M3.5.0,M10.5.0/3";  // TimeZone rule for Europe/Rome including daylight adjustment rules (optional)

void printLocalTime()
{
  struct tm timeinfo;
  if(!getLocalTime(&timeinfo)){
    Serial.println("No time available (yet)");
    return;
  }
  Serial.println(&timeinfo, "%A, %B %d %Y %H:%M:%S");
}

// Callback function (get's called when time adjusts via NTP)
void timeavailable(struct timeval *t)
{
  Serial.println("Got time adjustment from NTP!");
  printLocalTime();
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

  sntp_set_time_sync_notification_cb( timeavailable );

  /**
   * NTP server address could be aquired via DHCP,
   *
   * NOTE: This call should be made BEFORE esp32 aquires IP address via DHCP,
   * otherwise SNTP option 42 would be rejected by default.
   * NOTE: configTime() function call if made AFTER DHCP-client run
   * will OVERRIDE aquired NTP server address
   */
  sntp_servermode_dhcp(1);    // (optional)

  /**
   * This will set configured ntp servers and constant TimeZone/daylightOffset
   * should be OK if your time zone does not need to adjust daylightOffset twice a year,
   * in such a case time adjustment won't be handled automagicaly.
   */
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer1, ntpServer2);
  
  //connect to WiFi
  Serial.printf("Connecting to %s ", ssid);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
      delay(500);
      Serial.print(".");
  }
  Serial.println(" CONNECTED");
}

void loop() {
  pixels.clear(); // Set all pixel colors to 'off'
  
  struct tm timeinfo;
  if(getLocalTime(&timeinfo)){
    printLocalTime();  
    int num_lights = timeinfo.tm_hour;
  
    // The first NeoPixel in a strand is #0, second is 1, all the way up
    // to the count of pixels minus one.
    for(int i=0; i<num_lights; i++) { // For each pixel...
  
      // pixels.Color() takes RGB values, from 0,0,0 up to 255,255,255
      // Here we're using a moderately bright green color:
      pixels.setPixelColor(i, pixels.Color(0, 150, 0));
    }
    pixels.show();   // Send the updated pixel colors to the hardware.
  
    delay(DELAYVAL); // Pause before next pass through loop
  }
}
