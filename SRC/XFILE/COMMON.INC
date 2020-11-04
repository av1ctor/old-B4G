;;
;; internal xfile module definitions
;;

                .model  medium, basic
                .386
                option  proc:private
                
                include ..\inc\equ.inc
                include ..\inc\addr.inc
                include ..\inc\dos.inc
                include ..\inc\bas.inc
                include ..\inc\mem.inc
                include ..\inc\core.inc
                include ..\inc\xfile.inc

;;::::::::::::::
CODE_INI        macro
xf_text         segment word public use16 'CODE'
                assume  cs:xf_text, ds:DGROUP, ss:DGROUP
endm

;;::::::::::::::
CODE_END        macro
xf_text         ends
endm

                ;; globals :::::

                ;; from xfopen.asm:
                global  xf$intx:INTX

                ;; from handle.asm:
                global  xf$handle_add:near16
                global  xf$handle_del:near16

                ;; from b2z.asm:
                global  bstrg_2_zstrg:near16
