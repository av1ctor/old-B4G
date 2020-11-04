;;
;; dos_int.inc -- hooks DOS interrupt vector, to make DOS memory 
;;                services work with BASIC memory manager behind :).
;;                must be installed _before_ load CWS.
;;

;;      as BASIC memory manager allocate all free conventional memory to it
;; own use when the program starts, the calls to DOS memory services to
;; allocate and resize memory blocks will always fail.
;;      there's an easy work-around that is: before call DOS to allocate
;; memory we must call BASIC (the SETMEM function) to first free the memory
;; need, but, as B4G uses CWS as DPMI host when the system are in real or v86
;; modes and as CWS calls DOS to allocate and resize memory to use for page
;; tables, of course DOS will return error in every attempt.
;;      what can be made is hook the DOS interrupt vector and then intercept
;; any calls to the memory services, but there's another problem: when BASIC
;; shrinks it heap, the upper part of that heap is given to DOS, so when DOS
;; allocates a block, it will reserve this upper part, but, as CWS resizes
;; the block allocated for pages tables, DOS cannot find space to grow the
;; block as it will be the last one (the memory above it belongs to video
;; ram, BIOS rom, etc...).
;;      one solution is allocate almost all memory that BASIC reserved, but
;; doing this way, you cannot use dynamics arrays and thus the program will
;; not run in the IDE (where the arrays are always dynamics). another one
;; could be make a complete extender (that works in RAW/VCPI modes), but i
;; haven't enough knowledge to do it...yet. :P
;;      the way i found is change the mode that the DOS resize memory service
;; works: instead of fail when it cannot grow the block when there's no free
;; memory above it, it will _reallocate_ the block: find an enough space
;; anywhere in low memory, copy the old block to the new block and then, free
;; the old block and return a _different_ block address. here is another
;; problem: CWS (as any other program) doesn't expect that the block address
;; change when it resizes the block. but another time there's a solution:
;; change the way that CWS expects that DOS works! luckily CWS is open source,
;; so what i did is add some lines to it and now everything works perfect.
;; the only drawback is that you need use this "special" version of CWSDPMI 
;; instead of use the normal one.
;;      God, why did i start this lib? :}

childs          word    1
_ds             word    ?
_sssp           dword   ?
_flgs           word    ?
org_dos_int     dword   ?
;;::::::::::::::
                align   4
dos_int         proc
                PS      ax, dx
                mov     dx, ax
                lahf                            ;; save flags

                cmp     cs:b4g$mem_intcpt, TRUE
                je      @@check_mem             ;; intercept DOS mem services?

@@continue:     cmp     dh, DOS_EXIT
                je      @@exit                  ;; trying exit?

                cmp     dh, DOS_TSR
                je      @@exit                  ;; terminate & stay resident?

                cmp     dh, DOS_EXEC
                je      @@load                  ;; trying load?

@@chain:        sahf                            ;; restore flags
                PP      dx, ax
                jmp     cs:org_dos_int          ;; chain to dos

@@check_mem:    ;; calling DOS to manage memory?
                cmp     dh, DOS_MEM_RESIZE
                je      @@resize                ;; to resize?
                cmp     dh, DOS_MEM_FREE
                je      @@free                  ;; or to free?
                cmp     dh, DOS_MEM_ALLOC
                jne     @@continue              ;; or to alloc mem?

;;::::::::::::::
@@alloc:        mov     cs:b4g$mem_intcpt,FALSE ;; prevent looping forever
                PP      dx, ax

                ;;  in: bx= block size (paras)
                ;; out: CF= 0: ax= MCB + 1 of memory block allocated
                ;;      CF= 1: ax= 7,8; bx= largest free block (paras)

                cmp     bx, 0FFFFh
                je      @@avail                 ;; trying see free mem avail?

                ;; 1st) check if DOS has enough free memory
                push    bx                      ;; save size
                push    W [esp+4+2]             ;; duplicate flags
                call    cs:org_dos_int
                pop     bx                      ;; restore size
                jnc     @@alloc_done            ;; no error?

                ;; BASIC assumes: ds= ss= DGROUP
                mov     cs:_ds, ds
                mov     W cs:_sssp+2, ss
                mov     W cs:_sssp+0, sp
                mov     ax, [esp+4]
                mov     cs:_flgs, ax
                mov     ax, cs:seg_tb[DGROUP_SEG]
                mov     ds, ax
                mov     ss, ax
                mov     sp, O b4g$tmp_stk16 + 100h

                ;; 2nd) if DOS did fail, check how many bytes
                ;; of free memory BASIC has
                push    dx
                invoke  B$SETM, D 0
                ;; dx:ax= largest free block size
                sub     ax, 16                  ;; -1 for the MCB
                sbb     dx, 0                   ;; /
                shr     ax, 4                   ;; convert bytes to paras
                shl     dx, 16-4                ;; /
                or      ax, dx                  ;; /

                ;; the size is enough?
                cmp     ax, bx
                jb      @@alloc_error           ;; no?

                ;; make it free the memory need
                mov     ax, bx
                inc     ax                      ;; +1 for MCB
                mov     dx, ax                  ;; convert paras to bytes
                shl     ax, 4                   ;; /
                shr     dx, 16-4                ;; /
                neg     ax                      ;; negate dx:ax
                adc     dx, 0                   ;; /
                neg     dx                      ;; /
                invoke  B$SETM, dx::ax

                ;; 3th) reserve this block using DOS
                mov     ah, DOS_MEM_ALLOC
                push    cs:_flgs                ;; dup flags
                call    cs:org_dos_int
                jc      @@alloc_error2          ;; error???

                pop     dx
                mov     ds, cs:_ds              ;; restore data seg
                lss     sp, cs:_sssp            ;;    "    stack ptr

@@alloc_done:   and     W [esp+4], not C_FLG    ;; clear CF

@@alloc_exit:   mov     cs:b4g$mem_intcpt, TRUE
                iret                            ;; return to caller

@@alloc_error:  pop     dx
                mov     bx, ax                  ;; bx= largest free block size
                mov     ax, 8                   ;; ax= (insufficient mem)
                mov     ds, cs:_ds              ;; restore data seg
                lss     sp, cs:_sssp            ;;    "    stack ptr
                or      W [esp+4], C_FLG        ;; set CF
                jmp     short @@alloc_exit

@@alloc_error2: ;; give back to BASIC the memory allocated (and not used)
                invoke  B$SETM, 7FFFFFFFh
                mov     ax, bx                  ;; ax= largest block
                jmp     short @@alloc_error

;;::::::::::::::
@@avail:        ;; 1st) check the largest free memory block that DOS has
                push    W [esp+4]               ;; dup flags
                call    cs:org_dos_int
                ;; bx= largest freeblk (paras)

                ;; BASIC assumes: ds= ss= DGROUP
                mov     cs:_ds, ds
                mov     W cs:_sssp+2, ss
                mov     W cs:_sssp+0, sp
                mov     ax, cs:seg_tb[DGROUP_SEG]
                mov     ds, ax
                mov     ss, ax
                mov     sp, O b4g$tmp_stk16 + 100h

                ;; 2nd) now check BASIC
                push    dx
                invoke  B$SETM, D 0
                ;; dx:ax= largest free block size
                sub     ax, 16                  ;; -1 for the MCB
                sbb     dx, 0                   ;; /
                shr     ax, 4                   ;; convert bytes to paras
                shl     dx, 16-4                ;; /
                or      ax, dx                  ;; /
                pop     dx

                lss     sp, cs:_sssp            ;; restore stack ptr
                mov     ds, cs:_ds              ;;    "    data seg

                ;; who has the largest?
                cmp     bx, ax
                jae     @F
                mov     bx, ax                  

@@:             ;; return as service 48h,4Ah has fail
                mov     ax, 8                   ;; ax= (insufficient mem)
                or      W [esp+4], C_FLG        ;; set CF
                mov     cs:b4g$mem_intcpt, TRUE
                iret                            ;; return to caller

;;::::::::::::::
@@free:         mov     cs:b4g$mem_intcpt,FALSE ;; prevent looping forever
                PP      dx, ax

                ;;  in: es= MCB + 1 of memory block to free
                ;; out: CF= 1: ax= 9
                
                push    W [esp+4]               ;; dup flags
                call    cs:org_dos_int
                PS      ax, dx
                lahf
                mov     B [esp+4+2+2], ah       ;; set flags
                jc      @@free_exit             ;; error?

                ;; BASIC assumes: ds= ss= DGROUP
                mov     cs:_ds, ds
                mov     W cs:_sssp+2, ss
                mov     W cs:_sssp+0, sp
                mov     ax, cs:seg_tb[DGROUP_SEG]
                mov     ds, ax
                mov     ss, ax
                mov     sp, O b4g$tmp_stk16 + 100h

                ;; give the memory freed to BASIC (only works if block
                ;; freed is adjacent to BASIC's far heap block)
                invoke  B$SETM, 7FFFFFFFh

                lss     sp, cs:_sssp            ;; restore stack ptr
                mov     ds, cs:_ds              ;;    "    data seg

@@free_exit:    PP      dx, ax
                mov     cs:b4g$mem_intcpt, TRUE
                iret                            ;; return to caller

;;::::::::::::::
@@resize:       mov     cs:b4g$mem_intcpt,FALSE ;; prevent looping forever
                PP      dx, ax

                ;;  in: es= MCB + 1 of memory block to resize
                ;;      bx= new block size (paras)
                ;; out: CF= 0: es= MCB + 1 of memory block resized
                ;;      CF= 1: ax= 7,8,9; bx= largest free block (paras)

                cmp     bx, 0FFFFh
                je      @@avail                 ;; trying see free mem avail?

                ;; want shrink the block?
                push    es
                push    es
                dec     W [esp]                 ;; es -> MCB
                pop     es                      ;; /
                cmp     bx, es:[MCB._size]
                pop     es
                jb      @@resiz_shrnk
                je      @@resiz_done            ;; same size? are you nuts? ;)

                ;; BASIC assumes: ds= ss= DGROUP
                mov     cs:_ds, ds
                mov     W cs:_sssp+2, ss
                mov     W cs:_sssp+0, sp
                mov     ax, [esp+4]
                mov     cs:_flgs, ax
                mov     ax, cs:seg_tb[DGROUP_SEG]
                mov     ds, ax
                mov     ss, ax
                mov     sp, O b4g$tmp_stk16 + 100h

                ;; 1st) try allocate the new block (we cannot use DOS
                ;; resize service to get any free adjacent block because
                ;; it will resize what it can, then precious bytes 
                ;; will be lost.
                push    dx                      ;; (0)
                push    bx                      ;; save new size
                mov     ah, DOS_MEM_ALLOC
                push    cs:_flgs                ;; dup flags
                call    cs:org_dos_int
                pop     bx                      ;; restore
                jnc     @@resiz_move            ;; no error?

                ;; 2nd) as DOS had fail, check how many bytes of
                ;; free memory BASIC has
                invoke  B$SETM, D 0
                ;; dx:ax= largest free block size
                sub     ax, 16                  ;; -1 for the MCB
                sbb     dx, 0                   ;; /
                shr     ax, 4                   ;; convert bytes to paras
                shl     dx, 16-4                ;; /
                or      ax, dx                  ;; /

                ;; the size is enough?
                cmp     ax, bx
                jb      @@resiz_error           ;; no?

                ;; make it free the memory need
                mov     ax, bx
                inc     ax                      ;; +1 for MCB
                mov     dx, ax                  ;; convert paras to bytes
                shl     ax, 4                   ;; /
                shr     dx, 16-4                ;; /
                neg     ax                      ;; negate dx:ax
                adc     dx, 0                   ;; /
                neg     dx                      ;; /
                invoke  B$SETM, dx::ax

                ;; 3th) allocated this memory
                mov     ah, DOS_MEM_ALLOC
                push    cs:_flgs                ;; dup flags
                call    cs:org_dos_int
                jc      @@resiz_error2          ;; error???

@@resiz_move:   ;; 4th) move old block to new block
                push    ax                      ;; (1)
                PS      bx, cx, di, si, es, ds

                mov     dx, es
                dec     dx                      ;; -> MCB
                mov     es, dx
                inc     dx
                mov     bx, es:[MCB._size]      ;; bx= old blk size in bytes
                cld

@@mov_loop:     mov     cx, 65536/4             ;; assume 64K to move
                cmp     bx, 65536/16
                jae     @F                      ;; bx < 64K?
                mov     cx, bx
                shl     cx, 2                   ;; cx= bx * 16 / 4

@@:             mov     ds, dx
                xor     si, si                  ;; ds:si -> old block
                mov     es, ax
                xor     di, di                  ;; es:di -> new block
                rep     movsd

                add     dx, 65536/16            ;; next 64K
                add     ax, 65536/16            ;; /
                sub     bx, 65536/16
                ja      @@mov_loop              ;; any dword left?

                PP      ds, es, si, di, cx, bx

                ;; 5th) free the old memory block
                mov     ah, DOS_MEM_FREE
                push    cs:_flgs                ;; dup flags
                call    cs:org_dos_int

                pop     es                      ;; (1) return es -> new block

                ;; 6th) give that memory block back to BASIC
                invoke  B$SETM, 7FFFFFFFh

                pop     dx                      ;; (0)
                mov     ds, cs:_ds              ;; restore data seg
                lss     sp, cs:_sssp            ;;    "    stack ptr

@@resiz_done:   and     W [esp+4], not C_FLG    ;; clear CF

@@resiz_exit:   mov     cs:b4g$mem_intcpt, TRUE
                iret                            ;; return to caller

@@resiz_shrnk:  push    W [esp+4]               ;; dup flags
                call    cs:org_dos_int
                jmp     short @@resiz_done

@@resiz_error:  pop     dx                      ;; (0)
                mov     bx, ax                  ;; bx= largest free block size
                mov     ax, 8                   ;; ax= (insufficient mem)
                mov     ds, cs:_ds              ;; restore data seg
                lss     sp, cs:_sssp            ;;    "    stack ptr
                or      W [esp+4], C_FLG        ;; set CF
                jmp     short @@resiz_exit

@@resiz_error2: ;; give back to BASIC the memory allocated (and not used)
                invoke  B$SETM, 7FFFFFFFh
                mov     ax, bx                  ;; ax= largest block
                jmp     short @@resiz_error

;;::::::::::::::
@@load:         test    dl, dl
                jnz     @@chain                 ;; load and execute?

                PP      dx, ax
                inc     cs:childs               ;; ++childs (assuming ok)
                push    W [esp+4]               ;; dup flags
                call    cs:org_dos_int
                push    ax
                lahf
                mov     B [esp+4+2], ah         ;; set flags
                pop     ax
                sbb     cs:childs, 0            ;; --childs if error
                iret                            ;; return to caller

;;::::::::::::::
@@exit:         ;; check child processes
                dec     cs:childs
                jnz     @@chain                 ;; if childs > 0, not exit

                pop     dx

                ;; restore orginal DOS interrupt vector
                lds     dx, cs:org_dos_int
                mov     ax, (DOS_INT_VECTOR_SET * 256) or DOS_INT
                push    W [esp+4+2]             ;; dup flags
                call    cs:org_dos_int
                
                ;; finaly, get out!
                pop     ax                      ;; restore errorlevel
                int     DOS_INT
dos_int         endp
