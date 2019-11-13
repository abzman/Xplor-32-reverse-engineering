REM Initialize serial interrupt
5      PRINT "SERIAL BUFFER INSTALLED"
10     CALL 8144
REM Wait for some characters
20     FOR A=1 TO 100
25     NEXT A
REM Buffer empty ?
30     IF DBY 24 = DBY 25 THEN GOTO 20
REM Get buffer character
40     CALL 8146
REM Print out the character
45     CALL 8152
REM Loop until a "6" is received
50     IF DBY 26 = 54 THEN GOTO 60
55     GOTO 30
REM Write <cr> to SBUF
60     CALL 8148
70     PRINT "Found a 6 in buffer."
REM Clear TI bit and disable Serial Interrupt
80     CALL 8150
90     BIT 172=0 : CALL 8148
