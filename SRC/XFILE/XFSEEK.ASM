;; name: xfseek
;; desc: change the file position
;;
;; type: function
;; args: [in] xf:XFILE,           | XFILE structure of file to seek
;;            origin:integer,     | seek origin: from start, current or end
;;            bytes:long          | distance from origin
;; retn: long                     | position after seek (0 if error)
;;
;; decl: xfseek& (seg xf as XFILE,_
;;                byval origin as integer,_
;;                byval bytes as long)
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

CODE_INI
;;::::::::::::::
xfseek          proc    uses di es,\
                        xf:far ptr XFILE,\
                        origin:word,\
                        bytes:dword

                les     di, xf                  ;; es:di -> xf

                ;; seek file
                mov     bx, es:[di].XFILE.handle
                mov     dx, W bytes             ;; LSW
                mov     cx, W bytes+2           ;; MSW
                mov     al, B origin
                mov     ah, DOS_FILE_SEEK
                int     DOS_INT
                jc      @@error

                mov     es:[di].XFILE.state, 0  ;; clear state
                                                ;; return new pos, CF clear
@@exit:         ret

@@error:        mov     es:[di].XFILE.state, ax ;; save error
                mov     ax, 0                   ;; return 0; CF set
                mov     dx, ax
                jmp     short @@exit
xfseek          endp
CODE_END
                end
