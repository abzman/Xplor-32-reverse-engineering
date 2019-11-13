;           File Name: LIBRARY.A51                  Date: 06/21/95

; /*      COPYRIGHT (C) 1994-95, BLUE EARTH RESEARCH, MANKATO, MN, USA       */
; /*                        ALL RIGHTS RESERVED.                             */
; /*       COMMERCIAL USE OF THIS PROGRAM ONLY BY WRITTEN PERMISSION         */

$Width 112
$Length 59

; ----------------------- LIBRARY TABLE OF CONTENTS ---------------------------

; **A**  Access the serial EEPROM (Xplor-32u and Xplor-32ua ONLY)
; **B**  Print the BASIC program line number
; **C**  Print a string of characters from memory
; **D**  Write to the lower half of the EEPROM
; **E**  Serial Input Buffer for interrupt driven serial communications
; **F**  LCD Module software driver
; **G**  Scan a 4x2 or 4x4 Keypad
; **H**  X-10 Transmit routine
; **I**  Find the end of the BASIC program in EEPROM

; ----------------------------- INTRODUCTION ----------------------------------

; The library functions below are all written in assembly language for speed
; and compactness. We have included an abundance of comments so that you should
; be able to review and modify the code to adapt all or part of it to specific
; applications. If you don't own an 8051 assembler, all Xplor starter packages
; include one that can generate hex code from this file. The hex file can be
; uploaded to the Xplor PDC using QCOMM, which is also included with the
; starter packages.

; To generate the hex file from the library source file using BXA51:
;  At the DOS prompt type "BXA51 LIBRARY.A51".

; To also generate a listing file for viewing:
;  At the DOS prompt type "BXA51 -L LIBRARY.A51".

; ------------------------------- NOTES ---------------------------------------

; Note: Depending on the instruction, "A" & "ACC" both refer to Accumulator.

; If you don't understand assembly language you can still probably make
; changes to equate table and get them to work.

; To print the list file created by the assembler from this source file, you
; will need a printer with 132 column printing capability.

; When making changes to the library routines, please use caution when 
; reassigning I/O Port bits. Future hardware and firmware revisions may not 
; be compatible with your specific software.

; **A** ------------------- ACCESS THE SERIAL EEPROM --------------------------

; Several routines are provided for accessing the serial EEPROM:
;  - Read the serial EEPROM data memory
;  - Read the serial EEPROM status register
;  - Write the serial EEPROM data memory
;  - Write the serial EEPROM status register

; The routine for setting the WEL (Write Enable Latch) bit is included in the
; data and status register write routines. The WEL bit must be set each time
; the serial EEPROM is written to. Writing to the serial EEPROM data memory
; will always reset the WEL bit. Writing to the status register will also
; reset the WEL bit unless the WPEN bit is set and the WP pin is low.

; Note: This routine requires the optional serial EEPROM device to be
; installed in the Xplor-32u or Xplor-32ua.

; The optional serial EEPROM should not be confused with the EEPROM that is
; included on all the Xplor Series controllers. The serial EEPROM can only be
; used to store data. It can not be used as program (code) memory.


; **B** ------------- PRINT THE BASIC PROGRAM LINE NUMBER ---------------------

; This routine was added to help increase the usefulness of the TB52 error
; reporting. TB52 will print a SORRY, WHAT, or HOW whenever it detects a
; run-time error. Finding the source of that error may be a difficult task if
; you have no idea what part of the program caused the error.

; This routine calls the BASIC line number printing subroutine to display the
; current BASIC program line number. If this is executed immediately after the
; BASIC program terminates as the result of an error, the most recently
; executed line number will be displayed.

; Limitations: Invalid data will be printed in several circumstances. All of
;    these occur when the error is a line number error. For example, if you
;    have a GOTO, GOSUB, or ONTIME statement that references a line number
;    that does not exist, the line number stored in memory will not be valid
;    (if it was, there would not be an error!)

; Note: This routine requires TB52 Version 1.1c or later. The TB52 line number
; and character string output routine addresses must be substituted when this 
; routine is used with previous versions of TB52.


; **C** ------------- PRINT A CHARACTER STRING FROM MEMORY --------------------

; This routine will output a string of characters to the TB52 character
; output routine. The character string is assumed to be located in EEPROM,
; and the beginning address must be loaded to the BASIC "C" variable. The
; characters will be printed until a double quote character (") is detected.

; Note: This routine requires TB52 Version 1.1a or later. The TB52 character
; output routine address must be substituted when this routine is used with
; previous versions of TB52.


; **D** -------------------- EEPROM WRITE LOW ROUTINE -------------------------

; This code can be called from BASIC to write data to the lower half (4K) of
; the EEPROM. Executing the "CALL 8142" statement from BASIC will write the
; data stored in the BASIC "B" variable to the address stored in the BASIC "A"
; variable.

; Note: It will only write to addresses 0-0FFFH (0-4095).

; BASIC EXAMPLE:
; To write the value 244 to EEPROM address 4070 (0FE6H):
; 10  A=4070 : B=244 : CALL 8142

; **E** --------------- 8051 SERIAL INPUT BUFFER ROUTINE ----------------------

; This program implements a 20 byte circular buffer for receiving serial
; characters via the '51's on-chip UART. The equate table can be changed to
; resize the buffer to any user desired length.

; The sample BASIC program "SBUF.BAS" shows how to use this program in
; combination with TB52.

; NOTE: Whenever BASIC writes a character to the on-chip UART, it first tests
; the UART's TI bit to determine if the 1 byte transmit buffer is empty or not.
; If the TI bit is "1", indicating the buffer is now empty, BASIC will then
; clear it and load another character into the buffer. Otherwise, it waits
; until it is a "1". Therefore, if another program should clear the TI bit,
; BASIC will go into a wait forever mode when attempting to write to the serial
; port.

; However, for this serial buffer routine to function properly, the TI bit
; must be cleared or the CPU will continuously service the serial interrupt.
; This will make any other program run very slowly since the CPU will only be
; able to execute one instruction between serial interrupts. This program
; therefore clears the TI bit as part the initialization process. To prevent
; BASIC from hanging up, "SBUF" must be loaded with a character by an assembly
; language routine before any BASIC output routine is used. (TI can only be
; set by the UART and this is the only way to do it.)

; Whenever BASIC is used to output serial characters using the "PRINT"
; statement, the "CALL 8148" Statement must be executed prior to the BASIC
; PRINT Statement, and the "CALL 8150" Statement must be executed immediately
; after it to prevent slow program operation.

; The serial interrupt should also be disabled when BASIC is expected to
; receive serial characters instead of the serial interrupt routine. This
; should be done before executing an INPUT statement or returning to the
; command mode. The serial interrupt is disabled by the "BIT 172=0" statement.
; If characters will be printed from BASIC after the interrupt is disabled,
; the "CALL 8148" statement should also be executed.

; IMPORTANT NOTE: This BASIC program does not check for a Ctrl-C (ASCII 3) or
; any other control character. It will therefore be difficult to stop the
; program once it is entered. You may want to either check for a Ctrl-C and
; then end, or put a delay loop at the beginning of the program to allow a
; Ctrl-C to be received before initializing the serial buffer interrupt.

; For each serial character received, the Buffer "Head" address pointer is
; bumped and the received character stored into that location. Reading the
; buffer is accomplished by bumping the Buffer "Tail" address pointer and then
; reading that location into "Char" so BASIC can get it using a simple DBY
; instruction. If the Head & Tail pointers are equal, then the Buffer is
; considered empty. Trying to read an empty Buffer will produce a NULL code
; (0) in Char and will not advance the Tail pointer. A BASIC program can just
; check for a 0 in Char if it does not want to check Head & Tail pointers
; before doing a "ReadBuffer".

; **F** ------------ LCD MODULE SOFTWARE DRIVER ROUTINE -----------------------

; For more info on LCD modules, consult an appropriate data sheet.

; This program implements a 4-bit data interface which takes less I/O
; lines than an 8-bit interface but requires more code space and executes
; somewhat slower. An "E" signal is required to clock data/commands into the
; module. The "RS" line specifies whether data or a command is to be
; written. The R/W line is not used (grounded). Therefore this software only
; supports writing data to the LCD module.

; The LCD driver software is written in assembly language for speed and
; compactness. The driver is furnished in a ready to load HEX file format.
; The well documented source code (below) allow the user to customize the
; driver to his/her needs. An assembler is included with all starter
; packages to aid the user in making code changes.

; The sample BASIC program "TERM.BAS" shows how to use this program in
; combination with TB52.

; When this program is initialized from within BASIC by executing the
; "CALL 8132" Statement, characters are written to the LCD by writing them
; to internal memory location 29 and executing the "CALL 8138" Statement.
; Characters may also be written to the LCD using the PRINT command, since
; the LCD initialization also configures the TB52 User Output Option.
; To PRINT characters to the serial port after initializing the LCD, you
; must execute the "Bit 126=0" Statement.

; HINT: If your think your hardware/software is working ok but the LCD
; module isn't displaying characters, be sure to check the contrast control
; which is normally set near ground potential (zero volts).

; **G** ---------------------- SCAN A MATRIX KEYPAD ---------------------------

; The keypad software does not require any initialization. If you are
; using a 4x4 keypad, you will need to execute the BIT 2=1 Statement to
; enable the library routine to scan the bottom two rows of the keypad.

; Executing the CALL 8140 Statement will scan the keypad and return a
; number between 0 and 8 (0 and 16 for a 4x4 keypad). The number will be
; placed in internal memory location 27. The number indicates the key
; being pressed, where 1 represents row 1 column 1, 2 represents row 2
; column 1, etc. A zero indicates that no keys are pressed.

; The keypad scan routine simply checks each row for a key press and
; returns the number corresponding to the first key press detected, or
; zero if no keys are pressed. As an option, Bit 3 can be set to force the
; key scan software to wait until a new key is pressed. The routine will
; not return a zero.

; --------------- CONNECTING AN LCD MODULE AND KEYPAD TO THE CPU --------------

; The LCD and Keypad software included with this program assume that system
; wiring is a shown in the following diagram. The diagram corresponds to the
; declarations in the Equate table (see below). If your wiring is not
; identical to the diagram as shown, you will need to make changes to the
; Equate table. Note that the numbers shown in parentheses are the LCD module
; pin numbers.

;           LCD          CONTROLLER         KEYPAD
;          -----        ------------       --------
;                     旼컴컴컴컴컴컴커
;     (14)  DB7컴컴컴캑 P1.7    P1.7 쳐컴컴컴COL4
;     (13)  DB6컴컴컴캑 P1.6    P1.6 쳐컴컴컴COL3
;     (12)  DB5컴컴컴캑 P1.5    P1.5 쳐컴컴컴COL2
;     (11)  DB4컴컴컴캑 P1.4    P1.4 쳐컴컴컴COL1
;      (6)   E컴컴컴컴� P1.3    P3.3 쳐컴컴컴ROW1
;      (4)   RS컴컴컴캑 P1.2    P3.5 쳐컴컴컴ROW2
;      (5)  R/W컴컴컴캑 GND     P3.2 쳐컴컴컴ROW3 (Optional)
;      (3)  Vee컴컴컴캑 GND     P3.4 쳐컴컴컴ROW4 (Optional)
;      (2)  Vcc컴컴컴캑 +5V          �
;      (1)  Vss컴컴컴캑 GND          �
;                     읕컴컴컴컴컴컴켸

; **H** ---------------------- X-10 TRANSMIT ROUTINE --------------------------

; This routine will send a series of 1 ms pulses, synchronized with the
; line frequency, to the power line interface module. These pulses
; represent the appropriate codes. Specific details on sending codes can
; be found in the power line interface module application guide. The
; timing of these pulses is critical, and is therefore provided as part of
; the TB52 interpreter utilities. This allows a simple user interface
; program to be written in BASIC. X-10 codes may be sent by placing the
; appropriate values in the House (36), Unit (37), and Function (38)
; internal memory locations and then executing the CALL 6 statement.

; See the Xplor-32 user's manual for a complete description of the X-10
; functions and capabilities.

; **I** -------------------- FIND BASIC PROGRAM LENGTH ------------------------

; This program can be used to find the length of the BASIC program stored in
; EEPROM. Executing the "CALL 8156" statement from BASIC will result in the
; address of the BASIC program End Of File character being written to internal
; data memory locations 30 (low byte) and 31 (high byte). This is useful if
; you are concerned about your BASIC program filling up all of the available
; EEPROM program storage space.
                             
; BASIC EXAMPLE:
; CALL 8156
; PRINT 256*(DBY 31) + DBY 30


; -------------------------- LIBRARY EQUATE TABLE -----------------------------

; EQUATING A CPU MEMORY LOCATION OR I/O LINE TO A SYMBOL MAKES THE PROGRAM
; EASIER TO FOLLOW AND CHANGE. A SINGLE EQUATE TABLE CHANGE WILL AFFECT ALL
; REFERENCED ITEMS THROUGHOUT THE PROGRAM.

; Variable Equates

DIFF    EQU     1               ; DATA BIT      Different key pressed ?
LINES   EQU     2               ; DATA BIT      1=4x4 Keypad, 0=2x4.
W4Key   EQU     3               ; DATA BIT      Set to wait until key pressed
SGN_FLG EQU     7AH             ; DATA BIT      Flag for printing line number
USRBIT  EQU     126             ; DATA BIT      User output bit

WorkL   EQU     6               ; DATA BYTE     Working register (LSB)
WorkH   EQU     7               ; DATA BYTE     Working register (MSB)

AR0     EQU     24              ; DATA BYTE     R0 in Register Bank 3
AR1     EQU     25              ; DATA BYTE     R1 in Register Bank 3
BufChar EQU     26              ; DATA BYTE     Contains retrieved character
KEYS    EQU     27              ; DATA BYTE     Where to store.
LFNO    EQU     28              ; DATA BYTE     Line feed count
CHAR    EQU     29              ; DATA BYTE     Character to be written
LastL   EQU     30              ; DATA BYTE     Low byte of last address
LastH   EQU     31              ; DATA BYTE     High byte of last address

; NEXT 5 BYTES FOR X-10

HOUSE   EQU     36              ; House codes A-P
UNIT?   EQU     37              ; Unit codes 1-16  (or BRIGHT/DIM control)
FUNC    EQU     38              ; Function code
TIMER   EQU     39              ; An X-10 Timer
COUNTR  EQU     40              ; An X-10 Counter

;  EEPROM read/write routines for X25640, 8bit X 8K, MSB first

CT      EQU     40              ; Counter Register (Used for X-10 too)
EE_dat  EQU     41              ; 8-bit data     (Used for ADC too)
EE_addr EQU     42              ; 16-Bit address ( "    "   "   " )

Head    EQU     AR0             ; Pointer to last character stuffed
Tail    EQU     AR1             ; Pointer to last character read

NO_VAR  EQU     26              ; Allow 26 user variables (A-Z)
BUFRSIZ EQU     20              ; Allow 20 characters in the buffer,
                                ; reducing variable space to 16 (A-P)

LineL   EQU     77H             ; BASIC program source line counter.
LineH   EQU     78H             ;   "       "       "   high byte.

A_LOW   EQU     80H             ; Low and high bytes of BASIC variables
A_HIGH  EQU     81H
B_LOW   EQU     82H
C_LOW   EQU     84H

; I/O Line Equates

RS      EQU     P1.2            ; PORT PIN      LCD Data/Instruction Mode
Eclk    EQU     P1.3            ; PORT PIN      LCD Clock
C1_D4   EQU     P1.4            ; PORT PIN      Keypad Column 1, LCD D4
C2_D5   EQU     P1.5            ; PORT PIN      Keypad Column 2, LCD D5
C3_D6   EQU     P1.6            ; PORT PIN      Keypad Column 3, LCD D6
C4_D7   EQU     P1.7            ; PORT PIN      Keypad Column 4, LCD D7
ROW1    EQU     P3.3            ; PORT PIN      Keypad Row 1
ROW2    EQU     P3.5            ; PORT PIN      Keypad Row 2
ROW3    EQU     P3.2            ; PORT PIN      Keypad Row 3 (Optional)
ROW4    EQU     P3.4            ; PORT PIN      Keypad Row 4 (Optional)

CROSS_0 BIT     P3.2            ; PORT PIN      Zero crossing signal from X-10
X10OUT  BIT     P3.4            ; PORT PIN      Active low transmit output

X25CS   EQU     P1.5            ; PORT PIN      X25640 Chip Select: 0 = enable
SCLK    EQU     P1.6            ; PORT PIN      Serial Data Clock signal
SD_IN   EQU     P1.7            ; PORT PIN      Serial Data in to X25640
SD_OUT  EQU     P2.6            ; ADDRESS LINE  Serial Data out from X25640


; Miscellaneous Equates

COLS    EQU     0F0H            ; Keypad column lines are in upper nibble.
ERROR   EQU     2EH             ; Call to error message in interpreter
STROUT  EQU     21H             ; Print a string from ROM
PRNTOS  EQU     10H             ; Print the current line number
Char_Output     EQU     30H     ; Call to character output in interpreter

CR      EQU     0DH

RegisterBank3	EQU	00011000B
Buffer          EQU     80H+(2*NO_VAR)-BUFRSIZ ; Where circular Buffer starts
BufferEnd       EQU     Buffer+BUFRSIZ

; ------ THE ORG STATEMENT SPECIFIES WHERE YOUR HEX CODE WILL BE LOCATED ------

        ORG     7317            ; Program starts at this address

; **A** ------------------- ACCESS THE SERIAL EEPROM --------------------------

;***************************************************
; NAME: READ_256
;   The external X25640 eeprom is enabled.
;   Write the instruction: 0000 0011
;   Write the 16-bit address to the device, then
;   read the corresponding data. (8-bits, msb first)
;   Max clock frequency of 1MHz.
; INPUTS: SD_OUT, EE_addr (16 bits)
; OUTPUTS: SCLK, SD_IN, EE_dat (8 bits)
; REGS: CT(=bit counter)
; WRITTEN:  (RKA) 11/02/94
; MODIFIED: (TMB) 06/08/95
;---------------------------------------------------

READ_256:
        MOV     A,#3
        ACALL   START_OUT

        MOV     A,EE_addr
        ACALL   OUT_8BITS       ; send 16-bit address
        MOV     A,EE_addr+1
        ACALL   OUT_8BITS
         
IN_8BITS:                       ; input on SDAT pin
        MOV     CT,#08

READ_IN: SETB   SCLK            ; clock pulse
        NOP
        MOV     C,SD_OUT        ; read data byte
        CLR     SCLK
        RLC     A
        DJNZ    CT,READ_IN
        MOV     EE_dat,A

        SETB    X25CS
        RET                     ; EE_dat contains data


;***************************************************
; NAME: RDSR_256
;   The external X25640 eeprom is enabled.
;   Write the instruction: 0000 0101
;   Read the status register data:
;       WPEN x  x  x  BP1 BP0 WEL WIP
;   Max clock frequency of 1MHz.
; INPUTS: SD_OUT
; OUTPUTS: SCLK, SD_IN
; REGS: CT(=bit counter)
; WRITTEN:  (RKA) 11/02/94
; MODIFIED: (TMB) 06/08/95
;---------------------------------------------------

RDSR_256:
        MOV     A,#5
        ACALL   START_OUT
        SJMP    IN_8BITS        ; input on SDAT pin


;***************************************************
; NAME: WRITE_256
;   The external X25640 eeprom is enabled.
;   Write the instruction: 0000 0010
;   Write the 16-bit address to the device, then write
;   the corresponding data. (8-bits, msb first.)
;   Max clock frequency of 1MHz. Input
;   data must be present on the rising edge of SCLK.
; INPUTS: SD_OUT, EE_addr (16 bits), EE_dat (8 bits)
; OUTPUTS: SCLK, SD_IN
; REGS: CT(=bit counter)
; WRITTEN:  (RKA) 11/02/94
; MODIFIED: (TMB) 06/08/95
;---------------------------------------------------

WRITE_256:              ; Always write enable the device before writing to it.
        ACALL   WREN_256        ; Clear the WEL bit
        MOV     A,#2            ; Write opcode
        ACALL   START_OUT

        MOV     A,EE_addr
        ACALL   OUT_8BITS       ; send 16-bit address
        MOV     A,EE_addr+1
        ACALL   OUT_8BITS

        MOV     A,EE_dat
        ACALL   OUT_8BITS
        SETB    X25CS
        SETB    SD_IN
        RET


;***************************************************
; NAME: WRSR_256
;   The external X25640 eeprom is enabled.
;   Write the instruction: 0000 0001
;   Write the new status register data:
;       WPEN x  x  x  BP1 BP0 WEL WIP
;   Max clock frequency of 1MHz.
; INPUTS: SD_OUT, EE_dat (8-bits)
; OUTPUTS: SCLK, SD_IN
; REGS: CT(=bit counter)
; WRITTEN:  (RKA) 02/08/95
; MODIFIED: (TMB) 06/08/95
;---------------------------------------------------

WRSR_256:
        ACALL   WREN_256        ; Clear the WEL bit
        MOV     A,#1
        ACALL   START_OUT

        MOV     A,EE_dat        ; assume new data here
        ACALL   OUT_8BITS
        SETB    X25CS
        RET


;***************************************************
; Subroutines for reading and writing the serial EEPROM

START_OUT:                      ; Select the device and send 8 bits
        CLR     X25CS
        CLR     SCLK

OUT_8BITS:
        MOV     CT,#8
OUT_LOOP:
        RLC     A
        MOV     SD_IN,C
        NOP
        SETB    SCLK
        NOP
        CLR     SCLK
        DJNZ    CT,OUT_LOOP
        RET


;***************************************************
; NAME: WREN_256
;   The external X25640 eeprom is enabled.
;   Write the instruction: 0000 0110
;   Max clock frequency of 1MHz.
; INPUTS: SD_OUT
; OUTPUTS: SCLK, SD_IN
; REGS: CT(=bit counter)
; WRITTEN:  (RKA) 11/02/94
; MODIFIED: (TMB) 06/08/95
;---------------------------------------------------

WREN_256:
        MOV     A,#6
        ACALL   START_OUT       ; Write 8 bits to the device
        SETB    X25CS
        SETB    SD_IN
        RET


; **B** ------------- PRINT THE BASIC PROGRAM LINE NUMBER ---------------------

; Print out the current BASIC program line number.
; This routine reads the BASIC program line number
; from RAM and prints it out using calls to the
; interpreter. This requires TB52 V1.1c or later.

; WRITTEN:  (TMB) 06/08/95
;---------------------------------------------------

Line_Num:
        LCALL    STROUT          ; Print a space and the line number
        DB      'LINE',' ' OR 80H

        MOV     WorkH,LineH
        MOV     WorkL,LineL
	CLR	SGN_FLG
        LCALL   PRNTOS

        LCALL   STROUT          ; Always send a CR
        DB      CR OR 80H

        RET


; **C** ------------- PRINT A CHARACTER STRING FROM MEMORY --------------------

STRING: PUSH    DPL             ; Save the CPU registers
        PUSH    DPH
        PUSH    ACC
        PUSH    0

        MOV     R0,#C_LOW       ; Point to low byte of BASIC "C" variable
        MOV     A,@R0
        MOV     DPL,A           ; Save as low byte of character string

        INC     R0              ; Get the high byte of the address too.
        MOV     A,@R0
        MOV     DPH,A
                                                                      
        POP     0

C_Loop: MOVX    A,@DPTR         ; Get the character from memory
        CJNE    A,#'"',C_Out    ; Check for terminating character

        POP     ACC             ; Restore registers and return
        POP     DPH
        POP     DPL
        RET                                                   

C_Out:  PUSH    DPL             ; Save the CPU registers
        PUSH    DPH
        CALL    Char_Output     ; Address of char output vector
                                ; NOTE: This requires TB52 V1.1a or later!
        POP     DPH
        POP     DPL             ; Restore the character pointer

        INC     DPTR            ; Point to the next character
        SJMP    C_Loop
        
; **D** -------------------- EEPROM WRITE LOW ROUTINE -------------------------

WriteL: PUSH    DPL             ; Save all system parameters so that TB52
        PUSH    DPH             ;  operation will not be affected.
        PUSH    PSW
        ORL     PSW,#RegisterBank3      ; Select Register Bank 3
        PUSH    AR0
        PUSH    AR1

        MOV     R0,#A_LOW       ; Point to the low byte of write address
        MOV     AR1,@R0         ; Save it in R1
        INC     R0              ; Point to the high byte of write address
        MOV     P2,@R0          ; Save it in P2
        INC     R0              ; Point to the data byte

; P2,R1 contains write address, @R0 has data byte

WriteX: JBC     P2.7,Seven      ; 1st check if address above 8191
        JBC     P2.6,Six        ; Only addresses below 8192 are valid
        JBC     P2.5,Five       ;  memory addresses for X88C64.

        JBC     P2.4,IsHigh     ; Write high plane ?
                                ; This software can only write low plane.

        PUSH    IE              ; Save interrupt enables
        CLR     EA              ; Disable all interrupts

        MOV     DPTR,#0555H
        MOV     A,#0AAH
        MOVX    @DPTR,A         ; Write AA to x555

        MOV     DPTR,#0AAAH
        CPL     A
        MOVX    @DPTR,A         ; Write 55 to xAAA

        MOV     DPTR,#0555H
        MOV     A,#0A0H
        MOVX    @DPTR,A         ; Write A0 to x555

        MOV     A,@R0           ; Get the data to write.
        MOV     DPH,A
        MOVX    @R1,A           ; Write the byte.

        MOVX    A,@R1

POLL:   MOV     DPL,A
        MOVX    A,@R1
        CJNE    A,DPL,POLL      ; Bit6 still toggling ?

        POP     IE              ; Enable all interrupts
        MOVX    A,@R1
        CJNE    A,DPH,ChkErr    ; Write failed so "SORRY!"

OUT2:   POP     AR1
        POP     AR0
        POP     PSW
        POP     DPH
        POP     DPL
        RET

Seven:  SETB    P2.7            ; PERIPHERAL WRITE EXITS.
        SJMP    OUT2

Six:    SETB    P2.6
        SJMP    OUT2

Five:   SETB    P2.5
        SJMP    OUT2

IsHigh: SETB    P2.4
        SJMP    OUT2
     
ChkErr: POP     AR1
        POP     AR0
        POP     PSW
        POP     DPH
        POP     DPL
        LJMP    ERROR           ; "SORRY!"

; **E** ---------------- SERIAL INTERRUPT ROUTINE -----------------------------

SerialInt:      JNB  RI,NotRecv         ; Not a receive interrupt ?
                PUSH PSW                ; Save registers
                PUSH ACC
		ORL  PSW,#RegisterBank3

		INC  R0 		; Check the buffer pointer
		CJNE R0,#BufferEnd,Head_OK

		MOV  R0,#Buffer

Head_OK:	MOV  A,SBUF		; Get serial input character
                CLR  RI                 ; and reenable interrupt.
		MOV  @R0,A		; Store character in Buffer

                POP  ACC
                POP  PSW

NotRecv:        RETI

; ---------------------- READ CHARACTER FROM BUFFER ---------------------------

ReadBuffer:	MOV  A,Head		; If Head & Tail are the same,
                XRL  A,Tail             ; the Buffer is considered empty.
                JNZ  GetChar
                MOV  BufChar,A          ; So return with NULL character
                RET

GetChar:	PUSH PSW		; Save registers
		ORL  PSW,#RegisterBank3

		INC  R1
                CJNE R1,#BufferEnd,Tail_OK

                MOV  R1,#Buffer

Tail_OK:        MOV  A,@R1              ; Read the Buffer
                MOV  BufChar,A          ; and put it here.

		POP  PSW
                RET

; ------------------------INITIALIZE SERIAL INTERRUPT -------------------------

SerialBuffer:   MOV  Head,#Buffer       ; Initialize Buffer pointers
		MOV  Tail,#Buffer
                MOV  BufChar,#0         ; Initialize Char to "NULL"
                SETB ES                 ; Enable serial interrupt
                SETB EA                 ; Global interrupts enable

ClearTI:        JNB  TI,$               ; Normally set by BASIC.
                CLR  TI                 ; We want it cleared.
                RET

; ------------------------- DISABLE SERIAL INTERRUPT --------------------------

; May want to load SBUF with 1st character of an output string instead of a
; NULL and let BASIC take care of sending the rest of them.

StopSerial:     CLR  ES                 ; Disable serial interrupt

WriteCR:        MOV  SBUF,#0DH          ; Write <cr> to set TI bit
                RET

WriteChar:      MOV  SBUF,BufChar
                SJMP ClearTI
                  

; **F** ------------- LCD MODULE DISPLAY DRIVER ROUTINES ----------------------

; ----------------------------- CLEAR DISPLAY ---------------------------------

; Moved this code here to place the "HERE" label in a common location for all
; of the various LCD Drivers.

CLEAR:  MOV     A,#1            ; Clear display
        ACALL   COMMAND

WAIT5mS: MOV    A,#10           ; Wait >5mS
HERE:   MOV     B,#0FFH         ; (5.5mS at 11.0592 Mhz)
        DJNZ    B,$
        DJNZ    ACC,HERE
        RET                                                                  

; ------------------ INITIALIZE LCD MODULE (PER DATA SHEET) -------------------

; The code below performs a software initialization of the LCD module. For more
; information on this subject, consult an LCD data sheet.

Init:   SETB    USRBIT          ; Set user output bit
        CLR     RS              ; Command mode
        MOV     A,#30H          ; Function Set (default 8-bit interface)
        ACALL   NIBBLE          ; Clock and wait >120uS
        ACALL   WAIT5mS         ; Need to wait >5 mS the 1st time

        MOV     A,#30H          ; Function Set Again (default 8-bit interface)
        ACALL   NIBBLE          ; (Actually 03H)

        MOV     A,#30H          ; Function Set Again (default 8-bit interface)
        ACALL   NIBBLE

        MOV     A,#20H          ; Function Set: Set 4-bit interface
        ACALL   NIBBLE

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

OUTPUT: RLC     A               ; Rotate instruction/data bit into carry
        MOV     C4_D7,C         ;  and then move carry bit to LCD data line.
        RLC     A
        MOV     C3_D6,C         ; (Do high nibble 1st)
        RLC     A
        MOV     C2_D5,C
        RLC     A
        MOV     C1_D4,C

        SETB    Eclk            ; Clock nibble (4-bits) into LCD
        CLR     Eclk

NIBBLE: RLC     A
        MOV     C4_D7,C
        RLC     A               ; (Do lower nibble)
        MOV     C3_D6,C
        RLC     A
        MOV     C2_D5,C
        RLC     A
        MOV     C1_D4,C

CLOKIT: SETB    Eclk            ; Clock nibble into LCD
        CLR     Eclk

WAIT:   MOV     B,#60           ; Wait at least 120 uS
        DJNZ    B,$             ; (130uS at 11.0592 Mhz)
NoChar: RET

LCD_32D:        DS      6       ; Leave room for Xplor-32d software version

; **G** ------------------------- READ KEYPAD ---------------------------------

KEYPAD: ORL     P1,#COLS        ; Assert column input high

ROW_1:  CLR     ROW1            ; Enable Row 1
        MOV     B,#1            ; Offset value to B register
        MOV     A,P1
        CPL     A
        ANL     A,#COLS         ; Clear lower nibble.
        SETB    ROW1            ; Disable Row 1
        JNZ     ISKEY           ; Find one pressed ?

ROW_2:  CLR     ROW2            ; Do Row 2
        MOV     B,#5
        MOV     A,P1
        CPL     A
        ANL     A,#COLS
        SETB    ROW2
        JNZ     ISKEY
        JNB     LINES,CLRDIF    ; Just 2x4 keypad ?

ROW_3:  CLR     ROW3            ; Do Row 3
        MOV     B,#9
        MOV     A,P1
        CPL     A
        ANL     A,#COLS
        SETB    ROW3
        JNZ     ISKEY

ROW_4:  CLR     ROW4            ; Do Row 4
        MOV     B,#13
        MOV     A,P1
        CPL     A
        ANL     A,#COLS
        SETB    ROW4
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

; **H** ----------------------- X-10 SOFTWARE ---------------------------------

X10XMIT: SETB   X10OUT          ; ----------------- BEGIN HERE ----------------
        JB      CROSS_0,$       ; Turn off transmitter and get in sync
        JNB     CROSS_0,$       ;  by waiting for positive zero crossing.


        MOV     A,FUNC          ; ------------ BRIGHT/DIM COMMAND ? -----------
        CJNE    A,#18,CHK26     ; Dim command ?
        AJMP    START1
CHK26:  CJNE    A,#26,NORMAL    ; Bright command ?


START1: XCH     A,UNIT?         ; -------------- BRIGHT/DIM MODE --------------
        MOV     FUNC,A          ; Swap FUNC and UNIT? registers
        JZ      NoDim           ; Didn't load the BRIGHT/DIM count

MORE:   ACALL   START2          ; The BRIGHT/DIM loop
        DJNZ    FUNC,MORE
NoDim:  RET

NORMAL: ACALL   TWICE           ; --------------- NORMAL MODE -----------------

        MOV     COUNTR,#06      ; Wait 6 power line half cycles after
X_WAIT: ACALL   READY           ; transmitting the 1st pair of codes.
        DJNZ    COUNTR,X_WAIT

        MOV     UNIT?,FUNC      ; Move FUNC code to UNIT? register before
                                ; transmitting 2nd pair of codes.

TWICE:  ACALL   START2          ; Output HOUSE and UNIT codes twice

START2: ACALL   SEND1           ; --------------- TRANSMIT LOOP ---------------
        ACALL   SEND1
        ACALL   SEND1           ; Send start code 1st. (Three ones & a zero)
        ACALL   SEND0

        MOV     COUNTR,#4       ; Initialize loop counter to send 4 bits
        MOV     A,HOUSE
        ACALL   XMIT            ; Send 4-bit house code

        MOV     COUNTR,#5       ; Initialize loop counter to send 5 bits
        MOV     A,UNIT?         ; Load unit code


XMIT:   JNB     ACC.0,AZERO     ; Send a zero ?

        ACALL   SEND1           ; Send one
        SJMP    SKPOVR

AZERO:  ACALL   SEND0           ; Send zero

SKPOVR: ACALL   SNDCPL          ; Send opposite

        RR      A               ; Get ready for next bit
        DJNZ    COUNTR,XMIT     ; Repeat for all bits
        RET


SNDCPL: JB      ACC.0,SEND0     ; ---------- TRANSMIT A ONE OR ZERO ? ---------

SEND1:  ACALL   BURST           ; Send 1st one
        ACALL   DELAY           ; Delay 1.77mS
        ACALL   BURST           ; Send 2nd one
        ACALL   DELAY           ; Delay 1.77mS
        ACALL   BURST           ; Send 3rd one


SEND0:                          ; ----------- WAIT FOR ZERO CROSSING ----------
READY:  JB      CROSS_0,UPPER   ; If in upper half cycle goto UPPER
        JNB     CROSS_0,$       ; Otherwise wait for positive crossing
        RET

UPPER:  JB      CROSS_0,$       ; Wait for negative crossing
        RET

BURST:  MOV     TIMER,#230      ; ----------- 120 KHZ BURST FOR 1mS -----------

W1000:  CLR     X10OUT          ; Turn on output for 1mS.
        NOP
        DJNZ    TIMER,W1000
        SETB    X10OUT          ; Turn off output
        RET


DELAY:  MOV     TIMER,#233      ; ------------ SET UP 1.770mS DELAY -----------
W1778:  NOP
        NOP                     ; Used for 3 phase timing
        NOP
        NOP
        NOP
        DJNZ    TIMER,W1778
        RET

; **I** -------------------- FIND BASIC PROGRAM LENGTH ------------------------

FindEnd:MOV     DPTR,#4095      ; Point to the beginning of program memory -1

EOF?:   INC     DPTR
        MOVX    A,@DPTR
        CJNE    A,#255,FindCR   ; Test for end of file record

        MOV     LastH,DPH       ; Save the address and exit
        MOV     LastL,DPL
        RET

FindCR: INC     DPTR            ; Bump the pointer past the line number

LookForCR:
        INC     DPTR
        MOVX    A,@DPTR
        CJNE    A,#13,LookForCR ; Test for end of line record

        SJMP    EOF?

$EJECT

; --------------------------------- VECTORS -----------------------------------

        ORG     8120            ; AJMPs to library functions

        AJMP    READ_256        ; 8120 Read the Serial EEPROM
        AJMP    RDSR_256        ; 8122 Read the Serial EEPROM status register
        AJMP    WRITE_256       ; 8124 Write to the Serial EEPROM
        AJMP    WRSR_256        ; 8126 Write to the Serial EEPROM status reg
        AJMP    Line_Num        ; 8128 Output the Line Number ERROR
        AJMP    STRING          ; 8130 Output character string from memory
        AJMP    INIT            ; 8132 Initialize LCD module
        AJMP    CLEAR           ; 8134 Clear LCD module
        AJMP    HOME            ; 8136 Home cursor
        AJMP    ONE_WR          ; 8138 Write single character to LCD
        AJMP    KEYPAD          ; 8140 Read keypad input
        AJMP    WriteL          ; 8142 Write to lower half of EEPROM
        AJMP    SerialBuffer    ; 8144 Initialize Serial Input Buffer
        AJMP    ReadBuffer      ; 8146 Check the Buffer for characters
        AJMP    WriteCR         ; 8148 Set the TI bit by sending a CR
        AJMP    ClearTI         ; 8150 Clear the TI bit after transmitting
        AJMP    WriteChar       ; 8152 Send the character from the Buffer
        AJMP    X10XMIT         ; 8154 X-10 transmit subroutine
        AJMP    FindEnd         ; 8156 Find the end of the BASIC program

        ORG     8161            ; TB52 Vectors

USRIN:  DB      0,0,0
USROUT: LJMP    OUTUSR          ; User output routine

        ORG     8179

        JMP     SerialInt       ; Serial Interrupt vector

        END

