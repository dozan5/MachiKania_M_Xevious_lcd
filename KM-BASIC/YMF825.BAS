REM YMF825 board Driver

REM  Pin Assign
REM  1 SS    --> G3
REM  2 MOSI  --> G9/MOSI
REM  3 MISO  --> F2/MISO
REM  4 SCK   --> F6/CLK
REM  5 GND   --> GND
REM  6 5V    --> +5V
REM  7 RST_N --> RB12(OPTION)
REM  8 AUDIO --> NC
REM  9 3.3V  --> +3.3V

USEVAR FNUMH, FNUML
USEVAR CH, OCT, KEY, VOL, MAX
USEVAR M_CNT, M_DATA, P_CNT, P_STOP

USEVAR LATGCL, LATGST, ODCGCL, RSTBIT

REM 10MHz/16bit/Mode0/CS:G3
SPI 10000,16,0,$63

DIM FNUML(12), FNUMH(12)
DIM M_DATA(3,128), P_CNT(3), M_CNT(3)
DIM P_STOP(3), OCT(3), KEY(3), VOL(3)

RESTORE FNH
FOR I=0 TO 11
 FNUMH(I)=CREAD()
NEXT

RESTORE FNL
FOR I=0 TO 11
 FNUML(I)=CREAD()
NEXT

GOSUB INIT

N=8:S=0
CLS

LABEL SELECT

FOR I=0 TO 2
 P_CNT(I)=0
 P_STOP(I)=0
 M_CNT(I)=1
 VOL(I)=18
NEXT

CURSOR 0,5
PRINT "Select by Up/Down Key"
PRINT "and Hit Fire Key"

CURSOR 0,10
PRINT "1  Credit"
PRINT "2  Start"
PRINT "3  BGM"
PRINT "4  Blaster"
PRINT "5  Zapper"
PRINT "6  CheckPoint"
PRINT "7  Extend"
PRINT "8  END"

S=GOSUB(CHOICE)
CLS
CURSOR 0,5
PRINT "Press the START key"
PRINT "    To Break"

IF S=0 THEN GOSUB CREDIT:GOSUB PLAY
IF S=1 THEN GOSUB START:GOSUB PLAY
IF S=2 THEN GOSUB BGM:GOSUB PLAY
IF S=3 THEN GOSUB BLASTE:GOSUB PLAY
IF S=4 THEN GOSUB ZAPPER:GOSUB PLAY
IF S=5 THEN GOSUB CHECK:GOSUB PLAY
IF S=6 THEN GOSUB EXTEND:GOSUB PLAY
IF S=7 THEN CLS:END
GOTO SELECT

LABEL CHOICE

CURSOR 2,10+S
PRINT ">";
GOSUB WAIT10
IF KEYS() THEN CHOICE

LABEL CHOICL

K=KEYS()
IF K=0 THEN CHOICL
GOSUB WAIT10
CURSOR 2, 10+S
PRINT " ";

IF K=32 THEN RETURN S
IF K=1 THEN S=S-1
IF K=2 THEN S=S+1
IF S<0 THEN S=0
IF S=N THEN S=N-1
GOTO CHOICE

END

LABEL PLAY

WHILE KEYS()!=16

 FOR CH=0 TO MAX
  IF P_STOP(CH)=0 THEN GOSUB C_PLAY
 NEXT

 WAIT 1

 IF P_STOP(0)=1 THEN RETURN

WEND

RETURN 

LABEL C_PLAY

 M_CNT(CH)=M_CNT(CH)-1
 IF M_CNT(CH)>0 THEN RETURN

 OCT(CH)=M_DATA(CH,1+P_CNT(CH))
 KEY(CH)=M_DATA(CH,2+P_CNT(CH))
 M_CNT(CH)=M_DATA(CH,3+P_CNT(CH))

 P_CNT(CH)=P_CNT(CH)+3

 IF KEY(CH)=255 THEN GOSUB KEYOFF,CH
 IF KEY(CH)=254 THEN GOSUB KEYOFF,CH:P_STOP(CH)=1
 IF KEY(CH)=253 THEN P_CNT(CH)=0
 IF KEY(CH)<250 THEN GOSUB KEYON, CH, OCT(CH), KEY(CH), VOL(CH)

RETURN

LABEL INIT
 REM Initialize YMF825

 ODCGCL=$BF886644

 POKE16 ODCGCL,$08:REM G3 OPEN DRAIN OFF 
 GOSUB WAIT10

REM RST_N RB12
REM OUT 12,1
REM GOSUB WAIT10
REM OUT 12,0
REM GOSUB WAIT10
REM OUT 12,1
REM GOSUB WAIT10

 SPIWRITE $1D01:REM OUTPUT_power
 SPIWRITE $020E
 GOSUB WAIT10
 SPIWRITE $0001:REM CLKEN
 SPIWRITE $0100:REM AKRST
 SPIWRITE $1AA3
 GOSUB WAIT10
 SPIWRITE $1A00
 GOSUB WAIT10
 SPIWRITE $0204:REM AP1,AP3
 GOSUB WAIT10
 SPIWRITE $0200
 GOSUB WAIT10

 SPIWRITE $19F0:REM MASTER VOL
 SPIWRITE $1B3F:REM interpolation
 SPIWRITE $1400:REM interpolation
 SPIWRITE $0301:REM Analog Gain

 SPIWRITE $08F6
 GOSUB WAIT10
 SPIWRITE $0800
 SPIWRITE $09F8
 SPIWRITE $0A00
 SPIWRITE $1740:REM MS_S
 SPIWRITE $1800

REM TONE

 SPIWRITE $08F6
 GOSUB WAIT10
 SPIWRITE $0800

 SPIWRITE $0781, $0143, $2122, $F59E, $0010, $0020, $32FF, $7200, $5000, $2122, $FD66, $0110, $0011, $52F4, $2801, $1000, $8003, $8180

REM SETCH

 FOR C=0 TO 16
  SPIWRITE $0B00+C:REM channnel select
  SPIWRITE $0F30:REM keyon = 0
  SPIWRITE $1071:REM chvol
  SPIWRITE $1100:REM XVB
  SPIWRITE $1208:REM FRAC
  SPIWRITE $1300:REM FRAC
 NEXT

 SPIWRITE $19A0:REM MASTER VOL 40

RETURN

LABEL KEYON

 C=ARGS(1)
 O=ARGS(2)
 K=ARGS(3)
 V=ARGS(4)<<2

 SPIWRITE $0B00+C:REM channnel select
 SPIWRITE $0F00

 GOSUB WAIT1

 SPIWRITE $0C00+V:REM voice volume
 SPIWRITE $0D00+FNUMH(K)+O:REM FNUMH
 SPIWRITE $0E00+FNUML(K):REM FNUML
 SPIWRITE $0F40:REM keyon

RETURN

LABEL KEYOFF

 C=ARGS(1)

 SPIWRITE $0B00+C:REM channnel select
 SPIWRITE $0F00:REM keyon = 0

RETURN

LABEL WAIT1

 FOR W=0 TO 4700
 NEXT

RETURN

LABEL WAIT10

 FOR W=0 TO 18100
 NEXT

RETURN

LABEL CREDIT

 RESTORE D_CRED
 MAX=1
 GOSUB D_READ

RETURN

LABEL START

 RESTORE D_STAR
 MAX=2
 GOSUB D_READ

RETURN

LABEL BGM

 RESTORE D_BGM
 MAX=0
 GOSUB D_READ

RETURN

LABEL BLASTE

 RESTORE D_BLAS
 MAX=0
 GOSUB D_READ

RETURN

LABEL ZAPPER

 RESTORE D_ZAPP
 MAX=0
 GOSUB D_READ

RETURN

LABEL CHECK

 RESTORE D_CHEC
 MAX=0
 GOSUB D_READ

RETURN

LABEL EXTEND

 RESTORE D_EXTE
 MAX=2
 GOSUB D_READ

RETURN

LABEL D_READ

 FOR I=0 TO MAX
  M_DATA(I,0)=CREAD()
  FOR J=1 TO M_DATA(I,0)
   M_DATA(I,J)=CREAD()
  NEXT
 NEXT

RETURN

LABEL FNH

CDATA  16, 16, 24, 24, 24, 24, 24, 32, 32 ,32, 32, 40

LABEL FNL

CDATA 101,122, 17, 41, 66, 93,121, 23, 55, 89,125, 34

LABEL D_CRED

CDATA 87
REM   1  G#    1  G     1  F#    1  F
CDATA 1, 8, 1, 1, 7, 1, 1, 6, 1, 1, 5, 1
REM   1  E     1  D#    1  D     2  G#
CDATA 1, 4, 1, 1, 3, 1, 1, 2, 1, 2, 8, 1
REM   2  G     2  F#    2  F     2  E
CDATA 2, 7, 1, 2, 6, 1, 2, 5, 1, 2, 4, 1
REM   2  D#    2  D     3  G#    3  G
CDATA 2, 3, 1, 2, 2, 1, 3, 8, 1, 3, 7, 1
REM   3  F#    3  F     3  E     3  D#
CDATA 3, 6, 1, 3, 5, 1, 3, 4, 1, 3, 3, 1
REM   3  D     4  G#    4  G     4  F#
CDATA 3, 2, 1, 4, 8, 1, 4, 7, 1, 4, 6, 1
REM   4  F     4  E     4  D#    4  D
CDATA 4, 5, 1, 4, 4, 1, 4, 3, 1, 4, 2, 1
REM   0  END
CDATA 0, 254, 1

CDATA 87
REM   1  G     1  F#    1  F     1  E
CDATA 1, 7, 1, 1, 6, 1, 1, 5, 1, 1, 4, 1
REM   1  D#    1  D     1  C#    2  G
CDATA 1, 3, 1, 1, 2, 1, 1, 1, 1, 2, 7, 1
REM   2  F#    2  F     2  E     2  D#
CDATA 2, 6, 1, 2, 5, 1, 2, 4, 1, 2, 3, 1
REM   2  D     2  C#    3  G     3  F#
CDATA 2, 2, 1, 2, 1, 1, 3, 7, 1, 3, 6, 1
REM   3  F     3  E     3  D#    3  D
CDATA 3, 5, 1, 3, 4, 1, 3, 3, 1, 3, 2, 1
REM   3  C#    4  G     4  F#    4  F
CDATA 3, 1, 1, 4, 7, 1, 4, 6, 1, 4, 5, 1
REM   4  E     4  D#    4  D     4  C#
CDATA 4, 4, 1, 4, 3, 1, 4, 2, 1, 4, 1, 1
REM   0  END
CDATA 0, 254, 1

LABEL D_STAR

CDATA 108
REM   4  F      0  R       4  C     4  F
CDATA 4, 5, 32, 0, 255, 8, 4, 0, 8, 4, 5, 8
REM   4  A     5  C     4  A     0  R
CDATA 4, 9, 8, 5, 0, 8, 4, 9, 8, 0, 255, 8
REM   4  F     4  G     0  R       4  G
CDATA 4, 5, 8, 4, 7, 8, 0, 255, 8, 4, 7, 8
REM   4  G     0  R       4  D      0  R
CDATA 4, 7, 8, 0, 255, 8, 4, 2, 16, 0, 255, 8
REM   4  G     4  F     0  R       4  E
CDATA 4, 7, 8, 4, 5, 8, 0, 255, 8, 4, 4, 8
REM   4  F      0  R       4  C     4  F
CDATA 4, 5, 32, 0, 255, 8, 4, 0, 8, 4, 5, 8
REM   4  A     5  C     4  A     0  R
CDATA 4, 9, 8, 5, 0, 8, 4, 9, 8, 0, 255, 8
REM   4  F     4  F#    0  R       4  F#
CDATA 4, 5, 8, 4, 6, 8, 0, 255, 8, 4, 6, 8
REM   4  F#    0  R       4  F
CDATA 4, 6, 8, 0, 255, 8, 4, 5, 56
REM   0  End
CDATA 0, 254, 1

CDATA 108
REM   3  A      0  R       3  A     3  A
CDATA 3, 9, 32, 0, 255, 8, 3, 9, 8, 3, 9, 8
REM   4  C     4 F      4  C     0  R  
CDATA 4, 0, 8, 4, 5, 8, 4, 0, 8, 0, 255,8
REM   3  A     3  A#      0  R       3  A#
CDATA 3, 9, 8, 3, 10,  8, 0, 255, 8, 3, 10, 8
REM   3  A#     0  R       3  A#      0  R 
CDATA 3, 10, 8, 0, 255, 8, 3, 10, 16, 0, 255, 8
REM   3  A#     3  A#     0  R       3  A#
CDATA 3, 10, 8, 3, 10, 8, 0, 255, 8, 3, 10,  8
REM   3  A      0  R       3  A     3  A
CDATA 3, 9, 32, 0, 255, 8, 3, 9, 8, 3, 9, 8,
REM   4  C    4  F      4  C     0  R
CDATA 4, 0, 8,4, 5,  8, 4, 0, 8, 0, 255, 8
REM   3  A    3  A#      0  R       3  A#
CDATA 3, 9, 8, 3, 10, 8, 0, 255, 8, 3, 10, 8
REM   3  A#     0  R       3  A#
CDATA 3, 10, 8, 0, 255, 8, 3, 10, 56
REM   0  End
CDATA 0, 254, 1

CDATA 111
REM   2  F     2  F     2  F     2  F
CDATA 2, 5, 8, 2, 5, 8, 2, 5, 8, 2, 5, 8
REM   0  R        2  F     2  F     2  F
CDATA 0, 255, 16, 2, 5, 8, 2, 5, 8, 2, 5, 8
REM   2  F     0  R        2  F     2  F
CDATA 2, 5, 8, 0, 255, 16, 2, 5, 8, 2, 5, 8
REM   2  F     2  F     0  R        2  F
CDATA 2, 5, 8, 2, 5, 8, 0, 255, 16, 2, 5, 8
REM   2  F     2  F     2  F     0  R
CDATA 2, 5, 8, 2, 5, 8, 2, 5, 8, 0, 255, 16
REM   2  F     2  F     2  F     2  F
CDATA 2, 5, 8, 2, 5, 8, 2, 5, 8, 2, 5, 8
REM   0  R        2  F     2  F     2  F
CDATA 0, 255, 16, 2, 5, 8, 2, 5, 8, 2, 5, 8
REM   2  F     0  R        2  F     2  F
CDATA 2, 5, 8, 0, 255, 16, 2, 5, 8, 2, 5, 8
REM   2  F     2  F     0  R       2  F
CDATA 2, 5, 8, 2, 5, 8, 0, 255, 8, 2, 5, 56
REM   0  End
CDATA 0, 254, 1

LABEL D_BGM

CDATA 99
REM   4  C     5  C     4  B      5  C
CDATA 4, 0, 6, 5, 0, 6, 4, 11, 6, 5, 0, 6
REM   5  E     5  C     4  B      5  C
CDATA 5, 4, 6, 5, 0, 6, 4, 11, 6, 5, 0, 6
REM   4  C     5  C     4  A#     5  C
CDATA 4, 0, 6, 5, 0, 6, 4, 10, 6, 5, 0, 6
REM   5  E     5  C     4  A#     5  C
CDATA 5, 4, 6, 5, 0, 6, 4, 10, 6, 5, 0, 6
REM   4  C     5  C     4  A     5  C
CDATA 4, 0, 6, 5, 0, 6, 4, 9, 6, 5, 0, 6
REM   5  E     5  C     4  A     5  C
CDATA 5, 4, 6, 5, 0, 6, 4, 9, 6, 5, 0, 6
REM   4  C     5  C     4  G#    5  C
CDATA 4, 0, 6, 5, 0, 6, 4, 8, 6, 5, 0, 6
REM   5  E     5  C     4  G#    5  C
CDATA 5, 4, 6, 5, 0, 6, 4, 8, 6, 5, 0, 6
REM   0  Repeat
CDATA 0, 253, 1

LABEL D_BLAS

CDATA 102
REM   4  C     4  C#    4  D     4  D#
CDATA 4, 0, 1, 4, 1, 1, 4, 2, 1, 4, 3, 1
REM   4  E     4  D#    4  D     4  C#
CDATA 4, 4, 1, 4, 3, 1, 4, 2, 1, 4, 2, 1
REM   4  C     3  B      3  A#     3  A
CDATA 4, 0, 1, 3, 11, 1, 3, 10, 1, 3, 9, 1
REM   3  G#    3  G     3  F#    3  F
CDATA 3, 8, 1, 3, 7, 1, 3, 6, 1, 3, 5, 1
REM   3  E     3  D#    3  D     3  C#
CDATA 3, 4, 1, 3, 3, 1, 3, 2, 1, 3, 1, 1
REM   3  C     2  B      2  A#     2  A
CDATA 3, 0, 1, 2, 11, 1, 2, 10, 1, 2, 9, 1
REM   2  G#    2  G     2  F#    2  F
CDATA 2, 8, 1, 2, 7, 1, 2, 6, 1, 2, 5, 1
REM   2  E     2  D#    2  D     2  C#
CDATA 2, 4, 1, 2, 3, 1, 2, 2, 1, 2, 1, 1
REM   2  C
CDATA 2, 0, 1
REM   0  End
CDATA 0, 254, 1

LABEL D_ZAPP

CDATA 27
REM   1  F#    6  F#    1  G     6  C#
CDATA 1, 6, 1, 6, 6, 1, 1, 7, 1, 6, 1, 1
REM   1  G#    5  G#    1  A     5  D#
CDATA 1, 8, 1, 5, 8, 1, 1, 9, 1, 5, 3, 1
REM   0  End
CDATA 0, 254, 1

LABEL D_CHEC

CDATA 57
REM   4  D     4  F     4  G     4  A
CDATA 4, 2, 3, 4, 5, 3, 4, 7, 3, 4, 9, 3
REM   5  C     5  D     4  D     4  F
CDATA 5, 0, 3, 5, 2, 3, 4, 2, 3, 4, 5, 3
REM   4  G     4  A     5  C     5  D
CDATA 4, 7, 3, 4, 9, 3, 5, 0, 3, 5, 2, 3
REM   4  D     4  F     4  G     4  A
CDATA 4, 2, 3, 4, 5, 3, 4, 7, 3, 4, 9, 3
REM   5  C     5  D
CDATA 5, 0, 3, 5, 2, 3
REM   0  End
CDATA 0, 254, 1

LABEL D_EXTE

CDATA 24
REM   5  C     4  G     4  E     4  C
CDATA 5, 0, 6, 4, 7, 6, 4, 4, 6, 4, 0, 6
REM   4  E     4  G     5  C
CDATA 4, 4, 6, 4, 7, 6, 5, 0, 6
REM   0  End
CDATA 0, 254, 1

CDATA 24
REM   4  G     4  E     4  C     3  G
CDATA 4, 7, 6, 4, 4, 6, 4, 0, 6, 3, 7, 6
REM   4  C     4  E     4  G
CDATA 4, 0, 6, 4, 4, 6, 4, 7, 6
REM   0  End
CDATA 0, 254, 1

CDATA 24
REM   4  E     4  C     3  G     0  R
CDATA 4, 4, 6, 4, 0, 6, 3, 7, 6, 0, 255, 6
REM   3  G     4  C     4  E
CDATA 3, 7, 6, 4, 0, 6, 4, 4, 6
REM   0  End
CDATA 0, 254, 1
