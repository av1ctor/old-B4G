;;
;; block.asm -- helper functions to find and split a block
;;

                include common.inc

CODE32_SEGMENT
;;::::::::::::::
xm$block_find   proc    near
                ;;  in: eax= memory block size in bytes to find
                ;;
                ;; out: esi= linear address of memory block found (header)
                ;;      ebx= memory block heap (header)

                PS      ecx, edx, edi, ebp
                                
                xor     esi, esi                ;; esi= block found address
                mov     edi, fs:xm$heap_tail    ;; edi -> last heap
                test    edi, edi
                jz      @@exit                  ;; any heap allocated?
                mov     ecx, 0FFFFFFFFh         ;; ecx= min free block found

@@heap_loop:    mov     ebx, edi                ;; save heap ptr
                ;; if heap.fblk_head= NULL, ...
                mov     edx, [edi].HEAP.fblk_head
                test    edx, edx
                jz      @@heap_next

@@block_loop:   ;; else, seek for the closest block
                mov     ebp, [edx].BLOCK._size
                cmp     ebp, eax
                jb      @@block_next
                je      @@block_equal
                cmp     ebp, ecx
                jae     @@block_next
                mov     ecx, ebp
                mov     esi, edx

@@block_next:   mov     edx, [edx].FBLOCK.nextf
                test    edx, edx
                jnz     @@block_loop            ;; last free blk? if not, loop
                
@@heap_next:    mov     edi, [edi].HEAP.prev
                test    edi, edi
                jnz     @@heap_loop             ;; last heap? if not, loop

@@exit:         PP      ebp, edi, edx, ecx
                ret

@@block_equal:  mov     esi, edx
                jmp     short @@exit
xm$block_find   endp

;;::::::::::::::
xm$block_split  proc    near
                ;;  in: eax= memory block size in bytes to split
                ;;      ebx= memory block heap (header)
                ;;      esi= linear address of memory block to split (header)
                ;;
                ;; out: eax= linear address of splited memory block (data)

                PS      ecx, edx, edi, esi
                
                lea     edx, [eax + T BLOCK]
                mov     ecx, [esi].BLOCK._size
                cmp     ecx, edx
                jbe     @@remove                ;; if bytes=> freeblk.size, ...
                
                ;; edi= (freeblk + bytes + BLOCK)
                lea     edi, [esi + edx]
                
                sub     ecx, edx
                mov     [edi].BLOCK._size, ecx  ;; freeblk.size-=(bytes+BLOCK)
                mov     [edi].BLOCK.heap, 0     ;; freeblk= free (0)

                ;; update free blocks logical linked list
                mov     ecx, [esi].FBLOCK.prevf ;; save
                mov     [edi].FBLOCK.prevf, ecx ;; transfer

                ;; if blk= heap.fblk_head, heap.fblk_head= freeblk
                cmp     esi, [ebx].HEAP.fblk_head
                jne     @@prev_free
                mov     [ebx].HEAP.fblk_head, edi
                jmp     short @@next_free

@@prev_free:    test    ecx, ecx
                jz      @@next_free
                mov     [ecx].FBLOCK.nextf, edi ;; freeblk.prevf.nextf= freeblk

@@next_free:    mov     ecx, [esi].FBLOCK.nextf
                mov     [edi].FBLOCK.nextf, ecx ;; transfer
                test    ecx, ecx
                jz      @@relink
                mov     [ecx].FBLOCK.prevf, edi ;; freeblk.nextf.prevf= freeblk

@@relink:       ;; update blocks physical linked list
                mov     [edi].BLOCK.prev, esi   ;; freeblk.prev= blk

                mov     ecx, [esi].BLOCK.next
                mov     [edi].BLOCK.next, ecx   ;; transfer
                test    ecx, ecx
                jz      @@no_next
                mov     [ecx].BLOCK.prev, edi   ;; freeblk.next.prev= freeblk

@@no_next:      ;; set allocated block header
                mov     [esi].BLOCK._size, eax  ;; set blk.size
                mov     [esi].BLOCK.next, edi   ;; blk.next= freeblk

@@exit:         mov     [esi].BLOCK.heap, ebx   ;; set blk.heap (cause is 0)
                lea     eax, [esi + T BLOCK]    ;; eax -> blk data
                PP      esi, edi, edx, ecx
                ret

;;.............
@@remove:       ;; bytes+BLOCK is >= freeblk.size (exactly size or
                ;; no space for adjacent freeblk header) so, remove
                ;; freeblk from free blocks logical linked list
                mov     ecx, [esi].FBLOCK.prevf
                mov     edx, [esi].FBLOCK.nextf

                test    edx, edx
                jz      @F
                mov     [edx].FBLOCK.prevf, ecx

@@:             test    ecx, ecx
                jz      @@set_as_head
                mov     [ecx].FBLOCK.nextf, edx
                jmp     short @@exit

@@set_as_head:  ;; heap.fblk_head= freeblk.next
                mov     [ebx].HEAP.fblk_head, edx
                jmp     short @@exit
xm$block_split  endp
CODE32_ENDS
                end
