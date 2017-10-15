######################################################################
# Makefile user configuration
######################################################################

# Path to nodemcu-uploader (https://github.com/kmpm/nodemcu-uploader)
NODEMCU-UPLOADER ?= nodemcu-uploader

# Serial port
export SERIALPORT ?= /dev/cu.usbserial-A9OZ31TX
SERIALSPEED ?= 115200

NODEMCU-COMMAND=$(NODEMCU-UPLOADER) -b $(SERIALSPEED)

######################################################################

SOURCEDIR = src
BUILDDIR = build

SOURCES := $(wildcard $(SOURCEDIR)/*.lua)
SOURCES := $(filter-out $(wildcard */*.example.*), $(SOURCES))
TARGETS := $(patsubst $(SOURCEDIR)/%.lua, $(BUILDDIR)/%.lua, $(SOURCES))


.PHONY: default all clean terminal format ls

default: $(BUILDDIR) $(TARGETS)

help:
	@echo " make                to upload only changed files"
	@echo " make all            to upload all files"
	@echo " make terminal       to start lua terminal on ESP"
	@echo " make ls             to list files on ESP"
	@echo " make format         to remove all files from ESP"
	@echo $(TEST)

all: clean default

$(BUILDDIR):
	mkdir -p $@

$(BUILDDIR)/%.lua: $(SOURCEDIR)/%.lua
	$(NODEMCU-COMMAND) upload $<:$(notdir $<) --verify=raw
	cp -v $< $@

clean:
	rm -rf $(BUILDDIR)

terminal:
	rlwrap --always-readline $(NODEMCU-COMMAND) terminal

format:
	$(NODEMCU-COMMAND) file format

ls:
	$(NODEMCU-COMMAND) file list
