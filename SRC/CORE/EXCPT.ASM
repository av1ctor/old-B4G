;;
;; excpt.asm -- processor exceptions handler
;;

                include common.inc


                EXCEPTIONS      equ 10h

EXCPT_STK       struct
                _gs             dword   ?
                _fs             dword   ?
                _es             dword   ?
                _ds             dword   ?
                _edi            dword   ?
                _esi            dword   ?
                _ebp            dword   ?
                                dword   ?       ;; esp
                _ebx            dword   ?
                _edx            dword   ?
                _ecx            dword   ?
                _eax            dword   ?
                num             dword   ?
                caller_eip      dword   ?
                caller_cs       word    ?, ?
                error_code      dword   ?
                _eip            dword   ?
                _cs             word    ?, ?
                _flgs           dword   ?
                _esp            dword   ?
                _ss             word    ?, ?
EXCPT_STK       ends


data16          segment
excpt_msg       byte    9+5, 'exception'        ;; \
excpt_hex       byte    '[ ] ('                 ;; /
excpt_num       dword   ?

                CRLF            equ 13,10

type_tb         byte    16, 'division by zero'
                byte    05, 'debug'
                byte    03, 'NMI'
                byte    10, 'breakpoint'
                byte    08, 'overflow'
                byte    12, 'bounds check'
                byte    14, 'invalid opcode'
                byte    15, 'FPU unavailable'
                byte    12, 'double fault'
                byte    11, 'FPU overrun'
                byte    11, 'invalid TSS'
                byte    19, 'segment not present'
                byte    11, 'stack fault'
                byte    24, 'general protection fault'
                byte    10, 'page fault'
                byte    09, 'FPU error'
                byte    0

type_unknown    byte    07, 'unknown'

sels_regs_msg   byte    14+20+20+(4*13-1)+(8*13-1-1+2)+2+2+2+2+2
                byte    ') error=#', 4, EXCPT_STK.error_code, ' ', CRLF
                byte    'cs:eip=#', 4, EXCPT_STK._cs, ' '
                byte    ':#', 8, EXCPT_STK._eip, 5 dup (' ')
                byte    CRLF
                byte    'ss:esp=#', 4, EXCPT_STK._ss, ' '
                byte    ':#', 8, EXCPT_STK._esp, 5 dup (' ')
                byte    CRLF
                byte    'ds= #', 4, EXCPT_STK._ds, 5 dup (' ')
                byte    ' es= #', 4, EXCPT_STK._es, 5 dup (' ')
                byte    ' fs= #', 4, EXCPT_STK._fs, 5 dup (' ')
                byte    ' gs= #', 4, EXCPT_STK._gs, 5 dup (' ')
                byte    CRLF
                byte    'eax=#', 8, EXCPT_STK._eax, 5 dup (' ')
                byte    ' ebx=#', 8, EXCPT_STK._ebx, 5 dup (' ')
                byte    ' ecx=#', 8, EXCPT_STK._ecx, 5 dup (' ')
                byte    ' edx=#', 8, EXCPT_STK._edx, 5 dup (' ')
                byte    CRLF
                byte    'edi=#', 8, EXCPT_STK._edi, 5 dup (' ')
                byte    ' esi=#', 8, EXCPT_STK._esi, 5 dup (' ')
                byte    ' ebp=#', 8, EXCPT_STK._ebp, 5 dup (' ')
                byte    ' flags=#', 8, EXCPT_STK._flgs, 5 dup (' ')
                byte    CRLF
data16          ends

CODE16_SEGMENT
;;::::::::::::::
excpt_ret       proc
                ;; restore fs,gs sregs (DPMI's raw switch function trashs it)
                mov     fs, cs:[bp].SWITCH.rm_fs
                mov     gs, cs:[bp].SWITCH.rm_gs

                sub     cs:b4g$swt_buf_ptr, T SWITCH

                ;; dump everything to standard error (screen by
                ;; default) and terminate

                ;; if current screen mode != 3 (T:25x80) set it
                mov     ah, 0Fh
                int     10h
                cmp     al, 3
                je      @F
                invoke  B$CSCN, 1, 0, 2         ;; set screen mode 0
                invoke  B$WIDT, 80, -1          ;; 80 columns

@@:             mov     edx, O excpt_msg + 1    ;; print exception + num
                call    print_strg              ;; /

                call    print_descption         ;; + description

                mov     edx, O sels_regs_msg+1  ;; + selectors and registers
                call    print_strg              ;; /

                ;; put cursor in a secure :) position 
                invoke  B$LOCT, 1, 24, 1, 1, 4

                ;; astalavista baby...
                invoke  B$CEND
excpt_ret       endp

;;::::::::::::::
print_strg      proc    near
                ;;  in: ds:edx -> PAS string (to data)

                movzx   cx, B [edx-1]           ;; cx= string lenght
                mov     bx, STD_ERROR
                mov     ah, DOS_FILE_WRITE
                int     DOS_INT

                ret
print_strg      endp

;;::::::::::::::
print_descption proc    near
                ;; find a description for the exception
                mov     ax, W excpt_num
                xor     bx, bx
                xor     cx, cx                  ;; 1st exception
                mov     si, O type_tb + 1       ;; 1st description
                jmp     short @@test

@@loop:         mov     bl, [si-1]
                test    bl, bl
                jz      @@unknown               ;; size=null?
                lea     si, [si + bx + 1]       ;; no, next string
                inc     cx                      ;; next expcetion
@@test:         cmp     cx, ax
                jne     @@loop                  ;; same?

                movzx   edx, si
@@done:         call    print_strg              ;; print it
                ret

@@unknown:      mov     dx, O type_unknown + 1
                jmp     short @@done
print_descption endp
CODE16_ENDS


CODE32_SEGMENT
org_hnd_tb      fword   EXCEPTIONS dup (?)

new_hnd_tb      label   dword
        e       = 0
        repeat  EXCEPTIONS
                pushd   e                       ;; 1 + 1
                jmp     near ptr excpt_handler  ;; 1 + 4
                e       = e + 1
        endm

;;::::::::::::::
b4g$excpt_inst  proc    near uses edi esi ebp
                
                mov     edi, O org_hnd_tb       ;; fs:edi=org_hnd_tb
                xor     ebx, ebx                ;; 1st exception
                mov     ebp, O new_hnd_tb       ;; /
                mov     esi, EXCEPTIONS         ;; total of exceptions

@@loop:         ;; save the current handler address
                mov     eax, DPMI_EXCP_HND_GET
                int     DPMI_INT
                mov     fs:[edi], edx           ;; org_hnd_tb[edi]=cx:edx
                mov     fs:[edi+4], cx          ;; /
                
                ;; set the new handler
                mov     ecx, cs
                mov     edx, ebp                ;; cx:edx->new handler
                mov     eax, DPMI_EXCP_HND_SET
                int     DPMI_INT

                add     edi, T fword            ;; next
                inc     ebx                     ;; /
                add     ebp, (1+1)+(1+4)        ;; /
                dec     esi
                jnz     @@loop                  ;; last exception?

                ret
b4g$excpt_inst  endp

;;::::::::::::::
b4g$excpt_remv  proc    near uses edi esi

                ;; restore old exceptions handlers (necessary?)
                mov     edi, O org_hnd_tb       ;; fs:edi=org_hnd_tb
                xor     ebx, ebx                ;; 1st exception
                mov     esi, EXCEPTIONS         ;; total of exceptions

@@loop:         mov     cx, cs:[edi+4]
                mov     edx, cs:[edi]           ;; cx:edx->old handler
                mov     eax, DPMI_EXCP_HND_SET
                int     DPMI_INT

                add     edi, T fword            ;; next
                inc     ebx                     ;; /
                dec     esi
                jnz     @@loop                  ;; last exception?

                ret
b4g$excpt_remv  endp

;;::::::::::::::
excpt_ret32     proc    near

                ;; load selectors (as ASSUMEd)
                mov     gs, cs:code16a_sel_32   ;; sel_tb is in code16
                mov     ds, gs:sel_tb[DATFLT_SEL]
                mov     es, gs:sel_tb[DGROUP_SEL]
                mov     fs, gs:sel_tb[CODE32A_SEL]

                ;; finish in real mode (make life easier :})
                mov     ebp, large ss:b4g$swt_buf_ptr
                sub     ebp, T SWITCH
                mov     ss:[ebp].SWITCH.rm_ip, O excpt_ret

                SV_RM_STT                       ;; save real mode state

                ;; set a safe rmode stack
comment #       IDE doesn't like it (shows out of stack space message)
                mov     eax, O b4g$tmp_stk16 + 100h
                mov     ss:[ebp].SWITCH.rm_sp, ax
#
                ;; switch to real mode (go to excpt_ret)
                RET2RM
excpt_ret32     endp

hex_tb          byte    '0123456789abcdef'
;;::::::::::::::
tohex           proc    near uses ebx ecx
                ;;  in: eax= byte|word|dword to convert
                ;;      es:edi -> hex string
                ;;;     ecx= number of nibbles
                ;; out: hex string filled

@@loop:         mov     ebx, eax
                and     ebx, 0Fh                ;; mask nibble
                mov     bl, cs:hex_tb[ebx]      ;; convert
                mov     es:[edi+ecx-1], bl      ;; save
                shr     eax, 4                  ;; next nibble
                dec     ecx
                jnz     @@loop

                ret
tohex           endp

;;::::::::::::::
fill_sels_regs  proc    near
                ;;  in: ss:ebp->EXCPT_STK struct

                cld
                xor     ebx, ebx
                mov     edi, O sels_regs_msg+1  ;; es:edi -> sels_regs_msg
                mov     esi, 1 + 6 + 9 + 1      ;; error + sels + regs + flgs

@@loop:         mov     al, '#'
                mov     ecx, 0FFh
                repne   scasb                   ;; scan for '#'
                dec     edi                     ;; back 1

                mov     cl, es:[edi+1]          ;; get number of nibbles
                mov     bl, es:[edi+2]          ;; + index into excpt stack
                mov     eax, ss:[ebp+ebx]       ;; eax= EXCPT_STK[ebx]
                call    tohex                   ;; save in message

                dec     esi
                jnz     @@loop                  ;; any sel or reg left?

                ret
fill_sels_regs  endp

;;::::::::::::::
excpt_handler   proc    near
                ;; exception did occur in code32?
                push    eax
                mov     eax, cs
                cmp     ax, [esp+4+4+4+4+4+4]
                jne     @@chain

                ;; exception= 1 or= 3? redirect to debugger
                mov     eax, [esp+4]
                cmp     eax, 1
                je      @@chain
                cmp     eax, 3
                je      @@chain
                pop     eax

                ;; we need handle it...
                pushad
                PS      ds, es, fs, gs
                mov     ebp, esp

                ;; load the segregs with the ASSUMEd selectors
                mov     gs, cs:code16a_sel_32   ;; sel_tb is in code16
                assume  gs:code16
                mov     ds, gs:sel_tb[DATFLT_SEL]
                mov     es, gs:sel_tb[DGROUP_SEL]
                mov     fs, gs:sel_tb[CODE32A_SEL]

                ;; save info to print later
                mov     eax, [esp].EXCPT_STK.num
                mov     es:excpt_num, eax       ;; exception number

                mov     edi, O excpt_hex+1      ;; + in hex
                mov     ecx, 1                  ;; nibbles
                call    tohex                   ;; /

                call    fill_sels_regs          ;; + selectors + registers

                ;; make caller returns to excpt_ret32 proc
                ;; instead to the faulting instruction
                mov     [esp].EXCPT_STK._eip, O excpt_ret32

                ;; and set a proper stack (safe in case of a stack fault)
                mov     [esp].EXCPT_STK._ss, gs
                mov     eax, large gs:b4g$stack32_ptr
                add     eax, STACK32_SIZE
                mov     [esp].EXCPT_STK._esp, eax

                PP      gs, fs, es, ds
                popad
                add     esp, 4                  ;; free stack (num)
                retf

@@chain:        pop     eax
                xchg    eax, [esp]              ;; eax=0:num; save eax
                shl     eax, 1
                pushd   D cs:org_hnd_tb[eax*2+eax]  ;; ofs=org[num].ofs
                mov     ax, W cs:org_hnd_tb[eax*2+eax+4]
                xchg    eax, [esp+4]            ;; sel=org[num].sel; rest eax
                retf
excpt_handler   endp
CODE32_ENDS
                end
