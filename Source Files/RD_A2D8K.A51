$TITLE "TINY BASIC Rd_A2D8k"
$XREF
$LENGTH 59

;    /* (c) Copyright BLUE EARTH RESEARCH, MANKATO, MN 1994. */
;    /*                All rights reserved.                  */

;                               BASIC PROGRAM EXAMPLE:
; 20 INPUT 'CHANNEL NUMBER ',C
; 30 IF C<12 THEN GOTO 50
; 40 END
; 50 D.41 = C : CALL 24400
; 60 R=(D.42)+(256*(D.43)) : P. R
; 70 GOTO 20
  
DO      EQU     P2.6            ; ------------------ EQUATES ------------------
DI      EQU     P1.7
CLK     EQU     P1.6

ADC_CH  EQU     29H             ; Analog Channel
A_DATA  EQU     2AH             ; Analog Data

; Note: The A/D software must be located at 1F50H in order to load it to the
; Xplor-32a's EEPROM. However, since the internal CPU ROM is accessed below
; 3FFFH, it must be CALLed at 5F50H (24400). The "LCALL addr+0C000H" is
; necessary because the ADC's chip select is wired to the A15 signal. The
; intermediate CALL to 5F50H is required so that PSEN (the ADC's SYS Clock)
; is running prior to the Chip Select being asserted.

        ORG     1F50H

        CLR     CLK             ; I/O Clock should be low at start

        LCALL   Rd_A2D+0C000H   ; 1st time retrieves old data.
        MOV     R6,#22
        DJNZ    R6,$            ; Wait 44 PSENs for conversion.
        LCALL   Rd_A2D+0C000H   ; 2nd time retrieves current data.

        SETB    CLK
        RET                     ; Back to BASIC

; --------------------------- READ A/D CONVERTER ------------------------------

; Need to call twice before current data is available.

Rd_A2D: PUSH    IE              ; Save interrupt enables (TMB v10a 6/6/94) ;*
        CLR     EA              ; Disable all interrupts for now           ;*

        MOV     P2,#0FFH        ; This may cause other problems

        MOV     C,DO            ; D9 out
        MOV     (A_DATA+1).1,C  ; Store D9

        MOV     C,ADC_CH.3
        ACALL   CLK_2           ; Clock in A3 (to 1541) & out D8 (from 1541)
        MOV     (A_DATA+1).0,C  ; Store D8

        MOV     C,ADC_CH.2
        ACALL   CLK_2           ; Clock in A2, Clock out D7
        MOV     A_DATA.7,C      ; Store D7

        MOV     C,ADC_CH.1
        ACALL   CLK_2           ; Clock in A1, Clock out D6
        MOV     A_DATA.6,C      ; Store D6

        MOV     C,ADC_CH.0
        ACALL   CLK_2           ; Clock in A0, Clock out D5
        MOV     A_DATA.5,C      ; Store D5

        ACALL   CLK_ADC         ; Clock out D4
        MOV     A_DATA.4,C      ; Store D4

        ACALL   CLK_ADC         ; Clock out D3
        MOV     A_DATA.3,C      ; Store D3

        ACALL   CLK_ADC         ; Clock out D2
        MOV     A_DATA.2,C      ; Store D2

        ACALL   CLK_ADC         ; Clock out D1
        MOV     A_DATA.1,C      ; Store D1

        ACALL   CLK_ADC         ; Clock out D0
        MOV     A_DATA.0,C      ; Store D0

        SETB    CLK             ; 10th Clock pulse
        CLR     CLK             ; Initiate hold function
        SETB    DI

        ANL     A_DATA+1,#3     ; Strip garbage bits
        POP     IE              ; Restore Interrupt status (TMB v10a 6/6/94) ;*
        RET

CLK_2:  MOV     DI,C
CLK_ADC:SETB    CLK             ; Clock the bits to/from the ADC
        CLR     CLK
        MOV     C,DO
        RET

        END
