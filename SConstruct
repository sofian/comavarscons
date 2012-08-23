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
import os
from os import path

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

MCU = 'atmega168'
F_CPU = 16000000
AVR_GCC_PATH = ""
INCPATH = ""
LIBPATH = ""
SRCPATH = ""
LIBS = ""
platform = "computer"
mode = "release"

# Import settings
CONFIG = ['TARGET', 'MCU', 'F_CPU', 'AVR_GCC_PATH', 'INCPATH', 'LIBPATH', 'SRCPATH', 'LIBS', 'platform', 'mode']
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
elif computerOs == 'win32':
    # For Windows, use environment variables.
    ARDUINO_HOME        = resolve_var('ARDUINO_HOME', None)
    ARDUINO_PORT        = resolve_var('ARDUINO_PORT', '')
    SKETCHBOOK_HOME     = resolve_var('SKETCHBOOK_HOME', '')
    AVR_GCC_PATH        = resolve_var('AVR_GCC_PATH',
                                      path.join(ARDUINO_HOME, 'hardware/tools/avr/bin'))
else:
    # For Ubuntu Linux (9.10 or higher)
    ARDUINO_HOME        = resolve_var('ARDUINO_HOME', '/usr/share/arduino/')
    ARDUINO_PORT        = resolve_var('ARDUINO_PORT', getUsbTty('/dev/ttyUSB*'))
    SKETCHBOOK_HOME     = resolve_var('SKETCHBOOK_HOME',
                                      path.expanduser('~/share/arduino/sketchbook/'))
    AVR_HOME            = resolve_var('AVR_GCC_PATH', '')

# Get mode.
platform = resolve_var("platform", "computer")
mode     = resolve_var("mode", "release")

# Basic compilation arguments.
INCPATH = resolve_var('INCPATH', INCPATH).split(":")
INCPATH = unique(INCPATH + [os.getcwd()])

# AVR arguments
MCU = resolve_var('MCU', MCU)
F_CPU = resolve_var('F_CPU', F_CPU)

# Shared library arguments.
LIBS = resolve_var('LIBS', LIBS).split(',')
LIBPATH = resolve_var('LIBPATH', LIBPATH).split(':')

BUILD_DIR = "build/" + platform + "/"

LIBS += ["m"]

# There should be a file with the same name as the folder and with the extension .pde
#TARGET = os.path.basename(os.path.realpath(os.curdir))
#assert(os.path.exists(TARGET+'.pde'))

#AVR_GCC_PATH = resolve_var('AVR_GCC_PATH', AVR_GCC_PATH)

AVR_BIN_PREFIX = path.join(AVR_GCC_PATH, 'avr-');

SRCPATH = resolve_var('SRCPATH', SRCPATH).split(':');

sources = []
for dir in SRCPATH:
	sources += Glob(dir + "/*.cpp")
	sources += Glob(dir + "/*.cxx")
	sources += Glob(dir + "/*.c")

# Remove empty items
LIBS = filter(None, LIBS)
LIBPATH = filter(None, LIBPATH)

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