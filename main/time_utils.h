#include "time.h"
#include "sntp.h"

long  gmtOffset_sec = 7200;
unsigned long time_timer = -1000;
unsigned long time_timer_delay = -time_timer;
int alarmCount = 0;
bool isAlarm = false;
int indexAlarm = -1;
int stopIndex = -1;
int last_hour = 0;
int last_minute = 0;

const char* dayNames[] = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};

void printLocalTime()
{
  struct tm timeinfo;
  if(!getLocalTime(&timeinfo)){
    Serial.println("No time available (yet)");
    return;
  }
  Serial.println(&timeinfo, "%A, %B %d %Y %H:%M:%S");
}

void timeavailable(struct timeval *t)
{
  Serial.println("Got time adjustment from NTP!");
  printLocalTime();
}

void setup_time()
{
  // Setting up time
  Serial.println("Setting up time");
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
  configTime(gmtOffset_sec, 0, "pool.ntp.org", "time.nist.gov");
  Serial.println("Time setup done");
}

int round_minute_to_nearest_five(int minute)
{
  int remainder = minute % 5;
  int res = remainder < 3 ? minute - remainder : minute + (5 - remainder);
  return res;
}
