;; name: xmpeekb, xmpeeki, xmpeekl, xmpeeks, xmpeekd, xmpeekstr, xmpeekt
;; desc: get a byte, integer, long integer, single, double, string or
;;       a structure from memory
;;
;; type: function
;; args: [in]  src:long         | linear address of source
;;   or: [in]  src:long,        |   "       "         "
;;             bytes:integer    | string size
;;   or: [out] struct:any,      | struct to write
;;       [in]  src:long,        |   "       "         "
;;             bytes:integer    | string size
;; retn: byte, integer, long,\
;;       single, double, string | byte, ..., double, or string read
;;
;; decl: xmpeekb%   (byval src as long)
;;       xmpeeki%   (byval src as long)
;;       xmpeekl&   (byval src as long)
;;       xmpeeks!   (byval src as long)
;;       xmpeekd#   (byval src as long)
;;       xmpeekstr$ (byval src as long,_
;;                   byval bytes as integer)
;;       xmpeekt    (seg struct as any,_
;;                   byval src as long,_
;;                   byval bytes as integer)
;;
;; updt: jul/00 [v1ctor]
;; obs.: if source is less than 1M, no switch will be made

                include common.inc

.code
;;::::::::::::::
xmpeekb         proc    src:dword

                mov     ebx, src
                cmp     ebx, 100000h
                jb      @@huge_peek             ;; source < 1M?

                CALLPM  xmpeek32

@@exit:         xor     ah, ah
                ret

@@huge_peek:    push    ds
                L2FP    bx
                mov     eax, ebx
                shr     eax, 16
                mov     ds, ax                  ;; ds:bx -> src
                mov     al, ds:[bx]             ;; get byte
                pop     ds
                jmp     short @@exit
xmpeekb         endp

;;::::::::::::::
xmpeeki         proc    src:dword

                mov     ebx, src
                cmp     ebx, 100000h - 1
                jb      @@huge_peek             ;; source < 1M?

                CALLPM  xmpeek32

@@exit:         ret

@@huge_peek:    push    ds
                L2FP    bx
                mov     eax, ebx
                shr     eax, 16
                mov     ds, ax                  ;; ds:bx -> src
                mov     ax, ds:[bx]             ;; get word
                pop     ds
                jmp     short @@exit
xmpeeki         endp

;;::::::::::::::
xmpeekl         proc    src:dword

                mov     ebx, src
                cmp     ebx, 100000h - 3
                jb      @@huge_peek             ;; source < 1M?

                CALLPM  xmpeek32
                
@@exit:         EAX2DXAX
                ret

@@huge_peek:    push    ds
                L2FP    bx
                mov     eax, ebx
                shr     eax, 16
                mov     ds, ax                  ;; ds:bx -> src
                mov     eax, ds:[bx]            ;; get dword
                pop     ds
                jmp     short @@exit
xmpeekl         endp

;;::::::::::::::
xmpeeks         proc    src:dword,\
                        result:near ptr real4

                mov     ebx, src
                cmp     ebx, 100000h - 3
                jb      @@huge_peek             ;; source < 1M?

                CALLPM  xmpeek32
                
@@exit:         mov     bx, result
                mov     [bx], eax
                mov     ax, bx                  ;; ax -> result (IDE bug)
                ret

@@huge_peek:    push    ds
                L2FP    bx
                mov     eax, ebx
                shr     eax, 16
                mov     ds, ax                  ;; ds:bx -> src
                mov     eax, ds:[bx]            ;; get real4
                pop     ds
                jmp     short @@exit
xmpeeks         endp

;;::::::::::::::
xmpeekd         proc    src:dword,\
                        result:near ptr qword

                mov     ebx, src
                cmp     ebx, 100000h - 7
                jb      @@huge_peek             ;; source < 1M?

                CALLPM  xmpeekd32
                
@@exit:         mov     bx, result
                mov     [bx], eax
                mov     [bx+4], edx
                mov     ax, bx                  ;; ax -> result (IDE bug)
                ret

@@huge_peek:    push    ds
                L2FP    bx
                mov     eax, ebx
                shr     eax, 16
                mov     ds, ax                  ;; ds:bx -> src
                mov     eax, ds:[bx]            ;; get qword
                mov     edx, ds:[bx+4]          ;; /
                pop     ds
                jmp     short @@exit
xmpeekd         endp

;;::::::::::::::
xmpeekstr       proc    uses di si,\
                        src:dword,\
                        bytes:word

                mov     esi, src
                mov     di, O b4g$buffer        ;; ds:di -> b4g$buffer

                mov     cx, bytes
                cmp     cx, B4G_BUFFER_SIZE
                jbe     @F
                mov     cx, B4G_BUFFER_SIZE
@@:             and     ecx, B4G_BUFFER_SIZE    ;; clip
                jz      @@exit                  ;; it's zero?

                lea     eax, [esi + ecx - 1]
                cmp     eax, 100000h
                jb      @@huge_peek             ;; source < 1M?

                push    di
                FP2L    di, ds                  ;; edi= (ds*16)+di
                CALLPM  peek_blk32
                pop     di
                
@@exit:         ;; make string descriptor
                mov     bx, O b4g$str_dsc
                BSTRS   bx, di, cx

                mov     ax, bx                  ;; ds:ax -> string descriptor
                ret

@@huge_peek:    PS      cx, di, es, ds
                mov     ax, ds
                mov     es, ax                  ;; es:di -> strg

                L2FP    si
                mov     eax, esi
                shr     eax, 16
                mov     ds, ax                  ;; ds:si -> src

                mov     ax, cx
                and     ax, 3                   ;; % 4
                shr     cx, 2                   ;; / 4
                rep     movsd                   ;; get string
                mov     cx, ax
                rep     movsb
                PP      ds, es, di, cx
                jmp     short @@exit
xmpeekstr       endp

;;::::::::::::::
xmpeekt         proc    uses di si es,\
                        _struct:far ptr,\
                        src:dword,\
                        bytes:word

                les     di, _struct             ;; es:di -> struct
                mov     esi, src
                movzx   ecx, bytes
                
                lea     eax, [esi + ecx - 1]
                cmp     eax, 100000h
                jb      @@huge_peek             ;; source < 1M?

                FP2L    di, es                  ;; edi= (es*16)+di
                CALLPM  peek_blk32
                
@@exit:         ret

@@huge_peek:    push    ds

                L2FP    si
                mov     eax, esi
                shr     eax, 16
                mov     ds, ax                  ;; ds:si -> src

                mov     ax, cx
                and     ax, 3                   ;; % 4
                shr     cx, 2                   ;; / 4
                rep     movsd                   ;; get struct
                mov     cx, ax
                rep     movsb

                pop     ds
                jmp     short @@exit
xmpeekt         endp


CODE32_SEGMENT
;;::::::::::::::
xmpeek32        proc    near
                ;;  in: ebx= source linear address
                ;;
                ;; out: eax= dword read

                mov     eax, [ebx]              ;; get dword
                ret
xmpeek32        endp

;;::::::::::::::
xmpeekd32       proc    near
                ;;  in: ebx= source linear address
                ;;
                ;; out: edx:eax= qword read

                mov     eax, [ebx]              ;; get qword
                mov     edx, [ebx+4]            ;; /
                ret
xmpeekd32       endp

;;::::::::::::::
peek_blk32      proc    near uses ecx edi esi es
                ;;  in: esi= source linear address
                ;;      edi= destine  "       "
                ;;      ecx= bytes to read

                mov     eax, ds
                mov     es, eax                 ;; es= ds (base= 0, limit= 4G)

                mov     eax, ecx
                and     eax, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, eax
                rep     movsb

                ret
peek_blk32      endp
CODE32_ENDS
                end
