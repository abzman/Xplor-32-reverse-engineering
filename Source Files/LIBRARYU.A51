;           File Name: LIBRARYU.A51                 Date: 07/11/95

; /*      COPYRIGHT (C) 1994-95, BLUE EARTH RESEARCH, MANKATO, MN, USA       */
; /*                        ALL RIGHTS RESERVED.                             */
; /*       COMMERCIAL USE OF THIS PROGRAM ONLY BY WRITTEN PERMISSION         */

$Width 122
$Length 59

; ----------------------------- INTRODUCTION ----------------------------------

; ------------------ LCD MODULE SOFTWARE DRIVER ROUTINE -----------------------

; This routine can be used to replace the LCD and keypad software drivers
; when using the Xplor-32u, Xplor-32ua, and Xplor-32s. Since these
; controllers have additional I/O lines, there are more I/O lines available
; for interfacing to additional devices.

; Note that this routine functions similar to the LCD and keypad software
; written for the Xplor-32 and Xplor-32d.

; -------------------------- LIBRARY EQUATE TABLE -----------------------------

; Variable Equates

DIFF    EQU     1               ; DATA BIT      Different key pressed ?
LINES   EQU     2               ; DATA BIT      1=4x4 Keypad, 0=2x4.
W4Key   EQU     3               ; DATA BIT      Set to wait until key pressed
USRBIT  EQU     126             ; DATA BIT      User output bit
KEYS    EQU     27              ; DATA BYTE     Where to store.
LFNO    EQU     28              ; DATA BYTE     Line feed count
CHAR    EQU     29              ; DATA BYTE     Character to be written

; I/O Line Equates

ROW1    EQU     62FFH           ; I/O LINE ADDRESS      Keypad Row 1
ROW2    EQU     64FFH           ; I/O LINE ADDRESS      Keypad Row 2
ROW3    EQU     68FFH           ; I/O LINE ADDRESS      Keypad Row 3
ROW4    EQU     70FFH           ; I/O LINE ADDRESS      Keypad Row 4

; Miscellaneous Equates

LCD_CMD         EQU     7EFFH   ; A8 determines LCD Command or Data
LCD_DATA        EQU     7FFFH   

; ------ THE ORG STATEMENT SPECIFIES WHERE YOUR HEX CODE WILL BE LOCATED ------

        ORG     7680            ; Program starts at this address


; ----------------------------- CLEAR DISPLAY ---------------------------------

; Moved this code here to place the "HERE" label in a common location for all
; of the various LCD Drivers.

CLEAR:  MOV     A,#1            ; Clear display
        ACALL   COMMAND

WAIT5mS:MOV     A,#10           ; Wait >5mS
HERE:   MOV     B,#0FFH         ; (5.5mS at 11.0592 Mhz)
        DJNZ    B,$
        DJNZ    ACC,HERE
        RET

; ------------------ INITIALIZE LCD MODULE (PER DATA SHEET) -------------------

; The code below performs a software initialization of the LCD module. For more
; information on this subject, consult an LCD data sheet.

Init:   MOV     DPTR,#LCD_CMD   ; OUTPUT TO COMMAND REGISTER
        SETB    USRBIT          ; Set user output bit
        MOV     A,#30H          ; Function Set (default 8-bit interface)
        ACALL   Output          ; Clock and wait >120uS
        ACALL   WAIT5mS         ; Need to wait >5 mS the 1st time

        MOV     A,#30H          ; Function Set Again (default 8-bit interface)
        ACALL   Output          ; (Actually 03H)

        MOV     A,#30H          ; Function Set Again (default 8-bit interface)
        ACALL   Output

        MOV     A,#38H          ; Function Set: Set 8-bit interface, 2 lines
        ACALL   Output

        MOV     A,#08H          ; Display Control: Display off,
        ACALL   Output          ; Cursor off, Blink off

        ACALL   CLEAR           ; Clear Display (Code is #01H)

        MOV     A,#06H
        ACALL   Output          ; Entry mode: Increment (+1)

        MOV     A,#0CH
        AJMP    Output          ; Display Control: Display on

; -------------------------------- LCD UPDATE ---------------------------------

; The code below executes every time BASIC encounters a "PRINT"
; statement if the User Output bit is set.

OUTUSR: PUSH    ACC             ; Save status of Accumulator (ACC)
        PUSH    PSW             ;  and Program Status Word (PSW)
        PUSH    DPL             ;  and DPTR
        PUSH    DPH

        ACALL   CHOUT           ; Write character in ACC to LCD.

        POP     DPH
        POP     DPL
        POP     PSW             ; Restore ACC & PSW before returning
        POP     ACC             ;  to BASIC interpreter.
        RET

; ------------------ CHECK FOR SPECIAL LINE FEED CHARACTER --------------------

; Optional entry point to "CALL" which writes a single character to LCD.

ONE_WR: MOV     A,CHAR          ; Get character to write to LCD.

CHOUT:  CJNE    A,#5CH,NO_LF    ; Is it a "\", our linefeed character ?
        INC     LFNO            ; Yes, so increment the count.
        MOV     A,LFNO

        CJNE    A,#4,$+3        ; Check if the count is out of range.
        JNC     NoChar

        CJNE    A,#1,CHK2       ; If LFNO=1, move cursor to 2nd line
        MOV     A,#0C0H         ; Assumes HD44780 type LCD controller

CHK2:   CJNE    A,#2,CHK3       ; If LFNO=2, move cursor to 3rd line
        MOV     A,#94H          ; Value for 4x20 display

CHK3:   CJNE    A,#3,COMMAND    ; If LFNO=3, move cursor to 4th line
        MOV     A,#0D4H         ; Value for 4x20 display
        SJMP    COMMAND

; ------------------- CHECK FOR NON-PRINTABLE CHARACTERS ----------------------

NO_LF:  MOV     LFNO,#0         ; Get ready to count "\"s again.
        JBC     ACC.7,COMMAND   ; Above 128 are LCD instructions

        CJNE    A,#32,$+3       ; Printable character ?
        JNC     DODATA

        CJNE    A,#8,FF_Chk     ; Backspace character ?
        MOV     A,#04H
        ACALL   COMMAND         ; Entry mode: Decrement (-1)

        MOV     A,#32           ; Print a " "
        ACALL   DODATA

        MOV     A,#06H
        SJMP    COMMAND         ; Entry mode: Increment (+1)

FF_Chk: CJNE    A,#12,CR_Chk    ; Form Feed ?
        AJMP    CLEAR           ; Clear LCD, Home cursor

CR_Chk: CJNE    A,#13,NoChar    ; Carriage return ?
HOME:   MOV     A,#2            ; Home cursor (DD RAM = 0)


; ------------- SUBROUTINE TO SEND A CHARACTER OR COMMAND TO LCD --------------

COMMAND:MOV     DPTR,#LCD_CMD   ; Set LCD to receive instruction
        SJMP    OUTPUT

DODATA: MOV     DPTR,#LCD_DATA  ; Set LCD to receive data


; SEND AN 8-BIT CHARACTER (OR COMMAND) TO THE LCD.

; ------------------ OUTPUT CHARACTER -------------------------

Output: PUSH    IE
        CLR     EA              ; No Interrupts now
        MOVX    @DPTR,A         ; OUTPUT COMMAND OR DATA
        POP     IE              ; Interrupts OK now
        
WAIT:   MOV     B,#60           ; Wait at least 120 uS
        DJNZ    B,$             ; (130uS at 11.0592 Mhz)

NoChar: RET                     ; Go Back


; ------------------------------- READ KEYPAD ---------------------------------

KEYPAD:
ROW_1:  MOV     DPTR,#ROW1
        MOVX    A,@DPTR         ; READ COLUMNS
        CPL     A
        ANL     A,#0FH          ; MASK OFF UNUSED BITS
        MOV     B,#1            ; Offset value to B register
        JNZ     ISKEY           ; Find one pressed ?

ROW_2:  MOV     DPTR,#ROW2      ; Do Row 2
        MOVX    A,@DPTR         ; READ COLUMNS
        CPL     A
        ANL     A,#0FH          ; MASK OFF UNUSED BITS
        MOV     B,#2
        JNZ     ISKEY
        JNB     LINES,CLRDIF    ; Just 2x4 keypad ?

ROW_3:  MOV     DPTR,#ROW3      ; Do Row 3
        MOVX    A,@DPTR         ; READ COLUMNS
        CPL     A
        ANL     A,#0FH          ; MASK OFF UNUSED BITS
        MOV     B,#3
        JNZ     ISKEY

ROW_4:  MOV     DPTR,#ROW4      ; Do Row 4
        MOVX    A,@DPTR         ; READ COLUMNS
        CPL     A
        ANL     A,#0FH          ; MASK OFF UNUSED BITS
        MOV     B,#4
        JNZ     ISKEY

CLRDIF: CLR     DIFF
        MOV     B,#0            ; Nothing pressed
        SJMP    STORE

ISKEY:  JB      ACC.3,OKSTOR    ; Col 1 ?
        INC     B
        INC     B
        INC     B
        INC     B
        JB      ACC.2,OKSTOR    ; Col 2 ?
        INC     B
        INC     B
        INC     B
        INC     B
        JB      ACC.1,OKSTOR    ; Col 3 ?
        INC     B               ; Must be Col 4 !
        INC     B
        INC     B               
        INC     B               

OKSTOR: MOV     A,KEYS
        SETB    DIFF
        CJNE    A,B,STORE       ; Different ?
        CLR     DIFF            ; No !

STORE:  MOV     KEYS,B          ; Stuff here ?

        JNB     W4Key,KeyEnd    ; Sample once or wait until a key is pressed?
        JNB     DIFF,KEYPAD
KeyEnd: RET                     ; Only one exit point !

; --------------------------------- VECTORS -----------------------------------

        ORG     8132            ; AJMPs to library functions

        AJMP    INIT            ; 8132 Initialize LCD module
        AJMP    CLEAR           ; 8134 Clear LCD module
        AJMP    HOME            ; 8136 Home cursor
        AJMP    ONE_WR          ; 8138 Write single character to LCD
        AJMP    KEYPAD          ; 8140 Read keypad input

        ORG     8161            ; TB52 Vectors

USRIN:  DB      0,0,0
USROUT: LJMP    OUTUSR          ; User output routine

        END

