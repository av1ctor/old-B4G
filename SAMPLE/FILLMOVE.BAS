'' 
'' fillmove.bas -- gets all free extended memory and use it as
''                 virtual screen mode 13h pages
''

defint a-z
'$include: '..\bi\b4g.bi'

declare sub fillmove ()
  
  if (b4ginit > 0) then
     print "ERROR! cannot switch to pmode""
     end
  end if

  fillmove

  screen 0: width 80
  print "largest free xmem block avail:"; xmavail; "bytes"

  b4gdone

''::::::::::::::::::
sub fillmove static
  dim pages as integer, buffer as long, page as long

  '' pages= free extended memory \ screen mode 13h size
  pages = xmavail \ 64000

  '' allocate all free memory to use as pages
  buffer = xmalloc(xmavail)
  if (buffer = 0) then
     print "error!!!"
     exit sub
  end if

  '' fill it
  page = 0
  for c = 0 to pages - 1
      xmfill buffer + page, 64000, c
      page = page + 64000                       '' next page
  next c

  screen 13
 
  '' move the pages to screen (A0000h)
  page = 0
  for p = 0 to pages - 1
      xmmove buffer + page, 64000, &hA0000
      page = page + 64000                       '' next page
  next p

  '' erase it
  xmfree buffer
end sub

