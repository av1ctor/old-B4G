;; name: xmappokeb, xmappokei, xmappokel, xmappokes, xmappoked, xmappokestr,
;;       xmappoket
;; desc: write a byte, integer, long integer, single, double, string or a
;;       structure to extended memory (buffered)
;;
;; type: sub
;; args: [in] map:long,                  | map's far ptr
;;            ofs:long,                  | offset of mapped memory block
;;            value:byte, integer, long,\
;;                  single, double,\
;;            struct:any,\
;;            strg:string                | value to write
;; retn: none
;;
;; decl: xmappokeb   (byval map as long,_
;;                    byval ofs as long,_
;;                    byval value as integer)
;;       xmappokei   (byval map as long,_
;;                    byval ofs as long,_
;;                    byval value as integer)
;;       xmappokel   (byval map as long,_
;;                    byval ofs as long,_
;;                    byval value as long)
;;       xmappokes   alias "xmappokel" (byval map as long,_
;;                    byval ofs as long,_
;;                    byval value as single)
;;       xmappoked   (byval map as long,_
;;                    byval ofs as long,_
;;                    byval value as double)
;;       xmappokestr (byval map as long,_
;;                    byval ofs as long,_
;;                    strg as string)
;;       xmappoket   (byval map as long,_
;;                    byval ofs as long,_
;;                    seg struct as any,_
;;                    byval bytes as integer)
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

.code
;;::::::::::::::
xmappokeb       proc    uses di es,\
                        map:far ptr,\
                        ofs:dword,\
                        value:word
                
                mov     es, W map+2
                mov     edi, map                ;; edi= es:di -> map struct
                mov     ebx, ofs

                ;; ofs < or >= than the buffered part?
                cmp     ebx, es:[di].XMAP.buff_ini
                jb      @@bufferize
                cmp     ebx, es:[di].XMAP.buff_end
                jae     @@bufferize

                ;; no, so...  ofs < wr_ini or > wr_end? set if so
                cmp     ebx, es:[di].XMAP.wr_ini
                jb      @@set_wr_ini
                cmp     ebx, es:[di].XMAP.wr_end
                jbe     @@write
@@set_wr_end:   mov     es:[di].XMAP.wr_end, ebx

@@write:        sub     ebx, es:[di].XMAP.buff_ini
                
                mov     al, B value
                mov     es:[di+bx+T XMAP], al   ;; map.buffer[bx]= value
                ret

@@set_wr_ini:   ;; map.buffer was changed?
                cmp     es:[di].XMAP.wr_ini, 0FFFFFFFFh
                mov     es:[di].XMAP.wr_ini, ebx
                jne     @@write
                jmp     short @@set_wr_end

@@bufferize:    push    di
                FP2L    di                      ;; edi= (es*16)+di
                CALLPM  xmp$bufferize32
                pop     di
                mov     es:[di].XMAP.wr_ini, ebx
                mov     es:[di].XMAP.wr_end, ebx
                mov     al, B value
                mov     es:[di + T XMAP], al    ;; map.buffer[0]= value
                ret
xmappokeb       endp

;;::::::::::::::
xmappokei       proc    uses di es,\
                        map:far ptr,\
                        ofs:dword,\
                        value:word
                
                mov     es, W map+2
                mov     edi, map                ;; edi= es:di -> map struct
                mov     ebx, ofs

                lea     eax, [ebx + 1]          ;; eax= last byte offset

                ;; ofs < or >= than the buffered part?
                cmp     ebx, es:[di].XMAP.buff_ini
                jb      @@bufferize
                cmp     eax, es:[di].XMAP.buff_end
                jae     @@bufferize

                ;; no, so...  ofs < wr_ini or > wr_end? set if so
                cmp     ebx, es:[di].XMAP.wr_ini
                jb      @@set_wr_ini
                cmp     eax, es:[di].XMAP.wr_end
                jbe     @@write
@@set_wr_end:   mov     es:[di].XMAP.wr_end, eax

@@write:        sub     ebx, es:[di].XMAP.buff_ini
                mov     ax, value
                mov     es:[di+bx+T XMAP], ax   ;; map.buffer[bx]= value
                ret

@@set_wr_ini:   ;; map.buffer was changed?
                cmp     es:[di].XMAP.wr_ini, 0FFFFFFFFh
                mov     es:[di].XMAP.wr_ini, ebx
                jne     @@write
                jmp     short @@set_wr_end

@@bufferize:    push    di
                FP2L    di                      ;; edi= (es*16)+di
                CALLPM  xmp$bufferize32
                pop     di
                mov     es:[di].XMAP.wr_ini, ebx
                inc     ebx
                mov     es:[di].XMAP.wr_end, ebx
                mov     ax, value
                mov     es:[di + T XMAP], ax    ;; map.buffer[0]= value
                ret
xmappokei       endp

;;::::::::::::::
xmappokel       proc    uses di es,\
                        map:far ptr,\
                        ofs:dword,\
                        value:dword
                
                mov     es, W map+2
                mov     edi, map                ;; edi= es:di -> map struct
                mov     ebx, ofs

                lea     eax, [ebx + 3]          ;; eax= last byte offset

                ;; ofs < or >= than the buffered part?
                cmp     ebx, es:[di].XMAP.buff_ini
                jb      @@bufferize
                cmp     eax, es:[di].XMAP.buff_end
                jae     @@bufferize

                ;; no, so...  ofs < wr_ini or > wr_end? set if so
                cmp     ebx, es:[di].XMAP.wr_ini
                jb      @@set_wr_ini
                cmp     eax, es:[di].XMAP.wr_end
                jbe     @@write
@@set_wr_end:   mov     es:[di].XMAP.wr_end, eax

@@write:        sub     ebx, es:[di].XMAP.buff_ini
                mov     eax, value
                mov     es:[di+bx+T XMAP], eax  ;; map.buffer[bx]= value
                ret

@@set_wr_ini:   ;; map.buffer was changed?
                cmp     es:[di].XMAP.wr_ini, 0FFFFFFFFh
                mov     es:[di].XMAP.wr_ini, ebx
                jne     @@write
                jmp     short @@set_wr_end

@@bufferize:    push    di
                FP2L    di                      ;; edi= (es*16)+di
                CALLPM  xmp$bufferize32
                pop     di
                mov     es:[di].XMAP.wr_ini, ebx
                add     ebx, 3
                mov     es:[di].XMAP.wr_end, ebx
                mov     eax, value
                mov     es:[di + T XMAP], eax   ;; map.buffer[0]= value
                ret
xmappokel       endp

;;::::::::::::::
xmappoked       proc    uses di es,\
                        map:far ptr,\
                        ofs:dword,\
                        value:qword
                
                mov     es, W map+2
                mov     edi, map                ;; edi= es:di -> map struct
                mov     ebx, ofs

                lea     eax, [ebx + 7]          ;; eax= last byte offset

                ;; ofs < or >= than the buffered part?
                cmp     ebx, es:[di].XMAP.buff_ini
                jb      @@bufferize
                cmp     eax, es:[di].XMAP.buff_end
                jae     @@bufferize

                ;; no, so...  ofs < wr_ini or > wr_end? set if so
                cmp     ebx, es:[di].XMAP.wr_ini
                jb      @@set_wr_ini
                cmp     eax, es:[di].XMAP.wr_end
                jbe     @@write
@@set_wr_end:   mov     es:[di].XMAP.wr_end, eax

@@write:        sub     ebx, es:[di].XMAP.buff_ini
                mov     eax, D value
                mov     edx, D value+4
                mov     es:[di+bx+T XMAP], eax  ;; map.buffer[bx]= value
                mov     es:[di+bx+T XMAP+4], edx;; /
                ret

@@set_wr_ini:   ;; map.buffer was changed?
                cmp     es:[di].XMAP.wr_ini, 0FFFFFFFFh
                mov     es:[di].XMAP.wr_ini, ebx
                jne     @@write
                jmp     short @@set_wr_end

@@bufferize:    push    di
                FP2L    di                      ;; edi= (es*16)+di
                CALLPM  xmp$bufferize32
                pop     di
                mov     es:[di].XMAP.wr_ini, ebx
                add     ebx, 7
                mov     es:[di].XMAP.wr_end, ebx
                mov     eax, D value
                mov     edx, D value+4
                mov     es:[di + T XMAP], eax   ;; map.buffer[0]= value
                mov     es:[di + T XMAP+4], edx ;; /
                ret
xmappoked       endp

;;::::::::::::::
xmappokestr     proc    uses di si es ds,\
                        map:far ptr,\
                        ofs:dword,\
                        strg:near ptr STRG_DSC
                
                mov     es, W map+2
                mov     edi, map                ;; edi= es:di -> map struct
                mov     ebx, ofs

                xor     ecx, ecx
                BSTRG   strg, ds, si, cx
                test    cx, cx
                jz      @@exit                  ;; string.len= 0?

                lea     eax, [ebx + ecx - 1]    ;; eax= last byte offset

                ;; ofs < or >= than the buffered part?
                cmp     ebx, es:[di].XMAP.buff_ini
                jb      @@bufferize
                cmp     ebx, es:[di].XMAP.buff_end
                jae     @@bufferize
                cmp     eax, es:[di].XMAP.buff_end
                jae     @@bufferize

                ;; no, so...  ofs < wr_ini or > wr_end? set if so
                cmp     ebx, es:[di].XMAP.wr_ini
                jb      @@set_wr_ini
                cmp     eax, es:[di].XMAP.wr_end
                jbe     @@write
@@set_wr_end:   mov     es:[di].XMAP.wr_end, eax

@@write:        sub     ebx, es:[di].XMAP.buff_ini
                lea     di, [di + bx + T XMAP]
                mov     ax, cx
                and     ax, 3                   ;; % 4
                shr     cx, 2                   ;; / 4
                rep     movsd                   ;; map.buffer[bx]= string
                mov     cx, ax
                rep     movsb

@@exit:         ret

@@set_wr_ini:   ;; map.buffer was changed?
                cmp     es:[di].XMAP.wr_ini, 0FFFFFFFFh
                mov     es:[di].XMAP.wr_ini, ebx
                jne     @@write
                jmp     short @@set_wr_end

@@bufferize:    FP2L    si, ds                  ;; esi= (ds*16)+si
                FP2L    di                      ;; edi= (es*16)+di
                CALLPM  poke_blk32
                ret
xmappokestr     endp

;;::::::::::::::
xmappoket       proc    uses di si es ds,\
                        map:far ptr,\
                        ofs:dword,\
                        _struct:far ptr,\
                        bytes:word
                
                mov     es, W map+2
                mov     edi, map                ;; edi= es:di -> map struct
                mov     ebx, ofs

                lds     si, _struct             ;; ds:si -> struct
                movzx   ecx, bytes

                lea     eax, [ebx + ecx - 1]    ;; eax= last byte offset

                ;; ofs < or >= than the buffered part?
                cmp     ebx, es:[di].XMAP.buff_ini
                jb      @@bufferize
                cmp     ebx, es:[di].XMAP.buff_end
                jae     @@bufferize
                cmp     eax, es:[di].XMAP.buff_end
                jae     @@bufferize

                ;; no, so...  ofs < wr_ini or > wr_end? set if so
                cmp     ebx, es:[di].XMAP.wr_ini
                jb      @@set_wr_ini
                cmp     eax, es:[di].XMAP.wr_end
                jbe     @@write
@@set_wr_end:   mov     es:[di].XMAP.wr_end, eax

@@write:        sub     ebx, es:[di].XMAP.buff_ini
                lea     di, [di + bx + T XMAP]
                mov     ax, cx
                and     ax, 3                   ;; % 4
                shr     cx, 2                   ;; / 4
                rep     movsd                   ;; map.buffer[bx]= struct
                mov     cx, ax
                rep     movsb

@@exit:         ret

@@set_wr_ini:   ;; map.buffer was changed?
                cmp     es:[di].XMAP.wr_ini, 0FFFFFFFFh
                mov     es:[di].XMAP.wr_ini, ebx
                jne     @@write
                jmp     short @@set_wr_end

@@bufferize:    FP2L    si, ds                  ;; esi= (ds*16)+si
                FP2L    di                      ;; edi= (es*16)+di
                CALLPM  poke_blk32
                ret
xmappoket       endp


CODE32_SEGMENT
;;::::::::::::::
poke_blk32      proc    near uses ebp esi es
                ;;  in: edi= map struct linear address
                ;;      ecx= bytes to erite
                ;;      esi= source linear address
                ;;      ebx= destine   "      "
                ;;      eax= destine last byte

                ;;   |__________block___________|
                ;;             |buffer|
                ;; 1)          |[src] |           to buffer
                ;; 2)      [sou|ce]   |           to dst, to buffer
                ;; 3)          |    [s|urce]      to buffer, to dst, bufferize?
                ;; 4)        [_|_sourc|___]       to dst, invalidate buffer
                ;; 5) [source] |      |           to dst, bufferize?
                ;; 5)          |      | [source]  to dst, bufferize?

                mov     edx, ds
                mov     es, edx                 ;; es= ds

                mov     ebp, [edi].XMAP.buff_ini
                mov     edx, [edi].XMAP.buff_end

                ;; ofs >= buff_end or ofs+len-1 < buff_ini?
                cmp     ebx, edx
                jae     @@dst__buffz
                cmp     eax, ebp
                jb      @@dst__buffz

                ;; ofs <= buff_ini?
                sub     ebp, ebx
                jbe     @@buff__dst

                ;; ofs+len-1 >= buff_end?
                cmp     eax, edx
                jae     @@dst__invld

;;............. (2)
                ;; move source to destine...
                sub     ecx, ebp                ;; = str.len-(buff_ini-ofs)
                PS      ecx, edi
                mov     edi, [edi].XMAP.blk_addr
                add     edi, ebx                ;; es:edi -> dst+ofs
                mov     ecx, ebp                ;; ecx= buff_ini - ofs
                and     ebp, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, ebp
                rep     movsb

                ;; ... and to map.buffer
                mov     edi, [esp]
                mov     ecx, [esp+4]
                add     edi, T XMAP             ;; es:edi -> map.buffer
                mov     eax, ecx
                and     eax, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, eax
                rep     movsb
                PP      edi, ecx

                ;; update map struct
                mov     eax, [edi].XMAP.buff_ini
                mov     [edi].XMAP.wr_ini, eax  ;; wr_ini= buff_ini
                lea     ecx, [ecx + eax - 1]
                cmp     ecx, edx
                jbe     @F
                ;; wr_end= buff_ini + (str.len - (buff_ini - ofs)) - 1
                mov     [edi].XMAP.wr_end, ecx
@@:             ret

;;............. (3)
@@buff__dst:    add     ebp, ebx
                
                ;; update map struct
                cmp     ebx, [edi].XMAP.wr_ini
                jae     @F
                mov     [edi].XMAP.wr_ini, ebx  ;; wr_ini= ofs

@@:             mov     eax, edx
                dec     eax
                mov     [edi].XMAP.wr_end, eax  ;; wr_end= buff_end-1

                ;; move source to map.buffer...
                PS      ecx, edi
                sub     edx, ebx                ;; edx= buff_end - ofs
                PS      ebx, edx
                sub     ebx, ebp
                lea     edi, [edi+ebx+T XMAP]   ;; es:edi -> map.buffer+ofs
                
                mov     ecx, edx                ;; ecx= buff_end - ofs
                and     edx, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, edx
                rep     movsb
                PP      edx, ebx

                ;; ... and to destine and bufferize if need
                mov     edi, [esp]
                mov     ecx, [esp+4]
                sub     ecx, edx                ;; ecx= str.len-(buff_end-ofs)
                mov     edi, [edi].XMAP.blk_addr
                add     edx, ebx
                add     edi, edx                ;; es:edi -> dst+ofs+(buff_end-ofs)

                mov     eax, ecx
                and     eax, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, eax
                rep     movsb
                PP      edi, eax

                ;; source len >= map.size?
                cmp     eax, [edi].XMAP._size
                jae     @@invld

                ;; nope, so... bufferize
                call    xmp$bufferize32
                ret

;;............. (4)
@@dst__invld:   ;; move source to destine...
                push    edi
                mov     edi, [edi].XMAP.blk_addr
                add     edi, ebx                ;; es:edi -> dst+ofs
                mov     eax, ecx
                and     eax, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, eax
                rep     movsb
                pop     edi

@@invld:        ;; ... and invalidate map.buffer
                mov     [edi].XMAP.wr_ini, 0FFFFFFFFh
                mov     [edi].XMAP.wr_end, ecx  ;; 0!!!
                mov     [edi].XMAP.buff_ini, ecx;; /
                mov     [edi].XMAP.buff_end, ecx;; /
                ret

;;............. (5)
@@dst__buffz:   ;; move source to destine and bufferize if need
                PS      ecx, edi
                mov     edi, [edi].XMAP.blk_addr
                add     edi, ebx                ;; es:edi -> dst+ofs
                mov     eax, ecx
                and     eax, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, eax
                rep     movsb
                PP      edi, eax

                ;; source len >= map.size?
                cmp     eax, [edi].XMAP._size
                jae     @@invld

                ;; nope, so... bufferize
                call    xmp$bufferize32
                ret
poke_blk32      endp
CODE32_ENDS
                end
