.equ RAMEND, 0x08FF

.equ SREG, 0x3F
.equ SPL,  0x3D
.equ SPH,  0x3E

.equ PORTD, 0x0B
.equ DDRD,  0x0A

.equ PORTB, 0x05
.equ DDRB, 0x04

.equiv PINCONFIG, 24

.org 0x0000

INIT_MEM:

    ; Description:
    ; -----------
    ;
    ;  Reset the system status in SREG, initialize the stack using SPL and 
    ;  SPH and set output PINs on PORTB. 
    ;
    ; Pins used for DATA will be DIGITAL PIN 1-7 from PORTD and DIGITAL PIN 8
    ; from PORTB.
    ;
    ; Pins used for REGISTER SELECT, READ/WRITE and ENABLE are DIGITAL PINS
    ; 10, 11, respectively 12 from PORTB.

    clr r16
    out SREG, r16

    ldi r16, lo8(RAMEND)
    out SPL, r16

    ldi r16, hi8(RAMEND)
    out SPH, r16

    ldi r16, 0xFE
    out DDRD, r16

    ldi r16, 0x1C
    out DDRB, r16

INIT_LCD:

    ldi PINCONFIG, 0x10
    out PORTB, PINCONFIG

    ldi PINCONFIG, 0x70
    out PORTD, PINCONFIG

MAIN:
    rjmp MAIN
