$TITLE "TINY BASIC VECTORS"
$XREF
$LENGTH 59

;   This file shows the default vector addresses in TB52.  The resulting hex
;   file can be loaded to memory to restore the default vectors.


DOZERO  EQU     3FH             ; Interrupt location

        ORG     1FE1H

USRIN:  DB      0,0,0           ; ------- JUMP TABLE FOR USER ROUTINES --------
USROUT: DB      0,0,0
INT_0:  DB      0,0,0
TIMR_0: LJMP    DOZERO
INT_1:  RETI
        DB      0,0
TIMR_1: DB      0,0,0
SERIAL: DB      0,0,0
TIMER2: DB      0,0,0
PCA:    DB      0,0,0

        LJMP    0               ; FAILSAFE
        END

