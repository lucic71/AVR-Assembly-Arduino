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

; Aliases for registers. It is easier to develop the logic this way.

.equiv ABIT, 17
.equiv BBIT, 18
.equiv CBIT, 19
.equiv DBIT, 20
.equiv RESULT, 21
.equiv TEMP1, 22
.equiv TEMP2, 23

; Aliases for PINs connected to the 7 segment display. These are the
; values written in PORTD. DIGITAL PINs 0-6 are connected to PINs a-g
; of the 7 segment display.

; TO BE IMPLEMENTED


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

    ; Description:
    ; -----------
    ;
    ;  To represent a digit we will use a 4 bit number looking like this DCBA
    ;  (A is the LSB and D is the MSB). The equations for the 7 segment display
    ;  PINs are the following, they can be easily computed using Karnaugh 
    ;  Diagrams:
    ;  
    ;  a = A + C + BD + !B!D
    ;  b = !B + !C!D + CD
    ;  c = B + !C + D
    ;  d = !B!D + C!D + B!CD + !BC + A
    ;  e = !b!d + C!D
    ;  f = A + !C!D + B!C + B!D
    ;  g = A + B!C + !BC + C!D
    ;
    ;  Each PIN equation will be computed in r21 and sent to its corresponding 
    ;  PIN. Other registers will be used to extract the bits from the binary
    ;  number and to perform logic operations.

    mov ABIT, r24
    andi ABIT, 0x01

    mov BBIT, r24
    asr BBIT
    andi BBIT, 0x01

    mov CBIT, r24
    asr CBIT
    asr CBIT
    andi CBIT, 0x01

    mov DBIT, r24
    asr DBIT
    asr DBIT
    asr DBIT

    ; Compute a. Steps:
    ;
    ; 1. Move A in RESULT and perform OR with C
    ; 2. Move B in TEMP1 and perform AND with B
    ; 3. Perform OR between (A + C) and BD
    ; 4. Move B in TEMP1, perform or with D and negate the result (!B!D = !(B + D))
    ;    (to negate all the bits we will use exclusive or between the register
    ;     and the value 0xFF)
    ; 5. Perform OR between (A + C + BD) and !B!D

    mov RESULT, ABIT

    or RESULT, CBIT

    mov TEMP1, BBIT 
    and TEMP1, DBIT
    or RESULT, TEMP1

    mov TEMP1, BBIT
    or TEMP1, DBIT
    ldi TEMP2, 0xFF
    eor TEMP1, TEMP2
    andi TEMP1, 0x01
    and RESULT, TEMP1

    ret

WAIT:

    ret
