# avr arduino atmega328 vga text library

## This library can be use to draw text on a VGA monitor using a atmega328 or an arduino and a couple of resistor.


## Info

Compiler command line

```
avra vga_test_640_480_60.asm
```

Send to chip

```
sudo avrdude -p m328p -c arduino -b 115200 -P /dev/ttyUSB0 -U flash:w:vga_test_640_480_60.hex
```