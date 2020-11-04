;; name: mfree
;; desc: free a conventional memory block
;;
;; type: sub
;; args: [in/out] fptr:long    | memory block far pointer
;; retn: none
;;
;; decl: mfree (seg fptr as long)
;;
;; updt: jul/00 [v1ctor]
;; obs.: if block exists, fptr will be set to NULL

                include common.inc

CODE16_SEGMENT
m$queued        word    FALSE
m$exit_q        EXIT_Q  <>
m$seg_tail      word    NULL

;;::::::::::::::
m$done          proc    uses ax es

                mov     es, cs:m$seg_tail       ;; es -> seg_tail
                jmp     short @@test

@@loop:         push    es:[MEM.prev]           ;; walk down
                mov     W cs:@@fptr+2, es       ;; fake a fptr to fool mfree
                PS      cs, O @@fptr
                call    mfree
                pop     es

@@test:         mov     ax, es
                test    ax, ax
                jnz     @@loop                  ;; last seg?

                mov     cs:m$queued, FALSE      ;; reinstall if need
                ret

@@fptr          dword   NULL
m$done          endp

;;::::::::::::::
mfree           proc    uses ds es,\
                        fptr:far ptr dword

                mov     cs:b4g$mem_intcpt, TRUE ;; alert dos_int

                lds     bx, fptr                ;; ds:bx -> fptr

                mov     ax, ds:[bx+2]           ;; get seg
                test    ax, ax
                jz      @@exit                  ;; seg= NULL?

                dec     ax                      ;; -> header
                mov     es, ax

                mov     cx, es:[MEM.prev]       ;; cx= block.prev
                mov     dx, es:[MEM.next]       ;; dx= block.next

                mov     ah, DOS_MEM_FREE
                int     DOS_INT
                jc      @@exit                  ;; error?

                xor     eax, eax
                mov     ds:[bx], eax            ;; fptr= NULL

                ;; update linked list
                test    cx, cx
                jz      @@next                  ;; block.prev= NULL?
                mov     es, cx
                mov     es:[MEM.next], dx       ;; block.prev.next= block.next

@@next:         test    dx, dx
                jz      @@set_tail              ;; block.next= NULL?
                mov     es, dx
                mov     es:[MEM.prev], cx       ;; block.next.prev= block.prev

@@done:         clc                             ;; return ok

@@exit:         mov     cs:b4g$mem_intcpt, FALSE
                ret

@@set_tail:     mov     cs:m$seg_tail, cx       ;; tail= block.prev
                jmp     short @@done
mfree           endp
CODE16_ENDS
                end
