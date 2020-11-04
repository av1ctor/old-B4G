;; name: xmapmake
;; desc: allocate a new xmap struct and buffer
;;
;; type: function
;; args: [in] size:long        | xmap buffer size (max 64K)
;; retn: long                  | far ptr of xmap struct allocated (0 if error)
;;
;; decl: xmapmake& (byval size as long)
;;

;; name: xmap
;; desc: map a memory region (extended or conventional)
;;
;; type: sub
;; args: [in] lin:long,        | region linear address
;;            bytes:long,      | region size
;;            map:long         | xmap struct to use
;; retn: none
;;
;; decl: xmap (byval lin as long,_
;;             byval bytes as long,_
;;             byval map as long)
;;

;; name: xmapflush
;; desc: flush a xmap buffer if need (must be called after poke to memory
;;       using the xmappoke_ routines if the region poked will be read
;;       by any others functions beside xmappeek_ routines)
;;
;; type: sub
;; args: [in] map:long         | xmap struct to flush
;; retn: none
;;
;; decl: xmapflush (byval map as long)
;;

;; name: xmapinval
;; desc: invalidate a xmap buffer (must be called before peek from memory
;;       using the xmappeek_ routines if the region peeked was written
;;       by any others functions beside xmappoke_ routines)
;;
;; type: sub
;; args: [in] map:long         | xmap struct to invalidate
;; retn: none
;;
;; decl: xmapinval (byval map as long)
;;

;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

.code
;;::::::::::::::
xmapmake        proc    _size:dword

                xor     eax, eax
                mov     ax, W _size
                add     ax, 3 + T XMAP
                jnc     @F
                mov     eax, 65536

@@:             and     ax, not 3
                push    eax                     ;; (0)
                invoke  malloc, eax
                jnc     @F
                add     sp, 4
                jmp     short @@exit

@@:             mov     es, dx
                mov     di, ax                  ;; es:di -> map
                ;; save size
                pop     ecx                     ;; (0)
                sub     ecx, T XMAP
                mov     es:[di].XMAP._size, ecx
                ;; clear struct
                xor     ecx, ecx
                mov     es:[di].XMAP.blk_addr, ecx
                mov     es:[di].XMAP.blk_size, ecx
                mov     es:[di].XMAP.buff_ini, ecx
                mov     es:[di].XMAP.buff_end, ecx
                mov     es:[di].XMAP.wr_ini, 0FFFFFFFFh
                mov     es:[di].XMAP.wr_end, ecx

@@exit:         ret
xmapmake        endp

;;::::::::::::::
xmap            proc    uses di es,\
                        lin:dword,\
                        bytes:dword,\
                        map:far ptr

                les     di, map                 ;; es:di -> map struct
                mov     eax, lin
                mov     es:[di].XMAP.blk_addr, eax
                mov     eax, bytes
                mov     es:[di].XMAP.blk_size, eax
                xor     eax, eax
                mov     es:[di].XMAP.buff_ini, eax
                mov     es:[di].XMAP.buff_end, eax
                mov     es:[di].XMAP.wr_ini, 0FFFFFFFFh
                mov     es:[di].XMAP.wr_end, eax

                ret
xmap            endp

;;::::::::::::::
xmapflush       proc    uses di es,\
                        map:far ptr

                mov     es, W map+2
                mov     edi, map                ;; edi= es:di -> map struct

                ;; anything was written to map.buffer? flush it
                cmp     es:[di].XMAP.wr_ini, 0FFFFFFFFh
                je      @@exit
                CALLPM  flush32

@@exit:         ret
xmapflush       endp

;;::::::::::::::
xmapinval       proc    uses di es,\
                        map:far ptr

                les     di, map                 ;; es:di -> map struct

                xor     eax, eax
                mov     es:[di].XMAP.wr_ini, 0FFFFFFFFh
                mov     es:[di].XMAP.wr_end, eax
                mov     es:[di].XMAP.buff_ini, eax
                mov     es:[di].XMAP.buff_end, eax

                ret
xmapinval       endp


CODE32_SEGMENT
;;::::::::::::::
xmp$bufferize32 proc    near uses esi es
                ;;  in: edi= map struct linear address
                ;;      ebx= offset of mapped block
                ;;      DF clear
                ;;
                ;; out: map struct updated

                mov     eax, ds
                mov     es, eax                 ;; es= ds= flat seg

                ;; anything was written to map.buffer? flush it
                cmp     [edi].XMAP.wr_ini, 0FFFFFFFFh
                je      @@no_flush
                mov     eax, [edi].XMAP.wr_ini
                mov     ecx, [edi].XMAP.wr_end
                sub     ecx, eax
                inc     ecx                     ;; ecx= (wr_end-wr_ini)+1
                ;; ds:esi -> map.buffer+(wr_ini-buff_ini)
                mov     esi, eax
                sub     esi, [edi].XMAP.buff_ini
                lea     esi, [esi + edi + T XMAP]
                xchg    edi, eax                ;; save edi
                add     edi, [eax].XMAP.blk_addr;; es:edi -> blk+wr_ini
                ;; move map.buffer to block
                mov     edx, ecx
                and     edx, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, edx
                rep     movsb
                mov     edi, eax                ;; restore edi

                mov     [edi].XMAP.wr_ini, 0FFFFFFFFh
                mov     [edi].XMAP.wr_end, ecx  ;; 0!!!

@@no_flush:     mov     [edi].XMAP.buff_ini, ebx;; save start

                mov     esi, [edi].XMAP.blk_addr
                add     esi, ebx                ;; ds:esi -> blk+ofs

                mov     eax, [edi].XMAP.blk_size
                mov     ecx, [edi].XMAP._size

                push    edi
                add     edi, T XMAP             ;; es:edi -> map.buffer

                sub     eax, ebx
                cmp     ecx, eax
                ja      @@partial               ;; map.size > blk.size-ofs?

                ;; not, fill buffer completely
                shr     ecx, 2
                rep     movsd

@@exit:         pop     edi
                sub     esi, [edi].XMAP.blk_addr
                mov     [edi].XMAP.buff_end, esi;; save end
                ret

@@partial:      ;; fill buffer with the end part of block
                mov     ecx, eax
                and     eax, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, eax                
                rep     movsb
                jmp     short @@exit
xmp$bufferize32 endp

;;::::::::::::::
flush32         proc    near uses edi esi es
                ;;  in: edi= map struct far pointer (seg:ofs)
                ;;      DF clear
                ;;
                ;; out: map struct updated

                mov     eax, ds
                mov     es, eax                 ;; es= ds= flat seg

                FP2L    di                      ;; farptr 2 linear

                mov     eax, [edi].XMAP.wr_ini
                mov     ecx, [edi].XMAP.wr_end
                sub     ecx, eax
                inc     ecx                     ;; ecx= (wr_end-wr_ini)+1
                ;; ds:esi -> map.buffer+(wr_ini-buff_ini)
                mov     esi, eax
                sub     esi, [edi].XMAP.buff_ini
                lea     esi, [esi + edi + T XMAP]
                xchg    edi, eax                ;; save edi
                add     edi, [eax].XMAP.blk_addr;; es:edi -> blk+wr_ini
                ;; move map.buffer to block
                mov     edx, ecx
                and     edx, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, edx
                rep     movsb
                mov     edi, eax                ;; restore edi

                mov     [edi].XMAP.wr_ini, 0FFFFFFFFh
                mov     [edi].XMAP.wr_end, ecx  ;; 0!!!

                ret
flush32         endp
CODE32_ENDS
                end
