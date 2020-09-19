#  Part of Grbl Simulator
#
#  Copyright (c) 2012 Jens Geisler
#  Copyright (c) 2014-2015 Adam Shelly
#
#  Grbl is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  Grbl is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Grbl.  If not, see <http://www.gnu.org/licenses/>.

# PLATFORM   = WINDOWS
# PLATFORM   = OSX
CC = gcc
PLATFORM   = LINUX
GRBL_ROOT = ../grbl
GRBL_DIR = ../grbl/grbl

#The original grbl code, except those files overriden by sim
GRBL_BASE_OBJECTS =   $(GRBL_DIR)/protocol.o $(GRBL_DIR)/planner.o $(GRBL_DIR)/settings.o $(GRBL_DIR)/print.o $(GRBL_DIR)/nuts_bolts.o  $(GRBL_DIR)/stepper.o $(GRBL_DIR)/gcode.o $(GRBL_DIR)/spindle_control.o $(GRBL_DIR)/motion_control.o $(GRBL_DIR)/limits.o $(GRBL_DIR)/coolant_control.o $(GRBL_DIR)/probe.o $(GRBL_DIR)/system.o $(GRBL_DIR)/jog.o 
# grbl files that have simulator overrrides 
GRBL_OVERRIDE_OBJECTS =  $(GRBL_DIR)/main.o $(GRBL_DIR)/serial.o $(GRBL_DIR)/report.o

#AVR interface simulation
AVR_OBJECTS  = avr/interrupt.o avr/pgmspace.o  avr/io.o  avr/eeprom.o grbl_eeprom_extensions.o

# Simulator Only Objects
SIM_OBJECTS = main.o simulator.o serial.o util/delay.o util/floatunsisf.o platform_$(PLATFORM).o system_declares.o

GRBL_SIM_OBJECTS = grbl_interface.o  $(GRBL_BASE_OBJECTS) $(GRBL_OVERRIDE_OBJECTS) $(SIM_OBJECTS) $(AVR_OBJECTS)
GRBL_VAL_OBJECTS = validator.o overridden_report.o $(GRBL_BASE_OBJECTS) $(AVR_OBJECTS) system_declares.o

CLOCK      = 16000000
SIM_EXE_NAME   = grbl_sim$(EXEEXT)
VALIDATOR_NAME = gvalidate$(EXEEXT)
ifeq ($(DEBUG),)
CFLAGS = -g -O3
else
CFLAGS = -g3 -ggdb -O0
endif
COMPILE    = $(CC) -Wall $(CFLAGS) -DF_CPU=$(CLOCK)  -include config.h -I. -I$(GRBL_ROOT) -DPLAT_$(PLATFORM)
LINUX_LIBRARIES = -lrt -pthread
OSX_LIBRARIES =
WINDOWS_LIBRARIES =

# symbolic targets:
all:	main gvalidate


install:
	install -m755 grbl_sim /usr/local/bin/
new: clean main gvalidate

clean:
	rm -f $(SIM_EXE_NAME) $(GRBL_SIM_OBJECTS) $(VALIDATOR_NAME) $(GRBL_VAL_OBJECTS)

# file targets:
main: $(GRBL_SIM_OBJECTS) 
	$(COMPILE) -o $(SIM_EXE_NAME) $(GRBL_SIM_OBJECTS) -lm $($(PLATFORM)_LIBRARIES)


gvalidate: $(GRBL_VAL_OBJECTS) 
	$(COMPILE)  -o $(VALIDATOR_NAME) $(GRBL_VAL_OBJECTS) -lm  $($(PLATFORM)_LIBRARIES)


%.o: %.c
	$(COMPILE) -c $< -o $@

$(GRBL_DIR)/planner.o: $(GRBL_DIR)/planner.c
	$(COMPILE) -include planner_inject_accessors.c -c $< -o $@

$(GRBL_DIR)/serial.o: $(GRBL_DIR)/serial.c
	$(COMPILE) -include serial_hooks.h -c $< -o $@

$(GRBL_DIR)/main.o: $(GRBL_DIR)/main.c
	$(COMPILE) -include rename_main.h -c $< -o $@

overridden_report.o: $(GRBL_DIR)/report.c
	$(COMPILE) -include rename_report_status_message.h -c $< -o $@
