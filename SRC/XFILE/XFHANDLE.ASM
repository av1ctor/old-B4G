;;
;; xfhandle.asm -- helper functions to add and del file handles
;;

                include common.inc


CODE_INI
queued          word    FALSE
exit_q          EXIT_Q  <>
file_tail       dword   NULL

;;::::::::::::::
done            proc    uses ax di es
                les     di, cs:file_tail        ;; es:di -> file_tail
                jmp     short @@test

@@loop:         invoke  xfclose, es::di
                les     di, es:[di].XFILE.prev  ;; walk down

@@test:         mov     ax, es
                or      ax, di
                jnz     @@loop                  ;; last file?

                mov     cs:queued, FALSE        ;; reinstall if need
                ret
done            endp

;;::::::::::::::
xf$handle_add   proc    near uses ebx ds
                ;;  in: es:di -> file struct

                ;; add the done proc to exit queue if need
                cmp     cs:queued, TRUE
                je      @F
                mov     cs:queued, TRUE
                PS      cs, O exit_q, cs, O done, PRIORITY_FIRST
                call    b4g$exit_q

@@:             ;; ebx= dx:bx= file_tail
                mov     edx, cs:file_tail
                mov     ebx, edx
                shr     edx, 16

                mov     es:[di].XFILE.prev, ebx ;; xf.prev= tail
                mov     es:[di].XFILE.next, NULL;; xf.next= NULL

                mov     ax, es
                shl     eax, 16
                mov     ax, di                  ;; eax= xf

                mov     cs:file_tail, eax       ;; tail= xf

                test    ebx, ebx
                jz      @@exit                  ;; tail= NULL?
                mov     ds, dx
                mov     ds:[bx].XFILE.next, eax ;; tail.next = xf

@@exit:         ret
xf$handle_add   endp

;;::::::::::::::
xf$handle_del   proc    near uses ebx esi ds
                ;;  in: es:di -> file struct

                ;; ebx= dx:bx= xf.prev
                mov     edx, es:[di].XFILE.prev
                mov     ebx, edx
                shr     edx, 16

                ;; esi= ax:si= xf.next
                mov     eax, es:[di].XFILE.next
                mov     esi, eax
                shr     eax, 16

                test    ebx, ebx
                jz      @F                      ;; xf.prev= NULL?
                mov     ds, dx
                mov     ds:[bx].XFILE.next, esi ;; xf.prev.next= xf.next

@@:             test    esi, esi
                jz      @@set_tail              ;; xf.next= NULL?
                mov     ds, ax
                mov     ds:[si].XFILE.prev, ebx ;; xf.next.prev= xf.prev

@@exit:         ret

@@set_tail:     mov     cs:file_tail, ebx       ;; tail= xf.prev
                jmp     short @@exit
xf$handle_del   endp
CODE_END
                end
