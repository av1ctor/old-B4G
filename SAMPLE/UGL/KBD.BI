''
'' kbd.bi --
''
type KEYBOARD
  last       as integer
  esc        as integer
  npd        as string * 20
  f000       as string * 04
  bspc       as integer
  tabk       as integer
  f001       as string * 24
  enter      as integer
  ctrl       as integer
  f002       as string * 24
  lfsh       as integer
  f003       as string * 22
  rgsh       as integer
  prt        as integer
  alt        as integer
  spck       as integer
  cap        as integer
  f1         as integer
  f2         as integer
  f3         as integer
  f4         as integer
  f5         as integer
  f6         as integer
  f7         as integer
  f8         as integer
  f9         as integer
  f10        as integer
  num        as integer
  scrl       as integer
  home       as integer
  up         as integer
  pgup       as integer
  min        as integer
  left       as integer
  mid        as integer
  right      as integer
  plus       as integer
  endk       as integer
  down       as integer
  pgdw       as integer
  ins        as integer
  del        as integer
  f004       as string * 06
  f11        as integer
  f12        as integer
  f005       as string * 80
end type

declare sub kbdinit (seg kbd as KEYBOARD)
declare sub kbddone ()
