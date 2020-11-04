''
'' initdone.bas -- shows how to init and finish the library (only for
''                 advanced users :P)
''

defint a-z
'$include: '..\bi\b4g.bi'

const errormsg = "ERROR! "

  dim result as integer

  '' try switch to 32-bit protected mode
  result = b4ginit
  if (result > 0) then
     print errormsg;
     select case result
            case B4G.ERROR.HOST
                 print "DPMI host not found"
            case B4G.ERROR.BIT
                 print "not a 32-bit host"
            case B4G.ERROR.MEM
                 print "not enough memory"
            case B4G.ERROR.SWT
                 print "cannot switch to pmode"
            case ELSE
                 print "unknown"
     end select
     end
  end if

  b4gdone                               '' only need when running in the IDE
