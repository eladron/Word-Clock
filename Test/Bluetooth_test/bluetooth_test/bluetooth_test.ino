#include "BluetoothSerial.h"
String device_name = "ESP32-BT-Slave";

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

#if !defined(CONFIG_BT_SPP_ENABLED)
#error Serial Bluetooth not available or not enabled. It is only available for the ESP32 chip.
#endif

BluetoothSerial SerialBT;

void setup() {
  Serial.begin(9600);
  SerialBT.begin(device_name); //Bluetooth device name
  Serial.printf("The device with name \"%s\" is started.\nNow you can pair it with Bluetooth!\n", device_name.c_str());
  //Serial.printf("The device with name \"%s\" and MAC address %s is started.\nNow you can pair it with Bluetooth!\n", device_name.c_str(), SerialBT.getMacString()); // Use this after the MAC method is implemented
}

void getNameandPass(String output, String& net_name, String& pass)
{
  int index = output.indexOf("+");
  net_name = output.substring(5, index);
  pass = output.substring(index+10);
}

void loop() {
  if (SerialBT.available()) {
    String output = SerialBT.readString();
    String net_name;
    String pass;
    getNameandPass(output, net_name, pass);
    Serial.println(net_name);
    Serial.println(pass);
  }
  delay(20);
}
