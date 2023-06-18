// Neo Pixel includes and global

#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
 #include <avr/power.h> // Required for 16 MHz Adafruit Trinket
#endif


#define PIN        5 // On Trinket or Gemma, suggest changing this to 1
#define WEATHERLIGHT 2
#define WIFILIGHT 5
#define ALARMLIGHT 4
#define CUBESLIGHT 10
#define NUMPIXELS 65 // Popular NeoPixel ring size
#define COLD pixels.Color(216, 173 ,230)
#define WARM pixels.Color(70, 250, 22)
#define WIFION pixels.Color(150, 0, 0)
#define WIFIOFF pixels.Color(0, 150, 0)
Adafruit_NeoPixel pixels(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);
bool isAlarmOn = false;

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
void setLightinRange(int a, int b) {
  for (int i=a; i<= b; i++) {
    pixels.setPixelColor(i, pixels.Color(150, 0 , 0));
  }
}

/*
Sets the light in the words It,Is and O'clock
*/
void setItIsOclock() {
  pixels.setPixelColor(62, pixels.Color(150, 0 , 0));
  pixels.setPixelColor(61, pixels.Color(150, 0 , 0));
  setLightinRange(13,15);
}

void setMinutes(int minute) {
  // Past
  if (minute <= 30) {
    setLightinRange(37,38);
  }
  else {
    setLightinRange(44,44);
    minute = 60 - minute;
  }
  int specific = minute % 5;
  if (specific != 0) {
    setLightinRange(CUBESLIGHT-specific,9);
  }
  minute = minute - minute % 5;
  switch (minute)
  {
  case 5:
    /* code */
    setLightinRange(48, 49);
    break;
  case 10:
    setLightinRange(57, 58);
    break;
  case 15:
    setLightinRange(50, 53);
    break;
  case 20:
    setLightinRange(54, 56);
    break;
  case 25:
    setLightinRange(48, 49);
    setLightinRange(54, 56);
    break;
  case 30:
    setLightinRange(59, 60);
    break;
  default:
    break;
  }
  if (minute != 0 && minute != 30) {
    setLightinRange(45,47);
  }
}

void setHour(int hour)
{
  switch (hour)
  {
  case 0:
    setLightinRange(10, 12);
    break;
  case 1:
    setLightinRange(35, 36);
    break;
  case 2:
    setLightinRange(39, 40);
    break;
  case 3:
    setLightinRange(41, 43);
    break;
  case 4:
    setLightinRange(33, 34);
    break;
  case 5:
    setLightinRange(31, 32);
    break;  
  case 6:
    setLightinRange(23, 24);
    break;
  case 7:
    setLightinRange(25, 27);
    break;
  case 8:
    setLightinRange(28, 30);
    break;
  case 9:
    setLightinRange(21, 22);
    break;
  case 10:
    setLightinRange(19, 20);
    break;
  case 11:
    setLightinRange(16, 18);
    break;  
  default:
    break;
  }
}

void clear_time_lights() 
{
  for (int i=6; i<= 62; i++) {
    pixels.setPixelColor(i, pixels.Color(0, 0, 0));
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
  int power = 1;
  if (temp > 5 && temp < 30) {
    power = 0.5;
  }
  auto color = WARM;
  if (temp < 17.5) {
    color = COLD;
  }
  pixels.setPixelColor(WEATHERLIGHT, color);
  pixels.show();
}

void light_alarm() 
{
  pixels.setPixelColor(ALARMLIGHT, pixels.Color(0, 0, 150));
  pixels.show();
  isAlarmOn = true;
}

void clear_alarm() 
{
  pixels.setPixelColor(ALARMLIGHT, pixels.Color(0, 0, 0));
  pixels.show();
  isAlarmOn = false;  
}

void wifi_not_connected() 
{
  pixels.setPixelColor(WEATHERLIGHT, pixels.Color(0,0,0));
  pixels.setPixelColor(WIFILIGHT, WIFIOFF);
  pixels.show();
}

void wifi_connected()
{
  pixels.setPixelColor(WIFILIGHT, WIFION);
  pixels.show();
}
