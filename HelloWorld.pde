#include <EEPROM.h>

void setup() {
  pinMode(13, OUTPUT);
  EEPROM.write(0, 'x');
}

void loop() {
  digitalWrite(13, HIGH);
  delay(1000);
  digitalWrite(13, LOW);
  delay(1000);
}
