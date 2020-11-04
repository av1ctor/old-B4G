;;
;; internal xmap module definitions
;;

                .model  medium, basic
                .386
                option  proc:private
                
                include ..\inc\equ.inc
                include ..\inc\addr.inc
                include ..\inc\bas.inc
                include ..\inc\core.inc
                include ..\inc\mem.inc
                include ..\inc\xmap.inc

XMAP            struct
                _size           dd      ?
                blk_addr        dd      ?
                blk_size        dd      ?
                buff_ini        dd      ?
                buff_end        dd      ?
                wr_ini          dd      ?
                wr_end          dd      ?                
XMAP            ends

                ;; globals :::::

                ;; from xmap.asm:
                global  xmp$bufferize32:near32
