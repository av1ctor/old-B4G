;; name: xfpos
;; desc: get the current file position
;;
;; type: function
;; args: [in] xf:XFILE            | XFILE structure of file to get position
;; retn: long                     | current position (-1 if error)
;;
;; decl: xfpos& (seg xf as XFILE)
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

CODE_INI
;;::::::::::::::
xfpos           proc    uses di es,\
                        xf:far ptr XFILE

                les     di, xf                  ;; es:di -> xf

                ;; seek file 0 bytes from current position,
                ;; and then get the position when the service returns
                mov     bx, es:[di].XFILE.handle
                xor     dx, dx                  ;; LSW
                xor     cx, cx                  ;; MSW
                mov     ax, (DOS_FILE_SEEK*256) + S_CURRENT
                int     DOS_INT
                jc      @@error

                mov     es:[di].XFILE.state, 0  ;; clear state
                                                ;; return curr pos, CF clear
@@exit:         ret

@@error:        mov     es:[di].XFILE.state, ax ;; save error
                mov     ax, -1                  ;; return -1; CF set
                mov     dx, ax
                jmp     short @@exit
xfpos           endp
CODE_END
                end
