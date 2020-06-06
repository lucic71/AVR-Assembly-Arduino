7 SEGMENT DISPLAY

segment.s implements the logic behind displaying numbers between 0 and 9 on
a 7 segment display. The PIN configuration is the following:

  * a - DIGITAL PIN 0
  * b - DIGITAL PIN 1
  * c - DIGITAL PIN 2
  * d - DIGITAL PIN 3
  * e - DIGITAL PIN 4
  * f - DIGITAL PIN 5
  * d - DIGITAL PIN 6

All these PINs are connected on PORTD, so we need to keep that in mind when
writing our output to the correct PORT.

The boolean formulas used to configure the PINs are calcualted using
Karnaugh Diagrams. 

As a final word, don't forget to add resistors in series with each display
PIN, on the breadboard, because I forgot to do so and I completely screwed
a display.
