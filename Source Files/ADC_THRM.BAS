
~              File: ADC_THRM.BAS      Date: 03/21/96
~
~    /* (c) Copyright BLUE EARTH RESEARCH, MANKATO, MN 1996. */
~    /*                All rights reserved.                  */
~
~
~     ษอออออออออออออออออออออออออออออออออออออออออออออออออออออป
~     บ         READ TEMPERATURE USING A THERMISTOR         บ
~     ศอออออออออออออออออออออออออออออออออออออออออออออออออออออผ
~
~      ีอออออออออออออออออออออออออออออออออออออออออออออออออออธ
~      ณ            Written By: Thomas Bachmann            ณ
~      ณ      Blue Earth Research, Mankato, MN  56001      ณ
~      ิอออออออออออออออออออออออออออออออออออออออออออออออออออพ
~
~    NOTES:
~       This program uses a standard linear (or near linear) thermistor
~       to measure temperature (in degrees C) on any of the analog
~       Xplor-32 controllers. Several assumptions are made about the
~       thermistor and the circuit it is used in. Most of these are
~       defined by variables in the first few lines of the program.
~
~       The thermistor should be wired something like:
~
~                        To ADC Channel
~                              |
~           +5V ____/\/\/\_____|_____/\/\/\_____ GND
~                   R=2200๊        Thermistor
~
~       Given that R is the fixed resistor and M is the thermistor
~       resistance, the voltage divider yields an ADC reading of:
~           ADC = [M/(R+M)]*1024

~       Solving the equation for M gives:
~           M = (R*ADC)/(1024-ADC)

~       Since integer math is used in determining both the thermistor
~       resistance and the resulting temperature, great accuracy should
~       not be expected.

10 R=2200                           ~ Series resistor value, in ohms
20 R=R/100                          ~ Scale it to allow integer math
30 N=3000                           ~ Resistance of thermistor at 25๘C
40 S=125                            ~ Linear scaling factor, in Ohms/๘C

50 INPUT 'CHANNEL TO READ'; C       ~ Enter 0-10 for the channel number
60 X=CHAN C                         ~ Result is 0-1023
70 Y=1024-X                         ~ Result is 1-1024 (Can't divide by zero)
80 Z=(R*X)/Y                        ~ Get resistance of thermistor
90 A=((R*X) MOD Y)*10               ~ Get remainder of integer math
100 E=A/Y                           ~ and convert to tens digit
110 B=(A MOD Y)*10                  ~ Get remainder of integer math
120 O=A/Y                           ~ and convert to ones digit
130 M=Z*100+E*10+O                  ~ Calculate the resistance
140 T=25+((M-N)/S)                  ~ and the resulting temperature
150 P. 'TEMP IS ';T
160 GOTO 50

