;; name: mrealloc
;; desc: resize a conventional memory block previously allocated
;;
;; type: function
;; args: [in/out] fptr:long     | far pointer of block to resize
;;       [in] bytes:long        | new block size in bytes
;; retn: integer                | result: 0 if ok, DOS error code otherwise
;;
;; decl: mrealloc% (seg blk as long,_
;;                  byval bytes as long)
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc


CODE16_SEGMENT
;;::::::::::::::
mrealloc        proc    uses di es ds,\
                        fptr:far ptr dword,\
                        bytes:dword

                mov     cs:b4g$mem_intcpt, TRUE ;; alert dos_int

                ;; add the done proc to exit queue if need
                cmp     cs:m$queued, TRUE
                je      @F
                mov     cs:m$queued, TRUE
                PS      cs, O m$exit_q, cs, O m$done, PRIORITY_LAST
                call    b4g$exit_q

@@:             lds     di, fptr                ;; ds:di -> fptr

                mov     cx, ds:[di+2]           ;; get seg
                dec     cx                      ;; -> header
                mov     es, cx

                mov     ebx, bytes
                add     ebx, 16 + 15            ;; +header +align
                shr     ebx, 4                  ;; convert to paragraph
                mov     ah, DOS_MEM_RESIZE
                int     DOS_INT
                jc      @@exit                  ;; error?

                ;; read dos_int.inc and see why DOS memory resize 
                ;; service acts different than the normal way
                mov     ax, es

                mov     es:[MEM.paras], bx      ;; save new size

                cmp     cx, ax
                je      @@done                  ;; block addr did change?

                ;; yep! so, update linked list
                mov     bx, es:[MEM.prev]
                mov     cx, es:[MEM.next]

                test    bx, bx
                jz      @F                      ;; block.preview= NULL?
                mov     es, bx
                mov     es:[MEM.next], ax       ;; block.preview.next= block

@@:             test    cx, cx
                jz      @@set_tail              ;; block.next= NULL?
                mov     es, cx
                mov     es:[MEM.prev], ax       ;; block.next.preview= block

@@done:         inc     ax                      ;; skip header (16 bytes)
                mov     ds:[di+2], ax           ;; fptr+2= new seg
                xor     ax, ax                  ;; return 0, ok (CF=0)

@@exit:         mov     cs:b4g$mem_intcpt, FALSE
                ret

@@set_tail:     mov     cs:m$seg_tail, ax       ;; tail= block
                jmp     short @@done
mrealloc        endp
CODE16_ENDS
                end
