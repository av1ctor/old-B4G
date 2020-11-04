;; name: xmalloc
;; desc: allocate an extended memory block
;;
;; type: function
;; args: [in] bytes:long       | number of bytes to alloc
;; retn: long                  | linear address of block (0 if error)
;;
;; decl: xmalloc& (byval bytes as long)
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

.code
;;::::::::::::::
xmalloc         proc    bytes:dword

                mov     eax, bytes
                CALLPM  xmalloc32
                EAX2DXAX

                ret
xmalloc         endp


CODE32_SEGMENT
;;::::::::::::::
xmalloc32       proc    near uses ebx esi
                ;;  in: eax= bytes
                ;;
                ;; out: eax= block linear address (data)
                
                cmp     eax, STC_DIFF
                jb      @@add                   ;; < STC_DIFF?

                add     eax, 3                  ;; make dword granular
                and     eax, not 3              ;; /
@@find:         call    xm$block_find
                test    esi, esi
                jz      @@alloc                 ;; found?
@@split:        call    xm$block_split
@@exit:         ret

@@alloc:        call    xm$heap_alloc           ;; try alloc a new heap
                jnc     @@split                 ;; error?
                xor     eax, eax
                jmp     short @@exit

@@add:          add     eax, STC_DIFF + 3       ;; min size = STC_DIFF
                and     eax, not 3              ;; dword granular
                jmp     short @@find
xmalloc32       endp
CODE32_ENDS
                end
