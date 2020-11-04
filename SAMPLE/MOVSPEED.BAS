'' 
'' movspeed.bas -- moves a buffer (in conventional and extended memory)
''                 to screen (mode 13h) and show the difference between
''                 the two in frames per second
''
'' to compile: mk2* movspeed timer2 -- where * can be qb, qbx or vbd
''

defint a-z
'$include: '..\bi\b4g.bi'

const SECONDS = 5                       '' seconds to measure
const errormsg = "ERROR! "

declare function timer2& ()
declare function xmemmove% ()
declare function cmemmove% ()

  dim shared cblk as long
  dim shared xblk as long
 
  '' try switch to 32-bit protected mode
  if (b4ginit > 0) then
     print errormsg
     end
  end if

  '':::

  '' alloc two blocks: one in low memory, other in extended
  cblk = malloc(64000)
  xblk = xmalloc(64000)
  if ((cblk = 0) or (xblk = 0)) then
     print errormsg;
     print "not enough memory"
     end
  end if

  screen 13

  '':::

  xfps = xmemmove                       '' do xbuffer -> screen
  cfps = cmemmove                       '' do cbuffer -> screen
 
  '' print the result
  screen 0: width 80
  print "xmem -> scr:"; xfps \ SECONDS
  print "cmem -> scr:"; cfps \ SECONDS


''::::::::::::::::::::::::::::::::::::::
function xmemmove% static
  dim fps as integer, delay as long

  xmfill xblk, 64000, 1                 '' fill buffer with color 1

  fps = 0
  delay = timer2 + cint(18.2 * SECONDS) '' calc the delay in ticks

  do
     xmmove xblk, 64000, &hA0000        '' move buffer to screen
     fps = fps + 1
  loop until (timer2 >= delay)

  xmemmove = fps                        '' return fps
end function

''::::::::::::::::::::::::::::::::::::::
function cmemmove% static
  dim fps as integer, delay as long, lin as long

  lin = fp2lin(cblk)                    '' get the linear address

  xmfill lin, 64000, 2                  '' fill buffer with color 2

  fps = 0
  delay = timer2 + cint(18.2 * SECONDS) '' calc the delay in ticks

  do
     xmmove lin, 64000, &hA0000         '' move buffer to screen
     fps = fps + 1
  loop until (timer2 >= delay)

  cmemmove = fps                        '' return fps
end function
