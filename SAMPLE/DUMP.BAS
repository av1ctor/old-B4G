DEFINT A-Z
'$INCLUDE: '..\bi\b4g.bi'
DECLARE SUB xmdump (BYVAL dst AS LONG)

CONST FLINE = 10
CONST MEMSIZE = 4000 '2048000-36

DECLARE FUNCTION dotest1 ()
DECLARE FUNCTION dotest2 ()
DECLARE FUNCTION dotest3 ()
DECLARE FUNCTION dotest4 ()
  
  IF (b4ginit > 0) THEN
     PRINT "DPMI Error"
     END
  END IF

  'CLS
  'IF (NOT dotest1) THEN
  '   PRINT "Not enough extended memory"
  '   END
  'END IF
  'WHILE (INKEY$ = ""): WEND

  'CLS
  'IF (NOT dotest2) THEN
  '   PRINT "Not enough extended memory"
  '   END
  'END IF
  'WHILE (INKEY$ = ""): WEND

  'CLS
  'IF (NOT dotest3) THEN
  '   PRINT "Not enough extended memory"
  '   END
  'END IF
  'WHILE (INKEY$ = ""): WEND

  CLS
  IF (NOT dotest4) THEN
     PRINT "Not enough extended memory"
     END
  END IF
  LOCATE 24, 1

''::::::::::::::::::
FUNCTION dotest1
  DIM p1 AS LONG, p2 AS LONG, p3 AS LONG
 
  PRINT "! 1! 12! 123! 1!3! 1! !"
  PRINT "#-10-110-1110-1010-10-#"

  scraddr& = &HB8000 + (160 * (FLINE + 1))
 
  xmdump scraddr&: scraddr& = scraddr& + 160

  p1 = xmalloc(MEMSIZE)
  IF (p1 = 0) THEN EXIT FUNCTION
  xmfill p1, MEMSIZE, 1
  xmdump scraddr&: scraddr& = scraddr& + 160

  p2 = xmalloc(MEMSIZE)
  IF (p2 = 0) THEN EXIT FUNCTION
  xmfill p2, MEMSIZE, 1
  xmdump scraddr&: scraddr& = scraddr& + 160
 
  IF (xmrealloc(p1, MEMSIZE * 2) > 0) THEN EXIT FUNCTION
  xmfill p1, MEMSIZE * 2, 2
  xmdump scraddr&: scraddr& = scraddr& + 160

  IF (xmrealloc(p1, MEMSIZE * 4) > 0) THEN EXIT FUNCTION
  xmfill p1, MEMSIZE * 4, 3
  xmdump scraddr&: scraddr& = scraddr& + 160

  xmfree p1
  xmdump scraddr&: scraddr& = scraddr& + 160

  xmfree p2
  xmdump scraddr&: scraddr& = scraddr& + 160
 
  dotest1 = -1
END FUNCTION

''::::::::::::::::::
FUNCTION dotest2
  DIM p1 AS LONG, p2 AS LONG, p3 AS LONG

  PRINT "! 1! 12! 123! 1!3! !3! !"
  PRINT "#-10-110-1110-1010-010-#"

  xmdump &HB8000 + (160 * (FLINE + 1))

  p1 = xmalloc(MEMSIZE)
  IF (p1 = 0) THEN EXIT FUNCTION
  xmfill p1, MEMSIZE, 1
  xmdump &HB8000 + (160 * (FLINE + 2))
  
  p2 = xmalloc(MEMSIZE)
  IF (p2 = 0) THEN EXIT FUNCTION
  xmfill p2, MEMSIZE, 2
  xmdump &HB8000 + (160 * (FLINE + 3))

  p3 = xmalloc(MEMSIZE)
  IF (p3 = 0) THEN EXIT FUNCTION
  xmfill p3, MEMSIZE, 3
  xmdump &HB8000 + (160 * (FLINE + 4))

  xmfree p2
  xmdump &HB8000 + (160 * (FLINE + 5))

  xmfree p1
  xmdump &HB8000 + (160 * (FLINE + 6))

  xmfree p3
  xmdump &HB8000 + (160 * (FLINE + 7))

  dotest2 = -1
END FUNCTION

''::::::::::::::::::
FUNCTION dotest3
  DIM p1 AS LONG, p2 AS LONG, p3 AS LONG

  PRINT "! 1! 12! 123! 12! 1! !"
  PRINT "#-10-110-1110-110-10-#"

  xmdump &HB8000 + (160 * (FLINE + 1))

  p1 = xmalloc(MEMSIZE)
  IF (p1 = 0) THEN EXIT FUNCTION
  xmfill p1, MEMSIZE, 1
  xmdump &HB8000 + (160 * (FLINE + 2))
  
  p2 = xmalloc(MEMSIZE)
  IF (p2 = 0) THEN EXIT FUNCTION
  xmfill p2, MEMSIZE, 2
  xmdump &HB8000 + (160 * (FLINE + 3))

  p3 = xmalloc(MEMSIZE)
  IF (p3 = 0) THEN EXIT FUNCTION
  xmfill p3, MEMSIZE, 3
  xmdump &HB8000 + (160 * (FLINE + 4))

  xmfree p3
  xmdump &HB8000 + (160 * (FLINE + 5))

  xmfree p2
  xmdump &HB8000 + (160 * (FLINE + 6))

  xmfree p1
  xmdump &HB8000 + (160 * (FLINE + 7))

  dotest3 = -1
END FUNCTION

''::::::::::::::::::
FUNCTION dotest4
  DIM p1 AS LONG, p2 AS LONG, p3 AS LONG
  
  PRINT "! 1! 12! 123! !23! 12! !1!-!"
  PRINT "#-10-110-1110-0110-110-010-#"

  scraddr& = &HB8000 + (160 * (FLINE + 1))
 
  xmdump scraddr&: scraddr& = scraddr& + 160

  p1 = xmalloc(MEMSIZE)
  IF (p1 = 0) THEN EXIT FUNCTION
  xmfill p1, MEMSIZE, 1
  xmdump scraddr&: scraddr& = scraddr& + 160

  p2 = xmalloc(MEMSIZE)
  IF (p2 = 0) THEN EXIT FUNCTION
  xmfill p2, MEMSIZE, 2
  xmdump scraddr&: scraddr& = scraddr& + 160
 
  p3 = xmalloc(MEMSIZE)
  IF (p3 = 0) THEN EXIT FUNCTION
  xmfill p3, MEMSIZE, 3
  xmdump scraddr&: scraddr& = scraddr& + 160
 
  xmfree p1
  xmdump scraddr&: scraddr& = scraddr& + 160

  IF (xmrealloc(p2, MEMSIZE * 2) > 0) THEN EXIT FUNCTION
  xmfill p2, MEMSIZE * 2, 4
  xmdump scraddr&: scraddr& = scraddr& + 160

  xmfree p2
  xmdump scraddr&: scraddr& = scraddr& + 160
 
  xmfree p3
  xmdump scraddr&: scraddr& = scraddr& + 160

  dotest4 = -1
END FUNCTION

