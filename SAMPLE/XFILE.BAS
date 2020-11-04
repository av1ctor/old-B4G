''
'' xfile.bas -- shows how to read from and write to a file using
''              the XFILE module routines
''

defint a-z
'$include: '..\bi\b4g.bi'

const errormsg = "ERROR! "

  dim inpxf as XFILE, _
      outxf as XFILE                            '' in/out file XFILE structs
  dim xblk as long                              '' extended memory block
 
  '' try switch to 32-bit protected mode
  if (b4ginit > 0) then
     print errormsg;
     print "cannot switch to pmode"
     end
  end if

  '':::

  '' allocate 1M of extended memory for our buffer
  xblk = xmalloc(&h100000)
  if (xblk = 0) then
     print errormsg;
     print "not enough memory"
     end
  end if

  '' open the input file for read access using B4G default buffer
  if (not xfopen(inpxf, "xfile.bas", XF4READ, 0)) then
     print errormsg;
     print "file not found"
     end
  end if

  '' create the output file (can be wrote and read) using B4G default buffer
  if (not xfopen(outxf, "temp.tmp", XF4CREATE, 0)) then
     print errormsg;
     print "cannot create a file"
     end
  end if

  '' read from input file (inpxf) to memory buffer (xblk), write what
  '' was read to the output file (outxf) and print on screen the number
  '' bytes written
  print xfwrite(outxf, xblk, xfread(inpxf, xblk, &h100000))

  '':::

  b4gdone                               '' only need when running in the IDE
