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

; Aliases for registers. ABIT, BBIT, CBIT, DBIT contain the bits in the binary
; representation of numbers displayed on the 7 segment display. A is the MSB
; and D is the LSB. RESULT, TEMP1 and EOREG are registers used when computing
; the boolean functions for each PIN. PINCONFIG is the register that decides
; which PINs are set when sending voltage to the 7 segment display.

.equiv ABIT, 17
.equiv BBIT, 18
.equiv CBIT, 19
.equiv DBIT, 20

.equiv RESULT, 21
.equiv TEMP1, 22
.equiv EOREG, 23

.equiv PINCONFIG, 30

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

    ; Reset PINCONFIG and RESULT registers.

    clr PINCONFIG
    clr RESULT

    ; Output a blank screen to put some delay between digits, it looks smoother
    ; this way.

    out PORTD, PINCONFIG
    call WAIT

    ; Description:
    ; -----------
    ;
    ;  To represent a digit we will use a 4 bit number looking like this ABCD
    ;  (A is the MSB and D is the LSB). The equations for the 7 segment display
    ;  PINs are the following, they can be easily computed using Karnaugh 
    ;  Diagrams:
    ;  
    ;  a = A + C + BD + !B!D
    ;  b = !B + !C!D + CD
    ;  c = B + !C + D
    ;  d = !B!D + C!D + B!CD + !BC + A
    ;  e = !B!D + C!D
    ;  f = A + !C!D + B!C + B!D
    ;  g = A + B!C + !BC + C!D
    ;
    ;  Each PIN equation will be computed in RESULT and sent to its corresponding 
    ;  PIN. Other registers will be used to extract the bits from the binary
    ;  number and to perform logic operations.

    mov DBIT, r24
    andi DBIT, 0x01

    mov CBIT, r24
    asr CBIT
    andi CBIT, 0x01

    mov BBIT, r24
    asr BBIT
    asr BBIT
    andi BBIT, 0x01

    mov ABIT, r24
    asr ABIT
    asr ABIT
    asr ABIT

    ; After shifting each bit in its corresponding register, clear carry flag
    ; because we will perform multiple ROL's and don't want any additional
    ; bit coming from Carry in RESULT.

    clc

    ; EOREG will be used for eor'ing with register TEMP1 or RESULT
    ; It is equivalent with flipping the bit in TEMP1 or RESULT.

    ldi EOREG, 0x01

    ; Compute a. Steps:
    ;
    ; 1. Move A in RESULT
    ; 2. Perform RESULT = RESULT + C
    ; 3. Compute DB using TEMP1 and perform RESULT = RESULT + BD
    ; 4. Compute !D!B = !(D + B) using TEMP1 and EOREG and perform 
    ;       RESULT = RESULT + !B!D.
    ; 5. Write RESULT to DIGITAL PIN 0

COMPUTEA:

    mov RESULT, ABIT

    or RESULT, CBIT

    mov TEMP1, BBIT 
    and TEMP1, DBIT
    or RESULT, TEMP1

    mov TEMP1, BBIT
    or TEMP1, DBIT
    eor TEMP1, EOREG
    or RESULT, TEMP1

    or PINCONFIG, RESULT

    ; Compute b. Steps:
    ;
    ; 1. Move B in RESULT and invert the bits.
    ; 2. Compute !C!D using TEMP1 and EOREG and perform RESULT = RESULT + !C!D
    ; 3. Compute CD using TEMP1 and perform RESULT = RESULT + CD
    ; 4. Write RESULT to DIGITAL PIN 1

COMPUTEB:

    mov RESULT, BBIT
    eor RESULT, EOREG

    mov TEMP1, CBIT
    or TEMP1, DBIT
    eor TEMP1, EOREG
    or RESULT, TEMP1

    mov TEMP1, CBIT
    and TEMP1, DBIT
    or RESULT, TEMP1

    rol RESULT

    or PINCONFIG, RESULT

    ; Compute c. Steps:
    ;
    ; 1. Move B in RESULT
    ; 2. Perform RESULT = RESULT + !C
    ; 3. Perform RESULT = RESULT + D
    ; 4. Write RESULT to DIGITAL PIN 2

COMPUTEC:

    mov RESULT, BBIT

    mov TEMP1, CBIT
    eor TEMP1, EOREG
    or RESULT, TEMP1

    or RESULT, DBIT

    rol RESULT
    rol RESULT

    or PINCONFIG, RESULT

    ; Compute d. Steps:
    ;
    ; 1. Move A int RESULT
    ; 2. Perform RESULT = RESULT + !B!D
    ; 3. Perform RESULT = RESULT + C!D
    ; 4. Perform RESULT = RESULT + B!CD
    ; 5. Perform RESULT = RESULT + !BC
    ; 6. Write RESULT to DIGITAL PIN 3

COMPUTED:

    mov RESULT, ABIT

    mov TEMP1, BBIT
    or TEMP1, DBIT
    eor TEMP1, EOREG
    or RESULT, TEMP1

    mov TEMP1, DBIT
    eor TEMP1, EOREG
    and TEMP1, CBIT
    or RESULT, TEMP1

    mov TEMP1, CBIT
    eor TEMP1, EOREG
    and TEMP1, BBIT
    and TEMP1, DBIT
    or RESULT, TEMP1

    mov TEMP1, BBIT
    eor TEMP1, EOREG
    and TEMP1, CBIT
    or RESULT, TEMP1

    rol RESULT
    rol RESULT
    rol RESULT

    or PINCONFIG, RESULT

    ; Compute e. Steps:
    ;
    ; 1. Compute RESULT = C!D
    ; 2. Compute RESULT = RESULT + !B!D
    ; 3. Write RESULT to DIGITAL PIN 4

COMPUTEE:

    mov RESULT, DBIT
    eor RESULT, EOREG
    and RESULT, CBIT

    mov TEMP1, BBIT
    or TEMP1, DBIT
    eor TEMP1, EOREG
    or RESULT, TEMP1

    rol RESULT
    rol RESULT
    rol RESULT
    rol RESULT

    or PINCONFIG, RESULT

    ; Compute f. Steps:
    ;
    ; 1. Compute RESULT = A
    ; 2. Compute RESULT = RESULT + !C!D
    ; 3. Compute RESULT = RESULT + B!C
    ; 4. Compute RESULT = RESULT + B!D
    ; 5. Write RESULT to DIGITAL PIN 5

COMPUTEF:

    mov RESULT, ABIT

    mov TEMP1, CBIT
    or TEMP1, DBIT
    eor TEMP1, EOREG
    or RESULT, TEMP1

    mov TEMP1, CBIT
    eor TEMP1, EOREG
    and TEMP1, BBIT
    or RESULT, TEMP1

    mov TEMP1, DBIT
    eor TEMP1, EOREG
    and TEMP1, BBIT
    or RESULT, TEMP1

    rol RESULT
    rol RESULT
    rol RESULT
    rol RESULT
    rol RESULT

    or PINCONFIG, RESULT

    ; Compute g. Steps:
    ;
    ; 1. Compute RESULT = B!C
    ; 2. Compute RESULT = RESULT + !BC
    ; 3. Compute RESULT = RESULT + C!D
    ; 4. Compute RESULT = RESULT + A
    ; 5. Write RESULT to DIGITAL PIN 6

COMPUTEG:

    mov RESULT, CBIT
    eor RESULT, EOREG
    and RESULT, BBIT

    mov TEMP1, BBIT
    eor TEMP1, EOREG
    and TEMP1, CBIT
    or RESULT, TEMP1

    mov TEMP1, DBIT
    eor TEMP1, EOREG
    and TEMP1, CBIT
    or RESULT, TEMP1

    or RESULT, ABIT

    rol RESULT
    rol RESULT
    rol RESULT
    rol RESULT
    rol RESULT
    rol RESULT

    or PINCONFIG, RESULT

WRITE_RESULT:

    out PORTD, PINCONFIG

    ret

WAIT:

    ; Description
    ; -----------
    ;
    ; Loop 0x{r17, r18, r19} times (for example 0x300000) times because the
    ; internal clock of the board is to fast and the digits cannot be seen.
    ; We know that 0x400000 iterations take approximately 0.7s so we can make
    ; further calcualtions based on this (or by looking in the instruction set
    ; at the clock cycles taken by each instruction used in the loop).

    ldi r17, 0x30
    ldi r18, 0x00
    ldi r19, 0x00

_WAIT:

    dec r19
    brne _WAIT

    dec r18
    brne _WAIT

    dec r17
    brne _WAIT

    ret
