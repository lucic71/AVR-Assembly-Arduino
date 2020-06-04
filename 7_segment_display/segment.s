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
    call WAIT
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
    ;  e = !B!D + C!D
    ;  f = A + !C!D + B!C + B!D
    ;  g = A + B!C + !BC + C!D
    ;
    ;  Each PIN equation will be computed in RESULT and sent to its corresponding 
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

    ; TEMP2 will be used for eor'ing with register TEMP1 or RESULT
    ; It is equivalent with flipping the bit in TEMP1 or RESULT.

    ldi TEMP2, 0x01

    ; Compute a. Steps:
    ;
    ; 1. Move A in RESULT
    ; 2. Perform RESULT = RESULT + C
    ; 3. Compute DB using TEMP1 and perform RESULT = RESULT + BD
    ; 4. Compute !D!B = !(D + B) using TEMP1 and TEMP2 and perform 
    ;       RESULT = RESULT + !B!D.
    ; 5. Write RESULT to DIGITAL PIN 0

    mov RESULT, ABIT

    or RESULT, CBIT

    mov TEMP1, BBIT 
    and TEMP1, DBIT
    or RESULT, TEMP1

    mov TEMP1, BBIT
    or TEMP1, DBIT
    eor TEMP1, TEMP2
    and RESULT, TEMP1

    out PORTD, RESULT
    call WAIT

    ; Compute b. Steps:
    ;
    ; 1. Move B in RESULT and invert the bits.
    ; 2. Compute !C!D using TEMP1 and TEMP2 and perform RESULT = RESULT + !C!D
    ; 3. Compute CD using TEMP1 and perform RESULT = RESULT + CD
    ; 4. Write RESULT to DIGITAL PIN 1

    mov RESULT, BBIT
    eor RESULT, TEMP2

    mov TEMP1, CBIT
    or TEMP1, DBIT
    eor TEMP1, TEMP2
    or RESULT, TEMP1

    mov TEMP1, CBIT
    and TEMP1, DBIT
    or RESULT, TEMP1

    clc
    rol RESULT

    out PORTD, RESULT
    call WAIT

    ; Compute c. Steps:
    ;
    ; 1. Move B in RESULT
    ; 2. Perform RESULT = RESULT + !C
    ; 3. Perform RESULT = RESULT + D
    ; 4. Write RESULT to DIGITAL PIN 2

    mov RESULT, BBIT

    mov TEMP1, CBIT
    eor TEMP1, TEMP2
    or RESULT, TEMP1

    or RESULT, DBIT

    clc
    rol RESULT

    clc
    rol RESULT

    out PORTD, RESULT
    call WAIT

    ; Compute d. Steps:
    ;
    ; 1. Move A int RESULT
    ; 2. Perform RESULT = RESULT + !B!D
    ; 3. Perform RESULT = RESULT + C!D
    ; 4. Perform RESULT = RESULT + B!CD
    ; 5. Perform RESULT = RESULT + !BC
    ; 6. Write RESULT to DIGITAL PIN 3

    mov RESULT, ABIT

    mov TEMP1, BBIT
    or TEMP1, DBIT
    eor TEMP1, TEMP2
    or RESULT, TEMP1

    mov TEMP1, DBIT
    eor TEMP1, TEMP2
    or TEMP1, CBIT
    or RESULT, TEMP1

    mov TEMP1, CBIT
    eor TEMP1, TEMP2
    and TEMP1, BBIT
    and TEMP1, DBIT
    or RESULT, TEMP1

    mov TEMP1, BBIT
    eor TEMP1, TEMP2
    and TEMP1, CBIT
    or RESULT, TEMP1

    clc
    rol RESULT

    clc
    rol RESULT

    clc
    rol RESULT

    out PORTD, RESULT
    call WAIT

    ; Compute e. Steps:
    ;
    ; 1. Compute RESULT = C!D
    ; 2. Compute RESULT = RESULT + !B!D
    ; 3. Write RESULT to DIGITAL PIN 4

    mov RESULT, DBIT
    eor RESULT, TEMP2
    and RESULT, CBIT

    mov TEMP1, BBIT
    or TEMP1, DBIT
    eor TEMP1, TEMP2
    or RESULT, TEMP1

    clc
    rol RESULT

    clc
    rol RESULT

    clc
    rol RESULT

    clc
    rol RESULT

    out PORTD, RESULT
    call WAIT

    ; Compute f. Steps:
    ;
    ; 1. Compute RESULT = A
    ; 2. Compute RESULT = RESULT + !C!D
    ; 3. Compute RESULT = RESULT + B!C
    ; 4. Compute RESULT = RESULT + B!D
    ; 5. Write RESULT to DIGITAL PIN 5

    mov RESULT, ABIT

    mov TEMP1, CBIT
    or TEMP1, DBIT
    eor TEMP1, TEMP2
    or RESULT, TEMP1

    mov TEMP1, CBIT
    eor TEMP1, TEMP2
    and TEMP1, BBIT
    or RESULT, TEMP1

    mov TEMP1, DBIT
    eor TEMP1, TEMP2
    and TEMP1, BBIT
    or RESULT, TEMP1

    clc
    rol RESULT

    clc
    rol RESULT

    clc
    rol RESULT

    clc
    rol RESULT

    clc
    rol RESULT

    out PORTD, RESULT
    call WAIT

    ; Compute g. Steps:
    ;
    ; 1. Compute RESULT = B!C
    ; 2. Compute RESULT = RESULT + !BC
    ; 3. Compute RESULT = RESULT + C!D
    ; 4. Compute RESULT = RESULT + A
    ; 5. Write RESULT to DIGITAL PIN 6

    mov RESULT, CBIT
    eor RESULT, TEMP2
    and RESULT, BBIT

    mov TEMP1, BBIT
    eor TEMP1, TEMP2
    and TEMP1, CBIT
    or RESULT, TEMP1

    mov TEMP1, DBIT
    eor TEMP1, TEMP2
    and TEMP1, CBIT
    or RESULT, TEMP1

    or RESULT, ABIT

    clc
    rol RESULT

    clc
    rol RESULT

    clc
    rol RESULT

    clc
    rol RESULT

    clc
    rol RESULT

    clc
    rol RESULT

    out PORTD, RESULT
    call WAIT

    ret

WAIT:

    ; Description
    ; -----------
    ;
    ;  Loop 0x400000 times which takes approximately 12 milion cycles which is
    ;  approximately 0.7s.

    ldi r17, 0x10
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
