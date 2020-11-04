'' 
'' ugl.bi -- useless graphic lib structs and functions prototypes
''

type BITMAP
  xmin            as long
  ymin            as long
  xmax            as long
  ymax            as long
  wdt             as long
  hgt             as long
  dat             as long
end type

declare sub UGLalloc (seg bmp as BITMAP, _
                      byval wdt as long, _
                      byval hgt as long)

declare sub UGLput   (seg src as BITMAP, _
                      byval x as long, _
                      byval y as long, _
                      seg dst as BITMAP)
