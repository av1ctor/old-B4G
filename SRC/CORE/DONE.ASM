;; name: b4gdone
;; desc: free allocated conventional and extended memory, close opened files
;;
;; type: sub
;; args: none
;; retn: none
;;
;; decl: b4gdone ()
;;
;; updt: jul/00 [v1ctor]
;; obs.: only need when using B4G in the IDE (qb.exe, qbx.exe or vbdos.exe)

                include common.inc


CODE16_SEGMENT
b4g$exited      byte    TRUE
hooked          byte    FALSE

org_dos_int     dword   ?
dos_error_level byte    ?, ?

exit_q_tail     dword   NULL

;;::::::::::::::
b4gdone         proc
                cmp     cs:b4g$installed, FALSE
                je      @@exit

                cmp     cs:exit_q_tail, NULL
                je      @F                      ;; any proc on queue?
                call    de_queue

@@:             mov     es, cs:seg_tb[CODE32_SEG]
                cmp     es:exit_q_tail32, NULL
                je      @@exit                  ;; any proc32 on queue?
                CALLPM  de_queue32
                
@@exit:         ret
b4gdone         endp

;;::::::::::::::
;; only called be BASIC after the program ends or an error occurs. in
;; the IDE it's only called when the program starts!
b4g$exit        proc
                ;; check if b4g was successfully initialized
                cmp     cs:b4g$installed, FALSE
                je      @@exit

                mov     cs:b4g$exited, TRUE     ;; alert b4ginit

                ;; called another time w/o call b4ginit first? strange...
                cmp     cs:hooked, TRUE
                je      @@exit
                mov     cs:hooked, TRUE

                ;; else, call procs on exit queue
                cmp     cs:exit_q_tail, NULL
                je      @F                      ;; any proc on queue?
                call    de_queue
@@:             cmp     cs:exit_q_tail32, NULL
                je      @@hook                  ;; any proc32 on queue?
                CALLPM  de_queue32

@@hook:         ;; get current DOS interrupt vector
                push    es
                mov     ax, (DOS_INT_VECTOR_GET * 256) or DOS_INT
                int     DOS_INT
                mov     W cs:org_dos_int, bx
                mov     W cs:org_dos_int+2, es
                pop     es

                ;; set new dos interrupt vector (dos_exit_intcpt proc)
                push    ds
                mov     ax, cs
                mov     ds, ax
                mov     dx, O dos_exit_intcpt
                mov     ax, (DOS_INT_VECTOR_SET * 256) or DOS_INT
                int     DOS_INT
                pop     ds
                
@@exit:         ret
b4g$exit        endp

;;::::::::::::::
b4g$unhook      proc    near
                ;; if was not hooked, return
                cmp     cs:hooked, FALSE
                je      @@exit
                mov     cs:hooked, FALSE

                ;; else, restore orginal DOS interrupt vector
                push    ds
                lds     dx, cs:org_dos_int
                mov     ax, (DOS_INT_VECTOR_SET * 256) or DOS_INT
                pushf
                call    cs:org_dos_int
                pop     ds

@@exit:         ret
b4g$unhook      endp

;;::::::::::::::
b4g$exit_q      proc    uses eax ebx edx di es\
                        exit_q:far ptr EXIT_Q,\
                        procptr:far ptr,\
                        _priority:word
                
                les     di, exit_q              ;; es:di -> exit_q struct

                mov     ax, _priority
                mov     es:[di].EXIT_Q.priority, ax
                mov     eax, procptr
                mov     es:[di].EXIT_Q.proc_ptr, eax

                ;; ebx= dx:bx= tail
                mov     ebx, cs:exit_q_tail
                mov     edx, ebx
                shr     edx, 16                 

                mov     es:[di].EXIT_Q.prev, ebx;; exit_q.prev= tail
                mov     es:[di].EXIT_Q.next,NULL;; exit_q.next= NULL

                mov     ax, es
                shl     eax, 16
                mov     ax, di                  ;; eax= es:di

                mov     cs:exit_q_tail, eax     ;; tail= exit_q

                test    ebx, ebx
                jz      @@exit                  ;; tail= NULL?
                mov     es, dx
                mov     es:[bx].EXIT_Q.next, eax;; tail.next = exit_q

@@exit:         ret
b4g$exit_q      endp

;;::::::::::::::
de_queue        proc    near uses ax cx di es

                mov     cx, PRIORITY_FIRST

@@de_queue:     les     di, cs:exit_q_tail      ;; es:di -> tail
                jmp     short @@test

@@loop:         cmp     es:[di].EXIT_Q.priority, cx
                jne     @@prev
                PS      cx, di, es
                call    es:[di].EXIT_Q.proc_ptr
                PP      es, di, cx
@@prev:         les     di, es:[di].EXIT_Q.prev ;; walk down

@@test:         mov     ax, es
                or      ax, di
                jnz     @@loop                  ;; last in queue?

                dec     cx
                jnz     @@de_queue              ;; last priority?

                mov     cs:exit_q_tail, NULL    ;; nothing more on exit queue
                ret
de_queue        endp

;;::::::::::::::
;; hooks DOS int vector to intercept the exit service, then switch to
;; pmode and issue an exit from there. only installed when b4g$exit is
;; called by BASIC when processing the exit chain. must be the first
;; one, otherwise CWS will get it.
dos_exit_intcpt proc
                PS      ax, dx
                mov     dx, ax
                lahf                            ;; save flags

                cmp     dh, DOS_EXIT
                je      @@exit                  ;; trying exit?

@@chain:        sahf                            ;; restore flags
                PP      dx, ax
                jmp     cs:org_dos_int          ;; chain to dos

@@exit:         PP      dx, ax
                mov     cs:dos_error_level, al  ;; save error level

                ;; restore orginal dos interrupt vector
                lds     dx, cs:org_dos_int
                mov     ax, (DOS_INT_VECTOR_SET * 256) or DOS_INT
                push    W [esp+4]               ;; duplicate flags
                call    cs:org_dos_int
                
                ;; return to pmode & exit
                pushd   O exit32
                call    call_pmode_nr
dos_exit_intcpt endp
CODE16_ENDS


CODE32_SEGMENT
exit_q_tail32   dword   NULL

;;::::::::::::::
exit32          proc    near
                ;; remove the exceptions handler
                call    b4g$excpt_remv

                ;; some hosts don't free descriptors automaticaly
                ;; so, we must free ourself
                ;; ...

                ;; return to real mode and exit
                mov     al, ss:dos_error_level
                mov     ah, DOS_EXIT
                int     DOS_INT
exit32          endp

;;::::::::::::::
b4g$exit_q32    proc    near uses eax ebx\
                        exit_q:near32 ptr EXIT_Q,\
                        procptr:near32 ptr,\
                        _priority:dword
                
                mov     ebx, exit_q              ;; fs:ebx -> exit_q struct

                mov     eax, _priority
                mov     fs:[ebx].EXIT_Q.priority, ax
                mov     eax, procptr
                mov     fs:[ebx].EXIT_Q.proc_ptr, eax

                mov     eax, fs:exit_q_tail32

                mov     fs:[ebx].EXIT_Q.prev, eax;; exit_q.prev= tail32
                mov     fs:[ebx].EXIT_Q.next,NULL;; exit_q.next= NULL

                mov     fs:exit_q_tail32, ebx   ;; tail32= exit_q

                test    eax, eax
                jz      @@exit                  ;; tail32= NULL?
                mov     fs:[eax].EXIT_Q.next,ebx;; tail.next = exit_q

@@exit:         ret
b4g$exit_q32    endp

;;::::::::::::::
de_queue32      proc    near uses ecx edi

                mov     ecx, PRIORITY_FIRST

@@de_queue:     mov     edi, fs:exit_q_tail32   ;; ss:edi -> tail
                jmp     short @@test

@@loop:         cmp     fs:[edi].EXIT_Q.priority, cx
                jne     @@prev
                PS      ecx, edi
                call    fs:[edi].EXIT_Q.proc_ptr
                PP      edi, ecx
@@prev:         mov     edi, fs:[edi].EXIT_Q.prev ;; walk down

@@test:         test    edi, edi
                jnz     @@loop                  ;; last in queue?

                dec     ecx
                jnz     @@de_queue              ;; last priority?

                mov     fs:exit_q_tail32, NULL  ;; nothing more on exit queue
                ret
de_queue32      endp
CODE32_ENDS
                end
