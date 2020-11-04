;; name: malloc
;; desc: allocate a conventional memory block
;;
;; type: function
;; args: [in] bytes:long       | number of bytes to allocate
;; retn: long                  | far pointer of block (0 if error)
;;
;; decl: malloc& (byval bytes as long)
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc


CODE16_SEGMENT
;;::::::::::::::
malloc          proc    uses es,\
                        bytes:dword

                mov     cs:b4g$mem_intcpt, TRUE ;; alert dos_int

                ;; add the done proc to exit queue if need
                cmp     cs:m$queued, TRUE
                je      @F
                mov     cs:m$queued, TRUE
                PS      cs, O m$exit_q, cs, O m$done, PRIORITY_LAST
                call    b4g$exit_q

@@:             mov     ebx, bytes
                add     ebx, 16 + 15            ;; +header +align
                shr     ebx, 4                  ;; convert to paragraph
                mov     ah, DOS_MEM_ALLOC
                int     DOS_INT
                jc      @@error                 ;; error?
                mov     es, ax

                ;; update linked list
                mov     es:[MEM.paras], bx      ;; save block size
                mov     bx, cs:m$seg_tail
                mov     es:[MEM.prev], bx       ;; block.preview= seg_tail
                mov     es:[MEM.next], NULL     ;; block.next= NULL
                mov     cs:m$seg_tail, ax       ;; seg_tail= block
                test    bx, bx
                jz      @@done                  ;; seg_tail= NULL?
                mov     es, bx
                mov     es:[MEM.next], ax       ;; seg_tail.next= block

@@done:         inc     ax                      ;; skip header (16 bytes)
                mov     dx, ax
                xor     ax, ax                  ;; return dx:ax, ok (CF=0)

@@exit:         mov     cs:b4g$mem_intcpt, FALSE
                ret

@@error:        mov     ax, 0
                mov     dx, ax                  ;; return 0, error (CF=1)
                jmp     short @@exit
malloc          endp
CODE16_ENDS
                end
