10 T=CHAN 10 : PRINT "ENTER DEGREES CELCIUS"
REM GET CURRENT TEMP AND CALIBRATION POINT
20 INPUT S
30 S=S+273 : C=T*43/88 : K=273+(C-S)
REM DISPLAY CURRENT TEMP
40 T=CHAN 10 : C=T*43/88
50 PRINT "TEMP = ";C-K : GOTO 40
