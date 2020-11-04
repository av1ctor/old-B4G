;; name: xfflush
;; desc: flush file buffer to disk
;;
;; type: sub
;; args: [in] xf:XFILE            | XFILE structure of file to flush
;; retn: none
;;
;; decl: xfflush (seg xf as XFILE)
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

CODE_INI
;;::::::::::::::
xfflush         proc    uses di es,\
                        xf:far ptr XFILE

                les     di, xf                  ;; es:di -> xf

                mov     bx, es:[di].XFILE.handle
                mov     ah, DOS_FILE_FLUSH
                int     DOS_INT
                jc      @@error

                mov     es:[di].XFILE.state, 0  ;; clear state
                                                ;; return curr pos, CF clear
@@exit:         ret

@@error:        mov     es:[di].XFILE.state, ax ;; save error
                jmp     short @@exit
xfflush         endp
CODE_END
                end
