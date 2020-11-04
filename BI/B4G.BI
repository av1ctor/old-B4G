''
''                   0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
''                   0                                   0
''                   0  000000      00    00    000000   0  
''                   0  00   00    00   0 00   00        0  
''                   0  00 000    00   0  00  00    000  0  
''                   0  00   00   00  000000  00     00  0  
''                   0  00   00  00       00   00    00  0  
''                   0  000000  00        00     0000    0
''                   0  BASIC four gigabytes  ver1E-32b  0
''                   0                                   0  
''                   0      copyleft Oct/2000 by v1ctor  0  
''                   0           [av1ctor@yahoo.com.br]  0  
''                   0             none rights reserved  0  
''                   0                                   0
''                   0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
''                           ABSOLUTELY NO WARRANTY
''
''     free for use in commercial ;), shareware and freeware applications
''

''
'' CORE -- constants, structs and functions prototypes for CORE module
''
'' b4ginit errors:
const B4G.ERROR.HOST = 1
const B4G.ERROR.BIT  = 2
const B4G.ERROR.MEM  = 3
const B4G.ERROR.SWT  = 4

''
type REGS386
     eax          as long
     ebx          as long
     ecx          as long
     edx          as long
     edi          as long
     esi          as long
     ebp          as long
     ds           as integer
     es           as integer
     flags        as integer
end type

type DESCRIPTOR
     limit015     as integer
     base023      as string * 3
     typDplP      as string * 1
     lim1619MdGr  as string * 1
     base2431     as string * 1
end type

type DPMIINFO
     version      as integer
     flags        as integer
     processor    as integer
     picBase      as integer
end type

''
declare function b4ginit%     ()
declare sub      b4gdone      ()
''
declare sub      interrupt386  (byval intnum as integer, _
                                seg regs as REGS386)
declare sub      interruptx386 (byval intnum as integer, _
                                seg regs as REGS386)
''
declare function dpmiDscAlloc%    (byval descriptors as integer)
declare sub      dpmiDscFree      (byval selector as integer)
declare function dpmiSeg2Dsc%     (byval segm as integer)
declare function dpmiSelInc%      ()
''
declare function dpmiSegBaseGet&  (byval selector as integer)
declare sub      dpmiSegBaseSet   (byval selector as integer, _
                                   byval linBase as long)
declare sub      dpmiSegLimitSet  (byval selector as integer, _
                                   byval limit as long)
declare sub      dpmiDscRgtsSet   (byval selector as integer, _
                                   byval rights as integer)
''
declare function dpmiCSAlias%     (byval csSel as integer)
''
declare sub      dpmiDscGet       (byval selector as integer, _
                                   dsc as DESCRIPTOR)
declare sub      dpmiDscSet       (byval selector as integer, _
                                   dsc as DESCRIPTOR)
declare function dpmiAllocSpcDsc% (selector as integer)
''
declare sub      dpmiGetInfo      (seg info as DPMIINFO)

declare sub      dpmiRegLock      (byval linBase as long, _
                                   byval bytes as long)
declare sub      dpmiRegUnLock    (byval linBase as long, _
                                   byval bytes as long)
''
declare function dpmiPhysMap&     (byval physBase as long, _
                                   byval bytes as long)

''
'' MEM -- functions prototypes for MEM module
''
declare function malloc&   (byval bytes as long)
declare function mrealloc% (seg farptr as long, _
                            byval bytes as long)
declare sub      mfree     (seg farptr as long)
declare function mavail&   ()
''
declare function segment%  alias "_segment" (byval fptr as long)
declare function offset&   alias "_offset"  (byval fptr as long)
''
declare function farptr&   (byval segm as integer, _
                            byval offs as integer)
declare function farptrex& alias "farptr" (seg array as any)

''
'' XFILE -- constants, structs and functions prototypes for XFILE module
''
'' open modes:
const XF4READ   = 1
const XF4WRITE  = 2
const XF4CREATE = 4
const XF4APPEND = 8

'' seek origins:
const XFSSTART   = 0
const XFSCURRENT = 1
const XFSEND     = 2

''
type XFILE
  prv             as long
  nxt             as long
  handle          as integer
  mode            as integer
  state           as integer
  buffer          as long
  buffsize        as long
end type

''
declare function xfopen%  (seg xf as XFILE, _
                           flname as string, _
                           byval mode as integer, _
                           byval buffSize as long)
''
declare sub      xfclose  (seg xf as XFILE)

''
declare function xfread&  (seg xf as XFILE, _
                           byval dst as long, _
                           byval bytes as long)
''
declare function xfwrite& (seg xf as XFILE, _
                           byval src as long, _
                           byval bytes as long)

''
declare function xfseek&  (seg xf as XFILE, _
                           byval origin as integer, _
                           byval bytes as long)
''
declare function xfpos&   (seg xf as XFILE)
''
declare function xfsize&  (seg xf as XFILE)
''
declare sub      xfflush  (seg xf as XFILE)

''
'' XMAP -- functions prototypes for XMAP module
''
declare function xmapmake&    (byval size as long)
declare sub      xmap         (byval lin as long, _
                               byval bytes as long, _
                               byval map as long)
declare sub      xmapflush    (byval map as long)
declare sub      xmapinval    (byval map as long)
''
declare function xmappeekb%   (byval map as long, _
                               byval ofs as long)
declare function xmappeeki%   (byval map as long, _
                               byval ofs as long)
declare function xmappeekl&   (byval map as long, _
                               byval ofs as long)
declare function xmappeeks!   (byval map as long, _
                               byval ofs as long)
declare function xmappeekd#   (byval map as long, _
                               byval ofs as long)
declare function xmappeekstr$ (byval map as long, _
                               byval ofs as long, _
                               byval bytes as integer)
declare sub      xmappeekt    (seg struct as any, _
                               byval map as long, _
                               byval ofs as long, _
                               byval bytes as integer)
''
declare sub      xmappokeb    (byval map as long, _
                               byval ofs as long, _
                               byval value as integer)
declare sub      xmappokei    (byval map as long, _
                               byval ofs as long, _
                               byval value as integer)
declare sub      xmappokel    (byval map as long, _
                               byval ofs as long, _
                               byval value as long)
declare sub      xmappokes    alias "xmappokel" (byval map as long, _
                               byval ofs as long, _
                               byval value as single)
declare sub      xmappoked    (byval map as long, _
                               byval ofs as long, _
                               byval value as double)
declare sub      xmappokestr  (byval map as long, _
                               byval ofs as long, _
                               strg as string)
declare sub      xmappoket    (byval map as long, _
                               byval ofs as long, _
                               seg struct as any, _
                               byval bytes as integer)

''
'' XMEM -- functions prototypes for XMEM module
''
declare function linear&    (byval segm as integer, _
                             byval offs as integer)
declare function fp2lin&    alias "linear" (byval fptr as long)
declare function linearex&  alias "linear" (seg array as any)
''
declare function xmalloc&   (byval bytes as long)
declare function xmcalloc&  (byval bytes as long)
declare function xmrealloc% (seg blk as long, _
                             byval bytes as long)
declare sub      xmfree     (seg blk as long)
declare function xmavail&   ()
''
declare sub      xmfill     (byval blk as long, _
                             byval bytes as long, _
                             byval char as integer)
declare sub      xmmove     (byval src as long, _
                             byval bytes as long, _
                             byval dst as long)
declare sub      xmmovefill (byval src as long, _
                             byval bytes as long, _
                             byval dst as long, _
                             byval char as integer)
''
declare function xmpeekb%   (byval src as long)
declare function xmpeeki%   (byval src as long)
declare function xmpeekl&   (byval src as long)
declare function xmpeeks!   (byval src as long)
declare function xmpeekd#   (byval src as long)
declare function xmpeekstr$ (byval src as long, _
                             byval bytes as integer)
declare sub      xmpeekt    (seg struct as any, _
                             byval src as long, _
                             byval bytes as integer)
''
declare sub      xmpokeb    (byval dst as long, _
                             byval value as integer)
declare sub      xmpokei    (byval dst as long, _
                             byval value as integer)
declare sub      xmpokel    (byval dst as long, _
                             byval value as long)
declare sub      xmpokes    alias "xmpokel" (byval dst as long, _
                             byval value as single)
declare sub      xmpoked    (byval dst as long, _
                             byval value as double)
declare sub      xmpokestr  (byval dst as long, _
                             strg as string)
declare sub      xmpoket    (byval dst as long, _
                             seg struct as any, _
                             byval bytes as integer)
