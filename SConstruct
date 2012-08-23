import os

# From http://code.activestate.com/recipes/502263/
# By Paul Rubin
def unique(seq, keepstr=True):
  t = type(seq)
  if t in (str, unicode):
    t = (list, ''.join)[bool(keepstr)]
  seen = []
  return t(c for c in seq if not (c in seen or seen.append(c)))

# General arguments

# Get mode.
platform = ARGUMENTS.get("platform", "computer")
mode     = ARGUMENTS.get("mode", "release")

TARGET = None

MCU = 'atmega168'
F_CPU = 16000000
AVR_GCC_PATH = ""
INCPATH = ""
LIBPATH = ""
SRCPATH = ""
LIBS = ""

if (platform == 'avr' or platform == 'arduino'):
  AVR_GCC_PATH = "/Applications/Arduino.app/Contents/Resources/Java/hardware/tools/avr/bin/"

# Import settings
CONFIG = ['TARGET', 'MCU', 'F_CPU', 'AVR_GCC_PATH', 'INCPATH', 'LIBPATH', 'SRCPATH', 'LIBS', 'platform', 'mode']
conf = SConscript(dirs='.', exports=CONFIG)
for i in range(len(CONFIG)):
  vars()[CONFIG[i]] = conf[i]

if TARGET == None:
  TARGET = COMMAND_LINE_TARGETS[0]

INCPATH = ARGUMENTS.get('INCPATH', INCPATH).split(":")
INCPATH = unique(INCPATH + [os.getcwd()])

# AVR arguments
MCU = ARGUMENTS.get('MCU', MCU)
F_CPU = ARGUMENTS.get('F_CPU', F_CPU)

# Shared library arguments.
LIBS = ARGUMENTS.get('LIBS', LIBS).split(',')
LIBPATH = ARGUMENTS.get('LIBPATH', LIBPATH).split(':')

BUILD_DIR = "build/" + platform + "/"

LIBS += ["m"]

# There should be a file with the same name as the folder and with the extension .pde
#TARGET = os.path.basename(os.path.realpath(os.curdir))
#assert(os.path.exists(TARGET+'.pde'))

AVR_GCC_PATH = ARGUMENTS.get('AVR_GCC_PATH', AVR_GCC_PATH)

AVR_BIN_PREFIX = AVR_GCC_PATH + '/avr-'

SRCPATH = ARGUMENTS.get('SRCPATH', SRCPATH).split(':');

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
  env.Append(BUILDERS = {'Elf':Builder(action=AVR_BIN_PREFIX+'gcc -mmcu=%s ' % MCU +
                         '-Os -Wl,--gc-sections,--relax -o $TARGET $SOURCES ' + libPathFlags + ' ' + libFlags)})
  env.Append(BUILDERS = {'Hex':Builder(action=AVR_BIN_PREFIX+'objcopy '+
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