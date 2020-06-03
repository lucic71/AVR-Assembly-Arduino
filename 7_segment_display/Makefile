BINARY=segment

AS=avr-as
LD=avr-ld
OBJCOPY=avr-objcopy
GDB=avr-gdb

AVRDUDE=avrdude
AVRDUDE_CONFIG=/etc/avrdude.conf

TTY=/dev/ttyACM0

ARCH=atmega328p

SIMAVR=simavr

build:
	$(AS) -g -mmcu=$(ARCH) -o $(BINARY).o $(BINARY).s
	$(LD) -o $(BINARY).elf $(BINARY).o
	$(OBJCOPY) -O ihex -R .eeprom $(BINARY).elf $(BINARY).hex	

upload:
	$(AVRDUDE) -C $(AVRDUDE_CONFIG) -p $(ARCH) -c arduino -P $(TTY) -b 115200 -D -U flash:w:$(BINARY).hex:i

sim:
	$(SIMAVR) -m $(ARCH) $(BINARY).elf -g 

debug:
	$(GDB) $(BINARY).elf


run: build upload
	
clean:
	ls | grep $(BINARY) | grep -v *.s | xargs rm -f --
