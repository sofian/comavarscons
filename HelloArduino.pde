#include <EEPROM.h>
#include "Extra.h"

void setup() {
  pinMode(13, OUTPUT);
  EEPROM.write(0, foo(2));
}

void loop() {
  digitalWrite(13, HIGH);
  delay(1000);
  digitalWrite(13, LOW);
  delay(1000);
}
