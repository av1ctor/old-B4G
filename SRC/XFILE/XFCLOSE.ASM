;; name: xfclose
;; desc: close a file previously opened
;;
;; type: sub
;; args: [in] xf:XFILE            | XFILE structure of file to close
;; retn: none
;;
;; decl: xfclose (seg xf as XFILE)
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

CODE_INI
;;::::::::::::::
xfclose         proc    uses di es,\
                        xf:far ptr XFILE

                les     di, xf                  ;; es:di -> xf

                ;; close file
                mov     bx, es:[di].XFILE.handle
                mov     ah, DOS_FILE_CLOSE
                int     DOS_INT
                jc      @@error

                ;; xf.buffer= b4g$buffer? if not, free xf.buffer
                mov     dx, ds
                shl     edx, 16
                mov     dx, O b4g$buffer        ;; edx= ds:b4g$buffer

                cmp     edx, es:[di].XFILE.buffer
                je      @@del_hdl
                lea     ax, [di].XFILE.buffer
                invoke  mfree, es::ax

@@del_hdl:      call    xf$handle_del           ;; delete from linked list

                mov     es:[di].XFILE.state, 0  ;; clear state

@@exit:         ret

@@error:        mov     es:[di].XFILE.state, ax ;; save error
                jmp     short @@exit
xfclose         endp
CODE_END
                end
