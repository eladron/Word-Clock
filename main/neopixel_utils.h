// Neo Pixel includes and global

#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
 #include <avr/power.h> // Required for 16 MHz Adafruit Trinket
#endif


#define PIN 26 // On Trinket or Gemma, suggest changing this to 1
#define WEATHERLIGHT 2
#define WIFILIGHT 5
#define ALARMLIGHT 4
#define CUBESLIGHT 10
#define CLEARLIGHT 0
#define CLOUDYLIGHT 1
#define RAINLIGHT 2
#define THUNDERLIGHT 3
#define NUMPIXELS 63 // Popular NeoPixel ring size
Adafruit_NeoPixel pixels(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);
bool isAlarmOn = false;

uint32_t day_words_color = pixels.Color(150, 0, 0);
uint32_t day_asc_color = pixels.Color(0, 0, 150);
uint32_t day_dsc_color = pixels.Color(0, 150, 0);
int night_start_hour = -1;
int night_start_min = -1;
int night_end_hour = -1;
int night_end_min = -1;


#include "lights.h"

void setup_neopixel()
{
    // These lines are specifically to support the Adafruit Trinket 5V 16 MHz.
    // Any other board, you can remove this part (but no harm leaving it):
    #if defined(__AVR_ATtiny85__) && (F_CPU == 16000000)
    clock_prescale_set(clock_div_1);
    #endif

    pixels.begin(); // INITIALIZE NeoPixel strip object (REQUIRED)

}

//Sets the light in range a and b
void setLightinRange(int a, int b, uint32_t c = GREEN) {
  for (int i=a; i<= b; i++) {
    pixels.setPixelColor(i, c);
  }
}

/*
Sets the light in the words It,Is and O'clock
*/
void setItIsOclock() {
  pixels.setPixelColor(62, day_words_color);
  pixels.setPixelColor(61, day_words_color);
  setLightinRange(13,15, day_words_color);
}

void setMinutes(int minute) {
  // Past
  auto specific_color = day_asc_color;
  auto words_color = day_words_color;
  // if is_night
  // { words_color = night_words_color;
  // }
  if (5 <= minute && minute <= 30) {
    setLightinRange(37,38, words_color);
  }
  // TO
  else if (31 <= minute) {
    if (minute <= 55) {
      setLightinRange(44,44, words_color);
    }
    minute = 60 - minute;
    specific_color = day_dsc_color;
  }
  int specific = minute % 5;
  if (specific != 0) {
    setLightinRange(CUBESLIGHT-specific,9, specific_color);
  }
  minute = minute - minute % 5;
  switch (minute)
  {
  case 5:
    /* code */
    setLightinRange(48, 49, words_color);
    break;
  case 10:
    setLightinRange(57, 58, words_color);
    break;
  case 15:
    setLightinRange(50, 53, words_color);
    break;
  case 20:
    setLightinRange(54, 56, words_color);
    break;
  case 25:
    setLightinRange(48, 49, words_color);
    setLightinRange(54, 56, words_color);
    break;
  case 30:
    setLightinRange(59, 60, words_color);
    break;
  default:
    break;
  }
  //Minutes
  if (minute != 0 && minute != 30 && minute != 15) {
    setLightinRange(45,47, words_color);
  }
}

void setHour(int hour)
{
  auto words_color = day_words_color;
  switch (hour)
  {
  case 0:
    setLightinRange(10, 12, words_color);
    break;
  case 1:
    setLightinRange(35, 36, words_color);
    break;
  case 2:
    setLightinRange(39, 40, words_color);
    break;
  case 3:
    setLightinRange(41, 43, words_color);
    break;
  case 4:
    setLightinRange(33, 34, words_color);
    break;
  case 5:
    setLightinRange(31, 32, words_color);
    break;  
  case 6:
    setLightinRange(23, 24, words_color);
    break;
  case 7:
    setLightinRange(25, 27, words_color);
    break;
  case 8:
    setLightinRange(28, 30, words_color);
    break;
  case 9:
    setLightinRange(21, 22, words_color);
    break;
  case 10:
    setLightinRange(19, 20, words_color);
    break;
  case 11:
    setLightinRange(16, 18, words_color);
    break;  
  default:
    break;
  }
}

void clear_time_lights() 
{
  for (int i=6; i<= 62; i++) {
    pixels.setPixelColor(i, NONCOLOR);
  }
  pixels.show();
}

void light_time(int hour, int minute)
{
  clear_time_lights();
  setItIsOclock();
  setMinutes(minute);
  hour = hour % 12;
  hour = minute > 30 ? (hour + 1) % 12  : hour;
  setHour(hour);
  pixels.show();   // Send the updated pixel colors to the hardware.
}

void temperature_to_color(int temp) 
{
  Serial.println(temp);
  auto color = WARM;
  if (temp < 17.5) {
    color = COLD;
  }
  pixels.setPixelColor(WEATHERLIGHT, color);
  pixels.show();
}

void light_alarm() 
{
  pixels.setPixelColor(ALARMLIGHT, YELLOW);
  pixels.show();
  isAlarmOn = true;
}

void clear_alarm() 
{
  pixels.setPixelColor(ALARMLIGHT,NONCOLOR);
  pixels.show();
  isAlarmOn = false;  
}

void show_all_lights()
{
  for (int i=0; i < 10; i++) {
    pixels.setPixelColor(i, WHITE);
    pixels.show();
    delay(500);
  }
  for (int i=0; i < 10; i++) {
    pixels.setPixelColor(i, NONCOLOR);
  }
  pixels.show();
  delay(500);
}

void clear_weather()
{
  for (int i=0; i<=3; i++) 
  {
    pixels.setPixelColor(i, NONCOLOR);
  }
}

void wifi_not_connected() 
{
  clear_weather();
  pixels.setPixelColor(WIFILIGHT, WIFIOFF);
  clear_time_lights();
  clear_alarm();
  pixels.show();
}

void wifi_connected()
{
  pixels.setPixelColor(WIFILIGHT, WIFION);
  pixels.show();
}

void setWeatherLights(int temp, int wc) {
  clear_weather();
  int code = wc / 100;
  //Clear
  if (wc == 800) {
    pixels.setPixelColor(CLEARLIGHT, CLEARCOLD);
    if (temp >=23) {
      pixels.setPixelColor(CLEARLIGHT, WARM);
    }
  }
  else if (code == 8 || code == 7) {
    pixels.setPixelColor(CLOUDYLIGHT, GREY);
  }
  else if (code == 6) {
    pixels.setPixelColor(CLOUDYLIGHT, WHITE);
  }
  else if (code == 5 || code == 3) {
    pixels.setPixelColor(RAINLIGHT, MIDNIGHTBLUE);
  }
  else {
    pixels.setPixelColor(THUNDERLIGHT, THUNDER);
  }
  pixels.show();
}
