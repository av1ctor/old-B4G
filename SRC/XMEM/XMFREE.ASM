;; name: xmfree
;; desc: free an extended memory block
;;
;; type: sub
;; args: [in/out] blk:long     | linear address of block to free
;; retn: none
;;
;; decl: xmfree (seg blk as long)
;;
;; updt: jul/00 [v1ctor]
;; obs.: if block exists, blk will be set to NULL

                include common.inc

.code
;;::::::::::::::
xmfree          proc    uses es,\
                        blk:far ptr dword

                les     bx, blk                 ;; es:di -> blk

                mov     eax, es:[bx]
                test    eax, eax
                jz      @@exit                  ;; blk= NULL?

                CALLPM  xmfree32

                xor     eax, eax
                mov     es:[bx], eax            ;; blk= NULL

@@exit:         ret
xmfree          endp


CODE32_SEGMENT
;;::::::::::::::
xmfree32        proc    near
                ;;  in: eax= block linear address (data)

                ;; the possibilities:
                ;;
                ;; 1) block has no surrounding free blocks:
                ;;    if there is no other free block, set block as 1st;
                ;;    relink free block linked list.
                ;;
                ;; 2) preview block is free:
                ;;    merge preview block with block.
                ;;
                ;; 3) next block is free:
                ;;    merge block with next block;
                ;;    if next block is the head, set block as head.
                ;;
                ;; 4) preview and next blocks are free:
                ;;    merge preview block with block and next block.

                PS      ebx, ecx, edx, edi, esi
                
                sub     eax, T BLOCK            ;; eax -> blk header
                mov     esi, [eax].BLOCK.heap   ;; esi= blk.heap
                mov     [eax].BLOCK.heap, 0     ;; set as free block

                mov     ecx, [eax].BLOCK.prev   ;; ecx= blk.prev
                mov     edx, [eax].BLOCK.next   ;; edx= blk.next

                ;; if blk.prev is free, merge blk.prev with blk
                test    ecx, ecx
                jz      @F
                cmp     [ecx].BLOCK.heap, 0
                je      @@merge_with_prev

@@:             ;; if blk.next is free, merge blk with blk.next
                test    edx, edx
                jz      @@insert
                cmp     [edx].BLOCK.heap, 0
                je      @@merge_with_next
                
;;.................. (1)
@@insert:       ;; else...
                mov     ecx, [esi].HEAP.fblk_head ;; freeblk= heap.fblk_head
                mov     [esi].HEAP.fblk_head, eax ;; heap.fblk_head= blk
                mov     [eax].FBLOCK.prevf, 0   ;; blk.prevf= NULL
                mov     [eax].FBLOCK.nextf, ecx ;; blk.nextf= freeblk                
                test    ecx, ecx
                jz      @@test_heap
                mov     [ecx].FBLOCK.prevf, eax ;; freeblk.prevf= blk
                jmp     @@test_heap

;;.................. (2)
@@merge_with_prev:
                ;; if blk.next is free, merge blk.prev with blk and blk.next
                test    edx, edx
                jz      @F
                cmp     [edx].BLOCK.heap, 0
                je      @@merge_with_prev_and_next

@@:             mov     ebx, [eax].BLOCK._size
                add     ebx, T BLOCK
                add     [ecx].BLOCK._size, ebx  ;; blk.prev.size+= blk.size+...
                             
                mov     [ecx].BLOCK.next, edx   ;; blk.prev.next= blk.next
                test    edx, edx
                jz      @@test_heap
                mov     [edx].BLOCK.prev, ecx   ;; blk.next.prev= blk.prev
                jmp     short @@test_heap

;;.................. (3)
@@merge_with_next:
                mov     ebx, [edx].BLOCK._size
                add     ebx, T BLOCK
                add     [eax].BLOCK._size, ebx  ;; blk.size+= blk.next.size+...

                mov     ebx, [edx].BLOCK.next
                mov     [eax].BLOCK.next, ebx   ;; blk.next= blk.next.next
                test    ebx, ebx
                jz      @F
                mov     [ebx].BLOCK.prev, eax   ;; blk.next.next.prev= blk

@@:             mov     ebx, [edx].FBLOCK.nextf
                mov     [eax].FBLOCK.nextf, ebx ;; blk.nextf= blk.next.nextf
                test    ebx, ebx
                jz      @F
                mov     [ebx].FBLOCK.prevf, eax ;; blk.next.nextf.prevf= blk

@@:             mov     ebx, [edx].FBLOCK.prevf
                mov     [eax].FBLOCK.prevf, ebx ;; blk.prevf= blk.next.prevf
                test    ebx, ebx
                jz      @F
                mov     [ebx].FBLOCK.nextf, eax ;; blk.next.prevf.nextf= blk
                jmp     short @@test_heap

@@:             ;; if blk.next is heap.fblk_head, heap.fblk_head= blk
                mov     [esi].HEAP.fblk_head, eax
                jmp     short @@test_heap

;;.................. (4)
@@merge_with_prev_and_next:
                ;; blk.prev.size+= blk.size+blk.next.size...
                mov     ebx, [eax].BLOCK._size
                add     ebx, [edx].BLOCK._size                                
                add     ebx, T BLOCK * 2
                add     [ecx].BLOCK._size, ebx

                mov     ebx, [edx].BLOCK.next
                mov     [ecx].BLOCK.next, ebx   ;; blk.prev.next= blk.next.next
                test    ebx, ebx
                jz      @F
                mov     [ebx].BLOCK.prev, ecx   ;; blk.next.prev= blk.prev

@@:             mov     eax, [edx].FBLOCK.prevf
                mov     ebx, [edx].FBLOCK.nextf
                
                test    ebx, ebx
                jz      @F
                mov     [ebx].FBLOCK.prevf, eax ;; blk.next.nextf.prevf= blk.next.prevf

@@:             test    eax, eax
                jz      @F
                mov     [eax].FBLOCK.nextf, ebx ;; blk.next.prevf.nextf= blk.next.nextf
                jmp     short @@test_heap

@@:             mov     [esi].HEAP.fblk_head, ebx ;; heap.head= blk.next.nextf
                
;;..................
@@test_heap:    ;; check if heap can be freed
                mov     ecx, [esi].HEAP.fblk_head
                mov     ecx, [ecx].BLOCK._size
                add     ecx, T BLOCK
                cmp     ecx, [esi].HEAP._size
                jne     @@exit                  ;; not?
                call    xm$heap_erase

@@exit:         PP      esi, edi, edx, ecx, ebx
                ret
xmfree32        endp
CODE32_ENDS
                end
