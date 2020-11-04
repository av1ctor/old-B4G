;;
;; internal core module definitions
;;

                .model  medium, basic
                .386
                option  proc:private

                include ..\inc\equ.inc
                include ..\inc\addr.inc
                include ..\inc\dos.inc
                include ..\inc\dpmi.inc
                include ..\inc\bas.inc
                include ..\inc\core.inc

;;::::::::::::::
SV_REGS         macro   idx:req, all:=<FALSE>, flags:=<FALSE>
                mov     idx.SWITCH._eax, eax
                mov     idx.SWITCH._ebx, ebx
                mov     idx.SWITCH._ecx, ecx
                mov     idx.SWITCH._edx, edx
                mov     idx.SWITCH._edi, edi
                mov     idx.SWITCH._esi, esi
        if      (flags eq TRUE)
                lahf
                mov     B idx.SWITCH._flgs, ah
        endif
        if      (all eq TRUE)
                pop     idx.SWITCH._ebp
        endif
endm
;;::::::::::::::
LD_REGS         macro   idx:req, all:=<FALSE>, flags:=<FALSE>
                mov     ebx, idx.SWITCH._ebx
                mov     ecx, idx.SWITCH._ecx
                mov     edx, idx.SWITCH._edx
                mov     edi, idx.SWITCH._edi
                mov     esi, idx.SWITCH._esi

if      (flags eq TRUE)
                mov     ah, B idx.SWITCH._flgs
        if      (all eq FALSE)
                sahf
                mov     eax, idx.SWITCH._eax
        else
                push    idx.SWITCH._eax
        endif
else
                mov     eax, idx.SWITCH._eax
endif
                
if      (all eq TRUE)
                mov     ebp, idx.SWITCH._ebp
        if      (@WordSize eq 2)
                sub     cs:b4g$swt_buf_ptr, T SWITCH
        else
                sub     large ss:b4g$swt_buf_ptr, T SWITCH
        endif

        if      (flags eq TRUE)
                sahf
                pop     eax
        endif
endif
endm
                
;;::::::::::::::
SWT2PM          macro   eip:req
                local   pm_return

                ;; save return address, current stack ptr and es,fs,gs sregs
                mov     cs:[bp].SWITCH.rm_ip, O pm_return
                mov     cs:[bp].SWITCH.rm_sp, sp
                mov     cs:[bp].SWITCH.rm_es, es
                mov     cs:[bp].SWITCH.rm_fs, fs
                mov     cs:[bp].SWITCH.rm_gs, gs

                ;; si:edi(cs:eip)= code32:pm_function
                mov     si, cs:sel_tb[CODE32_SEL]
                mov     edi,eip

                ;; ax(ds)= dataflat; cx(es)= dgroup; dx(ss)= code16a
                mov     ax, cs:sel_tb[DATFLT_SEL]
                mov     cx, cs:sel_tb[DGROUP_SEL]
                mov     dx, cs:sel_tb[CODE16A_SEL]

                ;; ebx(esp)= stack32_ptr; stack32_ptr-= size of stack32
                mov     ebx, cs:b4g$stack32_ptr
                sub     cs:b4g$stack32_ptr, STACK32_SIZE

                jmp     cs:b4g$rm_to_pm

pm_return:      ;; restore fs,gs sregs (DPMI's raw switch function trashs it)
                mov     fs, cs:[bp].SWITCH.rm_fs
                mov     gs, cs:[bp].SWITCH.rm_gs
endm

;;::::::::::::::
RET2RM          macro
                ;; restore stack32_ptr (preserving flags)
                mov     eax, ss:b4g$stack32_ptr
                lea     eax, [eax + STACK32_SIZE]
                mov     ss:b4g$stack32_ptr, eax

                ;; use dword 4 speeeeeed
                ;; si:di(cs:ip)= code16:rm caller ip
                mov     esi, D ss:seg_tb[CODE16_SEG]
                mov     edi, D ss:[ebp].SWITCH.rm_ip

                ;; ax(ds)= dx(ss)= dgroup
                mov     eax, D ss:seg_tb[DGROUP_SEG]
                mov     edx, eax

                ;; cx(es)= rm caller es
                mov     ecx, D ss:[ebp].SWITCH.rm_es

                ;; bx(sp)= rm caller sp
                mov     ebx, D ss:[ebp].SWITCH.rm_sp

                jmp     large ss:b4g$pm_to_rm
endm

;;::::::::::::::
SWT2RM          macro   ip:req
                local   rm_return

                ;; save return address, current stack ptr and gs sel
                mov     ss:[ebp].SWITCH.pm_eip, O rm_return
                mov     ss:[ebp].SWITCH.pm_esp, esp
                mov     ss:[ebp].SWITCH.pm_gs, gs

                ;; si:di(cs:ip)= code16:rm_function
                mov     esi, D ss:seg_tb[CODE16_SEG]
                mov     edi, ip

                ;; ax(ds)= dx(ss)= dgroup
                mov     eax, D ss:seg_tb[DGROUP_SEG]
                mov     edx, eax

                ;; cx(es)= last rm es
                mov     ecx, D ss:[ebp-T SWITCH].SWITCH.rm_es

                ;; bx(sp)= last rm sp; last rm sp-= size of stack16
                mov     ebx, D ss:[ebp-T SWITCH].SWITCH.rm_sp
                sub     ss:[ebp-T SWITCH].SWITCH.rm_sp, STACK16_SIZE

                jmp     ss:b4g$pm_to_rm

rm_return:      ;; restore fs,gs sels (DPMI's raw switch function trashs it)
                mov     fs, ss:sel_tb[CODE32A_SEL]
                mov     gs, ss:[ebp].SWITCH.pm_gs
endm

;;::::::::::::::
RET2PM          macro
                ;; restore stack16 ptr (preserving flags)
                mov     bx, cs:[bp-T SWITCH].SWITCH.rm_sp
                lea     bx, [bx + STACK16_SIZE]
                mov     cs:[bp-T SWITCH].SWITCH.rm_sp, bx
                
                ;; si:edi(cs:eip)= code32:pm caller eip
                mov     si, cs:sel_tb[CODE32_SEL]
                mov     edi,cs:[ebp].SWITCH.pm_eip

                ;; ax(ds)= dataflat; cx(es)= dgroup; dx(ss)= code16a
                mov     ax, cs:sel_tb[DATFLT_SEL]
                mov     cx, cs:sel_tb[DGROUP_SEL]
                mov     dx, cs:sel_tb[CODE16A_SEL]

                ;; ebx(esp)= pm caller esp
                mov     ebx, cs:[ebp].SWITCH.pm_esp

                jmp     cs:b4g$rm_to_pm
endm

                SAVE_RESTORE_RM_STATE   equ FALSE
                ;; only set the above equate to TRUE if you'll use the DPMI
                ;; services that switch modes (like invoke rmode interrupt,
                ;; call rmode proc) instead of the B4G functions (INTRM,
                ;; INTXRM, CALLRM). this is because we must save the real
                ;; mode state if raw mode switches(RMS) and non-RMS are used
                ;; in conjunction in some DPMI hosts (like Windows).
;;::::::::::::::
SV_RM_STT       macro
        if      (SAVE_RESTORE_RM_STATE eq TRUE)
                PS      edi, es

                ;; state buffer ptr-= state buffer size
                mov     eax, large ss:b4g$sttbuff_siz
                sub     large ss:b4g$sttbuff_ptr, eax
                ;; es:edi-> state buffer ptr
                mov     eax, ss
                mov     es, eax                 ;; es=ss
                mov     edi, large ss:b4g$sttbuff_ptr
                
                mov     al, DPMI_STT_SAVE
                call    large ss:b4g$pm_state   ;; save state

                PP      es, edi
        endif
endm
;;::::::::::::::
RT_RM_STT       macro
        if      (SAVE_RESTORE_RM_STATE eq TRUE)
                PS      edi, es
                ;; es:edi-> state buffer ptr
                mov     eax, ss
                mov     es, eax                 ;; es=ss
                mov     edi, large ss:b4g$sttbuff_ptr

                mov     al, DPMI_STT_RESTORE
                call    large ss:b4g$pm_state   ;; restore state

                ;; stt buff ptr+= state buffer size (preserving flags)
                mov     eax, large ss:b4g$sttbuff_siz
                lea     edi, [edi + eax]
                mov     large ss:b4g$sttbuff_ptr, edi

                PP      es, edi
        endif
endm
;;::::::::::::::
RETFD           macro
                byte    66h
                retf
endm

                ;; globals :::::

                ;; from init.asm:
                global  b4g$installed:byte

                global  b4g$swt_buf_ptr:dword

                global  b4g$sttbuff_ptr:dword, b4g$sttbuff_siz:dword
                global  b4g$rm_state:dword, b4g$rm_to_pm:dword
                global  b4g$pm_state:fword, b4g$pm_to_rm:fword

                global  b4g$tmp_stk16:byte


                ;; from excpt.asm:
                global  b4g$excpt_inst:near32, b4g$excpt_remv:near32


                ;; from done.asm:
                global  b4g$exit:proc
                global  b4g$unhook:near16
                global  b4g$exited:byte
