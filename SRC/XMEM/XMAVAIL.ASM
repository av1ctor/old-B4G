;; name: xmavail
;; desc: get the size of the largest extended memory block free
;;
;; type: function
;; args: none
;; retn: long                  | largest free block size
;;
;; decl: xmavail& ()
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

.code
;;::::::::::::::
xmavail         proc

                CALLPM  xmavail32
                EAX2DXAX

                ret
xmavail         endp


CODE32_SEGMENT
;;::::::::::::::
xmavail32       proc    near uses edi esi
                ;; out: eax= largest free block size
                
                xor     esi, esi                ;; esi= largest free block
                mov     edi, cs:xm$heap_tail    ;; edi -> last heap
                test    edi, edi
                jz      @@from_server           ;; any heap allocated?
                
@@heap_loop:    ;; if heap.fblk_head= NULL, ...
                mov     ebx, [edi].HEAP.fblk_head
                test    ebx, ebx
                jz      @@heap_next

@@block_loop:   ;; else, seek for the largest block
                mov     edx, [ebx].BLOCK._size
                cmp     esi, edx
                jae     @@block_next
                mov     esi, edx

@@block_next:   mov     ebx, [ebx].FBLOCK.nextf
                test    ebx, ebx
                jnz     @@block_loop            ;; last free blk? if not, loop
                
@@heap_next:    mov     edi, [edi].HEAP.prev
                test    edi, edi
                jnz     @@heap_loop             ;; last heap? if not, loop

@@from_server:  ;; get largest available free block from DPMI server
                mov     edi, large O xm$free_mem_inf
                mov     eax, DPMI_MEM_FREE_GETINFO
                int     DPMI_INT
                jc      @@error
                add     edi, cs:b4g$mem_inf_ofs ;; 0 or 8
                mov     eax, es:[edi]           ;; eax= free memory size
                dec     eax                     ;; CWS bug: reports 1 pg more

                mov     cl, cs:b4g$pg_shift     ;; convert pages to bytes
                shl     eax, cl                 ;; /

                sub     eax, T HEAP + T FBLOCK  ;; - headers

                ;; select the largest between xmem and DPMI blocks
                cmp     eax, esi
                jae     @@exit
@@error:        mov     eax, esi
@@exit:         ret
xmavail32       endp
CODE32_ENDS
                end
