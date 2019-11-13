
~              File: WDTE.BAS      Date: 11/02/95
~
~    /* (c) Copyright BLUE EARTH RESEARCH, MANKATO, MN 1995. */
~    /*                All rights reserved.                  */
~
~
~     ษอออออออออออออออออออออออออออออออออออออออออออออออออออออป
~     บ             PCA WATCHDOG TIMER FOR TB52             บ
~     ศอออออออออออออออออออออออออออออออออออออออออออออออออออออผ
~
~      ีอออออออออออออออออออออออออออออออออออออออออออออออออออธ
~      ณ            Written By: Thomas Bachmann            ณ
~      ณ      Blue Earth Research, Mankato, MN  56001      ณ
~      ิอออออออออออออออออออออออออออออออออออออออออออออออออออพ
~
~    NOTES:
~      This program generates a reset if the watchdog timer is NOT
~      updated periodically (about every four seconds).
~
~      The PCA increments once each timer0 overflow, so it will reset in
~      about four seconds if the watchdog reset subroutine is not called.
~
~      The PCA Watchdog timer requires a CPU upgrade. The PCA is NOT
~      included in the standard (80C32) Xplor Series CPU.

1 REM PCA Watchdog example

5   PRINT : PRINT "PROGRAM RESET"

~       Note: you may want to put a conditional break in the program
~       here (for testing purposes), since it will be hard to stop the
~       program after the watchdog has been initialized.

10  GOSUB 300                       ~ Initialize the PCA & Watchdog
15  GOTO 90                         ~ Main program

~       Watchdog reset subroutine:

20  BIT 175 = 0                     ~ Turn off the interrupts for now
22  Y = DBY 233 : Z = DBY 249       ~ Read the current PCA counter (L & H)
24  IF Y <> DBY 233 THEN GOTO 22    ~ Make sure the low byte hasn't changed
26  BIT 175 = 1
28  Z=Z+1 : IF Z=256 THEN Z=0       ~ Calculate match, check for overflow
30  DBY 238 = Y : DBY 254 = Z       ~ Update the compare registers (L & H)
32  RETURN

90 REM MAIN PROGRAM LOOP
100 INPUT "ENTER A NUMBER ",N       ~ Wait until a number is entered

110 GOSUB 20                        ~ Prevent Watchdog Reset
120 PRINT "JUST IN TIME"            ~ Must be entered in less than 4 seconds

130 GOTO 90

~   Set up the PCA in the Watchdog Timer mode

300 BIT 222 = 0 : DBY 233 = 0 : DBY 249 = 0     ~ Stop timer, PCA = 0
310 GOSUB 20                                ~ Get the first reload value
320 DBY 217 = 68 : DBY 222 = 72             ~ CMOD = 44H, CCAPM4 = 48H
330 DBY 216 = 64 : RETURN                   ~ CCON = 40H

