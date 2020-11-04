;; name: xfwrite
;; desc: write a block of data from memory (extended or conventional)
;;       to a file
;;
;; type: function
;; args: [in] xf:XFILE,           | XFILE structure of file to write
;;            src:long,           | linear address of source memory block
;;            bytes:long          | number of bytes to write
;; retn: long                     | number of bytes written (0 if error)
;;
;; decl: xfwrite& (seg xf as XFILE, byval src as long,_
;;                 byval bytes as long)
;;
;; updt: jul/00 [v1ctor]
;; obs.: if source address is less than 1M, no switch will be made

                include common.inc

CODE_INI
;;::::::::::::::
xfwrite         proc    uses edi esi es ds,\
                        xf:far ptr XFILE,\
                        source:dword,\
                        bytes:dword
                local   bytes_wr:dword

                les     si, xf                  ;; es:si -> xf

                mov     bx, es:[si].XFILE.handle
                mov     edi, bytes
                mov     edx, source

                lea     eax, [edx + edi - 1]
                cmp     eax, 100000h
                jb      @@huge_write            ;; source < 1M?

                ;; no, ...
                mov     eax, es:[si].XFILE.buffer
                mov     ecx, es:[si].XFILE.buff_size
                push    si
                mov     esi, edx
                CALLPM  xfwrite32
                pop     si
                jc      @@error
                mov     bytes_wr, eax

@@done:         mov     es:[si].XFILE.state, 0  ;; clear state
                mov     ax, W bytes_wr          ;; return bytes written,\
                mov     dx, W bytes_wr+2        ;;        CF clear
@@exit:         ret
                
@@error:        mov     es:[si].XFILE.state, ax ;; save error
                mov     ax, 0                   ;; return 0 bytes, CF set
                mov     dx, ax
                jmp     short @@exit

@@huge_write:   L2FP    dx                      ;; edx= source seg:ofs
                mov     source, edx
                mov     bytes_wr, 0             ;; 0 bytes written
                mov     ecx, 65536 - 16
                jmp     short @@test

@@loop:         sub     edi, ecx                ;; bytes= bytes - 65520

                mov     ah, DOS_FILE_WRITE
                int     DOS_INT
                jc      @@error                 ;; error?
                and     eax, 0FFFFh
                add     bytes_wr, eax           ;; bytes_wr+= eax
                cmp     ax, 65520
                jne     @@done                  ;; bytes written != 65520?

                add     source+2, 65520 / 16    ;; ds+= 65520

@@test:         mov     ds, W source+2          ;; ds:dx -> source
                cmp     edi, ecx
                jae     @@loop                  ;; bytes >= 65520? loop

                mov     cx, di                  ;; else, write remainder
                mov     ah, DOS_FILE_WRITE
                int     DOS_INT
                jc      @@error                 ;; error?
                and     eax, 0FFFFh
                add     bytes_wr, eax
                jmp     short @@done
xfwrite         endp
CODE_END

CODE32_SEGMENT
;;::::::::::::::
xfwrite32       proc    near
                local   bytes:dword, bytes_wr:dword
                ;;  in: esi= source linear address
                ;;      edi= number of bytes to write
                ;;      bx= file handle
                ;;      eax= lowmem buffer far ptr
                ;;      ecx= lowmem buffer size                

                mov     bytes, edi
                mov     bytes_wr, 0             ;; 0 bytes written
                                
                mov     edx, eax                ;; dx= lowmem buffer offset
                shr     eax, 16
                mov     es:xf$intx._ds, ax
                
                mov     edi, edx
                FP2L    di                      ;; edi= lowmem buffer lin addr
                jmp     short @@test
                                                
@@loop:         sub     bytes, ecx              ;; bytes-= lowmem buffer size
                                
                ;; move source to lowmem buffer
                PS      ecx, edi, es
                push    ds
                pop     es                      ;; es= ds
                mov     eax, ecx
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, eax
                and     ecx, 3                  ;; % 4
                rep     movsb
                PP      es, edi, ecx

                mov     ah, DOS_FILE_WRITE
                INTXRM  DOS_INT, O xf$intx
                jc      @@exit                  ;; error?
                and     eax, 0FFFFh
                add     bytes_wr, eax           ;; bytes_wr+= eax
                cmp     eax, ecx
                jne     @@done                  ;; disk full?
                                
@@test:         cmp     bytes, ecx
                ja      @@loop                  ;; bytes > buffer len? loop

                mov     eax, bytes
                ;; move source to lowmem buffer
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

                ;; write lowmem buffer remainder
                mov     ecx, eax                ;; bytes to write 
                mov     ah, DOS_FILE_WRITE
                INTXRM  DOS_INT, O xf$intx
                jc      @@exit                  ;; error?
                and     eax, 0FFFFh
                add     bytes_wr, eax

@@done:         clc                             ;; return CF clear,\
                mov     eax, bytes_wr           ;;        bytes written
@@exit:         ret
xfwrite32       endp
CODE32_ENDS
                end
