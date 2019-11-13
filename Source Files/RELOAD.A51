$ DATE(09-30-94)
$ LENGTH 60
$ TITLE "TB52 HEX FILE RELOAD"
$ XREF

;    /* (c) Copyright BLUE EARTH RESEARCH, MANKATO, MN 1994. */
;    /*                All rights reserved.                  */

; This program source file is provided only as a reference for Xplor Series
; Controllers that have the 8052 Tiny BASIC (TB52) in ROM.  It may not be
; incorporated into other products or otherwise used in any commercial
; application without specific written permission from Blue Earth Research.

; This program provides a means to read in a hex file that contains the
; standard TB52 interpreter source file. It can load hex data to the lower
; half of EEPROM, but it must be executed out of upper EEPROM. It can not be
; used to update the TB52 interpreter when it is located in the CPU ROM.

; It is invoked from the BASIC prompt by typing "CALL 7000" after loading
; the RELOAD hex file. After it is invoked, the program will wait for you to
; upload the hex fle containing TB52 (or any other hex file).

; If there are any errors during reception of the HEX file (or if <Ctrl>-C
; is typed) the "TRY AGAIN" message will be displayed and the program will
; once again wait for a hex file. If the hex load is successful, the software
; will reboot the controller. If the software is aborted by powering down the
; controller during the hex file transfer, the lower half of EEPROM will NOT
; be block protected.

; Note: While you are uploading a Hex file using the Reload program, any hex
; records that reference a memory address 4095 (1000H) or greater will be
; ignored. If you need to reload the TB52 vector address Hex file, simply
; upload it at the BASIC prompt.


CR      EQU     0DH             ; ASCII CODE FOR <CARRIAGE RETURN>.
LF	EQU	0AH		;  "    "    "  <LINE FEED>.
BEL	EQU	07H		;  "    "    "  <BELL>.

MODE    EQU     2EH             ; Operating mode bits.
BPR     BIT     MODE.0          ; Block Protect Register enable
NOCTRLC BIT     MODE.1          ; Don't check for <Ctrl> keys
GETRAM  BIT     MODE.2          ; For accessing on chip ram.
RUNMOD  BIT     MODE.3          ; Set when stored BASIC program is running.
HEXMOD  BIT     MODE.4          ; Set when operations should use HEX radix.
NOCTRL  BIT     MODE.5          ; Disables control char checking in run mode.
INDIR   BIT     MODE.6          ; To store/fetch from indirect RAM.
EN_FREQ BIT     MODE.7          ; Set to DISable frequency measuring mode.

AESP    EQU     37H             ; AES Pointer  (Arithmetic Expression Stack)
AES     EQU     38H             ; Buffer allocation.
TABCNT  EQU     73H             ; Column formatting count.
TABSIZ  EQU     8               ; Formatted column spacing.
ALL_OK  EQU     35.4            ; SET UNTIL AN ERROR OCCURS

A_LOW   EQU     80H             ; Low and high bytes of BASIC A & B variables
A_HIGH  EQU     81H
B_LOW   EQU     82H
B_HIGH  EQU     83H

AR0     EQU     0
AR1     EQU     1

; ------------------------- C-O-D-E  S-E-G-M-E-N-T ----------------------------

        ORG     7000

        SETB    ALL_OK          ; Set now, check after all code loaded
        CLR     EA              ; Disable all interrupts

        ACALL   STROUT
        DB      CR,'UPLOAD HEX FILE NOW',CR OR 80H
                                            
; ----- Clear the Block Protect Register Bits to allow writing to EEPROM ------

BOOT:   MOV     R1,#B_LOW       ; Point to BASIC "B" variable
        MOV     @R1,#55H        ; Load failsafe bytes
        INC     R1
        MOV     @R1,#0AAH
        MOV     A,#0            ; Clear all block protect bits.
        MOV     P2,#0FH
        SETB    BPR             ; Allow writing to the Block Protect Register
        ACALL   WriteX

        SJMP    WaitHex         ; Wait for the hex record to be received

DoneYet:JB      ALL_OK,SETBPR   ; Any errors?

TRY:    ACALL   STROUT          ; Error must have been detected
        DB      CR,'TRY AGAIN',CR OR 80H

        SETB    ALL_OK          ; Set now, check after all code loaded
        SJMP    GetHex          ; Wait for the hex record to be received

; ----- Set the Block Protect Register Bits to prevent writing to EEPROM ------

SETBPR: MOV     R1,#B_LOW       ; Point to BASIC "B" variable
        MOV     @R1,#55H        ; Load failsafe bytes
        INC     R1
        MOV     @R1,#0AAH
        MOV     A,#0FH          ; Protect the lower half of EEPROM
        MOV     P2,#0FH
        SETB    BPR             ; Allow writing to the Block Protect Register
        ACALL   WriteX

DONE:   LJMP    0               ; Reset again and return to the BASIC prompt


; ----------------------------- READ HEX RECORD -------------------------------

Ck_C:   CJNE    A,#3,CR_CHK     ; Check for <Ctrl>-C
DigErr: SJMP    TRY             ; "TRY AGAIN"

CR_CHK: CJNE    A,#CR,WaitHex   ; Check for CR

GetHex: JNB     TI,$
        CLR     TI
        MOV     SBUF,#'>'

WaitHex:JNB     RI,$            ; Character in SBUF ?
        MOV     A,SBUF
        CLR     RI
        CLR     ACC.7           ; Clear parity bit
        JNB     TI,$
        CLR     TI
        MOV     SBUF,A
        CJNE    A,#':',Ck_C     ; Wait for start character ?

; MAIN ENTRY POINT.  GET HERE IF ":" DETECTED AT BASIC PROMPT.

DoRec:  SETB    F0              ; ------------ THE MAIN ENTRY POINT -----------
        MOV     R2,#0           ; Start checksum
        ACALL   RdByte          ; 1) Get record length
        MOV     R4,A            ; Save record length
        MOV     R5,A

        ACALL   RdByte          ; 2) Get high address
        MOV     P2,A

        ACALL   RdByte          ; 3) Get low address
        MOV     R1,A

        ACALL   RdByte          ; 4) Get record type
        JZ      GetDat          ; 0 if data, 1 if last record
        CLR     F0              ; Clear flag

GetDat: MOV     A,R4            ; Check record length
        JZ      IsEnd

        MOV     R0,#AES         ; Temporary storage for data
DataIn: ACALL   RdByte          ; 5) Get a byte
        JNB     F0,NoStor       ; Store if data record
        MOV     @R0,A
        INC     R0
NoStor: DJNZ    R4,DataIn       ; Get more bytes

IsEnd:  ACALL   RdByte          ; Get checksum byte
        CJNE    R2,#0,Load_Error
        SJMP    Go_On           ; Continue if OK

Load_Error:
        CLR     ALL_OK          ; Error in Hex record - Try Again
        SJMP    JustCR

Go_On:  JNB     F0,JustCR       ; Data record ?
        MOV     A,R5            ; Check record length
        JZ      JustCR

        MOV     R0,#AES         ; Where data is stored
HexWR:  MOV     A,@R0
        ACALL   WriteX          ; Write data to EEPROM
        INC     R0
        INC     R1
        CJNE    R1,#0,NoInc
        INC     P2              ; Point to next byte
NoInc:  DJNZ    R5,HexWR

JustCR: MOV     A,#CR
        ACALL   C_OUT

        JB      F0,GetHex       ; Read another record ?
        AJMP    DoneYet         ; All done so reset Block Protect Register

; --------------------------------------------------------------------

RdByte: SETB    PSW.1           ; Get 2 characters & make a 2 digit byte

DoAgin: MOV     R3,A
        JNB     RI,$            ; Character in SBUF ?
        MOV     A,SBUF
        CLR     RI
        CLR     ACC.7           ; Clear parity bit
        CLR     C

        JNB     TI,$            ; Echo back to host
        CLR     TI
        MOV     SBUF,A

        SUBB    A,#'0'
        JNC     IsDigit         ; If not a digit (<30H) do "WHAT?".
        CLR     ALL_OK
        CLR     C
        CLR     A               ; Store a zero

IsDigit:SUBB    A,#10           ; Test for A-F
        JC      IsNmbr
        SUBB    A,#7            ; Adjust for gap

IsNmbr: ADD     A,#10           ; Restore
        ANL     A,#0FH
        JBC     PSW.1,DoAgin    ; 2nd time ?
        SWAP    A
        ORL     A,R3
        SWAP    A               ; 2 digits in ACC

        XCH     A,R2            ; Get Checksum
        ADD     A,R2            ; Update it and
        XCH     A,R2            ;  get byte back.
        RET

        LJMP    0               ; FAILSAFE ?

; ---------- Console Output routine --------------------

C_OUT:  JNB     TI,$            ; Wait til last character gone.
        CLR     TI              ; Clear interrupt flag.
        MOV     SBUF,A          ; Write out character.

        CJNE    A,#CR,COUT_2    ; If it was <CR> then follow with <LF>.
        JNB     TI,$
        CLR     TI
        MOV     SBUF,#LF        ; Output linefeed.

COUT_2: RET

STROUT: POP     DPH             ; ACCESS IN-LINE STRING AND SEND
        POP     DPL             ; TO CONSOLE OUTPUT.
STRO_1:	CLR	A
        MOVC    A,@A+DPTR       ; Read next byte.
        INC     DPTR            ; Bump pointer.
        JBC     ACC.7,STRO_2    ; Escape after last character.
        ACALL   C_OUT           ; Output character.
        SJMP    STRO_1          ; Loop until done.

STRO_2: ACALL   C_OUT           ; Output character.
	CLR	A
        JMP     @A+DPTR         ; Return to program.


; -------------------------- EEPROM WRITE ROUTINE -----------------------------

; MASS PATTERNING SEQUENCE BELOW WRITES DATA BYTE TO ENTIRE DEVICE.
; 1) AA --> X555, 2) 55 --> XAAA, 3) A0 --> X555,
; 4) AA --> X555, 5) 55 --> XAAA, 6) DATA --> XXXX

; P2,R1 contains write address, ACC has data, DPH/DPL destroyed.

WriteX: JBC     P2.7,Seven      ; 1st check if address above 8191
        JBC     P2.6,Six        ; Only addresses below 8192 are valid
        JBC     P2.5,Five       ;  memory addresses for X88C64.

        JBC     P2.4,IsHigh     ; Write high plane ?
                                ; This software can only write low plane.

H_or_L: PUSH    AR0
        PUSH    AR1
        PUSH    ACC
        MOV     DPTR,#0555H

        MOV     A,#0AAH
        MOVX    @DPTR,A         ; Write AA to 1555

        MOV     DPTR,#0AAAH
        CPL     A
        MOVX    @DPTR,A         ; Write 55 to 1AAA

        MOV     DPTR,#0555H
        MOV     A,#0A0H
        MOVX    @DPTR,A         ; Write A0 to 1555

        JNB     BPR,WByte       ; Write to BPR?

        MOV     R1,#82H         ; Get the codes from the BASIC Variable "B"
        CJNE    @R1,#55H,BPRErr  ; SORRY!

        CLR     A               
        MOV     @R1,A           ; Clear out the B variable code

        INC     R1
        CJNE    @R1,#0AAH,BPRErr  ; SORRY!

        MOV     @R1,A           ; Clear out the B variable code

WBPR:   MOV     A,#0AAH         ; Added writes for Block Protect
        MOVX    @DPTR,A         ; Write AA to 1555

        MOV     DPTR,#0AAAH
        MOV     A,#0C0H
        MOVX    @DPTR,A         ; Write 0C0H to 1AAA
                                ; Fall through to write routine
WByte:  POP     ACC
        MOV     DPH,A
        MOVX    @R1,A           ; Write the byte.

        MOVX    A,@R1
POLL:   MOV     DPL,A
        MOVX    A,@R1
        CJNE    A,DPL,POLL      ; Bit6 still toggling ?

        JBC     BPR,POLL1       ; Exit if writing to BPR
        MOVX    A,@R1
        CJNE    A,DPH,ChkErr    ; Write failed so "SORRY!"

POLL1:  POP     AR1
        POP     AR0
        RET

BPRErr: POP     ACC             ; Restore ACC and interrupts
        POP     AR1
        POP     AR0
        CLR     BPR             ; No more BPR enable

        ACALL   STROUT          ; Syntax error.
        DB      CR,'BPR ERROR',CR OR 80H
        LJMP    0
                 
ChkErr: CLR     ALL_OK          ; Syntax error.
        POP     AR1
        POP     AR0
        RET

Seven:  SETB    P2.7            ; PERIPHERAL WRITE EXITS.
        RET
Six:    SETB    P2.6
        RET
Five:   SETB    P2.5
        RET
IsHigh: SETB    P2.4
        RET

        END

