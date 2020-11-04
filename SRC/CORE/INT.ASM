;; name: interrupt386, interrupt386x
;; desc: invoke a 32-bit protected mode interrupt
;;
;; type: sub
;; args:          intnum:integer, | interrupt to invoke
;;       [in/out] regs:REGS386    | struct of registers to pass to interrupt
;; retn: none
;;
;; decl: interrupt386  (byval intnum as integer,_
;;                      seg regs as REGS386)
;;       interrupt386x (byval intnum as integer,_
;;                      seg regs as REGS386)
;;
;; updt: oct/00 [v1ctor]
;; obs.: the difference between interrupt386 and interrupt386x is that the
;;       last passes (and returns) the DS & ES selectors to (from) the
;;       interrupt invoked

                include common.inc

                ;; comment the equate below if are going to run this
                ;; lib mainly on P6 (PPro,PII/III,Celeron) or Athlon/Duron
                ;; processors where self-modyfing code is tooooo expensive
                ;; (more than 300 clocks of penalty!!!)
                ;__USE_SELF_MODYFING_CODE__  equ 1

CODE16_SEGMENT
;;::::::::::::::
interrupt386    proc    uses di si\
                        intnum:word,\
                        regs:far ptr REGS386

                ;; pass arguments to regs because bp will be used
                mov     ax, intnum
                mov     ebx, regs

                mov     ebp, cs:b4g$swt_buf_ptr
                add     cs:b4g$swt_buf_ptr, T SWITCH

                ;; set int vector proc to call
                mov     W cs:[bp].SWITCH.int_num, ax

                ;; set regs struct linear address
                FP2L    bx                      ;; ebx= (seg*16)+ofs
                mov     cs:[bp].SWITCH._ebx, ebx

                ;; switch to protected mode (call int386_32)
                SWT2PM  <large O int386_32>

                sub     cs:b4g$swt_buf_ptr, T SWITCH

                ret
interrupt386    endp

;;::::::::::::::
interruptx386   proc    uses di si\
                        intnum:word,\
                        regs:far ptr REGS386

                ;; pass arguments to regs because bp will be used
                mov     ax, intnum
                mov     ebx, regs

                mov     ebp, cs:b4g$swt_buf_ptr
                add     cs:b4g$swt_buf_ptr, T SWITCH

                ;; set int vector proc to call
                mov     B cs:[bp].SWITCH.int_num, al

                ;; set regs struct linear address
                FP2L    bx                      ;; ebx= (seg*16)+ofs
                mov     cs:[bp].SWITCH._ebx, ebx

                ;; switch to protected mode (call intx386_32)
                SWT2PM  <large O intx386_32>

                sub     cs:b4g$swt_buf_ptr, T SWITCH

                ret
interruptx386   endp

;;::::::::::::::
int_pmode       proc
                intnum  equ B [esp+4]
                
                push    ebp                     ;; (0)
                ;; ebp= swt_buf_ptr; swt_buf_ptr+= SWITCH
                mov     ebp, cs:b4g$swt_buf_ptr
                lea     ebp, [ebp + T SWITCH]
                xchg    ebp, cs:b4g$swt_buf_ptr

                ;; save registers to pass to pmode int
                SV_REGS cs:[bp], TRUE, TRUE     ;; (0)

                ;; set interrupt to call
                mov     al, intnum
                mov     B cs:[bp].SWITCH.int_num, al

                ;; switch to protected mode (call iret_rmode)
                SWT2PM  <large O iret_rmode>

                ;; load registers that the interrupt service did set
                LD_REGS cs:[bp], TRUE, TRUE

                ;; return to rmode caller
                ret     (2)
int_pmode       endp

;;::::::::::::::
iret_pmode      proc    near
                ;;  in: bp= switch buffer ptr

                ;; set fs,gs sregs (DPMI's raw switch function trashs it)
                mov     fs, cs:[bp-T SWITCH].SWITCH.rm_fs
                mov     gs, cs:[bp-T SWITCH].SWITCH.rm_gs

                push    ebp                     ;; (0)
                
        ifdef   __USE_SELF_MODYFING_CODE__
                push    W cs:@@intrm            ;; (1) re-entrance
                mov     al, B cs:[bp].SWITCH.int_num
                mov     cs:@@intrm+1, al        ;; set vector to invoke

                mov     ah, B cs:[bp].SWITCH._flgs
                sahf                            ;; set flags

        else
                push    es                      ;; (1)

                ;; make an INT-like stack-frame
                pushf                           ;; (virtualized!!!)
                push    cs                      ;; return address
                push    O @@return              ;; /

                ;; make flags for the IRET below
                mov     ax, [esp + 4]           ;; get current
                and     ax, 1111110000000000b   ;; clear T, I & ALU flags
                or      al, B cs:[bp].SWITCH._flgs ;; set ALU's flags
                push    ax

                ;; get the address from IVT
                xor     ax, ax
                mov     es, ax
                mov     bx, W cs:[bp].SWITCH.int_num
                shl     bx, 2
                push    D es:[bx]
        endif

                ;; load regs that the pmode caller proc did set
                mov     eax, cs:[bp].SWITCH._eax
                mov     ebx, cs:[bp].SWITCH._ebx
                mov     ecx, cs:[bp].SWITCH._ecx
                mov     edx, cs:[bp].SWITCH._edx
                mov     edi, cs:[bp].SWITCH._edi
                mov     esi, cs:[bp].SWITCH._esi                
                mov     ebp, cs:[bp].SWITCH._ebp
                
        ifdef   __USE_SELF_MODYFING_CODE__
                jmp     short $+2               ;; flush pre-fetch queue
@@intrm         byte    0CDh, 0                 ;; int ?? (virtualized!!!)
                pop     W cs:@@intrm            ;; (1)

        else
                iret                            ;; (virtualized!!!)
@@return:       pop     es                      ;; (1)
        endif

                xchg    ebp, [esp]              ;; (0)

                ;; save all regs and flags
                SV_REGS cs:[bp], TRUE, TRUE     ;; /
                
                ;; switch to protected mode (return to int_rmode)
                RET2PM
iret_pmode      endp

;;::::::::::::::
iretx_pmode     proc    near
                ;;  in: bp= switch buffer ptr

                ;; set fs,gs sregs
                mov     fs, cs:[bp-T SWITCH].SWITCH.rm_fs
                mov     gs, cs:[bp-T SWITCH].SWITCH.rm_gs

                push    ebp                     ;; (0)
                
        ifdef   __USE_SELF_MODYFING_CODE__
                push    W cs:@@intrmx           ;; (1)
                mov     al, B cs:[bp].SWITCH.int_num
                mov     cs:@@intrmx+1, al       ;; set vector to invoke

                mov     ah, B cs:[bp].SWITCH._flgs
                sahf                            ;; set flags

        else
                ;; make an INT-like stack-frame
                pushf                           ;; (virtualized!!!)
                push    cs                      ;; return address
                push    O @@return              ;; /

                ;; make flags for the IRET below
                mov     ax, [esp + 4]           ;; get current
                and     ax, 1111110000000000b   ;; clear T, I & ALU flags
                or      al, B cs:[bp].SWITCH._flgs ;; set ALU's flags
                push    ax

                ;; get the address from IVT
                xor     ax, ax
                mov     es, ax
                mov     bx, W cs:[bp].SWITCH.int_num
                shl     bx, 2
                push    D es:[bx]
        endif

                ;; load ds and es seg regs
                mov     ds, cs:[bp].SWITCH._ds
                mov     es, cs:[bp].SWITCH._es

                ;; load regs that the pmode caller proc did set
                mov     eax, cs:[bp].SWITCH._eax
                mov     ebx, cs:[bp].SWITCH._ebx
                mov     ecx, cs:[bp].SWITCH._ecx
                mov     edx, cs:[bp].SWITCH._edx
                mov     edi, cs:[bp].SWITCH._edi
                mov     esi, cs:[bp].SWITCH._esi                
                mov     ebp, cs:[bp].SWITCH._ebp
                
        ifdef   __USE_SELF_MODYFING_CODE__
                jmp     short $+2               ;; flush pre-fetch queue
@@intrmx        byte    0CDh, 0                 ;; int ?? (virtualized!!!)
                pop     W cs:@@intrmx           ;; (1)

        else
                iret                            ;; (virtualized!!!)
@@return:
        endif

                xchg    ebp, [esp]              ;; (0)

                ;; save ds and es seg regs 
                mov     cs:[bp].SWITCH._ds, ds
                mov     cs:[bp].SWITCH._es, es

                ;; save all others regs and flags
                SV_REGS cs:[bp], TRUE, TRUE     ;; /
                
                ;; switch to protected mode (return to intx_rmode)
                RET2PM
iretx_pmode     endp
CODE16_ENDS


CODE32_SEGMENT
;;::::::::::::::
iret_rmode      proc    near
                ;;  in: ebp= switch buffer ptr
                
                ;; set fs,gs sels (DPMI's raw switch function trashs it)
                mov     fs, ss:sel_tb[CODE32A_SEL]
                mov     gs, ss:[ebp].SWITCH.pm_gs

                RT_RM_STT                       ;; restore real mode state

                push    ebp                     ;; (0)
                
        ;;;;;ifdef   __USE_SELF_MODYFING_CODE__
                push    W fs:@@intpm            ;; (1) re-entrance
                mov     al, B ss:[ebp].SWITCH.int_num
                mov     fs:@@intpm+1, al        ;; set vector to invoke

                mov     ah, B ss:[ebp].SWITCH._flgs
                sahf                            ;; set flags

        ;;;;;else
        ;;;;;        ;; make an INT-like stack-frame
        ;;;;;        pushfd                          ;; (virtualized!!!)
        ;;;;;        push    cs                      ;; return address
        ;;;;;        push    O @@return              ;; /
        ;;;;;
        ;;;;;        ;; make flags for the IRET below
        ;;;;;        mov     eax, [esp + 4+4]        ;; get current
        ;;;;;        and     eax, 11111111111111111111110000000000b ;; T,I+ALU=0
        ;;;;;        or      al, B ss:[ebp].SWITCH._flgs ;; set ALU's flags
        ;;;;;        push    eax
        ;;;;;
        ;;;;;        ;; get the address from IDT
        ;;;;;        mov     ebx, ss:[ebp].SWITCH.int_num
        ;;;;;        ?????
        ;;;;;endif

                ;; load regs that the rmode caller proc did set
                mov     eax, ss:[ebp].SWITCH._eax
                mov     ebx, ss:[ebp].SWITCH._ebx
                mov     ecx, ss:[ebp].SWITCH._ecx
                mov     edx, ss:[ebp].SWITCH._edx
                mov     edi, ss:[ebp].SWITCH._edi
                mov     esi, ss:[ebp].SWITCH._esi                
                mov     ebp, ss:[ebp].SWITCH._ebp
                
        ;;;;;ifdef   __USE_SELF_MODYFING_CODE__
                jmp     short $+2               ;; flush pre-fetch queue
@@intpm         byte    0CDh, 0                 ;; int ??
                pop     W fs:@@intpm            ;; (1)

        ;;;;;else
        ;;;;;        iretd
@@return:
        ;;;;;endif

                xchg    ebp, [esp]              ;; (0)

                ;; save all regs and flags
                SV_REGS ss:[ebp], TRUE, TRUE    ;; /
                                               
                SV_RM_STT                       ;; save real mode state

                ;; switch to real mode (return to int_pmode)
                RET2RM
iret_rmode      endp

;;::::::::::::::
int386_32       proc    near
                ;;  in: ebp= switch buffer ptr
                
                ;; set fs,gs sels (DPMI's raw switch function trashs it)
                mov     fs, ss:sel_tb[CODE32A_SEL]
                mov     gs, ss:[ebp].SWITCH.pm_gs

                RT_RM_STT                       ;; restore real mode state
                
                push    ebp                     ;; (0)

                mov     ebx, ss:[ebp].SWITCH._ebx
                push    ebx                     ;; (1)

                push    W fs:@@int386           ;; (2)
                mov     al, B ss:[ebp].SWITCH.int_num
                mov     fs:@@int386+1, al       ;; set vector to invoke

                mov     ah, B ss:[ebp].SWITCH._flgs
                sahf                            ;; set flags

                ;; load registers that rmode proc did set
                mov     eax, [ebx].REGS386._eax
                mov     ecx, [ebx].REGS386._ecx
                mov     edx, [ebx].REGS386._edx
                mov     edi, [ebx].REGS386._edi
                mov     esi, [ebx].REGS386._esi
                mov     ebp, [ebx].REGS386._ebp
                mov     ebx, [ebx].REGS386._ebx
                
                jmp     short $+2               ;; flush pre-fetch queue
@@int386        byte    0CDh, 0                 ;; int ??
                
                pop     W fs:@@int386           ;; (2)

                xchg    ebx, [esp]              ;; (1)
                
                ;; save all regs...
                mov     [ebx].REGS386._eax, eax
                pop     [ebx].REGS386._ebx      ;; (1)
                mov     [ebx].REGS386._ecx, ecx
                mov     [ebx].REGS386._edx, edx
                mov     [ebx].REGS386._edi, edi
                mov     [ebx].REGS386._esi, esi
                mov     [ebx].REGS386._ebp, ebp
               
                ;; ...and flags
                lahf
                mov     B [ebx].REGS386._flgs, ah

                pop     ebp                     ;; (0)

                SV_RM_STT                       ;; save real mode state

                ;; switch to real mode (return to interrupt386)
                RET2RM
int386_32       endp

;;::::::::::::::
intx386_32      proc    near
                ;;  in: ebp= switch buffer ptr
                
                ;; set fs,gs sels
                mov     fs, ss:sel_tb[CODE32A_SEL]
                mov     gs, ss:[ebp].SWITCH.pm_gs

                RT_RM_STT                       ;; restore real mode state
                
                mov     ebx, ss:[ebp].SWITCH._ebx
                push    ebp                     ;; (0)
                push    ebx                     ;; (1)
                push    ds                      ;; (2)

                push    W fs:@@intx386          ;; (3)
                mov     al, B ss:[ebp].SWITCH.int_num
                mov     fs:@@intx386+1, al      ;; set vector to invoke

                mov     ah, B ss:[ebp].SWITCH._flgs
                sahf                            ;; set flags

                push    [ebx].REGS386._ds       ;; (4)

                ;; load registers that rmode proc did set
                mov     eax, [ebx].REGS386._eax
                mov     ecx, [ebx].REGS386._ecx
                mov     edx, [ebx].REGS386._edx
                mov     edi, [ebx].REGS386._edi
                mov     esi, [ebx].REGS386._esi
                mov     ebp, [ebx].REGS386._ebp
                mov     ebx, [ebx].REGS386._ebx
                
                ;; load ds and es seg regs
                mov     es, [ebx].REGS386._es
                pop     ds                      ;; (4)

                jmp     short $+2               ;; flush pre-fetch queue
@@intx386       byte    0CDh, 0                 ;; int ??
                
                pop     W fs:@@intx386          ;; (3)

                ;; save current ds and restore old
                push    eax
                mov     eax, ds
                xchg    eax, [esp+4]            ;; (2)
                mov     ds, eax
                pop     eax

                xchg    ebx, [esp+4]            ;; (1)
                
                ;; save ds and es seg regs
                pop     [ebx].REGS386._ds       ;; (2)
                mov     [ebx].REGS386._es, es

                ;; save all regs...
                mov     [ebx].REGS386._eax, eax
                pop     [ebx].REGS386._ebx      ;; (1)
                mov     [ebx].REGS386._ecx, ecx
                mov     [ebx].REGS386._edx, edx
                mov     [ebx].REGS386._edi, edi
                mov     [ebx].REGS386._esi, esi
                mov     [ebx].REGS386._ebp, ebp
               
                ;; ... and flags
                lahf
                mov     B [ebx].REGS386._flgs, ah

                pop     ebp                     ;; (0)

                SV_RM_STT                       ;; save real mode state

                ;; switch to real mode (return to interruptx386)
                RET2RM
intx386_32      endp

;;::::::::::::::
int_rmode       proc    near
                intnum          equ D [esp+4]

                push    ebp                     ;; (0)
                ;; ebp= swt_buf_ptr; swt_buf_ptr+= SWITCH
                mov     ebp, large ss:b4g$swt_buf_ptr
                lea     ebp, [ebp + T SWITCH]
                xchg    ebp, large ss:b4g$swt_buf_ptr

                ;; save registers to pass to the interrupt service
                SV_REGS ss:[ebp], TRUE, TRUE    ;; (0)

                ;; set interrupt to call
                mov     eax, intnum
                mov     ss:[ebp].SWITCH.int_num, eax

                SV_RM_STT                       ;; save real mode state
                
                ;; switch to real mode (call iret_pmode)
                SWT2RM  <small O iret_pmode>

                RT_RM_STT                       ;; restore real mode state

                ;; load registers that the interrupt service did set
                LD_REGS ss:[ebp], TRUE, TRUE

                ;; return to pmode caller
                ret     (4)
int_rmode       endp

;;::::::::::::::
intx_rmode      proc    near
                intnum          equ D [esp+8]
                intxptr         equ D [esp+4]

                push    ebp                     ;; (0)
                ;; ebp= swt_buf_ptr; swt_buf_ptr+= SWITCH
                mov     ebp, large ss:b4g$swt_buf_ptr
                lea     ebp, [ebp + T SWITCH]
                xchg    ebp, large ss:b4g$swt_buf_ptr

                ;; save registers to pass to the interrupt service
                SV_REGS ss:[ebp], TRUE, TRUE    ;; (0)

                ;; set interrupt to call
                mov     eax, intnum
                mov     ss:[ebp].SWITCH.int_num, eax

                ;; set rmode ds and es segments
                mov     ebx, intxptr
                mov     ax, es:[ebx].INTX._ds
                mov     ss:[ebp].SWITCH._ds, ax
                mov     ax, es:[ebx].INTX._es
                mov     ss:[ebp].SWITCH._es, ax

                SV_RM_STT                       ;; save real mode state
                
                ;; switch to real mode (call iretx_pmode)
                SWT2RM  <small O iretx_pmode>

                RT_RM_STT                       ;; restore real mode state

                ;; load registers that the interrupt service did set
                LD_REGS ss:[ebp], TRUE, TRUE

                ;; return to pmode caller
                ret     (4+4)
intx_rmode      endp
CODE32_ENDS
                end
