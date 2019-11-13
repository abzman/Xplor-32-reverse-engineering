;           File Name: LIBRARYD.A51                 Date: 11/03/94

; /*      COPYRIGHT (C) 1994-95, BLUE EARTH RESEARCH, MANKATO, MN, USA       */
; /*                        ALL RIGHTS RESERVED.                             */
; /*       COMMERCIAL USE OF THIS PROGRAM ONLY BY WRITTEN PERMISSION         */

$Width 122
$Length 59

; ----------------------------- INTRODUCTION ----------------------------------

; ------------------ LCD MODULE SOFTWARE DRIVER ROUTINE -----------------------

; This routine can be used to replace the LCD and keypad software driver
; when using the Xplor-32d. Since the Xplor-32d has additional I/O lines,
; there are more I/O lines available for interfacing to additional devices.

; Note that this routine functions similar to the LCD and keypad software
; written for the Xplor-32. However, the keypad rows and columns are
; transposed, and pull-up resistors are required on the keypad inputs PC4-PC7.

; -------------------------- LIBRARY EQUATE TABLE -----------------------------

; Variable Equates

DIFF    EQU     1               ; DATA BIT      Different key pressed ?
LINES   EQU     2               ; DATA BIT      1=4x4 Keypad, 0=2x4.
W4Key   EQU     3               ; DATA BIT      Set to wait until key pressed
USRBIT  EQU     126             ; DATA BIT      User output bit
KEYS    EQU     27              ; DATA BYTE     Where to store.
LFNO    EQU     28              ; DATA BYTE     Line feed count
CHAR    EQU     29              ; DATA BYTE     Character to be written
REG_SEL EQU     33              ; DATA BYTE     Hold Register Select bit

; I/O Line Equates

ROW1    EQU     ACC.4           ; I/O LINE      Keypad Row 1
ROW2    EQU     ACC.5           ; I/O LINE      Keypad Row 2
ROW3    EQU     ACC.6           ; I/O LINE      Keypad Row 3
ROW4    EQU     ACC.7           ; I/O LINE      Keypad Row 4

; Miscellaneous Equates

COLS    EQU     0F0H            ; Keypad column lines are in upper nibble.
ROWS    EQU     COLS            ; Keypad rows are too.

; Initialize the 82C55 Control Word as follows:
;       PORT A = OUTPUT         PORT C(0-3) = OUTPUT
;       PORT B = OUTPUT         PORT C(4-7) = INPUT
;    Note: For more information, see Page 3-107 in Intel Data
;    Book #296467-002, "1991 Peripheral Components"

ControlWord     EQU     10001000B       ; SELECT MODE 0

PORT_A          EQU     2000H           ; NEITHER A0 NOR A1
PORT_B          EQU     2100H           ; SET A0 ONLY
PORT_C          EQU     2200H           ; SET A1 ONLY
CONTROL         EQU     2300H           ; SET BOTH A0 & A1

RS              EQU     8               ; LCD Control signals
Eclk            EQU     ACC.1

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

; INITIALIZE 82C55 PORTS

Init:   MOV     DPTR,#CONTROL     ; Point to 82C55A Control Reg
        MOV     A,#ControlWord    ; All outputs (Except PC4-7)
        MOVX    @DPTR,A

        SETB    USRBIT          ; Set user output bit
        MOV     REG_SEL,#0      ; OUTPUT TO COMMAND REGISTER
        MOV     A,#30H          ; Function Set (default 8-bit interface)
        ACALL   Clock_N_Wait    ; Clock and wait >120uS
        ACALL   WAIT5mS         ; Need to wait >5 mS the 1st time

        MOV     A,#30H          ; Function Set Again (default 8-bit interface)
        ACALL   Clock_N_Wait    ; (Actually 03H)

        MOV     A,#30H          ; Function Set Again (default 8-bit interface)
        ACALL   Clock_N_Wait

        MOV     A,#20H          ; Function Set: Set 4-bit interface
        ACALL   Clock_N_Wait

        MOV     A,#28H          ; Function Set: Still 4-bit, now 2 lines
        ACALL   COMMAND

        MOV     A,#08H          ; Display Control: Display off,
        ACALL   COMMAND         ; Cursor off, Blink off

        ACALL   CLEAR           ; Clear Display (Code is #01H)

        MOV     A,#06H
        ACALL   COMMAND         ; Entry mode: Increment (+1)

        MOV     A,#0CH
        AJMP    COMMAND         ; Display Control: Display on

; -------------------------------- LCD UPDATE ---------------------------------

; The code below executes every time BASIC encounters a "PRINT"
; statement if the User Output bit is set.

OUTUSR: PUSH    ACC             ; Save status of Accumulator (ACC)
        PUSH    PSW             ;  and Program Status Word (PSW)

        ACALL   CHOUT           ; Write character in ACC to LCD.

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

COMMAND:CLR     RS              ; Set LCD to receive instruction
        SJMP    OUTPUT

DODATA: SETB    RS              ; Set LCD to receive data


; SEND AN 8-BIT CHARACTER (OR COMMAND) TO THE LCD.

OUTPUT: MOV     B,A             ; SAVE IT

; ------------------ OUTPUT CHARACTER HALF --------------------

        ANL     A,#0F0H         ; GET RID OF LOWER HALF
        ORL     A,REG_SEL       ; SELECT COMMAND OR DATA
        ACALL   TOGGLE
        MOV     A,B             ; GET OUTPUT BYTE AGAIN

; ------------------- OUTPUT SECOND HALF ----------------------

        SWAP    A               ; NOW DO LOWER HALF
        ANL     A,#0F0H
        ORL     A,REG_SEL       ; SELECT COMMAND OR DATA

CLOCK_N_WAIT:
        ACALL   TOGGLE

WAIT:   MOV     B,#60           ; Wait at least 120 uS
        DJNZ    B,$             ; (130uS at 11.0592 Mhz)

NoChar: RET                     ; Go Back


; ---------- SUBROUTINE FOR TOGGLING THE E SIGNAL -------------

TOGGLE: MOV     DPTR,#PORT_A    ; POINT TO DATA LINES
        PUSH    IE
        CLR     EA              ; No Interrupts now
        MOVX    @DPTR,A         ; OUTPUT COMMAND OR DATA
        SETB    Eclk
        MOVX    @DPTR,A         ; CLOCK IT IN
        CLR     Eclk
        MOVX    @DPTR,A
        POP     IE              ; Interrupts OK now
        RET

; ------------------------------- READ KEYPAD ---------------------------------

KEYPAD:

ROW_1:  MOV     A,#ROWS
        CLR     ROW1            ; Enable Row 1
        ACALL   GetRow
        MOV     B,#1            ; Offset value to B register
        JNZ     ISKEY           ; Find one pressed ?

ROW_2:  MOV     A,#ROWS
        CLR     ROW2            ; Do Row 2
        ACALL   GetRow
        MOV     B,#5
        JNZ     ISKEY
        JNB     LINES,CLRDIF    ; Just 2x4 keypad ?

ROW_3:  MOV     A,#ROWS
        CLR     ROW3            ; Do Row 3
        ACALL   GetRow
        MOV     B,#9
        JNZ     ISKEY

ROW_4:  MOV     A,#ROWS
        CLR     ROW4            ; Do Row 4
        ACALL   GetRow
        MOV     B,#13
        JNZ     ISKEY

CLRDIF: CLR     DIFF
        MOV     B,#0            ; Nothing pressed
        SJMP    STORE

ISKEY:  JB      ACC.4,OKSTOR    ; Col 1 ?
        INC     B
        JB      ACC.5,OKSTOR    ; Col 2 ?
        INC     B
        JB      ACC.6,OKSTOR    ; Col 3 ?
        INC     B               ; Must be Col 4 !

OKSTOR: MOV     A,KEYS
        SETB    DIFF
        CJNE    A,B,STORE       ; Different ?
        CLR     DIFF            ; No !

STORE:  MOV     KEYS,B          ; Stuff here ?

        JNB     W4Key,KeyEnd    ; Sample once or wait until a key is pressed?
        JNB     DIFF,KEYPAD
KeyEnd: RET                     ; Only one exit point !

GetRow: MOV     DPTR,#PORT_A    ; POINT TO KEYPAD ROWS
        MOVX    @DPTR,A         ; CLEAR ONE BIT
        MOV     DPTR,#PORT_C    ; POINT TO KEYPAD COLUMNS
        MOVX    A,@DPTR         ; READ COLUMNS
        ORL     A,#0FH          ; MASK OFF UNUSED BITS
        CPL     A
        RET

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

