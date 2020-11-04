;;
;; internal mem module definitions
;;

                .model  medium, basic
                .386
                option  proc:private

                include ..\inc\equ.inc
                include ..\inc\bas.inc
                include ..\inc\dos.inc
                include ..\inc\mem.inc
                include ..\inc\core.inc

MEM             struct
                prev            word    ?
                next            word    ?
                paras           word    ?       ;; w/ header
MEM             ends

                ;; globals :::::

                ;; from mfree.asm:
                global  m$seg_tail:word
                global  m$queued:word, m$exit_q:EXIT_Q, m$done:proc
