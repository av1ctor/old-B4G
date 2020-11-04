''
'' ugl_test.bas -- useless test for the useless graphic library
''
'' to compile: execute the mk.bat file
''

defint a-z
'$include: '..\..\bi\b4g.bi'
'$include: 'ugl.bi'
'$include: 'kbd.bi'

const errormsg = "ERROR! "

const BMPWDT   = 320*10
const BMPHGT   = 200*10
const TILES    = 7
const TILESIZE = 32
const STP      = TILESIZE \ 8

type PATTERN
  layer         as integer
  wdt           as integer
  hgt           as integer
  dat           as integer
end type

declare function RawLoad% (array() as any, flname as string, bytes as long)
declare sub      PalSet   (pal() as any)


  dim kbd as KEYBOARD

  dim bmp as BITMAP, _
      tile(0 to TILES-1) as BITMAP, _
      video as BITMAP

  dim tiles(0 to (TILESIZE-1)\2, 0 to TILESIZE-1, 0 to TILES-1) as integer

  dim pal(0 to 767) as integer

  dim patt(0 to 9) as PATTERN
  dim pattdat(0 to 999) as integer

  if (b4ginit > 0) then
     print erromsg;
     print "cannot switch to pmode"
     end
  end if

  '' load our palette
  if (not RawLoad(pal(), "ugl_test.pal", 256 * 3)) then
     print erromsg;
     print "opening palette file"
     end
  end if

  '' load the tiles (stolen from a PASCAL tile demo i saw; i don't
  ''                 remember the author's name, but anyway...sorry :})
  if (not RawLoad(tiles(), "ugl_test.tls", TILES * TILESIZE * TILESIZE)) then
     print erromsg;
     print "opening tiles file"
     end
  end if

  '' allocate the output bitmap
  UGLalloc bmp, BMPWDT, BMPHGT
  if (bmp.dat = 0) then
     print errormsg;
     print "not enough memory"
     end
  end if

  '' define video bitmap
  video.wdt  = 320
  video.hgt  = 200
  video.xmin = 0
  video.ymin = 0
  video.xmax = video.wdt - 1
  video.ymax = video.hgt - 1
  video.dat = &hA0000

  '' define tile bitmaps
  for t = 0 to TILES-1
      tile(t).wdt  = TILESIZE
      tile(t).hgt  = TILESIZE
      tile(t).xmin = 0
      tile(t).ymin = 0
      tile(t).xmax = TILESIZE - 1
      tile(t).ymax = TILESIZE - 1
      tile(t).dat = linearex(tiles(0, 0, t))
  next t
 
  '' read patterns
  restore patterns
  read totpatts
  d = 0
  for p = 0 to totpatts - 1
      read patt(p).layer, patt(p).wdt, patt(p).hgt
      patt(p).dat = d
      for i = 1 to patt(p).wdt * patt(p).hgt
          read pattdat(d)
          d = d + 1
      next i
  next p

  randomize timer

  '' fill bmp with tile(0) (ocean)
  for y = 0 to BMPHGT - 1 step TILESIZE      
      for x = 0 to BMPWDT - 1 step TILESIZE
          UGLput tile(0), x, y, bmp
      next x
  next y

  '' fill with patterns
  const MAXLAYERS = 3
  const MAXATTEMPTS = 64 \ MAXLAYERS

  for l = 1 to MAXLAYERS
      for i = 1 to MAXATTEMPTS

          p = cint(rnd * (totpatts-1))
          if (patt(p).layer = l) then

             inix = cint(rnd * BMPWDT - (patt(p).wdt*TILESIZE\2)) and (not TILESIZE-1)
             y = cint(rnd * BMPHGT - (patt(p).hgt*TILESIZE\2)) and (not TILESIZE-1)

             d = patt(p).dat
             for h = 1 to patt(p).hgt
                 x = inix
                 for w = 1 to patt(p).wdt
                     t = pattdat(d)
                     if (t <> 0) then UGLput tile(t), x, y, bmp
                     d = d + 1
                     x = x + TILESIZE
                 next w
                 y = y + TILESIZE
             next h
          end if

      next i
  next l

  screen 13
  line (video.xmin-1, video.ymin-1)- _
       (video.xmax+1, video.ymax+1), _
       128, b

  PalSet pal()                          '' setup a palette for tiles

  kbdinit kbd                           '' init new keyboard handler

  '' show bmp on screen
  x = 160-(BMPWDT\2)
  y = 100-(BMPHGT\2)
  moved = -1
  do
      if (kbd.left) then
         if (x + STP <= video.xmin) then
            x = x + STP
            moved = -1
         end if

      elseif (kbd.right) then
         if (x + BMPWDT - STP => video.xmax) then
            x = x - STP
            moved = -1
         end if
      end if

      if (kbd.up) then
         if (y + STP <= video.ymin) then
            y = y + STP
            moved = -1
         end if

      elseif (kbd.down) then
         if (y + BMPHGT - STP => video.ymax) then
            y = y - STP
            moved = -1
         end if
     end if

     if (moved <> 0) then
        UGLput bmp, x, y, video
        moved = 0
     end if
  loop until (kbd.esc)

  kbddone                               '' restore old keyboard handler

patterns:
data 3
'' island
data 1, 12, 7
data 0,0,0,0,4,4,4,0,0,0,0,0
data 0,0,4,4,4,4,4,4,4,0,0,0
data 0,4,4,4,4,4,4,4,4,4,4,0
data 4,4,4,4,4,4,4,4,4,4,4,4
data 4,4,4,4,4,4,4,4,4,4,4,4
data 0,0,4,4,4,4,4,4,4,4,4,0
data 0,0,0,4,4,4,4,4,4,0,0,0
'' little island
data 2, 8, 6
data 0,0,3,3,3,0,0,0
data 0,3,3,3,3,3,0,0
data 3,3,3,3,3,3,3,0
data 0,3,3,3,3,3,3,0
data 0,3,3,3,3,3,0,0
data 0,0,3,3,3,0,0,0
'' UGL text
data 3, 14, 4
data 6,0,0,6,0,0,6,6,6,0,6,0,0,0
data 6,0,0,6,0,6,0,0,0,0,6,0,0,0
data 6,0,0,6,0,6,0,0,6,0,6,0,0,6
data 0,6,6,0,0,0,6,6,6,0,0,6,6,0

'':::
function RawLoad% (array(), flname as string, bytes as long)
  dim xf as XFILE

  if (not xfopen(xf, flname, XF4READ, 0)) then exit function
  if (xfread(xf, linearex(array(0)), bytes) <> bytes) then exit function
  xfclose xf

  RawLoad = -1                          '' return ok
end function

'':::
sub PalSet (pal())
  dim ofs as integer, i as integer

  def seg = varseg(pal(0))
  ofs = varptr(pal(0))

  out &h3C8, 0
  for i = 0 to 255
      out &h3C9, peek(ofs+0)
      out &h3C9, peek(ofs+1)
      out &h3C9, peek(ofs+2)
      ofs = ofs + 3
  next i
end sub
