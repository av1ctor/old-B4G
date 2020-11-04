''
'' pokspeed.bas -- shows the difference in frames per second between
''                 methods of poke bytes to memory
''
'' to compile: mk2* pokspeed timer2 -- where * can be qb, qbx or vbd
''

defint a-z
'$include: '..\bi\b4g.bi'

declare function timer2& ()

const SECONDS = 5                       '' seconds to measure
const errormsg = "ERROR! "

declare function xmempoke% ()
declare function xmempokemaped% ()
declare function cmempoke% ()
declare function cmempokedirect% ()

dim shared blk as long
dim shared xblk as long
dim shared map as long
 
  '' try switch to 32-bit protected mode
  if (b4ginit > 0) then
     print errormsg;
     print "cannot switch to pmode"
     end
  end if

  '' allocate buffers and map
  xblk = xmalloc(64000)
  blk = malloc(64000)
  map = xmapmake(1024)
  if ((blk = 0) or (xblk = 0) or (map = 0)) then
     print errormsg;
     print "not enough memory"
     end
  end if

  screen 13

  '' set a linear palette
  out &h3C8, 0
  for c = 0 to 255
      out &h3C9, c \ 8
      out &h3C9, c \ 4
      out &h3C9, c \ 8
  next c

  '' do the tests
  fps0 = xmempoke
  fps1 = xmempokemaped
  fps2 = cmempoke
  fps3 = cmempokedirect
 
  '' free buffers
  mfree map
  mfree blk
  xmfree xblk

  ''print result
  screen 0: width 80
  print "|method       |fps |"
  print " xmem indirect"; fps0 \ SECONDS
  print " xmem mapped  "; fps1 \ SECONDS
  print " cmem indirect"; fps2 \ SECONDS
  print " cmem direct  "; fps3 \ SECONDS

''::::::::::::::::::::::::::::::::::::::
function xmempoke% static
  dim x as integer, y as integer, fps as integer, clr as integer
  dim delay as long, ofs as long, cccc as long

  fps = 0
  delay = timer2 + cint(18.2 * SECONDS)	'' calc the delay in ticks

  do
     ofs = 0
     for y = 0 to 199
         clr = (clr + 1) and 255
         cccc = (clr * 16777216) + (clr * 65536) + (clr * 256&) + clr

         for x = 0 to 319 step 4
             xmpokel xblk + ofs, cccc
             ofs = ofs + 4
         next x
     next y

     xmmove xblk, 64000, &HA0000	'' move buffer to screen

     fps = fps + 1
  loop until (timer2 >= delay)

  xmempoke = fps			'' return fps
end function

''::::::::::::::::::::::::::::::::::::::
function xmempokemaped% static
  dim x as integer, y as integer, fps as integer, clr as integer
  dim delay as long, ofs as long, cccc as long

  xmap xblk, 64000, map			'' map buffer

  fps = 0
  delay = timer2 + cint(18.2 * SECONDS)	'' calc the delay in ticks

  do
     ofs = 0
     for y = 0 to 199
         clr = (clr + 1) and 255
         cccc = (clr * 16777216) + (clr * 65536) + (clr * 256&) + clr

         for x = 0 to 319 step 4
             xmappokel map, ofs, cccc
             ofs = ofs + 4
         next x
     next y

     xmapflush map			'' flush map
     xmmove xblk, 64000, &HA0000	'' move buffer to screen

     fps = fps + 1
  loop until (timer2 >= delay)

  xmempokemaped = fps			'' return fps
end function

''::::::::::::::::::::::::::::::::::::::
function cmempoke% static
  dim x as integer, y as integer, fps as integer, clr as integer
  dim delay as long, ofs as long, cccc as long, lin as long

  lin = fp2lin(blk)			'' get the linear address

  fps = 0
  delay = timer2 + cint(18.2 * SECONDS)	'' calc the delay in ticks

  do
     ofs = 0
     for y = 0 to 199
         clr = (clr + 1) and 255
         cccc = (clr * 16777216) + (clr * 65536) + (clr * 256&) + clr

         for x = 0 to 319 step 4
             xmpokel lin + ofs, cccc
             ofs = ofs + 4
         next x
     next y

     xmmove lin, 64000, &HA0000		'' move buffer to screen

     fps = fps + 1
  loop until (timer2 >= delay)

  cmempoke = fps			'' return fps
end function

''::::::::::::::::::::::::::::::::::::::
function cmempokedirect% static
  dim x as integer, y as integer, fps as integer, clr as integer
  dim delay as long, ofs as long

  def seg = segment(blk)

  fps = 0
  delay = timer2 + cint(18.2 * SECONDS)	'' calc the delay in ticks

  do
     ofs = offset(blk)
     for y = 0 to 199
         clr = (clr + 1) and 255

         for x = 0 to 319 step 4
             poke ofs+0, clr
             poke ofs+1, clr
             poke ofs+2, clr
             poke ofs+3, clr
             ofs = ofs + 4
         next x
     next y

     xmmove fp2lin(blk), 64000, &HA0000	'' move buffer to screen

     fps = fps + 1
  loop until (timer2 >= delay)

  cmempokedirect = fps			'' return fps
end function

