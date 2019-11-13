$TITLE "TINY BASIC IDLE MODE"

;    /* (c) Copyright BLUE EARTH RESEARCH, MANKATO, MN 1995. */
;    /*                All rights reserved.                  */

; This program can be run on any of the Xplor Series controllers to use
; the CPU's IDLE mode. The Idle mode is a low power mode similar to the
; Power Down (SLEEP) Mode, but the internal timers continue to run while in
; the Idle mode. Also, any enabled interrupt will cause the CPU to recover
; from the Idle mode, so TB52's RTC can be used as an "Alarm clock."

; The Idle mode is controlled by bit 0 in the PCON register (DBY 135). Setting
; the bit will invoke the Idle mode. The following BASIC program can be used
; without any assembly language code for a modest power savings. Adding the
; CALL (new line 90) to the assembly routine will reduce power even further.
; NOTE: Make sure that you assemble this file and upload the Hex file before
; editing the BASIC program to substitute the CALL statement.

;       BASIC PROGRAM EXAMPLE:

; 10 REM SAMPLE "IDLE" PROGRAM
;
; ~   Get the number of seconds to idle, then just wait.
;
; 20 INPUT "HOW MANY SECONDS TO WAIT? ",A
; 30 IF A<1 THEN GOTO 50                      ~ The number must be positive
; 40 IF A<60 THEN GOTO 70                     ~ Less than 60 seconds, too
; 50 PRINT "ENTER A NUMBER BETWEEN 1 AND 60"  ~ for this sample alarm clock
; 60 GOTO 20
;
; 70 DBY 48=0 : DBY 49=0                      ~ Reset the timers to zero
;
; ~   Wait for a while...
;
; 80 PRINT "GOOD NIGHT"                       ~ Now set the IDLE bit in PCON
; ~ 90 CALL 7000                              ~ This can be done in assembly
; 90 DBY 135 = 1 OR DBY 135                   ~   or in BASIC
;
; 100 IF DBY 49 < A THEN GOTO 90              ~ Go back to sleep...
; 110 PRINT "GOOD MORNING"


SUBSEC  EQU     48              ; Incr every 1/60 second   (0-59 counts)

        ORG     7000

Good_Night:
;        MOV     P2,#32          ; Set address lines for internal ROM CPU
        ORL     PCON,#1         ; Set the IDLE Bit

        NOP                     
        NOP                     ; The CPU will service the interrupt first!
        NOP

        MOV     A,SUBSEC        ; Get the 1/60 second count from TB52 RTC
        JNZ     Good_Night      ; Back to BASIC only if a seconds change
        RET                     ; Back to BASIC

        END

