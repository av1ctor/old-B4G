;;
;; call.asm -- helper functions to call rmode and pmode routines from
;;             real or protected mode
;;

                include common.inc

CODE16_SEGMENT
;;::::::::::::::
call_pmode      proc
                pmproc  equ D [esp + 4]
                
                push    ebp                     ;; (0)
                mov     ebp, cs:b4g$swt_buf_ptr                
                add     cs:b4g$swt_buf_ptr, T SWITCH

                ;; save registers to pass to pmode proc
                SV_REGS cs:[bp], TRUE, FALSE    ;; (0)

                ;; set pmode proc to call
                mov     eax, pmproc
                mov     cs:[bp].SWITCH.pm_proc, eax

                ;; switch to protected mode (return to ret_rmode)
                SWT2PM  <large O ret_rmode>

                ;; load registers that pmode proc did set
                LD_REGS cs:[bp], TRUE, TRUE

                ;; return to rmode caller
                ret     (4)
call_pmode      endp

;;::::::::::::::
ret_pmode       proc    near
                ;;  in: bp= switch buffer ptr

                ;; set fs,gs sregs (DPMI's raw switch function trashs it)
                mov     fs, cs:[bp-T SWITCH].SWITCH.rm_fs
                mov     gs, cs:[bp-T SWITCH].SWITCH.rm_gs

                ;; load registers that pmode proc did set
                push    ebp                     ;; (0)
                PS      cs, O @@return          ;; (1)
                push    cs:[bp].SWITCH.rm_proc  ;; (2)
                LD_REGS cs:[bp], FALSE, FALSE
                mov     ebp, cs:[bp].SWITCH._ebp
                                
                retf                            ;; (2) call rmode proc (1)

@@return:       ;; save registers to return to pmode
                xchg    ebp, [esp]              ;; (0)
                SV_REGS cs:[bp], TRUE, TRUE     ;; /
                
                ;; switch to protected mode (return to call_rmode)
                RET2PM
ret_pmode       endp

;;::::::::::::::
call_pmode_nr   proc
                pmproc  equ D [esp + 4]
                
                mov     ebp, cs:b4g$swt_buf_ptr
                add     cs:b4g$swt_buf_ptr, T SWITCH
                
                ;; set pmode proc to call
                mov     eax, pmproc
                mov     cs:[bp].SWITCH.pm_proc, eax

                ;; switch to protected mode (return to ret_rmode_nr)
                SWT2PM  <large O ret_rmode_nr>

                sub     cs:b4g$swt_buf_ptr, T SWITCH

                ;; return to rmode caller
                ret     (4)
call_pmode_nr   endp

;;::::::::::::::
ret_pmode_nr    proc    near
                ;;  in: bp= switch buffer ptr
                                
                ;; set fs,gs sregs
                mov     fs, cs:[bp-T SWITCH].SWITCH.rm_fs
                mov     gs, cs:[bp-T SWITCH].SWITCH.rm_gs

                call    cs:[bp].SWITCH.rm_proc  ;; call rmode proc
                
                ;; switch to protected mode (return to call_rmode_nr)
                RET2PM
ret_pmode_nr    endp
CODE16_ENDS


CODE32_SEGMENT
;;::::::::::::::
ret_rmode       proc    near
                ;;  in: ebp= switch buffer ptr
                
                ;; set fs,gs sels (DPMI's raw switch function trashs it)
                mov     fs, ss:sel_tb[CODE32A_SEL]
                mov     gs, ss:[ebp].SWITCH.pm_gs

                RT_RM_STT                       ;; restore real mode state

                ;; load registers that rmode proc did set
                push    ebp                     ;; (0)
                push    O @@return              ;; (1)
                push    ss:[ebp].SWITCH.pm_proc ;; (2)
                LD_REGS ss:[ebp], FALSE, FALSE
                mov     ebp, ss:[ebp].SWITCH._ebp

                retn                            ;; (2) call pmode proc (1)
                
@@return:       ;; save registers to return to rmode
                xchg    ebp, [esp]              ;; (0)
                SV_REGS ss:[ebp], TRUE, TRUE    ;; /
                                                
                SV_RM_STT                       ;; save real mode state

                ;; switch to real mode (return to call_pmode)
                RET2RM
ret_rmode       endp

;;::::::::::::::
call_rmode      proc    near
                rmproc  equ D [esp+4]
                
                push    ebp                     ;; (0)
                mov     ebp, large ss:b4g$swt_buf_ptr
                add     large ss:b4g$swt_buf_ptr, T SWITCH

                ;; save registers to pass to rmode proc
                SV_REGS ss:[ebp], TRUE, FALSE   ;; (0)

                ;; set rmode proc to call
                mov     eax, rmproc
                mov     ss:[ebp].SWITCH.rm_proc, eax

                SV_RM_STT                       ;; save real mode state

                ;; switch to real mode (ret_pmode)
                SWT2RM  <small O ret_pmode>

                RT_RM_STT                       ;; restore real mode state

                ;; load registers that rmode proc did set
                LD_REGS ss:[ebp], TRUE, TRUE

                ;; return to pmode caller
                ret     (4)
call_rmode      endp

;;::::::::::::::
ret_rmode_nr    proc    near
                ;;  in: ebp= switch buffer ptr

                ;; set fs,gs sels
                mov     fs, ss:sel_tb[CODE32A_SEL]
                mov     gs, ss:[ebp].SWITCH.pm_gs

                RT_RM_STT                       ;; restore real mode state

                call    large ss:[ebp].SWITCH.pm_proc ;; call pmode proc
                                
                SV_RM_STT                       ;; save real mode state

                ;; switch to real mode (return to call_pmode_nr)
                RET2RM
ret_rmode_nr    endp

;;::::::::::::::
call_rmode_nr   proc    near
                rmproc  equ D [esp+4]
                
                mov     ebp, large ss:b4g$swt_buf_ptr
                add     large ss:b4g$swt_buf_ptr, T SWITCH

                ;; set rmode proc to call
                mov     eax, rmproc
                mov     ss:[ebp].SWITCH.rm_proc, eax
                
                SV_RM_STT                       ;; save real mode state

                ;; switch to real mode (ret_pmode_nr)
                SWT2RM  <small O ret_pmode_nr>

                RT_RM_STT                       ;; restore real mode state

                ;; return to pmode caller
                ret     (4)
call_rmode_nr   endp
CODE32_ENDS
                end
