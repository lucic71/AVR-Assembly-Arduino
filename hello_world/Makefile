all:
	avr-as -g -mmcu=atmega328p -o hello_world.o hello_world.s
	avr-ld -o hello_world.elf hello_world.o
	avr-objcopy -O ihex -R .eeprom hello_world.elf hello_world.hex

upload:
	avrdude -C /etc/avrdude.conf -p atmega328p -c arduino -P /dev/ttyACM0 -b 115200 -D -U flash:w:hello_world.hex:i

run: all upload

clean:
	ls | grep hello_world | grep -v *.s | xargs rm -f --
