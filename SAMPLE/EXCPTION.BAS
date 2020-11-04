''
'' excption.bas -- shows what happens when an exception occurs
''

DEFINT A-Z
'$INCLUDE: '..\bi\b4g.bi'

  '' try switch to 32-bit protected mode
  IF (b4ginit > 0) THEN
     PRINT "ERROR! cannot switch to pmode"
     END
  END IF

  xmmove &HDEADDEAD, 4, &HB8000                 '' generate the exception

