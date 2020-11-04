'' 
'' showdesc.bas -- prints a list of descriptors contents
''

defint a-z
'$include: '..\bi\b4g.bi'

const FIRSTSEL = 16*8
const SELS     = 8

  dim dsc as DESCRIPTOR
  dim dscbase as long, dsclimit as long
  dim dscstt as integer, dscstttb(0 to 1) as string
  dim dscdpl as integer
  dim dsctype as integer, dsctypetb(0 to 15) as string
  dim dscmode as integer, dscmodetb(0 to 1) as integer
  dim dscgran as integer, dscgrantb(0 to 1) as string

  '' try switch to 32-bit protected mode
  if (b4ginit > 0) then
     print "ERROR! cannot switch to pmode"     
     end
  end if

  '':::

  restore dscsttdata
  for i = 0 to 1
      read dscstttb(i)
  next i

  restore dsctypedata
  for i = 0 to 15
      read dsctypetb(i)
  next i

  restore dscgrandata
  for i = 0 to 1
      read dscgrantb(i)
  next i

  restore dscmodedata
  for i = 0 to 1
      read dscmodetb(i)
  next i

  for i = FIRSTSEL to FIRSTSEL + ((SELS - 1) * 8) step 8

      dpmiDscGet i or 7, dsc                    '' get from LDT; CPL=3

      dscbase  = cvl(dsc.base023 + chr$(0)) or (asc(dsc.base2431) * 16777216)
      dsclimit = (dsc.limit015 or _
                 ((asc(dsc.lim1619MdGr) and &h000F%) * 65536) _
                 ) and &h000FFFFF&
      dsctype  = (asc(dsc.typDplP) and &h1E) \ 2
      dscdpl   = (asc(dsc.typDplP) and &h60) \ 32
      dscstt   = (asc(dsc.typDplP) and &h80) \ 128
      dscmode  = (asc(dsc.lim1619MdGr) and &h40) \ 64
      dscgran  = (asc(dsc.lim1619MdGr) and &h80) \ 128

      if ((dsclimit <> 0)) then
         print
         print using "descriptor:## selector:&"; i \ 8; hex$(i)
         print using "base:&  limit:&  dpl:#  status:&"; _
                     hex$(dscbase); hex$(dsclimit); dscdpl; dscstttb(dscstt)
         print using "type:&  mode:##--bit  granularity:&"; _
                     dsctypetb(dsctype); dscmodetb(dscmode); dscgrantb(dscgran)
      end if
  next i

  '':::

  b4gdone                               '' only need when running in the IDE


dscsttdata:
data "ABSENT","PRESENT"

dsctypedata:
data "UKN","UKN","UKN","UKN"
data "UKN","UKN","UKN","UKN"
data "READ","READ/WRITE","READ, EXPAND DOWN","READ/WRITE, EXPAND DOWN"
data "EXECUTE","EXECUTE/READ","EXECUTE, CONFORMING","EXECUTE/READ, CONFORMING"

dscmodedata:
data 16,32

dscgrandata:
data "BYTE","PAGE"
