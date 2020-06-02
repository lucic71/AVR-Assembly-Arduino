; RAMEND is pretty self explanatory.

.equ RAMEND, 0x08FF

; Check [1] and [2] for more info about the following three
; symbols

.equ SREG, 0x3F
.equ SPL,  0x3D
.equ SPH,  0x3E

; Check [3] for more info about the following three symbols.

.equ PORTB, 0x05
.equ DDRB,  0x04
.equ PINB,  0X03

.org 0x0000
    rjmp MAIN

MAIN:

    ; Reset system status. Check this link for more details:
    ; http://www.rjhcoding.com/avr-asm-sreg.php [1]

    clr r16
    out SREG, r16

    ; Initialize stack pointer. Put the low byte of RAMEND in SPL (Stack Pointer Low)
    ; and the high byte in SPH (Stack Pointer High). Check this link for more details:
    ; http://www.rjhcoding.com/avr-asm-functions.php [2]

    ldi r16, lo8(RAMEND)
    out SPL, r16

    ldi r16, hi8(RAMEND)
    out SPH, r16

    ; Set port bits to output mode. We will use LED 5, so we need to set the fifth bit
    ; in DDRB (Data Direction Register B). Check this link for more details:
    ; https://web.ics.purdue.edu/~jricha14/Port_Stuff/PortB_general.htm [3]

    ldi r16, 0x20
    out DDRB, r16

    ; In the main loop we will toggle the fifht bit in PORTB to turn the LED on and off
    ; using exclusive or. After that we will wait for some time because we won't be able
    ; to see the LED blink otherwise.

    ldi r17, 0x20
    clr r16

MAINLOOP:

    eor r16, r17
    out PORTB, r16
    call WAIT
    rjmp MAINLOOP

WAIT:

    push r16
    push r17
    push r18

    ; Loop 0x400000 times which takes approximately 12 milion cycles which is
    ; approximately 0.7s. For cycles/instruction info check this link, this is
    ; actually the AVR Instruction Set Manual:
    ; http://ww1.microchip.com/downloads/en/devicedoc/atmel-0856-avr-instruction-set-manual.pdf [4]

    ldi r16, 0x20
    ldi r17, 0x00
    ldi r18, 0x00

_WAIT:

    dec r18
    brne _WAIT

    dec r17
    brne _WAIT

    dec r16
    brne _WAIT

    pop r18
    pop r17
    pop r16

    ret
