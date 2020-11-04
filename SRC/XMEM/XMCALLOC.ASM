;; name: xmcalloc
;; desc: allocate an extended memory block and clear it (fill with zeros)
;;
;; type: function
;; args: [in] bytes:long       | number of bytes to alloc and clear
;; retn: long                  | linear address of block (0 if error)
;;
;; decl: xmcalloc& (byval bytes as long)
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

.code
;;::::::::::::::
xmcalloc        proc    bytes:dword

                mov     eax, bytes
                CALLPM  xmcalloc32
                EAX2DXAX

                ret
xmcalloc        endp


CODE32_SEGMENT
;;::::::::::::::
xmcalloc32      proc    near uses ebx esi
                ;;  in: eax= bytes
                ;;      DF clear
                ;;
                ;; out: eax= block linear address (data)
                ;;      block filled with zeros
                
                cmp     eax, STC_DIFF
                jb      @@add                   ;; < STC_DIFF?

                add     eax, 3                  ;; make dword granular
                and     eax, not 3              ;; /
@@find:         push    eax                     ;; (0)
                call    xm$block_find
                test    esi, esi
                jz      @@alloc

@@split:        call    xm$block_split 

                ;; fill memory block with zeros
                pop     ecx                     ;; (0) ecx= block size
                PS      eax, es
                mov     edi, eax
                mov     eax, ds
                mov     es, eax                 ;; es:edi ptr to block
                xor     eax, eax
                shr     ecx, 2
                rep     stosd
                PP      es, eax

@@exit:         ret

@@alloc:        call    xm$heap_alloc
                jnc     @@split
                add     esp, 4                  ;; (0)
                xor     eax, eax
                jmp     short @@exit

@@add:          add     eax, STC_DIFF + 3       ;; min size = STC_DIFF
                and     eax, not 3              ;; dword granular
                jmp     short @@find
xmcalloc32      endp
CODE32_ENDS
                end
