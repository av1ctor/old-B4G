;;
;; heap.asm -- helper functions to alloc and free heaps
;;

                include common.inc

data16          segment
xm$free_mem_inf byte    30h dup (?)
data16          ends


CODE32_SEGMENT
queued          dword   FALSE
exit_q          EXIT_Q  <>
xm$heap_tail    dword   NULL
leeched         dword   FALSE

;;::::::::::::::
done            proc    near uses esi

                mov     esi, fs:xm$heap_tail    ;; ds:esi -> heap_tail
                jmp     short @@test

@@loop:         push    [esi].HEAP.prev         ;; walk down
                call    xm$heap_erase
                pop     esi

@@test:         test    esi, esi
                jnz     @@loop                  ;; last heap?

                mov     fs:queued, FALSE        ;; reinstall if need
                ret
done            endp

;;::::::::::::::
xm$heap_alloc   proc    near
                ;;  in: eax= heap size in bytes to alloc (dword granular)
                ;;
                ;; out: ebx= heap linear address (header)
                ;;      esi= linear address of first free block (header)

                PS      eax, ecx, edx, edi

                mov     cl, ss:b4g$cws_loaded   ;; alert dos_int
                mov     ss:b4g$mem_intcpt, cl   ;; /

                ;; add the done proc to exit queue if need
                cmp     fs:queued, TRUE
                je      @F
                mov     fs:queued, TRUE
                invoke  b4g$exit_q32, O exit_q, O done, D PRIORITY_LAST

@@:             add     eax, T HEAP + T FBLOCK  ;; add headers
                mov     esi, eax                ;; save eax

                ;; edx= MAX(BLOCK_MIN, eax)
                mov     edx, eax
                cmp     eax, BLOCK_MIN
                jae     @@mem_avail
                mov     edx, BLOCK_MIN

@@mem_avail:    ;; get largest available free block
                mov     edi, large O xm$free_mem_inf
                mov     eax, DPMI_MEM_FREE_GETINFO
                int     DPMI_INT
                jc      @@error
                add     edi, cs:b4g$mem_inf_ofs ;; 0 or 8
                mov     eax, es:[edi]           ;; eax= free memory size
                                
                mov     cl, cs:b4g$pg_shift     ;; convert pages to bytes
                shl     eax, cl                 ;; /

                cmp     eax, edx
                jae     @@alloc                 ;; if eax >= bytes need, ...
                cmp     eax, esi
                jb      @@size_error            ;; else, if eax < min bytes,:(
                mov     edx, eax                ;; else, alloc what is free

@@alloc:        mov     ebx, edx
                shr     ebx, 16
                mov     ecx, edx                ;; bx:cx= bytes to alloc
                mov     eax, DPMI_MEM_ALLOC
                int     DPMI_INT
                jc      @@error

                ;; lock memory allocated for the heap
                PS      edi, esi
                mov     esi, edx
                shr     esi, 16
                mov     edi, edx                ;; si:di= bytes to lock
                mov     eax, DPMI_REG_LOCK
                int     DPMI_INT
                PP      esi, edi

                shl     ebx, 16
                mov     bx, cx                  ;; ebx= linear address

                shl     esi, 16
                mov     si, di
                mov     [ebx].HEAP.handle, esi  ;; save heap handle
                
                ;; insert heap on heap's linked list
                mov     eax, fs:xm$heap_tail
                mov     fs:xm$heap_tail, ebx    ;; set new tail
                test    eax, eax
                jz      @F                      ;; if heap_tail <> NULL, ...
                mov     [eax].HEAP.next, ebx    ;; else, heap_tail.next= heap

@@:             mov     [ebx].HEAP.prev, eax    ;; heap.prev= heap_tail
                xor     ecx, ecx                ;; ecx= NULL
                mov     [ebx].HEAP.next, ecx    ;; heap.next= NULL
                sub     edx, T HEAP
                mov     [ebx].HEAP._size, edx   ;; save heap size (w/o hdr)
                
                ;; set first free block header 
                lea     esi, [ebx + T HEAP]     ;; esi -> 1st free blk header
                mov     [ebx].HEAP.fblk_head, esi ;; save
                               
                mov     [esi].BLOCK.prev, ecx   ;; blk.prev= NULL
                mov     [esi].BLOCK.next, ecx   ;; blk.next= NULL
                mov     [esi].FBLOCK.prevf, ecx ;; blk.prevf= NULL
                mov     [esi].FBLOCK.nextf, ecx ;; blk.nextf= NULL
                mov     [esi].BLOCK.heap, ecx   ;; set as free block
                sub     edx, T BLOCK            ;; CF= 0
                mov     [esi].BLOCK._size, edx  ;; set block size (w/o header)
                
@@exit:         mov     ss:b4g$mem_intcpt, FALSE
                PP      edi, edx, ecx, eax
                ret

@@error:        xor     esi, esi                ;; return NULL
                stc                             ;; CF= 1
                jmp     short @@exit

@@size_error:   cmp     fs:leeched, TRUE
                je      @@error
                mov     fs:leeched, TRUE
                call    leech_mem
                jnc     @@mem_avail
                jmp     short @@error
xm$heap_alloc   endp

;;::::::::::::::
leech_mem       proc    near
                ;; this is a sad history: Windows reports that has XX
                ;; megabytes of lockable-free-memory, but if you alloc,
                ;; lock, unlock and free this XX megabytes of lockable-
                ;; free-memory, then next time you call Winblows to know
                ;; how many bytes of lockable-free-memory it has, the
                ;; answer will change (it'll report like 30-50% more
                ;; bytes of lockable-free-memory comparing with the last
                ;; time you check it). damn multi-tasking system :) 

                pusha

                ;; check if DPMI host is Windows
                mov     eax, 1600h
                INTRM   2Fh
                test    al, al
                jz      @@error                 ;; not?

                xor     edx, edx
                mov     ebp, 3                  ;; do 3 times this shit, yuk!

@@loop:         ;; avail
                mov     edi, large O xm$free_mem_inf
                mov     eax, DPMI_MEM_FREE_GETINFO
                int     DPMI_INT
                add     edi, cs:b4g$mem_inf_ofs ;; 0 or 8
                mov     eax, es:[edi]           ;; eax= largest free blk size
                dec     eax                     ;; CWS bug: reports 1 pg more
                                
                mov     cl, cs:b4g$pg_shift     ;; convert pages to bytes
                shl     eax, cl                 ;; /

                cmp     eax, edx
                jbe     @@exit                  ;; changed since last time?
                mov     edx, eax

                ;; alloc
                mov     ebx, edx
                shr     ebx, 16
                mov     ecx, edx                ;; bx:cx= bytes to alloc
                mov     eax, DPMI_MEM_ALLOC
                int     DPMI_INT

                ;; lock
                PS      edi, esi
                mov     esi, edx
                shr     esi, 16
                mov     edi, edx                ;; si:di= bytes to lock
                mov     eax, DPMI_REG_LOCK
                int     DPMI_INT

                ;; unlock
                mov     eax, DPMI_REG_UNLOCK
                int     DPMI_INT
                PP      esi, edi

                ;; free
                mov     eax, DPMI_MEM_FREE
                int     DPMI_INT

                add     edx, 100000h            ;; at least 1M of difference

                dec     ebp
                jnz     @@loop
                                                ;; return ok (CF clear)
@@exit:         popa
                ret

@@error:        stc                             ;; return error (CF set)
                jmp     short @@exit
leech_mem       endp

;;::::::::::::::
xm$heap_erase   proc    near
                ;;  in: esi -> heap (header)
                ;;
                push    edi

                mov     al, ss:b4g$cws_loaded   ;; alert dos_int
                mov     ss:b4g$mem_intcpt, al   ;; /

                ;; remove heap from heaps linked list
                mov     ecx, [esi].HEAP.prev
                mov     edx, [esi].HEAP.next
                                
                test    ecx, ecx
                jz      @@no_prev                
                mov     [ecx].HEAP.next, edx

@@no_prev:      test    edx, edx
                jz      @@no_next
                mov     [edx].HEAP.prev, ecx
                jmp     short @@erase

@@no_next:      mov     fs:xm$heap_tail, ecx    ;; heap tail= heap.prev

@@erase:        ;; unlock memory owned by this heap
                push    esi
                mov     ebx, esi
                mov     ecx, ebx
                shr     ebx, 16                 ;; bx:cx= heap address
                mov     edi, [esi].HEAP._size
                mov     esi, edi
                shr     esi, 16                 ;; si:di= bytes to unlock
                mov     eax, DPMI_REG_UNLOCK
                int     DPMI_INT
                pop     esi

                ;; free it
                mov     edi, [esi].HEAP.handle
                mov     esi, edi
                shr     esi, 16                 ;; si:di= heap handle
                mov     eax, DPMI_MEM_FREE
                int     DPMI_INT

                mov     ss:b4g$mem_intcpt, FALSE
                pop     edi
                ret
xm$heap_erase   endp
CODE32_ENDS
                end
