;; name: xmrealloc
;; desc: reallocate an extended memory block previously allocated
;;
;; type: function
;; args: [in/out] blk:long     | linear address of block to resize
;;       [in] bytes:long       | new block size
;; retn: integer               | result: -1 if error, 0 otherwise
;;
;; decl: xmrealloc% (seg blk as long,_
;;                   byval bytes as long)
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

.code
;;::::::::::::::
xmrealloc       proc    uses es,\
                        blk:far ptr dword,\
                        bytes:dword

                les     bx, blk                 ;; es:bx -> blk

                mov     eax, es:[bx]
                test    eax, eax
                jz      @@exit                  ;; blk= NULL?

                mov     edx, bytes
                CALLPM  xmrealloc32
                test    eax, eax
                jz      @@error                 ;; null block?

                mov     es:[bx], eax            ;; set new address
                xor     ax, ax                  ;; return ok (CF clear)

@@exit:         ret

@@error:        dec     ax                      ;; return error (CF set)
                jmp     short @@exit
xmrealloc       endp


CODE32_SEGMENT
;;::::::::::::::
xmrealloc32     proc    near
                ;;  in: eax= block linear address (data)
                ;;      edx= bytes
                ;;
                ;; out: eax= reallocated blk lin addrs (data) (0 if error)

                ;; the possibilities:
                ;;
                ;; 1) shrink:
                ;;    split block in two;
                ;;    if next block is free, merge blk splited with it.
                ;;
                ;; 2) expand:
                ;;    if next block is free and has space to put the
                ;;     expanded block, split next block;
                ;;    else if preview block is free and has
                ;;     enough space to put expanded block,
                ;;     split it, merge the upper part with
                ;;     block and move block to it;
                ;;    else allocate a new block with the new size;
                ;;     move block to new block;
                ;;     free block.

                PS      ebx, ecx, edx, edi, esi

                add     edx, 3                  ;; make dword granular
                and     edx, not 3              ;; /

                sub     eax, T BLOCK            ;; eax -> blk header
                mov     esi, [eax].BLOCK.heap   ;; esi= blk.heap

                cmp     edx, [eax].BLOCK._size
                ja      @@expand_up
                je      @@done                  ;; same size? are you nuts? :)

;;............. (1)
@@shrink:       ;; ecx= (blk.size - newsize) - FBLOCK
                mov     ebx, [eax].BLOCK._size
                lea     ecx, [ebx - T FBLOCK]
                sub     ecx, edx
                jbe     @@done
                add     ecx, STC_DIFF
                
                mov     [eax].BLOCK._size, edx  ;; blk.size= newsize

                lea     ebx, [eax+T BLOCK+ebx]  ;; ebx -> sblk
                                
                mov     edx, [eax].BLOCK.next   ;; save
                mov     [eax].BLOCK.next, ebx   ;; blk.next= sblk
                mov     [ebx].BLOCK.prev, eax   ;; sblk.prev= blk
                mov     [ebx].BLOCK.heap, 0     ;; set as free block

                ;; if blk.next is free, merge sblk with blk.next
                test    edx, edx
                jz      @F
                cmp     [edx].BLOCK.heap, 0
                je      @@merge_with_next

@@:             mov     [ebx].BLOCK._size, ecx  ;; sblk.size= blk.size-newsize
                mov     [ebx].BLOCK.next, edx   ;; sblk.next= blk.next
                test    edx, edx
                jz      @F
                mov     [edx].BLOCK.prev, ebx   ;; blk.next.prev= sblk

@@:             mov     ecx, [esi].HEAP.fblk_head
                mov     [esi].HEAP.fblk_head, ebx ;; heap.fblk_head= sblk
                mov     [ebx].FBLOCK.nextf, ecx ;; sblk.nextf= heap.fblk_head
                mov     [ebx].FBLOCK.prevf, 0   ;; sblk.prevf= NULL
                test    ecx, ecx
                jz      @@done
                mov     [ecx].FBLOCK.prevf, ebx ;; fblk_head.prevf= sblk
                jmp     @@done

@@merge_with_next:
                ;; sblk.size= blk.next.size+BLOCK+(blk.size-newsize)-BLOCK
                add     ecx, [edx].BLOCK._size
                add     ecx, T BLOCK
                mov     [ebx].BLOCK._size, ecx

                mov     ecx, [edx].BLOCK.next
                mov     [ebx].BLOCK.next, ecx   ;; sblk.next= blk.next.next
                test    ecx, ecx
                jz      @F
                mov     [ecx].BLOCK.prev, ebx   ;; blk.next.next.prev= sblk

@@:             mov     ecx, [edx].FBLOCK.nextf
                mov     [ebx].FBLOCK.nextf, ecx ;; sblk.nextf= blk.next.nextf
                test    ecx, ecx
                jz      @F
                mov     [ecx].FBLOCK.prevf, ebx ;; blk.next.nextf.prevf= sblk

@@:             mov     ecx, [edx].FBLOCK.prevf
                mov     [ebx].FBLOCK.prevf, ecx ;; sblk.prevf= blk.next.prevf
                test    ecx, ecx
                jz      @@set_as_head
                mov     [ecx].FBLOCK.nextf, ebx ;; blk.next.prevf.nextf= sblk
                jmp     @@done

@@set_as_head:  ;; if blk.next= heap.fblk_head, heap.fblk_head= sblk
                mov     [esi].HEAP.fblk_head, ebx
                jmp     @@done

;;............. (2)
@@expand_up:    ;; if next block is free and it's size is enough to
                ;; expand the block, split next block and add it to block

                ;; exists?
                mov     ebx, [eax].BLOCK.next
                test    ebx, ebx
                jz      @@expand_down
                ;; is free?
                cmp     [ebx].BLOCK.heap, 0
                jne     @@expand_down
                
                ;; ...[block][freeblk]...

                ;; size is enough?
                mov     edi, edx                ;; edi= new - old size
                sub     edi, [eax].BLOCK._size  ;; /
                mov     ecx, [ebx].BLOCK._size  ;; ecx= blk.prev real size
                add     ecx, T BLOCK            ;; /
                sub     ecx, edi
                jb      @@expand_down
                je      @@remove_next
                ;; enough to split?
                sub     ecx, T FBLOCK
                jbe     @@remove_next

                ;; ...[block   ][fblk]...

                ;; split next block and add it to block
                mov     [eax].BLOCK._size, edx  ;; set new size

                ;; edi= (blk + newsize + BLOCK)
                lea     edi, [eax + edx + T BLOCK]
                
                add     ecx, STC_DIFF           ;; correct size
                push    ecx
                                
                ;; update free blocks logical linked list
                mov     ecx, [ebx].FBLOCK.prevf ;; get now to prevent override
                mov     edx, [ebx].FBLOCK.nextf ;; /
                mov     ebx, [ebx].BLOCK.next   ;; /

                pop     [edi].BLOCK._size       ;; fblk.size-=(new-old size)
                mov     [edi].BLOCK.heap, 0     ;; set as free block

                mov     [edi].FBLOCK.nextf, edx ;; transfer
                test    edx, edx
                jz      @F
                mov     [edx].FBLOCK.prevf, edi ;; blk.next.nextf.prevf= fblk

@@:             mov     [edi].FBLOCK.prevf, ecx ;; transfer
                test    ecx, ecx
                jz      @F
                mov     [ecx].FBLOCK.nextf, edi ;; blk.next.prevf.nextf= fblk
                jmp     short @@relink

@@:             ;; if next blk= heap.fblk_head, heap.fblk_head= fblk
                mov     [esi].HEAP.fblk_head, edi

@@relink:       ;; update blocks physical linked list
                mov     [eax].BLOCK.next, edi   ;; blk.next= fblk
                mov     [edi].BLOCK.prev, eax   ;; fblk.prev= blk
                
                mov     [edi].BLOCK.next, ebx   ;; transfer
                test    ebx, ebx
                jz      @@done
                mov     [ebx].BLOCK.prev, edi   ;; blk.next.next.prev= fblk
                jmp     @@done

@@remove_next:  ;; blk.size= new size + blk.next.size + BLOCK
                add     edx, [ebx].BLOCK._size
                add     edx, T BLOCK
                mov     [eax].BLOCK._size, edx

                mov     ecx, [ebx].BLOCK.next
                mov     [eax].BLOCK.next, ecx   ;; blk.next= blk.next.next
                test    ecx, ecx
                jz      @F
                mov     [ecx].BLOCK.prev, eax   ;; blk.next.next.prev= blk

@@:             mov     ecx, [ebx].FBLOCK.prevf
                mov     edx, [ebx].FBLOCK.nextf
                ;; blk.next.nextf.prevf= blk.next.prevf
                test    edx, edx
                jz      @F
                mov     [edx].FBLOCK.prevf, ecx

@@:             ;; blk.next.prevf.nextf= blk.next.nextf
                test    ecx, ecx
                jz      @F
                mov     [ecx].FBLOCK.nextf, edx
                jmp     @@done

@@:             ;; if blk.next= heap.fblk_head, heap.fblk_head= blk.next.nextf
                mov     [esi].HEAP.fblk_head, edx
                jmp     @@done
                
;;.............
@@expand_down:  ;; if preview block is free and it's size is enough to
                ;; expand the block, split it, merge the upper part with
                ;; block and move block to it

                ;; exists?
                mov     ebx, [eax].BLOCK.prev
                test    ebx, ebx
                jz      @@alloc_move_free
                ;; is free?
                cmp     [ebx].BLOCK.heap, 0
                jne     @@alloc_move_free

                ;; ...[freeblk][block]...

                ;; size is enough?
                mov     edi, edx                ;; edi= new - old size
                sub     edi, [eax].BLOCK._size  ;; /
                mov     ecx, [ebx].BLOCK._size  ;; ecx= blk.prev real size
                add     ecx, T BLOCK            ;; /
                sub     ecx, edi
                jb      @@alloc_move_free
                je      @@remove_prev
                ;; enough to split?
                sub     ecx, T FBLOCK
                jbe     @@remove_prev

                ;; ...[fblk][block   ]...

                ;; split preview block and add it to block
                mov     [eax].BLOCK._size, edx  ;; set new size

                ;; edi= blk - (new - old size)
                neg     edi
                add     edi, eax
                
                add     ecx, STC_DIFF           ;; correct size
                mov     [ebx].BLOCK._size, ecx  ;; blk.prev.size-=new-old size
                mov     [ebx].BLOCK.next, edi   ;; blk.prev.next= sblk

                mov     edx, [eax].BLOCK.next
                test    edx, edx
                jz      @F
                mov     [edx].BLOCK.prev, edi   ;; blk.next.prev= sblk
                
@@:             mov     esi, eax                ;; esi -> blk
                mov     ecx, [eax].BLOCK._size
                add     ecx, T BLOCK            ;; ecx= blk.size + BLOCK
                mov     eax, edi                ;; return eax -> sblk

@@move:         ;; move block to splited block
                push    es
                mov     edx, ds
                mov     es, edx                 ;; es= ds
                shr     ecx, 2                  ;; / 4
                rep     movsd
                pop     es
                jmp     short @@done

@@remove_prev:  mov     [ebx].BLOCK.heap, esi   ;; allocated (save heap ptr)

                mov     edx, [eax].BLOCK._size
                add     edx, T BLOCK
                add     [ebx].BLOCK._size, edx  ;; fblk.size+=blk.size+BLOCK

                ;; update physical linked list
                mov     ecx, [eax].BLOCK.next
                mov     [ebx].BLOCK.next, ecx   ;; transfer
                test    ecx, ecx
                jz      @F
                mov     [ecx].BLOCK.prev, ebx   ;; blk.next.prev= fblk

@@:             ;; update logical linked list
                mov     ecx, [ebx].FBLOCK.prevf
                mov     edx, [ebx].FBLOCK.nextf

                test    edx, edx
                jz      @F
                mov     [edx].FBLOCK.prevf, ecx ;; fblk.nextf.prevf=fblk.prevf

@@:             test    ecx, ecx
                jz      @@set_as_head2
                mov     [ecx].FBLOCK.nextf, edx ;; fblk.prevf.nextf=fblk.nextf
                jmp     short @F

@@set_as_head2: ;; if fblk= heap.fblk_head, heap.fblk_head= fblk.nextf
                mov     [esi].HEAP.fblk_head, edx

@@:             lea     esi, [eax + T BLOCK]    ;; esi -> blk data
                lea     edi, [ebx + T BLOCK]    ;; edi -> fblk data
                mov     ecx, [eax].BLOCK._size  ;; ecx= blk.size
                mov     eax, ebx                ;; return eax -> fblk
                jmp     short @@move

;;.............
@@alloc_move_free:
                push    eax                     ;; (0)
                mov     eax, edx
                call    xm$block_find
                test    esi, esi
                jz      @@alloc                 ;; found?

@@split:        call    xm$block_split

                ;; move old block to new block
                pop     esi                     ;; (0)
                mov     ecx, [esi].BLOCK._size  ;; ecx= old size
                mov     edi, eax                ;; edi -> new block data
                add     esi, T BLOCK            ;; esi -> old block data                
                PS      esi, es
                mov     ebx, ds
                mov     es, ebx                 ;; es=ds
                shr     ecx, 2
                rep     movsd
                PP      es, esi
                
                xchg    eax, esi                ;; eax -> old block data
                call    xmfree32
                mov     eax, esi                ;; restore new block address
                jmp     short @@exit

@@alloc:        call    xm$heap_alloc
                jnc     @@split
                add     esp, 4                  ;; (0)
                xor     eax, eax                ;; return error
                jmp     short @@exit
                
@@done:         add     eax, T BLOCK            ;; eax -> block data

@@exit:         PP      esi, edi, edx, ecx, ebx
                ret
xmrealloc32     endp
CODE32_ENDS
                end
