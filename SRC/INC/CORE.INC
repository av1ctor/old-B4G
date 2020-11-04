;;
;;                   0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
;;                   0                                   0
;;                   0  000000      00    00    000000   0  
;;                   0  00   00    00   0 00   00        0  
;;                   0  00 000    00   0  00  00    000  0  
;;                   0  00   00   00  000000  00     00  0  
;;                   0  00   00  00       00   00    00  0  
;;                   0  000000  00        00     0000    0
;;                   0  BASIC four gigabytes  ver1E-32b  0
;;                   0                                   0  
;;                   0      copyleft Oct/2000 by v1ctor  0  
;;                   0           [av1ctor@yahoo.com.br]  0  
;;                   0             none rights reserved  0  
;;                   0                                   0
;;                   0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
;;                           ABSOLUTELY NO WARRANTY
;;
;;     free for use in commercial ;), shareware and freeware applications

ifndef          __core_inc__
                __core_inc__    equ 1

                include regs.inc
                include bas.inc

                ;; b4ginit errors:
                B4G_ERROR_HOST          equ     1
                B4G_ERROR_BIT           equ     2
                B4G_ERROR_MEM           equ     3
                B4G_ERROR_SWT           equ     4

;;:::
                PRIORITY_FIRST          equ     2
                PRIORITY_LAST           equ     1

EXIT_Q          struct                          ;; exit queue structure
                prev            dword   ?
                next            dword   ?
                proc_ptr        dword   ?
                priority        word    ?
EXIT_Q          ends

;;:::
REGS386         struct                          ;; used by interrupt(x) procs
                _eax            dword   ?
                _ebx            dword   ?
                _ecx            dword   ?
                _edx            dword   ?
                _edi            dword   ?
                _esi            dword   ?
                _ebp            dword   ?
                _ds             word    ?
                _es             word    ?
                _flgs           word    ?
REGS386         ends

INTX            struct                          ;; used by int(x)_rmode functs
                _es             word    ?
                _ds             word    ?
INTX            ends

SWITCH          struct                          ;; used to switch rm/pm pm/rm
                                REGS    <>
                _flgs           word    ?
                                INTX    <>

                rm_es           word    ?
                rm_fs           word    ?
                rm_gs           word    ?
                rm_ip           word    ?
                rm_sp           word    ?

                rm_proc         dword   ?
                pm_proc         equ     rm_proc                
                int_num         equ     rm_proc

                pm_gs           word    ?
                pm_eip          dword   ?
                pm_esp          dword   ?
SWITCH          ends


DESCRIPTOR      struct
                limit0_15       word     0      ;; 00-15
                base0_23        byte     0,0,0  ;; 16-39
                typ_dpl_p       byte     0      ;; 40-47
                lim16_19_md_gr  byte     0      ;; 48-55
                base_24_31      byte     0      ;; 56-63
DESCRIPTOR      ends

                ;; type as memory segment:
                READ            equ 00010000b   ;; read only
                READ_WRITE      equ 00010010b   ;; read/write
                READ_DOWN       equ 00010100b   ;; read only, expand down
                READ_WRITE_DOWN equ 00010110b   ;; read/write, expand down
                EXEC            equ 00011000b   ;; execute only
                EXEC_READ       equ 00011010b   ;; execute/read
                EXEC_CONF       equ 00011100b   ;; execute only, conforming
                EXEC_READ_CONF  equ 00011110b   ;; execute/read, conforming

                ;; privilege level:
                DPL0            equ 00000000b   ;; 0 (more privileged)
                DPL1            equ 00100000b   ;; 1
                DPL2            equ 01000000b   ;; 2
                DPL3            equ 01100000b   ;; 3 (less privileged)

                ;; status:
                ABSENT          equ 00000000b
                PRESENT         equ 10000000b

                ;; size:
                S16             equ 00000000b   ;; 16-bit
                S32             equ 01000000b   ;; 32-bit

                ;; granularity:
                GRN_BYTE        equ 00000000b   ;; byte granular
                GRN_PAGE        equ 10000000b   ;; page granular

;;::::::::::::::
DSC_GEN         macro   dsc_name:req, base:=<0>, limit:req,\
                        typ:req, dpl:=<DPL0>, mode:req
                local   gran

        if      (limit le 0FFFFh)
                gran    = GRN_BYTE
        else
                gran    = GRN_PAGE
        endif

dsc_name        label   DESCRIPTOR
                word    limit and 0FFFFh
                word    base and 0FFFFh
                byte    (base shr 16) and 0FFh
                byte    typ or dpl or PRESENT
                byte    ((limit shr 16) and 0Fh) or mode or gran
                byte    base shr 24
endm

;;::::::::::::::
CALLPM          macro   proc32:req
                pushd   O proc32
                call    call_pmode
endm

;;::::::::::::::
CALLRM          macro   segm:req, offs:req
                pushw   segm
                pushw   offs
                call    call_rmode
endm

;;::::::::::::::
INTRM           macro   int_num:req
                pushd   int_num
                call    int_rmode
endm

;;::::::::::::::
INTXRM          macro   int_num:req, intx_ptr:req
                pushd   int_num
                pushd   intx_ptr
                call    intx_rmode
endm

;;::::::::::::::
INTPM           macro   int_num:req
                push    int_num
                call    int_pmode
endm

;;::::::::::::::
CODE16_SEGMENT  macro
code16          segment
                assume  cs:code16, ds:DGROUP, es:nothing,\
                        fs:nothing, gs:nothing, ss:DGROUP
                smallstack
endm
;;::::::::::::::
CODE16_ENDS     macro
code16          ends
endm

;;::::::::::::::
CODE32_SEGMENT  macro
code32          segment
                assume  cs:code32, ds:nothing, es:DGROUP,\
                        fs:code32, gs:nothing, ss:code16
                largestack
endm
;;::::::::::::::
CODE32_ENDS     macro
code32          ends
endm


data16          segment para public use16 'DATA'
data16          ends

                DGROUP  group data16

code16          segment para public use16 'CODE'
code16          ends

code32          segment para public use32 'CODE'                
code32          ends


                ;; globals :::::

                ;; from init.asm:
                global  sel_tb:word
                CODE32_SEL      equ 0 * T word  ;; same order as dsc_tb
                DATFLT_SEL      equ 1 * T word  ;; /                
                CODE32A_SEL     equ 2 * T word  ;; /
                CODE16A_SEL     equ 3 * T word  ;; /
                CODE16_SEL      equ 4 * T word
                DGROUP_SEL      equ 5 * T word                

                global  lin_tb:dword
                CODE32_LIN      equ CODE32_SEL * 2
                CODE16_LIN      equ CODE16_SEL * 2
                
                global  seg_tb:word
                CODE32_SEG      equ 0 * T word
                DATFLT_SEG      equ 1 * T word
                CODE16_SEG      equ 2 * T word
                DGROUP_SEG      equ 3 * T word

                global  code16a_sel_32:word

                global  b4g$mem_inf_ofs:dword, b4g$pg_shift:byte

                global  b4g$cws_loaded:byte, b4g$mem_intcpt:byte

                STACK16_SIZE    equ 100h
                STACK32_SIZE    equ 200h
                global  b4g$stack32_ptr:dword

                B4G_BUFFER_SIZE equ 2047        ;; or: ..., 1023, , 4095, ...
                global  b4g$buffer:byte

                global  b4g$str_dsc:STR_DSC
        ifdef   __FAR_STRINGS__
                global  b4g$fstr_seg_tb:word
                global  b4g$fstr_ofs_tb:word
        endif

                ;; exit_q       exitq:near ptr EXIT_Q,\
                ;;              procptr:far ptr,\
                ;;              priority:word
                b4g$exit_q      proto :far ptr EXIT_Q, :far ptr, :word

                ;; exit_q32     exitq:near16 ptr EXIT_Q,\
                ;;              procptr:near32 ptr,\
                ;;              priority:dword
                b4g$exit_q32    proto near32 :near32 ptr EXIT_Q, :near32 ptr, :dword

                ;; b4ginit%     ()
                b4ginit         proto


                ;; from done.asm:
                ;; b4gdone      ()
                b4gdone         proto


                ;; from int.asm:
                ;; interrupt386 (byval intnum as integer,_
                ;;               seg regs as XINT)
                interrupt386    proto :word, :far ptr REGS386

                ;; interruptx386 (byval intnum as integer,_
                ;;                seg regs as XINTX)
                interruptx386   proto :word, :far ptr REGS386

                global  int_pmode:proc
                global  int_rmode:near32, intx_rmode:near32


                ;; from call.asm:
                global  call_pmode:proc, call_pmode_nr:proc
                global  call_rmode:near32, call_rmode_nr:near32

endif   ;; __core_inc__
