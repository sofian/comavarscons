# Don't change these lines
Import(['CONFIG', 'platform', 'mode'])
for (k, v) in CONFIG.items():
  vars()[k] = v
# ------------------------

# Begin: editable zone #######################################

TARGET = "HelloWorld"
if (platform == 'avr'):
  MCU = 'atmega1280'
  F_CPU = 16000000
  AVR_GCC_PATH = '/Applications/Arduino.app/Contents/Resources/Java/hardware/tools/avr/bin'

elif (platform == 'arduino'):
  ARDUINO_BOARD = 'mega'
  TARGET = "HelloArduino"
  INCPATH = "extra"
  SRCPATH = "extra"

# End:   editable zone #######################################

# Don't change these lines
for (k, v) in CONFIG.items():
  CONFIG[k] = vars()[k]
Return('CONFIG')
# ------------------------