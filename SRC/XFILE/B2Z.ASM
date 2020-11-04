;;
;; b2z.asm -- helper function to convert a BASIC string to a
;;            null terminated string
;;

                include common.inc

CODE_INI
;;::::::::::::::
bstrg_2_zstrg   proc    near uses di si ds
                ;;  in: ds:bx -> BASIC's string descriptor
                ;;      es:dx -> null terminated string

                mov     di, dx                  ;; es:di -> zstrg

                ;; ds:si -> bstrg.data; cx= bstrg.len
                BSTRG   bx, ds, si, cx
                and     cx, B4G_BUFFER_SIZE     ;; clip

                mov     ax, cx
                and     ax, 3                   ;; % 4
                shr     cx, 2                   ;; / 4
                rep     movsd
                mov     cx, ax
                rep     movsb
                mov     es:[di], cl             ;; null terminator

                ret
bstrg_2_zstrg   endp
CODE_END
                end
