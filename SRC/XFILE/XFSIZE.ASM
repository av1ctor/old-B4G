;; name: xfsize
;; desc: get the current file size
;;
;; type: function
;; args: [in] xf:XFILE            | XFILE structure of file to get the size
;; retn: long                     | current size (-1 if error)
;;
;; decl: xfsize& (seg xf as XFILE)
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

CODE_INI
;;::::::::::::::
xfsize          proc    uses di es,\
                        xf:far ptr XFILE

                les     di, xf                  ;; es:di -> xf

                ;; get the current file position,
                ;; seeking 0 bytes from current position
                mov     bx, es:[di].XFILE.handle
                xor     dx, dx                  ;; LSW
                xor     cx, cx                  ;; MSW
                mov     ax, (DOS_FILE_SEEK*256) + S_CURRENT
                int     DOS_INT
                jc      @@error

                PS      ax, dx                  ;; save it

                ;; get the current file size,
                ;; seeking 0 bytes from the end of file
                xor     dx, dx                  ;; LSW
                xor     cx, cx                  ;; MSW
                mov     ax, (DOS_FILE_SEEK*256) + S_END
                int     DOS_INT

                xchg    dx, [esp+2]             ;; cx:dx= old pos; stk=dx:ax
                xchg    ax, [esp+0]             ;; /
                mov     cx, ax                  ;; /

                ;; restore old position
                mov     ax, (DOS_FILE_SEEK*256) + S_START
                int     DOS_INT

                mov     es:[di].XFILE.state, 0  ;; clear state
                PP      ax, dx                  ;; return curr size, CF clear

@@exit:         ret

@@error:        mov     es:[di].XFILE.state, ax ;; save error
                mov     ax, -1                  ;; return -1; CF set
                mov     dx, ax
                jmp     short @@exit
xfsize          endp
CODE_END
                end
