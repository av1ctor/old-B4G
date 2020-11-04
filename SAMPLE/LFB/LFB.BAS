''
'' lfb.bas -- shows how to access the Linear Frame Buffer on SVGA
''            video-cards w/ VBE 2.0 or great, using B4G library.
''
''            no more bank-switching baby :)
''
defint a-z
'$include: '..\..\bi\b4g.bi'
'$include: 'vbe2.bi'

const XRES = 640
const YRES = 480

declare sub Fill    (clr as integer)
declare sub DoError (errstrg as string)

  dim shared lfb as long                        '' pointer to LFB
  dim shared bpsl as integer                    '' bytes per scan line

  '' 1st) initialize B4G lib
  if (b4ginit <> 0) then DoError "Cannot switch to protected-mode"

  '' 2nd) check for VESA BIOS Extensions >= 2.0
  if (not vbe2init) then DoError "Need VBE version 2.0 or great"

  '' 3th) set a high-resolution mode w/ LFB enabled
  lfb = vbe2setmode(XRES, YRES)
  if (lfb = 0) then DoError "Linear Frame Buffer not supported"

  '' 4th) get the number of bytes per scan line
  bpsl = vbe2getbpsl

  '' 5th) fill the screen w/ blue color
  Fill 1

  '' 6th) wait 1 second :)
  sleep 1

  '' 7th) finish
  vbe2done
  b4gdone

'':::
sub Fill (clr as integer) static
  dim lin as long, y as integer

  lin = lfb
  for y = 1 to YRES
      xmfill lin, XRES, clr
      lin = lin + bpsl
  next y
end sub

'':::
sub DoError (errstrg as string)
  print "ERROR! ";
  print errstrg
  vbe2done                      '' safe even if not already initialized
  b4gdone                       '' /
  end
end sub
