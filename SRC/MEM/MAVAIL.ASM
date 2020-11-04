;; name: mavail
;; desc: return the largest free conventional memory block size
;;
;; type: function
;; args: none
;; retn: long                  | largest free block size
;;
;; decl: mavail& ()
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc


CODE16_SEGMENT
;;::::::::::::::
mavail          proc    

                mov     cs:b4g$mem_intcpt, TRUE ;; alert dos_int

                mov     bx, 0FFFFh              ;; largest possible size
                mov     ah, DOS_MEM_ALLOC
                int     DOS_INT
                mov     ax, bx                  ;; convert paras to bytes
                mov     dx, ax                  ;; /
                shl     ax, 4                   ;; /
                shr     dx, 16-4                ;; /

                mov     cs:b4g$mem_intcpt, FALSE
                ret
mavail          endp
CODE16_ENDS
                end
