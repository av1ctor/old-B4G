'' 
'' int386.bas -- shows how to invoke a 32-bit protected mode interrupt
''               vector using the interrupt(x)386 routines
''

defint a-z
'$include: '..\bi\b4g.bi'

  dim regs as REGS386
 
  '' try switch to 32-bit protected mode
  if (b4ginit > 0) then
     print "ERROR! cannot switch to pmode"     
     end
  end if

  '':::

  '' get protected mode interrupt vector
  regs.eax = &h0204
  regs.ebx = &h21                               '' get DOS int vector
  interrupt386 &h31, regs                       '' invoke DPMI server int num

  '' print vector: cx=selector:edx=offset
  print "selector:"; regs.ecx and &hFFFF&;
  print "offset:"; regs.edx

  '':::

  b4gdone                               '' only need when running in the IDE
