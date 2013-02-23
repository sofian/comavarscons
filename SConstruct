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
from itertools import ifilter, imap
from subprocess import check_call, CalledProcessError
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
CONFIG = {}

def resolve_var(varname, default_value):
    global VARTAB
    global CONFIG
    # precedence: 
    # 1. scons argument
    # 2. global variable
    # 3. environment variable
    # 4. default value
    ret = ARGUMENTS.get(varname, None)
    VARTAB[varname] = ('arg', ret)
    if ret == None:
        if (varname in CONFIG):
          ret = CONFIG[varname]
        VARTAB[varname] = ('var', ret)
    if ret == None:
        ret = os.environ.get(varname, None)
        VARTAB[varname] = ('env', ret)
    if ret == None:
        ret = default_value
        VARTAB[varname] = ('dfl', ret)
    return ret

def toList(var, separator):
  if (type(var) is list):
    return var
  elif (type(var) is str):
    return var.split(separator)
  else:
    exit("Variable has wrong type " + type(var) + ".")
    
def getUsbTty(rx):
    usb_ttys = glob(rx)
    return usb_ttys[0] if len(usb_ttys) == 1 else None

def run(cmd):
    """Run a command and decipher the return code. Exit by default."""
    print ' '.join(cmd)
    try:
        check_call(cmd)
    except CalledProcessError as cpe:
        print "Error: return code: " + str(cpe.returncode)
        sys.exit(cpe.returncode)

# WindowXP not supported path.samefile
def sameFile(p1, p2):
    if platform == 'win32':
        ap1 = path.abspath(p1)
        ap2 = path.abspath(p2)
        return ap1 == ap2
    return path.samefile(p1, p2)

def fnProcessing(target, source, env):
    wp = open(str(target[0]), 'wb')
    wp.write(open(ARDUINO_SKEL).read())

    types='''void
             int char word long
             float double byte long
             boolean
             uint8_t uint16_t uint32_t
             int8_t int16_t int32_t'''
    types=' | '.join(types.split())
    re_signature = re.compile(r"""^\s* (
        (?: (%s) \s+ )?
        \w+ \s*
        \( \s* ((%s) \s+ \*? \w+ (?:\s*,\s*)? )* \)
        ) \s* {? \s* $""" % (types, types), re.MULTILINE | re.VERBOSE)

    prototypes = {}

    for file in glob(path.realpath(os.curdir) + "/*" + sketchExt):
        for line in open(file):
            result = re_signature.search(line)
            if result:
                prototypes[result.group(1)] = result.group(2)

    for name in prototypes.iterkeys():
        print "%s;" % name
        wp.write("%s;\n" % name)

    # I don't understand these lines: why are we merging all .pde files
    # together???
    #for file in glob(path.realpath(os.curdir) + "/*" + sketchExt):
    #    print file, TARGET
    #    if not sameFile(file, TARGET + sketchExt):
    #        wp.write('#line 1 "%s"\r\n' % file)
    #        wp.write(open(file).read())

    # Add this preprocessor directive to localize the errors.
    sourcePath = str(source[0]).replace('\\', '\\\\')
    wp.write('#line 1 "%s"\r\n' % sourcePath)
    wp.write(open(str(source[0])).read())

def fnCompressCore(target, source, env):
    global BUILD_DIR
    core_prefix = path.join(BUILD_DIR, 'core').replace('/', os.path.sep)
    core_files = (x for x in imap(str, source)
                  if x.startswith(core_prefix))
    for file in core_files:
        run([AVR_BIN_PREFIX + 'ar', 'rcs', str(target[0]), file])

def gatherSources(srcpath, recursive = False):
    ptnSource = re.compile(r'\.(?:c(?:pp)?|S)$')
    sources = []
    for f in os.listdir(srcpath):
      fullpath = path.join(srcpath, f)
      if path.isdir(fullpath) and recursive:
        sources += gatherSources(fullpath, True)
      if path.isfile(fullpath) and ptnSource.search(f):
        sources += [fullpath]
    return sources

# General arguments

env = Environment()
computerOs = env['PLATFORM']

TARGET = None

# Get platform and mode.
platform = ARGUMENTS.get("platform", "computer")
mode     = ARGUMENTS.get("mode", "release")

# Import settings
CONFIG_VARS = ['TARGET', 'MCU', 'F_CPU', 'AVR_GCC_PATH', 'INCPATH', 'LIBPATH', 'SRCPATH', 'LIBS', 'ARDUINO_BOARD', 'ARDUINO_HOME', 'AVRDUDE_PORT', 'ARDUINO_SKETCHBOOK_HOME', 'ARDUINO_VER', 'ARDUINO_EXTRA_LIBRARIES_PATH', 'ARDUINO_EXTRA_LIBRARIES', 'RST_TRIGGER', 'AVRDUDE_CONF', 'EXTRA_SOURCES', 'CPPFLAGS']
for k in CONFIG_VARS:
  CONFIG[k] = None

# Get variables from SConscript
CONFIG = SConscript(dirs='.', exports=['CONFIG', 'platform', 'mode'])
for (k, v) in CONFIG.items():
  vars()[k] = v

# Get target from commandline (unless specified in SConscript)
if TARGET == None:
  TARGET = COMMAND_LINE_TARGETS[0]

if platform == 'arduino':
  if computerOs == 'darwin':
      # For MacOS X, pick up the AVR tools from within Arduino.app
      ARDUINO_HOME        = resolve_var('ARDUINO_HOME',
                                        '/Applications/Arduino.app/Contents/Resources/Java')
      AVRDUDE_PORT        = resolve_var('AVRDUDE_PORT', getUsbTty('/dev/tty.usbserial*'))
      ARDUINO_SKETCHBOOK_HOME     = resolve_var('ARDUINO_SKETCHBOOK_HOME', '')
      AVR_GCC_PATH        = resolve_var('AVR_GCC_PATH',
                                        path.join(ARDUINO_HOME, 'hardware/tools/avr/bin'))
      AVRDUDE_CONF        = path.join(ARDUINO_HOME, 'hardware/tools/avr/etc/avrdude.conf')
  elif computerOs == 'win32':
      # For Windows, use environment variables.
      ARDUINO_HOME        = resolve_var('ARDUINO_HOME', None)
      AVRDUDE_PORT        = resolve_var('AVRDUDE_PORT', '')
      ARDUINO_SKETCHBOOK_HOME     = resolve_var('ARDUINO_SKETCHBOOK_HOME', '')
      AVR_GCC_PATH        = resolve_var('AVR_GCC_PATH',
                                        path.join(ARDUINO_HOME, 'hardware/tools/avr/bin'))
      AVRDUDE_CONF        = path.join(ARDUINO_HOME, 'hardware/tools/avr/etc/avrdude.conf')
  else:
      # For Ubuntu Linux (9.10 or higher)
      ARDUINO_HOME        = resolve_var('ARDUINO_HOME', '/usr/share/arduino/')
      AVRDUDE_PORT        = resolve_var('AVRDUDE_PORT', getUsbTty('/dev/ttyUSB*'))
      ARDUINO_SKETCHBOOK_HOME     = resolve_var('ARDUINO_SKETCHBOOK_HOME',
                                        path.expanduser('~/share/arduino/sketchbook/'))
      AVR_GCC_PATH        = resolve_var('AVR_GCC_PATH', '')

if platform != 'computer':
  if computerOs == 'darwin':
      AVRDUDE_PORT        = resolve_var('AVRDUDE_PORT', getUsbTty('/dev/tty.usbserial*'))
  elif computerOs == 'win32':
      AVRDUDE_PORT        = resolve_var('AVRDUDE_PORT', '')
  else:
      AVRDUDE_PORT        = resolve_var('AVRDUDE_PORT', getUsbTty('/dev/ttyUSB*'))

# Basic compilation arguments.
INCPATH = toList(resolve_var('INCPATH', ""), ':')
INCPATH = unique(INCPATH + [os.getcwd()])

# AVR arguments
MCU   = resolve_var('MCU', "atmega168")
F_CPU = resolve_var('F_CPU', 16000000)

# Shared library arguments.
LIBS = toList(resolve_var('LIBS', ""), ',')
LIBPATH = toList(resolve_var('LIBPATH', ""), ':')
LIBS += ["m"]

# Remove empty items
LIBS = filter(None, LIBS)
LIBPATH = filter(None, LIBPATH)

# Source path.
SRCPATH = toList(resolve_var('SRCPATH', ""), ':')

# CPP extra flags / paths
CPPFLAGS = toList(resolve_var('CPPFLAGS', ''), ',')

# There should be a file with the same name as the folder and with the extension .pde
#TARGET = os.path.basename(os.path.realpath(os.curdir))
#assert(os.path.exists(TARGET+'.pde'))

if platform != 'computer':
  AVR_BIN_PREFIX = path.join(AVR_GCC_PATH, 'avr-');
  UPLOAD_PROTOCOL = resolve_var('UPLOAD_PROTOCOL', 'stk500')
  UPLOAD_SPEED = resolve_var('UPLOAD_PROTOCOL', 57600)

# Define build directory.
BUILD_DIR  = "build/"
BUILD_DIR += platform + "_"

if platform == "computer":
  BUILD_DIR += computerOs
elif platform == "arduino":
  BUILD_DIR += ARDUINO_BOARD
elif platform == "avr":
  BUILD_DIR += MCU# + "_" + str(F_CPU)

BUILD_DIR += "/" + mode + "/"
#BUILD_DIR = path.join("build", "_".join(platform, mode, 

# Arduino-specific stuff ##############################################################
if platform == 'arduino':
  ARDUINO_BOARD   = resolve_var('ARDUINO_BOARD', 'atmega328')
  ARDUINO_VER     = resolve_var('ARDUINO_VER', 0) # Default to 0 if nothing is specified
  RST_TRIGGER     = resolve_var('RST_TRIGGER', None) # use built-in pulseDTR() by default
  ARDUINO_EXTRA_LIBRARIES_PATH = resolve_var('ARDUINO_EXTRA_LIBRARIES_PATH', "") # handy for adding another arduino-lib dir
  ARDUINO_EXTRA_LIBRARIES = resolve_var('ARDUINO_EXTRA_LIBRARIES', "") # handy for explicitely specifying needed libraries
    
  pprint(VARTAB, indent = 4)
  
  if not ARDUINO_HOME:
      print 'ARDUINO_HOME must be defined.'
      raise KeyError('ARDUINO_HOME')
  
  ARDUINO_CONF = path.join(ARDUINO_HOME, 'hardware/arduino/boards.txt')
  # check given board name, ARDUINO_BOARD is valid one
  arduino_boards = path.join(ARDUINO_HOME,'hardware/*/boards.txt')
  custom_boards = path.join(ARDUINO_SKETCHBOOK_HOME,'hardware/*/boards.txt')
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
  if ARDUINO_EXTRA_LIBRARIES_PATH:
      ARDUINO_LIBS += ARDUINO_EXTRA_LIBRARIES_PATH.split(":")
  if ARDUINO_SKETCHBOOK_HOME:
      ARDUINO_LIBS.append(path.join(ARDUINO_SKETCHBOOK_HOME, 'libraries'))
  
  # Override MCU and F_CPU
  MCU = resolve_var('MCU', getBoardConf('build.mcu'))
  F_CPU = resolve_var('F_CPU', getBoardConf('build.f_cpu'))
  UPLOAD_PROTOCOL = getBoardConf('upload.protocol')
  UPLOAD_SPEED = getBoardConf('upload.speed')
  sketchExt = '.ino' if path.exists(TARGET + '.ino') else '.pde'

# Get sources #########################################################################
sources = []
for index, d in enumerate(SRCPATH):
  if (d == None or d == ""):
    continue
  srcdir = BUILD_DIR + 'src_%02d' % index
  env.VariantDir(srcdir, d)
  src = gatherSources(d, True)
  src = [x.replace(d, srcdir + "/") for x in src]
  sources += src

# Create environment and set default configurations ###################################

# AVR and Arduino modes ###############################################################
if (platform == 'avr' or platform == 'arduino'):
  cFlags = ['-ffunction-sections', '-fdata-sections', '-fno-exceptions',
            '-funsigned-char', '-funsigned-bitfields', '-fpack-struct', '-fshort-enums',
            '-Os', '-mmcu=%s'%MCU]
  cFlags += CPPFLAGS

  cppDefines = { 'F_CPU': F_CPU }
  if platform == 'arduino':
    cppDefines['ARDUINO'] = ARDUINO_VER
  
  env.Replace(CC = AVR_BIN_PREFIX + 'gcc',
             CXX = AVR_BIN_PREFIX + 'g++',
             AS = AVR_BIN_PREFIX + 'gcc',
             CPPPATH = INCPATH,
             LIBPATH = LIBPATH, # path to qualia static lib
             LIBS = LIBS, 
             CPPDEFINES = cppDefines,
             CFLAGS = cFlags + ['-std=gnu99'], 
             CCFLAGS = cFlags, 
             ASFLAGS = ['-assembler-with-cpp','-mmcu=%s' % MCU],
             LINKFLAGS = ['-mmcu=%s' % MCU ],
             TOOLS = ['gcc','g++', 'as'])

  libPathFlags = ' '.join([ "-L" + x for x in LIBPATH ])
  libFlags    = ' '.join([ "-l" + x for x in LIBS ])
  
  env.Append(BUILDERS = {'Processing' : Builder(action = fnProcessing)})
  env.Append(BUILDERS = {'CompressCore': Builder(action = fnCompressCore)})
  env.Append(BUILDERS = {'Elf': Builder(action = AVR_BIN_PREFIX+'gcc -mmcu=%s ' % MCU +
                                '-Os -Wl,--gc-sections,--relax -o $TARGET $SOURCES ' + 
                                 libPathFlags + ' ' + libFlags)})
  env.Append(BUILDERS = {'Hex': Builder(action = AVR_BIN_PREFIX+'objcopy ' +
                                '-O ihex -R .eeprom $SOURCES $TARGET')})
  
  env.VariantDir(BUILD_DIR, ".")

  if platform == 'arduino':
    hwVariant = path.join(ARDUINO_HOME, 'hardware/arduino/variants',
                       getBoardConf("build.variant", ""))
    if hwVariant:
      env.Append(CPPPATH = hwVariant)
    
    # Convert sketch(.pde) to cpp
    env.Processing(BUILD_DIR + TARGET + '.cpp', BUILD_DIR + TARGET + sketchExt)
    #sources += [BUILD_DIR + TARGET + '.cpp']

  # Local sources (in ".")
  sources += Glob(BUILD_DIR + "*.cpp")
  sources += Glob(BUILD_DIR + "*.cxx")
  sources += Glob(BUILD_DIR + "*.c")
  
  #objs  = env.Object([BUILD_DIR + TARGET + ".cpp"])
  objs  = env.Object(sources)

  if platform == 'arduino':
    # add arduino core sources
    coreVariantDir = path.join(BUILD_DIR, 'core')
    env.Append(CPPPATH = coreVariantDir)
    env.VariantDir(coreVariantDir, ARDUINO_CORE)
    coreSources = gatherSources(ARDUINO_CORE)
    coreSources = [x.replace(ARDUINO_CORE, coreVariantDir) for x
                   in coreSources if path.basename(x) != 'main.cpp']
    coreObjs = env.Object(coreSources)
    
    # add libraries
    libCandidates = ARDUINO_EXTRA_LIBRARIES.split(",")

    ptnLib = re.compile(r'^[ ]*#[ ]*include [<"](.*)\.h[>"]')
    for line in open(TARGET + sketchExt):
        result = ptnLib.search(line)
        if not result:
            continue
        # Look for the library directory that contains the header.
        filename = result.group(1) + '.h'
        for libdir in ARDUINO_LIBS:
            for root, dirs, files in os.walk(libdir, followlinks=True):
                if filename in files:
                    libCandidates.append(path.basename(root))
    
    # Hack. In version 20 of the Arduino IDE, the Ethernet library depends
    # implicitly on the SPI library.
    if ARDUINO_VER >= 20 and 'Ethernet' in libCandidates:
        libCandidates.append('SPI')
    
    all_libs_sources = []
    for index, orig_lib_dir in enumerate(ARDUINO_LIBS):
        lib_dir = BUILD_DIR + 'lib_%02d' % index
        env.VariantDir(lib_dir, orig_lib_dir)
        for libPath in ifilter(path.isdir, glob(path.join(orig_lib_dir, '*'))):
            libName = path.basename(libPath)
            if not libName in libCandidates:
                continue
            print libName
            env.Append(CPPPATH = libPath.replace(orig_lib_dir, lib_dir))
            lib_sources = gatherSources(libPath)
            utilDir = path.join(libPath, 'utility')
            if path.exists(utilDir) and path.isdir(utilDir):
                lib_sources += gatherSources(utilDir)
                env.Append(CPPPATH = utilDir.replace(orig_lib_dir, lib_dir))
            lib_sources = (x.replace(orig_lib_dir, lib_dir) for x in lib_sources)
            all_libs_sources.extend(lib_sources)
    
    objs += env.Object(all_libs_sources)
    objs += env.CompressCore(path.join(BUILD_DIR, 'core.a'), coreObjs)

  env.Elf(BUILD_DIR + TARGET + '.elf', objs)
  env.Hex(BUILD_DIR + TARGET + '.hex', BUILD_DIR + TARGET + '.elf')
  
  if platform == 'arduino':
    MAX_SIZE = getBoardConf('upload.maximum_size')
    print "maximum size for hex file: %s bytes" % MAX_SIZE
  
  env.Command(None, BUILD_DIR + TARGET+'.hex', AVR_BIN_PREFIX+'size --target=ihex $SOURCE')
  
  # Reset
  def pulseDTR(target, source, env):
      import serial
      import time
      ser = serial.Serial(AVRDUDE_PORT)
      ser.setDTR(1)
      time.sleep(0.5)
      ser.setDTR(0)
      ser.close()
  
  if AVRDUDE_PORT == None:
    print "No avrdude port specified. Make sure the USB device is plugged."
    
  else:
    if RST_TRIGGER:
        reset_cmd = '%s %s' % (RST_TRIGGER, AVRDUDE_PORT)
    else:
        reset_cmd = pulseDTR
    
    # Upload
    if UPLOAD_PROTOCOL == 'stk500':
        UPLOAD_PROTOCOL = 'stk500v1'
    
    avrdudeOpts = ['-V', '-F', '-c %s' % UPLOAD_PROTOCOL, '-b %s' % UPLOAD_SPEED,
                   '-p %s' % MCU, '-P %s' % AVRDUDE_PORT, '-U flash:w:$SOURCES']
    if AVRDUDE_CONF:
        avrdudeOpts.append('-C %s' % AVRDUDE_CONF)
    
    fuse_cmd = '%s %s' % (path.join(path.dirname(AVR_BIN_PREFIX), 'avrdude'),
                          ' '.join(avrdudeOpts))
    
    upload = env.Alias('upload', BUILD_DIR + TARGET + '.hex', [reset_cmd, fuse_cmd])
    env.AlwaysBuild(upload)

# Computer mode (ie. non-avr) #########################################################
else:
  env = Environment()
  env.Append(CPPPATH=["/usr/local/include", "/usr/include", os.getcwd()])
  if (mode == 'debug'):
    env.Append(CPPFLAGS=['-Wall', '-g', '-DDEBUG=1'])
  else:
    env.Append(CPPFLAGS=['-O2'])
  env.Append(CPPFLAGS=CPPFLAGS)

  env.VariantDir(BUILD_DIR, ".", duplicate=0)
  sources += Glob(BUILD_DIR + "*.cpp")
  sources += Glob(BUILD_DIR + "*.c")
  
  env.Program(BUILD_DIR + TARGET, sources, LIBS = LIBS, CPPPATH = INCPATH, LIBPATH = LIBPATH)

  #objects = env.StaticObject(source = sources)

  # Peut etre une erreur: on devrait construire des OBJETS (?)
  #lib = env.Library(target = target, source = sources)

#execfile("../../tools/scons/SConstruct")

# Clean build directory
env.Clean('all', BUILD_DIR)
