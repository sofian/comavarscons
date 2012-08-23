CONFIG = ['TARGET', 'MCU', 'F_CPU', 'AVR_GCC_PATH', 'INCPATH', 'LIBPATH', 'SRCPATH', 'LIBS', 'platform', 'mode']

Import(CONFIG)

TARGET = "HelloWorld"
if (platform == 'avr'):
  MCU = 'atmega1280'
  F_CPU = 16000000

Return(CONFIG)
