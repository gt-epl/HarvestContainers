ifneq ($(KERNELRELEASE),)
# kbuild part of makefile
obj-m := qidlecpu.o
qidlecpu-y := monitor.o

else
# Run this Makefile as follows:
# make clean && make all && make test
#
KDIR= /lib/modules/$(shell uname -r)/build

all:
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) M=$(PWD) clean
endif
