;; used for debugging purposes only

                include common.inc

.code
;;::::::::::::::
xmdump          proc    uses edi,\
                        dst:dword

                mov     edi, dst
                CALLPM  xmdump32

                ret
xmdump          endp


CODE32_SEGMENT
;;::::::::::::::
xmdump32        proc    near uses edi esi
                ;;  in: edi ptr to destine

                mov     B [edi], '|'
                add     edi, 2

                mov     esi, cs:xm$heap_tail
                jmp     short  @@test_heap
                
@@heap_loop:    lea     ebx, [esi + T HEAP]     ;; ebx=heap+HEAP (1st blk)

@@blk_loop:     mov     eax, [ebx].BLOCK.heap
                add     eax, -1
                sbb     eax, eax
                neg     eax
                add     al, '0'                 ;; al= 0 or 1 (ascii)
                mov     [edi], al               ;; put char on screen
                add     edi, 2

                mov     ebx, [ebx].BLOCK.next
                test    ebx, ebx
                jnz     @@blk_loop              ;; last blk? if not, loop

                mov     B [edi], '-'
                add     edi, 2

                mov     esi, [esi].HEAP.prev    ;; heap= heap.prev
@@test_heap:    test    esi, esi
                jnz     @@heap_loop             ;; last heap? loop if not

                mov     B [edi-2], '|'

                ret
xmdump32        endp
CODE32_ENDS
                end
