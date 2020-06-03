; For function calling conventions I will stick to this one:
; http://www.nongnu.org/avr-libc/user-manual/FAQ.html
; (see 'Function call conventions')

.equ RAMEND, 0x08FF

.equ SREG, 0x3F
.equ SPL,  0x3D
.equ SPH,  0x3E

; This memory mappings can be found in iom328p.h header file.

.equ PORTD, 0x0B
.equ DDRD,  0x0A

.org 0x0000

    rjmp INIT

INIT:

    ; Description:
    ; -----------
    ;
    ;  Reset the system status in SREG, initialize the stack using SPL and 
    ;  SPH and set output PINs on PORTB. We need 7 output PINs for the 7 
    ;  segment display so we  will use DIGITAL PINs 0-6.

    clr r16
    out SREG, r16

    ldi r16, lo8(RAMEND)
    out SPL, r16

    ldi r16, hi8(RAMEND)
    out SPH, r16

    ldi r16, 0x7F 
    out DDRD, r16

LOOP:

    ; Description:
    ; -----------
    ; 
    ;  COUNTER will implement a loop that counts from 0 to 9 and calls the ENCODE
    ;  subroutine to translate the binary number into a 7 segment displayable
    ;  number. After the subroutine is finished, WAIT will be called because we
    ;  want some delay between the numbers.

    clr r16

COUNTER:

    mov r24, r16
    call ENCODE

    call WAIT

    inc r16
    cpi r16, 0x0A
    brne COUNTER
     
    rjmp LOOP

ENCODE:

    ret

WAIT:

    ret
