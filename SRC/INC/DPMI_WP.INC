;;
;; DPMI API wrapper
;;

ifndef          __dpmi_wp_inc__
                __dpmi_wp_inc__ equ 1

DPMI_INFO       struct
                version         word    ?
                flags           word    ?
                processor       word    ?
                pic_base        word    ?
DPMI_INFO       ends

                ;; globals ::::::

                ;; dpmiDscAlloc% (byval descriptors as integer)
                dpmiDscAlloc    proto :word

                ;; dpmiDscFree  (byval selector as integer)
                dpmiDscFree     proto :word

                ;; dpmiSeg2Dsc% (byval segm as integer)
                dpmiSeg2Dsc     proto :word

                ;; dpmiSelInc%  ()
                dpmiSelInc      proto

                ;; dpmiSegBaseGet& (byval selector as integer)
                dpmiSegBaseGet  proto :word

                ;; dpmiSegBaseSet (byval selector as integer,_
                ;;                 byval linBase as long)
                dpmiSegBaseSet  proto :word, :dword

                ;; dpmiSegLimitSet (byval selector as integer,_
                ;;                  byval limit as long)
                dpmiSegLimitSet proto :word, :dword

                ;; dpmiDscRgtsSet (byval selector as integer,_
                ;;                 byval rights as integer)
                dpmiDscRgtsSet  proto :word, :word

                ;; dpmiCSAlias% (byval csSel as integer)
                dpmiCSAlias     proto :word

                ;; dpmiDscGet   (byval selector as integer,_
                ;;               dsc as DESCRIPTOR)
                dpmiDscGet      proto :word, :near ptr DESCRIPTOR

                ;; dpmiDscSet   (byval selector as integer,_
                ;;               dsc as DESCRIPTOR)
                dpmiDscSet      proto :word, :near ptr DESCRIPTOR

                ;; dpmiAllocSpcDsc% (selector as integer)
                dpmiAllocSpcDsc proto :word

                ;; dpmiGetInfo  (seg info as DPMIINFO)
                dpmiGetInfo     proto :far ptr DPMI_INFO

                ;; dpmiRegLock  (byval linBase as long,_
                ;;               byval bytes as long)
                dpmiRegLock     proto :dword, :dword

                ;; dpmiRegUnLock (byval linBase as long,_
                ;;                byval bytes as long)
                dpmiRegUnLock   proto :dword, :dword

                ;; dpmiPhysMap& (byval physBase as long,_
                ;;               byval bytes as long)
                dpmiPhysMap     proto :dword, :dword
endif   ;; __dpmi_wp_inc__
