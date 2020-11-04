;; name: dpmiDscAlloc
;; desc: allocate one or more LDT descriptors
;;
;; type: function
;; args: [in] descriptors:integer | descriptors to allocate
;; retn: integer                  | first descriptors's selector (0 if error)
;;
;; decl: dpmiDscAlloc% (byval descriptors as integer)
;;
;; obs.: the selectors can be non-continuous; use dpmiSelInc to access next
;;

;; name: dpmiDscFree
;; desc: free a LDT descriptor previously allocated using dpmiDscAlloc
;;       function
;;
;; type: sub
;; args: [in] selector:integer  | descriptor's selector to free
;; retn: none
;;
;; decl: dpmiDscFree (byval selector as integer)
;;

;; name: dpmiSeg2Dsc
;; desc: convert a real segment to a descriptor
;;
;; type: function
;; args: [in] segm:integer      | segment to convert
;; retn: integer                | sel of the descriptor converted (0 if error)
;;
;; decl: dpmiSeg2Dsc% (byval segm as integer)
;;

;; name: dpmiSelInc
;; desc: get selector increment value
;;
;; type: function
;; args: none
;; retn: integer                | selector increment
;;
;; decl: dpmiSelInc% ()
;;

;; name: dpmiSegBaseGet
;; desc: get a descriptor's segment base
;;
;; type: function
;; args: [in] selector:integer  | descriptor's selector to get
;; retn: long                   | segment base (linear address)
;;
;; decl: dpmiSegBaseGet& (byval selector as integer)
;;

;; name: dpmiSegBaseSet
;; desc: set a descriptor's segment base
;;
;; type: sub
;; args: [in] selector:integer, | descriptor's selector to set
;;            linBase:long      | segment base (linear address)
;; retn: none
;;
;; decl: dpmiSegBaseSet (byval selector as integer,_
;;                       byval linBase as long)
;;

;; name: dpmiSegLimitSet
;; desc: set a descriptor's segment limit (size)
;;
;; type: sub
;; args: [in] selector:integer, | descriptor's selector to set
;;            limit:long        | segment limit (byte or page granular)
;; retn: none
;;
;; decl: dpmiSegLimitSet (byval selector as integer,_
;;                        byval limit as long)
;;

;; name: dpmiDscRgtsSet
;; desc: set a descriptor's access rights
;;
;; type: sub
;; args: [in] selector:integer, | descriptor's selector to set
;;            rights:integer    | access rights
;; retn: none
;;
;; decl: dpmiDscRgtsSet (byval selector as integer,_
;;                       byval rights as integer)
;;

;; name: dpmiCSAlias
;; desc: create a code segment alias descriptor
;;
;; type: function
;; args: [in] selector:integer  | descriptor's selector of type executable
;; retn: integer                | alias sel to a data descriptor (0 if error)
;;
;; decl: dpmiCSAlias% (byval csSel as integer)
;;

;; name: dpmiDscGet
;; desc: get the contents of a descriptor
;;
;; type: sub
;; args: [in] selector:integer  | descriptor's selector to get
;;       [out] dsc:DESCRIPTOR   | descriptor's contents
;; retn: dsc struct filled
;;
;; decl: dpmiDscGet (byval selector as integer,_
;;                   dsc as DESCRIPTOR)
;;

;; name: dpmiDscSet
;; desc: set the contents of a descriptor
;;
;; type: sub
;; args: [in] selector:integer, | descriptor's selector to set
;;            dsc:DESCRIPTOR    | descriptor's contents
;; retn: none
;;
;; decl: dpmiDscSet (byval selector as integer,_
;;                   dsc as DESCRIPTOR)
;;

;; name: dpmiAllocSpcDsc
;; desc: allocate a specific LDT descriptor
;;
;; type: function
;; args: [in] selector:integer  | descriptor's selector to allocate
;; retn: integer                | 0 if error, -1 otherwise
;;
;; decl: dpmiAllocSpcDsc% (selector as integer)
;;

;; name: dpmiGetInfo
;; desc: get info about the DPMI host
;;
;; type: sub
;; args: [out] info:DPMIINFO    | structure to receive the info
;; retn: info struct filled
;;
;; decl: dpmiGetInfo (seg info as DPMIINFO)
;;

;; name: dpmiRegLock
;; desc: lock a specified linear address range of extended memory
;;
;; type: sub
;; args: [in] linBase:long,     | linear base of memory to lock
;;            bytes:long        | number of bytes to lock
;; retn: none
;;
;; decl: dpmiRegLock (byval linBase as long,_
;;                    byval bytes as long)
;;

;; name: dpmiRegUnLock
;; desc: unlock a specified linear address range of extended memory
;;       previously locked using dpmiRegLock function
;;
;; type: sub
;; args: [in] linBase:long,     | linear base of memory to unlock
;;            bytes:long        | number of bytes to unlock
;; retn: none
;;
;; decl: dpmiRegUnLock (byval linBase as long,_
;;                      byval bytes as long)
;;

;; name: dpmiPhysMap
;; desc: map a physical address region of extended memory to
;;       linear address
;;
;; type: sub
;; args: [in] physBase:long,    | physical base of memory to map
;;            bytes:long        | number of bytes to map
;; retn: long                   | lin addrs of memory mapped (used to access)
;;
;; decl: dpmiPhysMap& (byval physBase as long,_
;;                     byval bytes as long)
;;

;; updt: oct/00 [v1ctor]
;; obs.: for more details, see the DPMI specification (doc/dpmi09.txt)

                include common.inc
                include ..\inc\dpmi_wp.inc

.code
;;::::::::::::::
dpmiDscAlloc    proc    descriptors:word

                mov     cx, descriptors
                mov     ax, DPMI_DSC_ALLOC
                INTPM   DPMI_INT
                jc      @@error

@@exit:         ret

@@error:        xor     ax, ax
                jmp     short @@exit
dpmiDscAlloc    endp

;;::::::::::::::
dpmiDscFree     proc    selector:word

                mov     bx, selector
                mov     ax, DPMI_DSC_FREE
                INTPM   DPMI_INT

                ret
dpmiDscFree     endp

;;::::::::::::::
dpmiSeg2Dsc     proc    segm:word

                mov     bx, segm
                mov     ax, DPMI_SEG2DSC
                INTPM   DPMI_INT
                jc      @@error

@@exit:         ret

@@error:        xor     ax, ax
                jmp     short @@exit
dpmiSeg2Dsc     endp

;;::::::::::::::
dpmiSelInc      proc

                mov     ax, DPMI_SEL_INC
                INTPM   DPMI_INT

                ret
dpmiSelInc      endp

;;::::::::::::::
dpmiSegBaseGet  proc    selector:word

                mov     bx, selector
                mov     ax, DPMI_SEG_BASE_GET
                INTPM   DPMI_INT
                jc      @@error

                mov     ax, dx
                mov     dx, cx

@@exit:         ret

@@error:        xor     ax, ax
                xor     dx, dx
                jmp     short @@exit
dpmiSegBaseGet  endp

;;::::::::::::::
dpmiSegBaseSet  proc    selector:word,\
                        lin_base:dword

                mov     bx, selector
                mov     cx, W lin_base+2
                mov     dx, W lin_base+0
                mov     ax, DPMI_SEG_BASE_SET
                INTPM   DPMI_INT

                ret
dpmiSegBaseSet  endp

;;::::::::::::::
dpmiSegLimitSet proc    selector:word,\
                        limit:dword

                mov     bx, selector
                mov     cx, W limit+2
                mov     dx, W limit+0
                mov     ax, DPMI_SEG_LIM_SET
                INTPM   DPMI_INT

                ret
dpmiSegLimitSet endp

;;::::::::::::::
dpmiDscRgtsSet  proc    selector:word,\
                        rights:word

                mov     bx, selector
                mov     cx, rights
                mov     ax, DPMI_SEG_RGTS_SET
                INTPM   DPMI_INT

                ret
dpmiDscRgtsSet  endp

;;::::::::::::::
dpmiCSAlias     proc    cs_sel:word

                mov     bx, cs_sel
                mov     ax, DPMI_CS_ALIAS
                INTPM   DPMI_INT
                jc      @@error

@@exit:         ret

@@error:        xor     ax, ax
                jmp     short @@exit
dpmiCSAlias     endp

;;::::::::::::::
dpmiDscGet      proc    selector:word,\
                        dsc:near ptr DESCRIPTOR

                mov     bx, selector
                movzx   edi, dsc
                mov     ax, DPMI_DSC_GET
                INTPM   DPMI_INT

                ret
dpmiDscGet      endp

;;::::::::::::::
dpmiDscSet      proc    selector:word,\
                        dsc:near ptr DESCRIPTOR

                mov     bx, selector
                movzx   edi, dsc
                mov     ax, DPMI_DSC_SET
                INTPM   DPMI_INT

                ret
dpmiDscSet      endp

;;::::::::::::::
dpmiAllocSpcDsc proc    selector:word

                mov     bx, selector
                mov     ax, DPMI_SPCDSC_ALLOC
                INTPM   DPMI_INT
                jc      @@error

                mov     ax, TRUE

@@exit:         ret

@@error:        xor     ax, ax
                jmp     short @@exit
dpmiAllocSpcDsc endp

;;::::::::::::::
dpmiGetInfo     proc    uses di es,\
                        info:far ptr DPMI_INFO

                mov     ax, DPMI_GET_VER
                INTPM   DPMI_INT

                les     di, info
                mov     es:[di].DPMI_INFO.version, ax
                mov     es:[di].DPMI_INFO.flags, bx
                and     cx, 0FFh
                mov     es:[di].DPMI_INFO.processor, cx
                mov     es:[di].DPMI_INFO.pic_base, dx

                ret
dpmiGetInfo     endp

;;::::::::::::::
dpmiRegLock     proc    uses di si,\
                        lin_base:dword,\
                        bytes:dword

                mov     cx, W lin_base+0
                mov     bx, W lin_base+2
                mov     di, W bytes+0
                mov     si, W bytes+2
                mov     ax, DPMI_REG_LOCK
                INTPM   DPMI_INT

                ret
dpmiRegLock     endp

;;::::::::::::::
dpmiRegUnLock   proc    uses di si,\
                        lin_base:dword,\
                        bytes:dword

                mov     cx, W lin_base+0
                mov     bx, W lin_base+2
                mov     di, W bytes+0
                mov     si, W bytes+2
                mov     ax, DPMI_REG_UNLOCK
                INTPM   DPMI_INT

                ret
dpmiRegUnLock   endp

;;::::::::::::::
dpmiPhysMap     proc    uses di si,\
                        phys_base:dword,\
                        bytes:dword

                mov     cx, W phys_base+0
                mov     bx, W phys_base+2
                mov     di, W bytes+0
                mov     si, W bytes+2
                mov     ax, DPMI_PHYS_MAP
                INTPM   DPMI_INT
                mov     ax, cx
                mov     dx, bx

                ret
dpmiPhysMap     endp
                end
