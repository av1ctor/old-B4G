''
'' vbe2.bas -- enable the LFB w/ VBE 2.0+
''
defint a-z
'$include: '..\..\bi\b4g.bi'
'$include: 'c:\prg\cmp\qb\include\qb.bi'
'$include: 'vbe2.bi'

type VBE2INFOBLOCK
     VbeSignature        as string * 4
     VbeVersion          as integer
     OemStringPtr        as long
     Capabilities        as string * 4
     VideoModePtr        as long
     TotalMemory         as integer

     OemSoftwareRev      as integer
     OemVendorNamePtr    as long
     OemProductNamePtr   as long
     OemProductRevPtr    as long
     Reserved            as string * 222
     OemData             as string * 256
end type

type VBE2MODEINFOBLOCK     
     ModeAttributes      as integer
     WinAAttributes      as string * 1
     WinBAttributes      as string * 1
     WinGranularity      as integer
     WinSize             as integer
     WinASegment         as integer
     WinBSegment         as integer
     WinFuncPtr          as long
     BytesPerScanLine    as integer

     XResolution         as integer
     YResolution         as integer
     XCharSize           as string * 1
     YCharSize           as string * 1
     NumberOfPlanes      as string * 1
     BitsPerPixel        as string * 1
     NumberOfBanks       as string * 1
     MemoryModel         as string * 1
     BankSize            as string * 1
     NumberOfImagePages  as string * 1
     Reserved            as string * 1
                      
     RedMaskSize         as string * 1
     RedFieldPosition    as string * 1
     GreenMaskSize       as string * 1
     GreenFieldPosition  as string * 1
     BlueMaskSize        as string * 1
     BlueFieldPosition   as string * 1
     RsvdMaskSize        as string * 1
     RsvdFieldPosition   as string * 1
     DirectColorModeInfo as string * 1

     PhysBasePtr         as long
     OffScreenMemOffset  as long
     OffScreenMemSize    as integer
     Reserved2           as string * 206
end type

dim shared vbe2info as VBE2INFOBLOCK

dim shared vbe2initialized as integer, _
           vbe2modechanged as integer, _
           vbe2initialmode as integer, _
           vbe2bpsl as integer

'':::
function vbe2init% static
  dim rmregs as RegTypeX

  '' not initialized?
  if (not vbe2initialized) then
     vbe2init = 0                          '' assume no VBE

     '' get VBE info block
     vbe2info.VbeSignature = "VBE2"        '' request VBE 2.0 info

     rmregs.es = varseg(vbe2info)
     rmregs.di = varptr(vbe2info)
     rmregs.ax = &h4F00
     interruptX &h10, rmregs, rmregs

     '' function not supported (al <> 4Fh)?
     if ((rmregs.ax and &h00FF) <> &h4F) then exit function

     '' not VESA?
     if (vbe2info.VbeSignature <> "VESA") then exit function

     '' version < 2.0?
     if (vbe2info.VbeVersion < &h200) then exit function
     print hex$(vbe2info.VbeVersion)

     '' get current mode
     rmregs.ax = &h0F00
     interruptX &h10, rmregs, rmregs
     vbe2initialmode = rmregs.ax and &h00FF

     vbe2initialized = -1
  end if

  vbe2init = -1                         '' return ok
end function

'':::
sub vbe2done static
  dim rmregs as RegTypeX

  '' initialized?
  if (vbe2initialized) then
     vbe2initialized = 0

     '' mode changed?
     if (vbe2modechanged) then
        vbe2modechanged = 0

        '' restore old mode
        rmregs.ax = vbe2initialmode
        interruptX &h10, rmregs, rmregs
     end if
  end if
end sub

'':::
function vbe2setmode& (xRes as integer, yRes as integer)
  dim rmregs as RegTypeX, pmregs as REGS386
  dim lin as long, mode as integer
  dim vbe2modeinfo as VBE2MODEINFOBLOCK

  vbe2setmode = 0                               '' assume error

  '' already initialized?
  if (not vbe2initialized) then exit function

  '' scan the VBE supported modes list
  lin = fp2lin(vbe2info.VideoModePtr)           '' need linear to use xmpeeki
  mode = xmpeeki(lin)
  do while (mode <> -1)                         '' stop (mode = -1)?

     '' get mode info
     rmregs.es = varseg(vbe2modeinfo)
     rmregs.di = varptr(vbe2modeinfo)
     rmregs.cx = mode
     rmregs.ax = &h4F01
     interruptX &h10, rmregs, rmregs
     '' function not supported (al <> 4Fh)?
     if ((rmregs.ax and &h00FF) <> &h4F) then exit function

     '' check if this mode match
     if (asc(vbe2modeinfo.NumberOfPlanes) = 1) then
        if (asc(vbe2modeinfo.BitsPerPixel) = 8) then
           if (vbe2modeinfo.XResolution = xRes) then
              if (vbe2modeinfo.YResolution = yRes) then

                '' LFB available?
                if ((vbe2modeinfo.ModeAttributes and &h80) = 0) then exit function

                '' try request this mode w/ LFB enabled
                rmregs.bx = mode or &h4000        '' ask for LFB
                rmregs.ax = &h4F02
                interruptX &h10, rmregs, rmregs
                '' error (ah <> 0)?
                if ((rmregs.ax and &hFF00) <> 0) then exit function

                vbe2modechanged = -1              '' alert vbe2done

                vbe2bpsl = vbe2modeinfo.BytesPerScanLine

                '' now, map the frame buffer (using DPMI)
                vbe2setmode = dpmiPhysMap(vbe2modeinfo.PhysBasePtr, _
                                          vbe2info.TotalMemory * 64 * 1024&)
                exit function
             end if
           end if
       end if
     end if

     lin = lin + 2                               '' try next
     mode = xmpeeki(lin)                         '' /
  loop
end function

'':::
function vbe2getbpsl% static
  vbe2getbpsl = vbe2bpsl
end function
