ifneq ($(KERNELRELEASE),)

obj-m := qidlecpu.o
qidlecpu-y := monitor.o

else

KDIR= /lib/modules/$(shell uname -r)/build

all:
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) M=$(PWD) clean
endif
