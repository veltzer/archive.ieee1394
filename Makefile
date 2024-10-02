##############
# parameters #
##############
# do you want to show the commands executed ?
DO_MKDBG:=0
# do you want dependency on the Makefile itself ?
DO_ALLDEP:=1

#
# Makefile for the Linux IEEE 1394 implementation
#

ieee1394-objs := ieee1394_core.o ieee1394_transactions.o hosts.o \
		 highlevel.o csr.o nodemgr.o dma.o iso.o \
		 csr1212.o config_roms.o support.o

obj-$(CONFIG_IEEE1394) += ieee1394.o
obj-$(CONFIG_IEEE1394_PCILYNX) += pcilynx.o
obj-$(CONFIG_IEEE1394_OHCI1394) += ohci1394.o
obj-$(CONFIG_IEEE1394_VIDEO1394) += video1394.o
obj-$(CONFIG_IEEE1394_RAWIO) += raw1394.o
obj-$(CONFIG_IEEE1394_SBP2) += sbp2.o
obj-$(CONFIG_IEEE1394_DV1394) += dv1394.o
obj-$(CONFIG_IEEE1394_ETH1394) += eth1394.o

obj-$(CONFIG_PROVIDE_OHCI1394_DMA_INIT) += init_ohci1394_dma.o

# the base name of the module (the name of the variable is your own)
NAMES:=ieee1394 raw1394 ohci1394 video1394 dv1394 pcilynx
# the name of the .ko
KOS:=$(addsuffix .ko,$(NAMES))
# the .ko file that will be generated
# the variable obj-m is required for the kernel to know which module to create.
# I know that it's weird but this should be a .o name and is probably due to backwards
# compatibility issues.
obj-m:=$(addsuffix .o,$(NAMES))
# This is not strictly required for a single object module where the name of the module
# is the name of the single file in it. In my case this is not the case since the module
# is hello.ko while the single file is main.c.
multifile-objs:=main.o another_file.o
multifile2-objs:=main2.o another_file2.o
# You can override using "make KVER=2.6.35".
KVER:=$(shell uname -r)
# fill in the directory of the kernel build system
KDIR:=/lib/modules/$(KVER)/build
# fill in the vervosity level you want
# You can override using "make V=1"
V:=0

.PHONY: all
all:
	@true

# the next four targets (modules, modules_install, clean, help) are targets defined
# by the kernel makefile...
.PHONY: modules
modules:
	$(MAKE) -C $(KDIR) M=$(CURDIR) V=$(V) modules
.PHONY: modules_install
modules_install:
	$(MAKE) -C $(KDIR) M=$(CURDIR) V=$(V) modules_install
.PHONY: clean
clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR) V=$(V) clean
.PHONY: clean_hard
clean_hard:
	git clean -qffxd
.PHONY: help
help:
	$(MAKE) -C $(KDIR) M=$(CURDIR) V=$(V) help

# a target to debug my own makefile...
.PHONY: debug
debug:
	$(info NAMES is $(NAMES))
	$(info KOS is $(KOS))
	$(info KVER is $(KVER))
	$(info KDIR is $(KDIR))
	$(info V is $(V))
	$(info CURDIR is $(CURDIR))
	$(info obj-m is $(obj-m))
	$(info multifile-objs is $(multifile-objs))
	$(info multifile2-objs is $(multifile2-objs))
# easy macros to enable kernel development (these make little sense in this context)
.PHONY: insmod
insmod: rmmod
	sudo insmod ./ieee1394.ko
	sudo insmod ./raw1394.ko
	sudo insmod ./ohci1394.ko
.PHONY: rmmod
rmmod:
	-sudo fuser -k /dev/raw1394
	-sudo rmmod ohci1394
	-sudo rmmod raw1394
	-sudo rmmod ieee1394
.PHONY: modprobe
modprobe:
	sudo modprobe raw1394
	sudo modprobe ohci1394
	sudo modprobe ieee1394
.PHONY: modinfo
modinfo:
	modinfo $(KO)
.PHONY: chown
chown:
	sudo chown $(USER).$(USER) /dev/raw1394
.PHONY: modprobe_new
modprobe_new:
	sudo modprobe firewire_core
	sudo modprobe firewire_ohci
.PHONY: rmmod_new
rmmod_new:
	-sudo rmmod firewire_ohci
	-sudo rmmod firewire_core

.PHONY: plugold
plugold: rmmod_new modprobe chown

.PHONY: plugnew
plugnew: rmmod modprobe_new

##########
# alldep #
##########
ifeq ($(DO_ALLDEP),1)
.EXTRA_PREREQS+=$(foreach mk, ${MAKEFILE_LIST},$(abspath ${mk}))
endif # DO_ALLDEP
