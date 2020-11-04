;; name: xmappeekb, xmappeeki, xmappeekl, xmappeeks, xmappeekd, xmappeekstr,
;;       xmappeekt
;; desc: read a byte, integer, long integer, single, double, string or a
;;       structure from extended memory (buffered)
;;
;; type: function
;; args: [in]  map:long,        | map's far ptr
;;             ofs:long         | offset of mapped memory block
;; or:   [in]  map:long,        |  "     "   "
;;             ofs:long,        |   "    "    "      "      "
;;             bytes:integer    | string size
;; or:   [out] struct:any,      | struct to write
;;       [in]  map:long,        |  "     "   "
;;             ofs:long,        |   "    "    "      "      "
;;             bytes:integer    | struct size

;; retn: byte, integer, long,\
;;       single, double, string | byte, ..., double, or string read
;;
;; decl: xmappeekb%   (byval map as long,_
;;                     byval ofs as long)
;;       xmappeeki%   (byval map as long,_
;;                     byval ofs as long)
;;       xmappeekl&   (byval map as long,_
;;                     byval ofs as long)
;;       xmappeeks!   (byval map as long,_
;;                     byval ofs as long)
;;       xmappeekd#   (byval map as long,_
;;                     byval ofs as long)
;;       xmappeekstr$ (byval map as long,_
;;                     byval ofs as long,_
;;                     byval bytes as integer)
;;       xmappeekt    (seg struct as any,_
;;                     byval map as long,_
;;                     byval ofs as long,_
;;                     byval bytes as integer)
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

.code
;;::::::::::::::
xmappeekb       proc    uses di es,\
                        map:far ptr,\
                        ofs:dword
                
                mov     es, W map+2
                mov     edi, map                ;; edi= es:di -> map struct
                mov     ebx, ofs

                ;; ofs < or >= than the buffered part?
                cmp     ebx, es:[di].XMAP.buff_ini
                jb      @@bufferize
                cmp     ebx, es:[di].XMAP.buff_end
                jae     @@bufferize

                ;; no, so... get from map.buffer
                sub     ebx, es:[di].XMAP.buff_ini

                mov     al, es:[di+bx+T XMAP]   ;; byte= map.buffer[bx]
                xor     ah, ah
                ret

@@bufferize:    push    di
                FP2L    di                      ;; edi= (es*16)+di
                CALLPM  xmp$bufferize32
                pop     di
                mov     al, es:[di + T XMAP]    ;; byte= map.buffer[0]
                xor     ah, ah
                ret
xmappeekb       endp

;;::::::::::::::
xmappeeki       proc    uses di es,\
                        map:far ptr,\
                        ofs:dword
                
                mov     es, W map+2
                mov     edi, map                ;; edi= es:di -> map struct
                mov     ebx, ofs

                ;; ofs < or >= than the buffered part?
                cmp     ebx, es:[di].XMAP.buff_ini
                jb      @@bufferize
                lea     eax, [ebx + 1]
                cmp     eax, es:[di].XMAP.buff_end
                jae     @@bufferize

                ;; no, so... get from map.buffer
                sub     ebx, es:[di].XMAP.buff_ini

                mov     ax, es:[di+bx+T XMAP]   ;; word= map.buffer[bx]
                ret

@@bufferize:    push    di
                FP2L    di                      ;; edi= (es*16)+di
                CALLPM  xmp$bufferize32
                pop     di
                mov     ax, es:[di + T XMAP]    ;; word= map.buffer[0]
                ret
xmappeeki       endp

;;::::::::::::::
xmappeekl       proc    uses di es,\
                        map:far ptr,\
                        ofs:dword
                
                mov     es, W map+2
                mov     edi, map                ;; edi= es:di -> map struct
                mov     ebx, ofs

                ;; ofs < or >= than the buffered part?
                cmp     ebx, es:[di].XMAP.buff_ini
                jb      @@bufferize
                lea     eax, [ebx + 3]
                cmp     eax, es:[di].XMAP.buff_end
                jae     @@bufferize

                ;; no, so... get from map.buffer
                sub     ebx, es:[di].XMAP.buff_ini

                mov     ax, es:[di+bx+T XMAP]   ;; dword= map.buffer[bx]
                mov     dx, es:[di+bx+T XMAP+2]
                ret

@@bufferize:    push    di
                FP2L    di                      ;; edi= (es*16)+di
                CALLPM  xmp$bufferize32
                pop     di
                mov     ax, es:[di + T XMAP]    ;; dword= map.buffer[0]
                mov     dx, es:[di + T XMAP + 2]
                ret
xmappeekl       endp

;;::::::::::::::
xmappeeks       proc    uses di es,\
                        map:far ptr,\
                        ofs:dword,\
                        result:near ptr real4
                
                mov     es, W map+2
                mov     edi, map                ;; edi= es:di -> map struct
                mov     ebx, ofs

                ;; ofs < or >= than the buffered part?
                cmp     ebx, es:[di].XMAP.buff_ini
                jb      @@bufferize
                lea     eax, [ebx + 3]
                cmp     eax, es:[di].XMAP.buff_end
                jae     @@bufferize

                ;; no, so... get from map.buffer
                sub     ebx, es:[di].XMAP.buff_ini

                mov     eax, es:[di+bx+T XMAP]  ;; real4= map.buffer[bx]

@@exit:         mov     bx, result
                mov     [bx], eax
                mov     ax, bx                  ;; ax -> result (IDE bug)
                ret

@@bufferize:    push    di
                FP2L    di                      ;; edi= (es*16)+di
                CALLPM  xmp$bufferize32
                pop     di
                mov     eax, es:[di + T XMAP]   ;; real4= map.buffer[0]
                jmp     short @@exit
xmappeeks       endp

;;::::::::::::::
xmappeekd       proc    uses di es,\
                        map:far ptr,\
                        ofs:dword,\
                        result:near ptr qword
                
                mov     es, W map+2
                mov     edi, map                ;; edi= es:di -> map struct
                mov     ebx, ofs

                ;; ofs < or >= than the buffered part?
                cmp     ebx, es:[di].XMAP.buff_ini
                jb      @@bufferize
                lea     eax, [ebx + 3]
                cmp     eax, es:[di].XMAP.buff_end
                jae     @@bufferize

                ;; no, so... get from map.buffer
                sub     ebx, es:[di].XMAP.buff_ini

                mov     eax, es:[di+bx+T XMAP]  ;; qword= map.buffer[bx]
                mov     edx, es:[di+bx+T XMAP+4];; /

@@exit:         mov     bx, result
                mov     [bx], eax
                mov     [bx+4], edx
                mov     ax, bx                  ;; ax -> result (IDE bug)
                ret

@@bufferize:    push    di
                FP2L    di                      ;; edi= (es*16)+di
                CALLPM  xmp$bufferize32
                pop     di
                mov     eax, es:[di+T XMAP]   ;; qword= map.buffer[0]
                mov     edx, es:[di+T XMAP+4] ;; /
                jmp     short @@exit
xmappeekd       endp

;;::::::::::::::
xmappeekstr     proc    uses di si es,\
                        map:far ptr,\
                        ofs:dword,\
                        bytes:word
                
                push    ds

                mov     ax, ds
                mov     es, ax
                mov     di, O b4g$buffer        ;; es:di -> b4g$buffer

                mov     cx, bytes
                cmp     cx, B4G_BUFFER_SIZE
                jbe     @F
                mov     cx, B4G_BUFFER_SIZE
@@:             and     ecx, B4G_BUFFER_SIZE    ;; clip
                jz      @@exit                  ;; it's zero?

                mov     ds, W map+2
                mov     esi, map                ;; esi= ds:si -> map struct
                mov     ebx, ofs

                lea     eax, [ebx + ecx - 1]    ;; eax= last byte offset

                ;; ofs < or >= than the buffered part?
                cmp     ebx, ds:[si].XMAP.buff_ini
                jb      @@bufferize
                cmp     ebx, ds:[si].XMAP.buff_end
                jae     @@bufferize
                cmp     eax, ds:[si].XMAP.buff_end
                jae     @@bufferize

                ;; no, so... get from map.buffer
                sub     ebx, ds:[si].XMAP.buff_ini

                lea     si, [si + bx + T XMAP]

                PS      cx, di
                mov     ax, cx
                and     ax, 3                   ;; % 4
                shr     cx, 2                   ;; / 4
                rep     movsd                   ;; string= map.buffer[bx]
                mov     cx, ax
                rep     movsb
                PP      di, cx

@@exit:         pop     ds
                ;; make string descriptor
                mov     bx, O b4g$str_dsc
                BSTRS   bx, di, cx

                mov     ax, bx                  ;; ds:ax -> string descriptor
                ret

@@bufferize:    push    di
                FP2L    di, es                  ;; edi= (es*16)+di
                FP2L    si                      ;; esi= (ds*16)+si
                CALLPM  peek_blk32
                pop     di
                jmp     short @@exit
xmappeekstr     endp

;;::::::::::::::
xmappeekt       proc    uses di si es ds,\
                        _struct:far ptr,\
                        map:far ptr,\
                        ofs:dword,\
                        bytes:word
                
                les     di, _struct             ;; es:di -> struct
                mov     ds, W map+2
                mov     esi, map                ;; esi= ds:si -> map struct
                mov     ebx, ofs
                movzx   ecx, bytes

                lea     eax, [ebx + ecx - 1]    ;; eax= last byte offset

                ;; ofs < or >= than the buffered part?
                cmp     ebx, ds:[si].XMAP.buff_ini
                jb      @@bufferize
                cmp     ebx, ds:[si].XMAP.buff_end
                jae     @@bufferize
                cmp     eax, ds:[si].XMAP.buff_end
                jae     @@bufferize

                ;; no, so... get from map.buffer
                sub     ebx, ds:[si].XMAP.buff_ini

                lea     si, [si + bx + T XMAP]

                mov     ax, cx
                and     ax, 3                   ;; % 4
                shr     cx, 2                   ;; / 4
                rep     movsd                   ;; struct= map.buffer[bx]
                mov     cx, ax
                rep     movsb

@@exit:         ret

@@bufferize:    push    di
                FP2L    di, es                  ;; edi= (es*16)+di
                FP2L    si                      ;; esi= (ds*16)+si
                CALLPM  peek_blk32
                pop     di
                jmp     short @@exit
xmappeekt       endp


CODE32_SEGMENT
;;::::::::::::::
peek_blk32      proc    near uses ecx ebp edi esi es
                ;;  in: esi= map struct linear address
                ;;      ecx= bytes to read
                ;;      ebx= source linear address
                ;;      edi= destine  "       "
                ;;      eax= destine last byte

                ;;   |__________block___________|
                ;;             |buffer|
                ;; 1)          |[dst] |           f/ buffer
                ;; 2)      [des|ine]  |           f/ src, f/ buffer
                ;; 3)          |   [de|tine]      f/ buffer, f/ src, bufferize?
                ;; 4)        [_|_desti|e__]       f/ src, f/ buffer, f/ src
                ;; 5) [destine]|      |           f/ src, bufferize?
                ;; 5)          |      |[destine]  f/ src, bufferize?

                mov     eax, ds
                mov     es, eax                 ;; es= ds (base= 0, limit= 4G)

                mov     ebp, [esi].XMAP.buff_ini
                mov     edx, [esi].XMAP.buff_end

                ;; ofs >= buff_end or ofs+len-1 < buff_ini?
                cmp     ebx, edx
                jae     @@src__buffz
                cmp     eax, ebp
                jb      @@src__buffz

                ;; ofs <= buff_ini?
                sub     ebp, ebx
                jbe     @@buff__src

                ;; ofs+len-1 >= buff_end?
                cmp     eax, edx
                jae     @@src__buff__src

;;............. (2)
                ;; move source to destine...
                sub     ecx, ebp                ;; = str.len-(buff_ini-ofs)
                PS      ecx, esi
                mov     esi, [esi].XMAP.blk_addr
                add     esi, ebx                ;; ds:esi -> src+ofs
                mov     ecx, ebp                ;; ecx= buff_ini - ofs
                and     ebp, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, ebp
                rep     movsb

                ;; ... and map.buffer too
                PP      esi, ecx
                add     esi, T XMAP             ;; ds:esi -> map.buffer
                mov     eax, ecx
                and     eax, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, eax
                rep     movsb
                ret

;;............. (3)
@@buff__src:    add     ebp, ebx
                
                ;; move map.buffer to destine...
                PS      ecx, esi
                sub     edx, ebx                ;; edx= buff_end - ofs
                PS      ebx, edx
                sub     ebx, ebp
                lea     esi, [esi+ebx+T XMAP]   ;; ds:esi -> map.buffer+ofs
                
                mov     ecx, edx                ;; ecx= buff_end - ofs
                and     edx, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, edx
                rep     movsb
                PP      edx, ebx

                ;; ... and source too and bufferize if need
                mov     esi, [esp]
                mov     ecx, [esp+4]
                sub     ecx, edx                ;; ecx= str.len-(buff_end-ofs)
                mov     esi, [esi].XMAP.blk_addr
                add     edx, ebx
                add     esi, edx                ;; ds:esi -> src+ofs+(buff_end-ofs)

                mov     eax, ecx
                and     eax, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, eax
                rep     movsb
                PP      esi, eax

                ;; destine len >= map.size?
                cmp     eax, [esi].XMAP._size
                jae     @F

                ;; nope, so... bufferize
                mov     edi, esi                ;; edi -> map
                call    xmp$bufferize32
@@:             ret

;;............. (4)
@@src__buff__src:
                ;; move source to destine...
                PS      ecx, esi
                mov     esi, [esi].XMAP.blk_addr
                add     esi, ebx                ;; ds:esi -> src+ofs
                mov     ecx, ebp                ;; ecx= buff_ini - ofs
                and     ebp, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, ebp
                rep     movsb

                ;; ... and map.buffer...
                mov     esi, [esp]
                mov     ecx, [esi].XMAP._size   ;; ecx= map.buffer.size
                add     esi, T XMAP             ;; ds:esi -> map.buffer
                mov     eax, ecx
                and     eax, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, eax
                rep     movsb

                ;; ... and source too
                PP      esi, ecx
                sub     ecx, edx                ;; ecx= str.len-(buff_end-ofs)
                mov     esi, [esi].XMAP.blk_addr
                add     edx, ebx
                add     esi, edx                ;; ds:esi -> src+ofs+(buff_end-ofs)

                mov     eax, ecx
                and     eax, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, eax
                rep     movsb
                ret

;;............. (5)
@@src__buffz:   ;; move source to destine and bufferize if need
                PS      ecx, esi
                mov     esi, [esi].XMAP.blk_addr
                add     esi, ebx                ;; ds:esi -> src+ofs
                mov     eax, ecx
                and     eax, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, eax
                rep     movsb
                PP      esi, eax

                ;; destine len >= map.size?
                cmp     eax, [esi].XMAP._size
                jae     @F

                ;; nope, so... bufferize
                mov     edi, esi                ;; edi -> map
                call    xmp$bufferize32
@@:             ret
peek_blk32      endp
CODE32_ENDS
                end
