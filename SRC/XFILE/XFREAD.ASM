;; name: xfread
;; desc: read a block of data from a file to memory (extended or
;;       conventional)
;;
;; type: function
;; args: [in] xf:XFILE,           | XFILE structure of file to read
;;            dst:long,           | linear address of destine memory block
;;            bytes:long          | number of bytes to read
;; retn: long                     | number of bytes read (0 if error)
;;
;; decl: xfread& (seg xf as XFILE, byval dst as long,_
;;                byval bytes as long)
;;
;; updt: jul/00 [v1ctor]
;; obs.: if destine address is less than 1M, no switch will be made

                include common.inc

CODE_INI
;;::::::::::::::
xfread          proc    uses edi esi es ds,\
                        xf:far ptr XFILE,\
                        destine:dword,\
                        bytes:dword
                local   bytes_rd:dword

                les     di, xf                  ;; es:di -> xf

                mov     bx, es:[di].XFILE.handle
                mov     esi, bytes
                mov     edx, destine

                lea     eax, [edx + esi - 1]
                cmp     eax, 100000h
                jb      @@huge_read             ;; destine < 1M?

                ;; no, ...
                mov     eax, es:[di].XFILE.buffer
                mov     ecx, es:[di].XFILE.buff_size
                mov     edi, edx
                push    di
                CALLPM  xfread32                
                pop     di
                jc      @@error
                mov     bytes_rd, eax

@@done:         mov     es:[di].XFILE.state, 0  ;; clear state
                mov     ax, W bytes_rd          ;; return bytes read, CF clear
                mov     dx, W bytes_rd+2                
@@exit:         ret
                
@@error:        mov     es:[di].XFILE.state, ax ;; save error
                mov     ax, 0                   ;; return 0 bytes, CF set
                mov     dx, ax
                jmp     short @@exit

@@huge_read:    L2FP    dx                      ;; edx= destine seg:ofs
                mov     destine, edx
                mov     bytes_rd, 0             ;; 0 bytes read
                mov     ecx, 65536 - 16
                jmp     short @@test

@@loop:         sub     esi, ecx                ;; bytes= bytes - 65520

                mov     ah, DOS_FILE_READ
                int     DOS_INT
                jc      @@error                 ;; error?
                and     eax, 0FFFFh
                add     bytes_rd, eax           ;; bytes_rd+= eax
                cmp     ax, 65520
                jne     @@done                  ;; bytes read != 65520?

                add     destine+2, 65520 / 16   ;; ds+= 65520

@@test:         mov     ds, W destine+2         ;; ds:dx -> destine                
                cmp     esi, ecx
                jae     @@loop                  ;; bytes >= 65520? loop

                mov     cx, si                  ;; else, read remainder
                mov     ah, DOS_FILE_READ
                int     DOS_INT
                jc      @@error                 ;; error?
                and     eax, 0FFFFh
                add     bytes_rd, eax
                jmp     short @@done
xfread          endp
CODE_END

CODE32_SEGMENT
;;::::::::::::::
xfread32        proc    near
                local   bytes:dword, bytes_rd:dword
                ;;  in: edi= destine linear address
                ;;      esi= number of bytes to read
                ;;      bx= file handle
                ;;      eax= lowmem buffer far ptr
                ;;      ecx= lowmem buffer size                

                mov     bytes, esi
                mov     bytes_rd, 0             ;; 0 bytes read
                                
                mov     edx, eax                ;; dx= lowmem buffer offset
                shr     eax, 16
                mov     es:xf$intx._ds, ax
                
                mov     esi, edx
                FP2L    si                      ;; esi= lowmem buffer lin addr
                jmp     short @@test
                                                
@@loop:         sub     bytes, ecx              ;; bytes-= lowmem buffer size
                                
                mov     ah, DOS_FILE_READ
                INTXRM  DOS_INT, O xf$intx
                jc      @@exit                  ;; error?
                and     eax, 0FFFFh             
                add     bytes_rd, eax           ;; update bytes read

                ;; move lowmem buffer to destine
                PS      ecx, esi, es
                push    ds
                pop     es                      ;; es= ds
                mov     ecx, eax
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, eax
                and     ecx, 3                  ;; % 4
                rep     movsb
                PP      es, esi, ecx

                cmp     eax, ecx
                jne     @@done                  ;; end of file?
                                
@@test:         cmp     bytes, ecx
                ja      @@loop                  ;; bytes > buffer len? loop

                ;; read lowmem buffer remainder
                mov     ecx, bytes              ;; bytes to read
                mov     ah, DOS_FILE_READ
                INTXRM  DOS_INT, O xf$intx
                jc      @@exit                  ;; error?
                and     eax, 0FFFFh             
                add     bytes_rd, eax

                ;; move lowmem buffer to destine
                push    es
                push    ds
                pop     es                      ;; es= ds
                mov     ecx, eax
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, eax
                and     ecx, 3                  ;; % 4
                rep     movsb
                pop     es

@@done:         clc
                mov     eax, bytes_rd           ;; return bytes read, CF clear
@@exit:         ret
xfread32        endp
CODE32_ENDS
                end
