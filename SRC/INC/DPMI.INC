;;
;; dpmi.inc -- some DPMI host services and struct
;;

ifndef          __dpmi_inc__
                __dpmi_inc__    equ 1

                include regs.inc

                DPMI_INT                equ 0031h
                DPMI_MD_SWITCH_PTR_GET  equ 1687h
                DPMI_DSC_ALLOC          equ 0000h
                DPMI_DSC_FREE           equ 0001h
                DPMI_SEG2DSC            equ 0002h
                DPMI_SEL_INC            equ 0003h
                DPMI_SEG_BASE_GET       equ 0006h
                DPMI_SEG_BASE_SET       equ 0007h
                DPMI_SEG_LIM_SET        equ 0008h
                DPMI_SEG_RGTS_SET       equ 0009h
                DPMI_CS_ALIAS           equ 000Ah
                DPMI_DSC_GET            equ 000Bh
                DPMI_DSC_SET            equ 000Ch
                DPMI_SPCDSC_ALLOC       equ 000Dh
                DPMI_EXCP_HND_GET       equ 0202h
                DPMI_EXCP_HND_SET       equ 0203h
                DPMI_STT_SAVE_REST_GET  equ 0305h
                DPMI_RAW_SWITCH_GET     equ 0306h
                DPMI_GET_VER            equ 0400h
                DPMI_MEM_FREE_GETINFO   equ 0500h
                DPMI_MEM_ALLOC          equ 0501h
                DPMI_MEM_FREE           equ 0502h
                DPMI_REG_LOCK           equ 0600h
                DPMI_REG_UNLOCK         equ 0601h
                DPMI_PAGE_SIZE_GET      equ 0604h
                DPMI_PHYS_MAP           equ 0800h
                
                DPMI_STT_SAVE           equ 0
                DPMI_STT_RESTORE        equ 1

DPMI            struct
                                REGS    <>
                _flgs           word    ?
                _es             word    ?
                _ds             word    ?
                _fs             word    ?
                _gs             word    ?
                _ip             word    ?
                _cs             word    ?
                _sp             word    ?
                _ss             word    ?
DPMI            ends

endif   ;; __dpmi_inc__
