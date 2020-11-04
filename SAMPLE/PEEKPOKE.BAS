'' 
'' peekpoke.bas -- shows how to peek and poke to extended memory 
''                 direct or using mapped memory
''

defint a-z
'$include: '..\bi\b4g.bi'

const errorstr = "ERROR! "

type MYTYPE
  a     as integer
  b     as integer
  c     as integer
end type

const mystring = "string"

  dim xblk as long
  dim map as long
  dim mystruct as MYTYPE

  '' try switch to 32-bit protected mode
  if (b4ginit > 0) then
     print errorstr;
     print "cannot switch to pmode"
     end
  end if

  '' alloc a block of extended memory and a map
  xblk = xmalloc(32767)
  map = xmapmake(1024)
  if ((xblk = 0) or (map = 0)) then
     print errorstr;
     print "not enough memory"
     end
  end if

  ''::: peek and poke direct to extended memory

  mystruct.a = 1: mystruct.b = 2: mystruct.c = 3

  xmpokeb   xblk + 0, 127
  xmpokei   xblk + 0 + 1, 32767
  xmpokel   xblk + 0 + 1 + 2, 1111111111
  xmpokes   xblk + 0 + 1 + 2 + 4, 1.1!
  xmpoked   xblk + 0 + 1 + 2 + 4 + 4, 2.2#
  xmpokestr xblk + 0 + 1 + 2 + 4 + 4 + 8, mystring
  xmpoket   xblk + 0 + 1 + 2 + 4 + 4 + 8 + len(mystring), mystruct, len(mystruct)

  mystruct.a = 0: mystruct.b = 0: mystruct.c = 0

  print xmpeekb  (xblk + 0);
  print xmpeeki  (xblk + 0 + 1);
  print xmpeekl  (xblk + 0 + 1 + 2);
  print xmpeeks  (xblk + 0 + 1 + 2 + 4);
  print xmpeekd  (xblk + 0 + 1 + 2 + 4 + 4);
  print xmpeekstr(xblk + 0 + 1 + 2 + 4 + 4 + 8, len(mystring));
  xmpeekt mystruct, xblk + 0 + 1 + 2 + 4 + 4 + 8 + len(mystring), len(mystruct)
  print mystruct.a; mystruct.b; mystruct.c

  '':::

  xmfill xblk, 32767, 0                         '' clear block

  ''::: peek and poke using a mapped memory

  mystruct.a = 1: mystruct.b = 2: mystruct.c = 3

  xmap xblk, 32767, map                         '' map block

  xmappokeb   map, 0, 127
  xmappokei   map, 0 + 1, 32767
  xmappokel   map, 0 + 1 + 2, 1111111111
  xmappokes   map, 0 + 1 + 2 + 4, 1.1!
  xmappoked   map, 0 + 1 + 2 + 4 + 4, 2.2#
  xmappokestr map, 0 + 1 + 2 + 4 + 4 + 8, mystring
  xmappoket   map, 0 + 1 + 2 + 4 + 4 + 8 + len(mystring), mystruct, len(mystruct)

  mystruct.a = 0: mystruct.b = 0: mystruct.c = 0

  print xmappeekb  (map, 0);
  print xmappeeki  (map, 0 + 1);
  print xmappeekl  (map, 0 + 1 + 2);
  print xmappeeks  (map, 0 + 1 + 2 + 4);
  print xmappeekd  (map, 0 + 1 + 2 + 4 + 4);
  print xmappeekstr(map, 0 + 1 + 2 + 4 + 4 + 8, len(mystring));
  xmappeekt mystruct, map, 0 + 1 + 2 + 4 + 4 + 8 + len(mystring), len(mystruct)
  print mystruct.a; mystruct.b; mystruct.c

  '':::

  b4gdone                               '' only need when running in the IDE

