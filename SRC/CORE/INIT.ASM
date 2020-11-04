;; name: b4ginit
;; desc: load a DPMI server if need, switch to pmode, create descriptors,
;;       allocate selectors, return to rmode...
;;
;; type: function
;; args: none
;; retn: integer           | result: B4G.ERROR.HOST (DPMI host not found),
;;                                   B4G.ERROR.BIT  (not a 32-bit host),
;;                                   B4G.ERROR.MEM  (not enough memory),
;;                                   B4G.ERROR.SWT  (cannot switch to pmode)
;;                                   or 0 if ok
;;
;; decl: b4ginit% ()
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

BR_DATA         segment word public use16 'DATA'
                extrn   __psp:word
BR_DATA         ends

                DGROUP  group BR_DATA

data16          segment

                DSC_TB_ENTRIES  equ 3

dsc_tb          label   DESCRIPTOR              ;; descriptors table
DSC_GEN         code32_dsc  ,  , 0FFFFFFFFh, EXEC_READ , , S32
DSC_GEN         dataflat_dsc, 0, 0FFFFFFFFh, READ_WRITE, , S32
DSC_GEN         code32a_dsc ,  , 0FFFFFFFFh, READ_WRITE, , S32

;;::
b4g$str_dsc     STR_DSC <>                      ;; BASIC's string descriptor

ifdef   __FAR_STRINGS__
b4g$fstr_seg_tb dw      ?
b4g$fstr_ofs_tb dw      NULL
                dw      ?

                dw      ?                       ;; far strg len (DON'T MOVE!)
endif
b4g$buffer      byte    B4G_BUFFER_SIZE+1 dup (?) ;; general purpose buffer

;;::
exec            RUN     <0, 80h, 0, 5Ch, ?, 6Ch, ?>
cws_fname       byte    'CWSDPMI.EXE', 0

                align   2
b4g$tmp_stk16   byte    100h dup (?)
data16          ends


CODE16_SEGMENT
                ;; this variables and arrays must be allocated here in 
                ;; code16 segment because they must be preserved when
                ;; BASIC's IDE reload the (or load a new) main module
b4g$installed   byte    FALSE
b4g$cws_loaded  byte    FALSE
b4g$mem_intcpt  byte    FALSE

;;:::
                SEL_TB_ENTRIES  equ DSC_TB_ENTRIES + 3

                align   2
sel_tb          word    SEL_TB_ENTRIES dup (0)  ;; selectors table

lin_tb          label   dword                   ;; segments linear table
                dword   CODE32_SEG              ;; same order as dsc_tb
                dword   DATFLT_SEG              ;; /
                dword   CODE32_SEG              ;; /
                dword   CODE16_SEG

seg_tb          word    4 dup (0)               ;; segments tb

;;:::
                NESTING_LEVEL   equ 4           ;; number of nesting allowed

                align   4
switch_buffer   SWITCH  NESTING_LEVEL dup (<>)
b4g$swt_buf_ptr dword   large O switch_buffer
b4g$rm_to_pm    dword   do_nothing
b4g$pm_to_rm    fword   ?

;;:::
        if      (SAVE_RESTORE_RM_STATE eq TRUE)
                align   4
sttbuff         byte    NESTING_LEVEL * 20h dup (?)
b4g$sttbuff_ptr dword   O sttbuff + NESTING_LEVEL * 20h
b4g$sttbuff_siz dword   0
b4g$rm_state    dword   ?
b4g$pm_state    fword   ?
        endif

;;:::
                align   4
stack32         byte    NESTING_LEVEL * STACK32_SIZE dup (?)
b4g$stack32_ptr dword   O stack32 + (NESTING_LEVEL * STACK32_SIZE)

do_nothing:     retf

;;::::::::::::::
b4ginit         proc
                local   dpmi_switch:dword

                ;; if b4g$exit was called, call B_ONEXIT to
                ;; put b4g$exit on exit queue 
                cmp     cs:b4g$exited, FALSE
                je      @F
                mov     cs:b4g$exited, FALSE
                PS      cs, O b4g$exit
                call    B_ONEXIT

@@:             ;; check if already been called
                cmp     cs:b4g$installed, TRUE
                je      @@unhook
                
                mov     bx, W cs:b4g$swt_buf_ptr
                ;; save return address, current stack ptr and es,fs,gs sregs
                mov     cs:[bx].SWITCH.rm_ip, O @@pm_return
                mov     cs:[bx].SWITCH.rm_sp, sp
                mov     cs:[bx].SWITCH.rm_es, es
                mov     cs:[bx].SWITCH.rm_fs, fs
                mov     cs:[bx].SWITCH.rm_gs, gs

                ;; save index registers
                mov     cs:[bx].SWITCH._edi, edi
                mov     cs:[bx].SWITCH._esi, esi
                mov     cs:[bx].SWITCH._ebp, ebp

                ;; setup segments table
                mov     cs:seg_tb[CODE32_SEG], S code32
                mov     cs:seg_tb[DATFLT_SEG], 0
                mov     cs:seg_tb[CODE16_SEG], cs
                mov     cs:seg_tb[DGROUP_SEG], ds

                ;; hook the DOS interrupt vector
                push    es
                mov     ax, DOS_INT_VECTOR_GET*256 + DOS_INT
                int     DOS_INT
                mov     W cs:org_dos_int+0, bx
                mov     W cs:org_dos_int+2, es
                pop     es

                push    ds
                mov     ax, cs
                mov     ds, ax
                mov     dx, O dos_int           ;; ds:dx -> dos_int
                mov     ax, DOS_INT_VECTOR_SET*256 + DOS_INT
                int     DOS_INT
                pop     ds

                ;; setup segments linear addresses table
                mov     bx, O lin_tb
                mov     cx, 4

@@loop_lin:     mov     di, W cs:[bx]           ;; get index into seg_tb
                movzx   eax, cs:seg_tb[di]      ;; get segment
                shl     eax, 4                  ;; convert to linear
                mov     cs:[bx], eax            ;; save
                add     bx, T dword             ;; next
                dec     cx
                jnz     @@loop_lin              ;; any left?

@@check_dpmi:   ;; check if a DPMI host is present
                mov     ax, DPMI_MD_SWITCH_PTR_GET
                int     2Fh
                test    ax, ax
                jnz     @@no_dpmi

                test    bl, 00000001b
                jz      @@bit_error             ;; supports 32-bit?

                mov     cs:b4g$installed, TRUE  ;; so, set as installed

                mov     W dpmi_switch+2, es     ;; save mode switch entry ptr
                mov     W dpmi_switch+0, di

                ;; allocate buffer to dpmi host if need
                test    si, si
                jz      @@enter

                ;; call BASIC memory manager to free memory
                movzx   eax, si
                inc     eax                     ;; +1 for MCB
                shl     eax, 4                  ;; paras to bytes
                neg     eax
                invoke  B$SETM, eax

                mov     bx, si
                mov     ah, DOS_MEM_ALLOC
                int     DOS_INT
                jc      @@mem_error             ;; error?
                mov     es, ax                  ;; es -> dpmi buffer

@@enter:        ;; ds= cs (to return as a code16 alias sel after swt to pm16)
                mov     ax, cs
                mov     ds, ax
                assume  ds:code16

                ;; enter in 16-bit protected mode
                mov     ax, 00000001b           ;; has 32-bit code
                call    dpmi_switch             ;; switch
                jc      @@swt_error

                ;; request descriptors in LDT
                mov     cx, DSC_TB_ENTRIES      ;; number of descriptors
                mov     ax, DPMI_DSC_ALLOC
                int     DPMI_INT
                jc      @@dsc_error
                mov     bx, ax                  ;; save base selector

                ;; fix up descriptors
                mov     dx, cs                  ;; get current privilege level
                and     dx, 0000000000000011b
                and     bx, 1111111111111100b
                or      bx, dx                  ;; correct base selector RPL
                shl     dx, 5                   ;; dl= CPL

                xor     si, si
                xor     di, di
                mov     cx, DSC_TB_ENTRIES

@@loop_fix:     ;; correct base (assume linear base <= 20-bit)
                mov     eax, cs:lin_tb[si]
                or      D ss:dsc_tb[di].DESCRIPTOR.base0_23, eax

                ;; correct DPL
                or      ss:dsc_tb[di].DESCRIPTOR.typ_dpl_p, dl
                
                add     si, T dword             ;; next base
                add     di, T DESCRIPTOR        ;; next descriptor
                dec     cx
                jnz     @@loop_fix              ;; any left?

                ;; store descriptors in LDT
                push    ss
                pop     es
                mov     edi, O dsc_tb           ;; es:edi -> dsc_tb
                mov     si, O sel_tb            ;; ds:si -> sel_tb
                mov     cx, DSC_TB_ENTRIES

     			mov     ax, DPMI_SEL_INC        ;; get selector incrase
                int     DPMI_INT
                mov		dx, ax
                                
@@loop_str:     mov     ds:[si], bx             ;; save selectors in sel_tb
                add     si, T word

                mov     ax, DPMI_DSC_SET        ;; store descriptor
                int     DPMI_INT

                add     bx, dx                  ;; next selector
                add     di, T DESCRIPTOR        ;; next descriptor
                dec     cx
                jnz     @@loop_str              ;; any left?

                mov     ds:sel_tb[CODE16_SEL], cs ;; save code16 selector
                mov     ds:sel_tb[DGROUP_SEL], ss ;; and DGROUP
                mov     ds:sel_tb[CODE16A_SEL],ds ;; and code16 alias
                
                ;; enter in 32-bit protected mode
                push    cs:sel_tb[CODE32_SEL]
                pushd   O b4g_init32
                RETFD

;;::::::::::::::
@@pm_return:    mov     bx, W cs:b4g$swt_buf_ptr
                ;; restore caller's fs,gs segments (DPMI raw switch trashs it)
                mov     fs, cs:[bx].SWITCH.rm_fs
                mov     gs, cs:[bx].SWITCH.rm_gs

                ;; restore index registers
                mov     edi, cs:[bx].SWITCH._edi
                mov     esi, cs:[bx].SWITCH._esi
                mov     ebp, cs:[bx].SWITCH._ebp

@@done:         xor     ax, ax                  ;; return 0; CF clear

@@exit:         ret

;;::::::::::::::
@@unhook:       call    b4g$unhook
                jmp     short @@done

;;::::::::::::::
@@no_dpmi:      ;; try to load CWS DPMI server
                call    load_cwsdpmi
                jnc     @@check_dpmi            ;; server loaded?

                mov     ax, B4G_ERROR_HOST      ;; no, return host not found
                jmp     short @@exit

;;::::::::::::::
@@error:        stc                             ;; return error; CF set
                jmp     short @@exit

@@bit_error:    mov     ax, B4G_ERROR_BIT       ;; return not 32-bit
                jmp     short @@error

@@mem_error:    mov     ax, B4G_ERROR_MEM       ;; return not enough memory
                jmp     short @@exit

@@swt_error:    mov     ax, B4G_ERROR_SWT       ;; return cannot switch mode
                jmp     short @@error

@@dsc_error:    ;; there's any other method? (i mean an easy one)
                mov     ax, (DOS_EXIT*256) + 0FFh
                int     DOS_INT
b4ginit         endp

;;::::::::::::::
exec_cnt        word    0
sav_1           word    ?
sav_2           word    0
load_cwsdpmi    proc    near uses bp di si es

                ;; save current DOS memory allocation strategy
                mov     ax, DOS_MEM_STRATEGY*256 + 00h
                int     DOS_INT
                mov     cs:sav_1, ax
                mov     ax, DOS_MEM_STRATEGY*256 + 02h
                int     DOS_INT
                mov     B cs:sav_2, al

                cmp     cs:b4g$cws_loaded, TRUE
                je      @@error                 ;; already loaded?

                ;; free memory to DOS load cwsdpmi.exe
                invoke  B$SETM, -65536          ;; 64K are enough (code+data)

                ;; change strategy to: first umb, then conventional
                mov     bx, 80h
                mov     ax, DOS_MEM_STRATEGY*256 + 01h
                int     DOS_INT
                mov     bx, 1h
                mov     ax, DOS_MEM_STRATEGY*256 + 03h
                int     DOS_INT

                ;; fixup exec struct
                mov     es, __psp               ;; es= PSP seg

                mov     exec.cmmd_line_sg, es   ;; cmmd_line= psp:80h
                mov     exec.fcb_1_sg, es       ;; fcb1= psp.5Ch
                mov     exec.fcb_2_sg, es       ;; fcb2= psp.6Ch

                mov     bp, es:[2Ch]
                xor     di, di                  ;; bp:di -> env block

                mov     ax, ds
                mov     es, ax                  ;; es= ds
                mov     bx, O exec              ;; es:bx -> exec
                mov     si, O b4g$buffer        ;; ds:si -> b4g$buffer
                mov     dx, si                  ;; /

                ;; 1) search current directory
                ;; 2)   /    executable directory
                ;; 3)   /    PATH environment variable directory(ies)
                mov     cs:exec_cnt, 0

@@loop_exec:    cmp     cs:exec_cnt, 1
                jl      @@add_fname             ;; cnt=0?
                je      @@get_from_exe_dir      ;; cnt=1?

                cmp     cs:exec_cnt, 2
                jne     @@get_from_path_var     ;; cnt>2?
                jmp     @@find_path_var         ;; cnt=2?

@@add_fname:    ;; b4g$buffer+= 'CWSDPMI.EXE\0'
                push    di
                mov     di, si                  ;; es:di -> b4g$buffer[si]
                mov     si, O cws_fname         ;; ds:si -> cws_fname
                mov     cx, 12
                rep     movsb
                pop     di

                mov     si, dx                  ;; restore

                mov     ax, DOS_EXEC*256 + 00h
                int     DOS_INT
                inc     cs:exec_cnt
                jc      @@loop_exec             ;; found? loop if not

                ;; now check if is the correct version (CWS for B4G)
                mov     ah, DOS_RETCOD_GET
                int     DOS_INT
                cmp     al, 0FFh
                jne     @@error                 ;; return code= FFh?

                mov     cs:b4g$cws_loaded, TRUE ;; return ok (CF clear)

@@exit:         sbb     cx, cx                  ;; save CF

                ;; restore DOS memory allocation strategy
                mov     bx, cs:sav_1
                mov     ax, DOS_MEM_STRATEGY*256 + 01h
                int     DOS_INT
                mov     bx, cs:sav_2
                mov     ax, DOS_MEM_STRATEGY*256 + 03h
                int     DOS_INT

                ;; give to BASIC any free memory
                invoke  B$SETM, 07FFFFFFFh

                shr     cx, 1                   ;; restore CF
                ret

@@error:        stc                             ;; return error (CF set)
                jmp     short @@exit

;;::::::::::::::
@@find_path_var:
                ;; search for 'PATH' variable and the '=' char
                push    es
                mov     es, bp
                xor     al, al                  ;; '\0'
                mov     cx, 32768               ;; max environment size
                jmp     short @@chk_path
                
@@find_var:     repne   scasb
                jne     @@error

@@chk_path:     cmp     es:[di], al
                je      @@error

                cmp     D es:[di], 48544150h    ;; 'PATH'
                jne     @@find_var
                cmp     B es:[di+4], '='        ;; '='
                jne     @@find_var
                add     di, 5
                pop     es

;;::::::::::::::
@@get_from_path_var:
                push    es
                mov     es, bp                  ;; es= env block seg

                ;; b4g$buffer= PATH[di] until char ';' or '\0'
                jmp     short @@test_path
@@loop_path:    mov     ds:[si], al
                inc     si
@@test_path:    mov     al, es:[di]
                inc     di
                test    al, al
                jz      @@end_path
                cmp     al, ';'
                jne     @@loop_path
                
@@end_path:     pop     es

                cmp     si, dx
                je      @@error                 ;; path lenght= 0?

                ;; b4g$buffer last char= '\'?
                cmp     B ds:[si-1], '\'
                je      @@add_fname
                mov     B ds:[si], '\'          ;; no, so, add it
                inc     si
                jmp     @@add_fname

;;::::::::::::::
@@get_from_exe_dir:
                ;; search: '\0\0' then '\0' then '\'
                PS      bx, di, es, ds
                mov     es, bp                  ;; es= env block seg

                xor     ax, ax                  ;; '\0'
                mov     cx, 32768               ;; max env. size
@@loop_00:      repne   scasb
                jne     @@no_exe_dir
                scasb
                jne     @@loop_00
                
                cmp     es:[di], ax
                je      @@no_exe_dir            ;; any string following?

                ;; get exe full path length
                add     di, 2
                mov     bx, di
                mov     cx, 128
                repne   scasb                   

                ;; exclude exe file name (go to last slash)
                std
                mov     al, '\'
                neg     cx
                add     cx, 128
                repne   scasb
                cld
                
                mov     cx, di
                sub     cx, bx
                add     cx, 2                   ;; cx= exe dir (w/o exe name)

                ;; move it to b4g$buffer
                mov     si, bx
                mov     di, dx
                mov     ax, ds
                push    es
                pop     ds                      ;; ds:si -> exe dir
                mov     es, ax                  ;; es:di -> b4g$buffer
                rep     movsb
                mov     si, di
                PP      ds, es, di, bx
                jmp     @@add_fname

@@no_exe_dir:   PP      ds, es, di, bx
                inc     cs:exec_cnt             ;; jump exe dir
                jmp     @@loop_exec
load_cwsdpmi    endp

                include dos_int.inc

signature       byte    13,10,13,10
                byte    '| BASIC/4G library version 1E-32 beta                |',13,10
                byte    '| copyleft Oct/2000 by v1ctor [av1ctor@yahoo.com.br] |',13,10
                byte    13,10,13,10
CODE16_ENDS


CODE32_SEGMENT
code16a_sel_32  word    ?

b4g$mem_inf_ofs dword   0                       ;; 0 or 8
b4g$pg_shift    byte    0                       ;; 0, 12 or 22

;;::::::::::::::
b4g_init32      proc    near
                ;; setup stack
                mov     ax, ds
                mov     ss, ax                  ;; ss= code16 alias
                mov     esp, ss:b4g$stack32_ptr
                sub     ss:b4g$stack32_ptr, STACK32_SIZE

                ;; load selectors (as ASSUMEd)
                mov     ds, ss:sel_tb[DATFLT_SEL]
                mov     es, ss:sel_tb[DGROUP_SEL]
                mov     fs, ss:sel_tb[CODE32A_SEL]

                mov     ax, ss:sel_tb[CODE16A_SEL]
                mov     fs:code16a_sel_32, ax

        if      (SAVE_RESTORE_RM_STATE eq TRUE)
                ;; get dpmi save state functions addr & save state buffer size
                mov     eax, DPMI_STT_SAVE_REST_GET
                int     DPMI_INT
                mov     large W ss:b4g$rm_state, cx
                mov     large W ss:b4g$rm_state+2, bx
                mov     large D ss:b4g$pm_state, edi
                mov     large W ss:b4g$pm_state+4, si
                mov     large W ss:b4g$sttbuff_siz, ax
        endif

                ;; get dpmi raw switch functions address
                mov     eax, DPMI_RAW_SWITCH_GET
                int     DPMI_INT
                mov     large W ss:b4g$rm_to_pm, cx
                mov     large W ss:b4g$rm_to_pm+2, bx
                mov     large D ss:b4g$pm_to_rm, edi
                mov     large W ss:b4g$pm_to_rm+4, si
                
                ;; check if host fills in mem_info struct,
                ;; fields others than the first
                PS      edi, es
                mov     eax, ss
                mov     es, eax
                sub     esp, 30h
                mov     edi, esp                ;; es:edi -> 30h bytes buffer
                mov     eax, DPMI_MEM_FREE_GETINFO
                int     DPMI_INT
                cmp     D es:[edi+8], -1        ;; chk field 8 (lockable pgs)
                lea     esp, [esp + 30h]
                PP      es, edi
                je      @F                      ;; not?

                ;; get the dpmi host page size
                mov     eax, DPMI_PAGE_SIZE_GET
                int     DPMI_INT
                jc      @F
                shl     ebx, 16
                mov     bx, cx                  ;; ebx= page size
                bsf     ecx, ebx                ;; get lastest set bit
                jz      @F                      ;; size= 0?
                mov     fs:b4g$pg_shift, cl     ;; save as shift
                mov     fs:b4g$mem_inf_ofs, 8   ;; info f/ pages lockable (8)

@@:             ;; install the exceptions handler
                call    b4g$excpt_inst

                SV_RM_STT                       ;; save real mode state

                ;; switch to real mode (return to b4ginit)
                mov     ebp, large ss:b4g$swt_buf_ptr
                mov     ss:[ebp].SWITCH.pm_gs, 0;; gs sel= NULL
                RET2RM
b4g_init32      endp
CODE32_ENDS
                end
