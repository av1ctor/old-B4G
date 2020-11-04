;; name: xfopen
;; desc: open a existent or create a new file
;;
;; type: function
;; args: [out] xf:XFILE            | XFILE structure w/ info about the file
;;        [in] fname:string,       | file name
;;             mode:integer,       | mode (CREATE, APPEND, READ, WRITE)
;;             buffer_size:integer | real mode buffer size (0 if use default)
;; retn: integer                   | -1 if ok, 0 otherwise
;;
;; decl: xfopen% (seg xf as XFILE,_
;;                fname as string,_
;;                byval mode as integer,_
;;                byval buffSize as long)
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

data16          segment
xf$intx         INTX    <>
data16          ends


CODE_INI
;;::::::::::::::
xfopen          proc    uses di es,\
                        xf:far ptr XFILE,\
                        fname:near ptr STR_DSC,\
                        mode:word,\
                        buffer_size:dword
                
                ;; convert a BAS string to a zero terminated string
                mov     bx, fname               ;; ds:bx -> fname strg descpt
                mov     ax, ds
                mov     es, ax
                mov     dx, O b4g$buffer        ;; es:dx -> b4g$buffer
                call    bstrg_2_zstrg           
               
                les     di, xf                  ;; es:di -> xf

                mov     ax, mode
                mov     es:[di].XFILE.mode, ax
                mov     es:[di].XFILE.state, 0  ;; clear state
                               
                mov     bx, ax
                and     ax, not F_APPEND        ;; clear APPEND
                dec     al                      ;; DOS mode
                test    bx, F_CREATE
                jnz     @@create                ;; create file?

                mov     ah, DOS_FILE_OPEN
                int     DOS_INT
                jnc     @@save                  ;; ok?
                jmp     short @@error

@@create:       xor     cx, cx                  ;; type (archive)
                mov     ah, DOS_FILE_CREATE
                int     DOS_INT
                jc      @@error                 ;; error?

@@save:         mov     es:[di].XFILE.handle, ax ;; save file handle

                mov     ax, W buffer_size
                test    ax, ax
                jnz     @@alloc                 ;; alloc buffer?
                mov     W es:[di].XFILE.buffer, O b4g$buffer
                mov     W es:[di].XFILE.buffer+2, ds
                mov     es:[di].XFILE.buff_size, B4G_BUFFER_SIZE

@@insert:       call    xf$handle_add           ;; add to linked list

                test    es:[di].XFILE.mode, F_APPEND
                jnz     @@seek                  ;; append mode?

@@done:         clc
                mov     ax, TRUE                ;; return ok, CF clear
@@exit:         ret

@@alloc:        add     ax, 3
                and     ax, not 3               ;; make dword granular                
                and     eax, 0FFFFh
                mov     es:[di].XFILE.buff_size, eax
                invoke  malloc, eax
                jc      @F                      ;; error?

                mov     W es:[di].XFILE.buffer, ax
                mov     W es:[di].XFILE.buffer+2, dx
                jmp     short @@insert

@@:             mov     bx, es:[di].XFILE.handle
                mov     ah, DOS_FILE_CLOSE
                int     DOS_INT
                mov     ax, -1                  ;; error= FFFFh
                stc                             ;; set CF
                jmp     short @@error

@@seek:         xor     cx, cx
                xor     dx, dx
                mov     bx, es:[di].XFILE.handle
                mov     ax, (DOS_FILE_SEEK*256) or S_END
                int     DOS_INT
                jmp     short @@done

@@error:        mov     es:[di].XFILE.state, ax ;; save error type
                mov     ax, FALSE               ;; return error, CF set
                jmp     short @@exit
xfopen          endp
CODE_END
                end
