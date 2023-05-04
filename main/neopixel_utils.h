// Neo Pixel includes and global

#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
 #include <avr/power.h> // Required for 16 MHz Adafruit Trinket
#endif


#define PIN        5 // On Trinket or Gemma, suggest changing this to 1
#define WEATHERLIGHT 25
#define WIFILIGHT 26
#define NUMPIXELS 30 // Popular NeoPixel ring size
#define COLD pixels.Color(216, 173 ,230)
#define WARM pixels.Color(70, 250, 22)
#define WIFION pixels.Color(150, 0, 0)
#define WIFIOFF pixels.Color(0, 150, 0)
Adafruit_NeoPixel pixels(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);


void setup_neopixel()
{
    // These lines are specifically to support the Adafruit Trinket 5V 16 MHz.
    // Any other board, you can remove this part (but no harm leaving it):
    #if defined(__AVR_ATtiny85__) && (F_CPU == 16000000)
    clock_prescale_set(clock_div_1);
    #endif

    pixels.begin(); // INITIALIZE NeoPixel strip object (REQUIRED)

}

void light_time(int hour)
{
  if (hour == 0) {
    hour = 24;
  }
  for(int i=0; i<hour; i++) { // For each pixel...
    
        // pixels.Color() takes RGB values, from 0,0,0 up to 255,255,255
        // Here we're using a moderately bright green color:
      pixels.setPixelColor(i, pixels.Color(150, 0 , 0));
    }
    pixels.show();   // Send the updated pixel colors to the hardware.
}

void clear_time_lights() 
{
  for (int i=0; i< 24; i++) {
    pixels.setPixelColor(i, pixels.Color(0, 0, 0));
  }
  pixels.show();
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
