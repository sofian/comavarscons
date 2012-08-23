# SCons script for cross-platform building (computer, avr, arduino)
# https://github.com/sofian/comavarscons
#
# Copyright (C) 2012 by Sofian Audry <info --A_T-- sofianaudry --D_O_T-- com>
#
# Based on code from:
# http://github.com/suapapa/arscons
# Copyright (C) 2010-2012 by Homin Lee <homin.lee@suapapa.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

from glob import glob
import sys
import re
import os
from os import path
from pprint import pprint

# From http://code.activestate.com/recipes/502263/
# By Paul Rubin
def unique(seq, keepstr=True):
  t = type(seq)
  if t in (str, unicode):
    t = (list, ''.join)[bool(keepstr)]
  seen = []
  return t(c for c in seq if not (c in seen or seen.append(c)))

VARTAB = {}

def resolve_var(varname, default_value):
    global VARTAB
    # precedence: 
    # 1. scons argument
    # 2. global variable
    # 3. environment variable
    # 4. default value
    ret = ARGUMENTS.get(varname, None)
    VARTAB[varname] = ('arg', ret)
    if ret == None:
        if (varname in vars()):
          ret = vars()[varname]
        VARTAB[varname] = ('var', ret)
    if ret == None:
        ret = os.environ.get(varname, None)
        VARTAB[varname] = ('env', ret)
    if ret == None:
        ret = default_value
        VARTAB[varname] = ('dfl', ret)
    return ret

def getUsbTty(rx):
    usb_ttys = glob(rx)
    return usb_ttys[0] if len(usb_ttys) == 1 else None

# General arguments

env = Environment()
computerOs = env['PLATFORM']

TARGET = None

#MCU = 'atmega168'
#F_CPU = 16000000
#AVR_GCC_PATH = ""
#INCPATH = ""
#LIBPATH = ""
#SRCPATH = ""
#LIBS = ""
#platform = "computer"
#mode = "release"

# Import settings

# Get mode.
CONFIG = ['TARGET', 'MCU', 'F_CPU', 'AVR_GCC_PATH', 'INCPATH', 'LIBPATH', 'SRCPATH', 'LIBS', 'platform', 'mode']
for i in range(len(CONFIG)):
  vars()[CONFIG[i]] = None

platform = ARGUMENTS.get("platform", "computer")
mode     = ARGUMENTS.get("mode", "release")
conf = SConscript(dirs='.', exports=CONFIG)
for i in range(len(CONFIG)):
  vars()[CONFIG[i]] = conf[i]

if TARGET == None:
  TARGET = COMMAND_LINE_TARGETS[0]

if computerOs == 'darwin':
    # For MacOS X, pick up the AVR tools from within Arduino.app
    ARDUINO_HOME        = resolve_var('ARDUINO_HOME',
                                      '/Applications/Arduino.app/Contents/Resources/Java')
    ARDUINO_PORT        = resolve_var('ARDUINO_PORT', getUsbTty('/dev/tty.usbserial*'))
    SKETCHBOOK_HOME     = resolve_var('SKETCHBOOK_HOME', '')
    AVR_GCC_PATH        = resolve_var('AVR_GCC_PATH',
                                      path.join(ARDUINO_HOME, 'hardware/tools/avr/bin'))
    AVRDUDE_CONF        = path.join(ARDUINO_HOME, 'hardware/tools/avr/etc/avrdude.conf')
elif computerOs == 'win32':
    # For Windows, use environment variables.
    ARDUINO_HOME        = resolve_var('ARDUINO_HOME', None)
    ARDUINO_PORT        = resolve_var('ARDUINO_PORT', '')
    SKETCHBOOK_HOME     = resolve_var('SKETCHBOOK_HOME', '')
    AVR_GCC_PATH        = resolve_var('AVR_GCC_PATH',
                                      path.join(ARDUINO_HOME, 'hardware/tools/avr/bin'))
    AVRDUDE_CONF        = path.join(ARDUINO_HOME, 'hardware/tools/avr/etc/avrdude.conf')
else:
    # For Ubuntu Linux (9.10 or higher)
    ARDUINO_HOME        = resolve_var('ARDUINO_HOME', '/usr/share/arduino/')
    ARDUINO_PORT        = resolve_var('ARDUINO_PORT', getUsbTty('/dev/ttyUSB*'))
    SKETCHBOOK_HOME     = resolve_var('SKETCHBOOK_HOME',
                                      path.expanduser('~/share/arduino/sketchbook/'))
    AVR_GCC_PATH        = resolve_var('AVR_GCC_PATH', '')

# Basic compilation arguments.
INCPATH = resolve_var('INCPATH', "").split(":")
INCPATH = unique(INCPATH + [os.getcwd()])

# AVR arguments
MCU = resolve_var('MCU', "atmega168")
F_CPU = resolve_var('F_CPU', 16000000)

# Shared library arguments.
LIBS = resolve_var('LIBS', "").split(',')
LIBPATH = resolve_var('LIBPATH', "").split(':')
LIBS += ["m"]

# Remove empty items
LIBS = filter(None, LIBS)
LIBPATH = filter(None, LIBPATH)

# There should be a file with the same name as the folder and with the extension .pde
#TARGET = os.path.basename(os.path.realpath(os.curdir))
#assert(os.path.exists(TARGET+'.pde'))

AVR_BIN_PREFIX = path.join(AVR_GCC_PATH, 'avr-');

# Fetch sources.
SRCPATH = resolve_var('SRCPATH', "").split(':');

sources = []
for dir in SRCPATH:
	sources += Glob(dir + "/*.cpp")
	sources += Glob(dir + "/*.cxx")
	sources += Glob(dir + "/*.c")

BUILD_DIR = "build/" + platform + "/"

# Arduino-specific stuff ##############################################################
if platform == 'arduino':
  ARDUINO_BOARD   = resolve_var('ARDUINO_BOARD', 'atmega328')
  ARDUINO_VER     = resolve_var('ARDUINO_VER', 0) # Default to 0 if nothing is specified
  RST_TRIGGER     = resolve_var('RST_TRIGGER', None) # use built-in pulseDTR() by default
  EXTRA_LIB       = resolve_var('EXTRA_LIB', None) # handy for adding another arduino-lib dir
  
  pprint(VARTAB, indent = 4)
  
  if not ARDUINO_HOME:
      print 'ARDUINO_HOME must be defined.'
      raise KeyError('ARDUINO_HOME')
  
  ARDUINO_CONF = path.join(ARDUINO_HOME, 'hardware/arduino/boards.txt')
  # check given board name, ARDUINO_BOARD is valid one
  arduino_boards = path.join(ARDUINO_HOME,'hardware/*/boards.txt')
  custom_boards = path.join(SKETCHBOOK_HOME,'hardware/*/boards.txt')
  board_files = glob(arduino_boards) + glob(custom_boards)
  ptnBoard = re.compile(r'^([^#]*)\.name=(.*)')
  boards = {}
  for bf in board_files:
      for line in open(bf):
          result = ptnBoard.match(line)
          if result:
              boards[result.group(1)] = (result.group(2), bf)
  
  if ARDUINO_BOARD not in boards:
      print "ERROR! the given board name, %s is not in the supported board list:" % ARDUINO_BOARD
      print "all available board names are:"
      for name, description in boards.iteritems():
          print "\t%s for %s" % (name.ljust(14), description[0])
      #print "however, you may edit %s to add a new board." % ARDUINO_CONF
      sys.exit(-1)
  
  ARDUINO_CONF = boards[ARDUINO_BOARD][1]
  
  def getBoardConf(conf, default = None):
      for line in open(ARDUINO_CONF):
          line = line.strip()
          if '=' in line:
              key, value = line.split('=')
              if key == '.'.join([ARDUINO_BOARD, conf]):
                  return value
      ret = default
      if ret == None:
          print "ERROR! can't find %s in %s" % (conf, ARDUINO_CONF)
          assert(False)
      return ret
  
  ARDUINO_CORE = path.join(ARDUINO_HOME, path.dirname(ARDUINO_CONF),
                           'cores/', getBoardConf('build.core', 'arduino'))
  ARDUINO_SKEL = path.join(ARDUINO_CORE, 'main.cpp')
  
  if ARDUINO_VER == 0:
      arduinoHeader = path.join(ARDUINO_CORE, 'Arduino.h')
      print "No Arduino version specified. Discovered version",
      if path.exists(arduinoHeader):
          print "100 or above"
          ARDUINO_VER = 100
      else:
          print "0023 or below"
          ARDUINO_VER = 23
  else:
      print "Arduino version " + ARDUINO_VER + " specified"

  ARDUINO_LIBS = [path.join(ARDUINO_HOME, 'libraries')]
  if EXTRA_LIB:
      ARDUINO_LIBS.append(EXTRA_LIB)
  if SKETCHBOOK_HOME:
      ARDUINO_LIBS.append(path.join(SKETCHBOOK_HOME, 'libraries'))
  
  # Override MCU and F_CPU
  MCU = resolve_var('MCU', getBoardConf('build.mcu'))
  F_CPU = resolve_var('F_CPU', getBoardConf('build.f_cpu'))
  
# Create environment and set default configurations ###################################
if (platform == 'avr' or platform == 'arduino'):
  cFlags = ['-ffunction-sections', '-fdata-sections', '-fno-exceptions',
            '-funsigned-char', '-funsigned-bitfields', '-fpack-struct', '-fshort-enums',
            '-Os', '-mmcu=%s'%MCU]
  env = Environment(CC = AVR_BIN_PREFIX+'gcc',
                    CXX = AVR_BIN_PREFIX+'g++',
                    AS = AVR_BIN_PREFIX + 'gcc',
                    CPPPATH = INCPATH,
                    LIBPATH = LIBPATH, # path to qualia static lib
                    LIBS = LIBS, 
                    CPPDEFINES = {'F_CPU':F_CPU}, 
                    CFLAGS = cFlags + ['-std=gnu99'], 
                    CCFLAGS = cFlags, 
                    ASFLAGS = ['-assembler-with-cpp','-mmcu=%s' % MCU],
                    LINKFLAGS = ['-mmcu=%s' % MCU ])

  libPathFlags = ' '.join([ "-L" + x for x in LIBPATH ])
  libFlags    = ' '.join([ "-l" + x for x in LIBS ])
  env.Append(BUILDERS = {'Elf':Builder(action = AVR_BIN_PREFIX+'gcc -mmcu=%s ' % MCU +
                         '-Os -Wl,--gc-sections,--relax -o $TARGET $SOURCES ' + 
                         libPathFlags + ' ' + libFlags)})
  env.Append(BUILDERS = {'Hex':Builder(action = AVR_BIN_PREFIX+'objcopy ' +
                         '-O ihex -R .eeprom $SOURCES $TARGET')})
  
  env.VariantDir(BUILD_DIR, ".", duplicate=0)
  
  sources += Glob(BUILD_DIR + "*.cpp")
  sources += Glob(BUILD_DIR + "*.cxx")
  sources += Glob(BUILD_DIR + "*.c")
  
  objs = env.Object(sources)
  env.Elf(BUILD_DIR + TARGET + '.elf', objs)
#  env.Program(target = BUILD_DIR + TARGET + '.elf', source = sources, 
#  					  CPPFLAGS = ['-mmcu=%s' % MCU, '-Os'],
#  						LINKFLAGS = "-Wl,--gc-sections,--relax", )
  env.Hex(BUILD_DIR + TARGET + '.hex', BUILD_DIR + TARGET + '.elf')
  
  #MAX_SIZE = getBoardConf(r'^%s\.upload.maximum_size=(.*)'%ARDUINO_BOARD)
  #print ("maximum size for hex file: %s bytes"%MAX_SIZE)
  env.Command(None, BUILD_DIR + TARGET+'.hex', AVR_BIN_PREFIX+'size --target=ihex $SOURCE')

else:
  env = Environment()
  env.Append(CPPPATH=["/usr/local/include", "/usr/include", os.getcwd()])
  if (mode == 'debug'):
    env.Append(CPPFLAGS=['-Wall', '-g', '-DDEBUG=1'])
  else:
    env.Append(CPPFLAGS=['-O2'])

  env.VariantDir(BUILD_DIR, ".", duplicate=0)
  sources += Glob(BUILD_DIR + "*.cpp")
  sources += Glob(BUILD_DIR + "*.c")
  
  env.Program(BUILD_DIR + TARGET, sources, LIBS = LIBS, CPPPATH = INCPATH, LIBPATH = LIBPATH)


  #objects = env.StaticObject(source = sources)

  # Peut etre une erreur: on devrait construire des OBJETS (?)
  #lib = env.Library(target = target, source = sources)

#execfile("../../tools/scons/SConstruct")