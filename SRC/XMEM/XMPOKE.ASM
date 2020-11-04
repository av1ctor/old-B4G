;; name: xmpokeb, xmpokei, xmpokel, xmpokes, xmpoked, xmpokestr, xmpoket
;; desc: write a byte, integer, long integer, single, double, string
;;       or a structure to memory
;;
;; type: sub
;; args: [in] dst:long,             | linear address of destine
;;            value:integer, long,\
;;                  single, double,\
;;            struct:any,\
;;            strg:string           | byte, ..., struct, or string to write
;; retn: none
;;
;; decl: xmpokeb   (byval dst as long,_
;;                  byval value as integer)
;;       xmpokei   (byval dst as long,_
;;                  byval value as integer)
;;       xmpokel   (byval dst as long,_
;;                  byval value as long)
;;       xmpokes   alias "xmpokel" (byval dst as long,_
;;                  byval value as single)
;;       xmpoked   (byval dst as long,_
;;                  byval value as double)
;;       xmpokestr (byval dst as long,_
;;                  strg as string)
;;       xmpoket   (byval dst as long,_
;;                  seg struct as any,_
;;                  byval bytes as integer)
;;
;; updt: jul/00 [v1ctor]
;; obs.: if destine is less than 1M, no switch will be made

                include common.inc

.code
;;::::::::::::::
xmpokeb         proc    dst:dword,\
                        value:word

                mov     ebx, dst
                mov     al, B value
                cmp     ebx, 100000h
                jb      @@huge_poke             ;; destine < 1M?

                CALLPM  xmpokeb32

@@exit:         ret

@@huge_poke:    push    ds
                L2FP    bx
                mov     edx, ebx
                shr     edx, 16
                mov     ds, dx                  ;; ds:bx -> dst
                mov     ds:[bx], al             ;; put byte
                pop     ds
                jmp     short @@exit
xmpokeb         endp

;;::::::::::::::
xmpokei         proc    dst:dword,\
                        value:word

                mov     ebx, dst
                mov     ax, value
                cmp     ebx, 100000h - 1
                jb      @@huge_poke             ;; destine < 1M?

                CALLPM  xmpokei32

@@exit:         ret

@@huge_poke:    push    ds
                L2FP    bx
                mov     edx, ebx
                shr     edx, 16
                mov     ds, dx                  ;; ds:bx -> dst
                mov     ds:[bx], ax             ;; put word
                pop     ds
                jmp     short @@exit
xmpokei         endp

;;::::::::::::::
xmpokel         proc    dst:dword,\
                        value:dword

                mov     ebx, dst
                mov     eax, value
                cmp     ebx, 100000h - 3
                jb      @@huge_poke             ;; destine < 1M?

                CALLPM  xmpokel32

@@exit:         ret

@@huge_poke:    push    ds
                L2FP    bx
                mov     edx, ebx
                shr     edx, 16
                mov     ds, dx                  ;; ds:bx -> dst
                mov     ds:[bx], eax            ;; put dword
                pop     ds
                jmp     short @@exit
xmpokel         endp

;;::::::::::::::
xmpoked         proc    dst:dword,\
                        value:qword

                mov     ebx, dst
                mov     eax, D value
                mov     edx, D value+4
                cmp     ebx, 100000h - 7
                jb      @@huge_poke             ;; destine < 1M?

                CALLPM  xmpoked32

@@exit:         ret

@@huge_poke:    push    ds
                L2FP    bx
                mov     ecx, ebx
                shr     ecx, 16
                mov     ds, cx                  ;; ds:bx -> dst
                mov     ds:[bx], eax            ;; put qword
                mov     ds:[bx+4], edx          ;; /
                pop     ds
                jmp     short @@exit
xmpoked         endp

;;::::::::::::::
xmpokestr       proc    uses di si es,\
                        dst:dword,\
                        strg:near ptr STRG_DSC

                mov     edi, dst

                xor     ecx, ecx
                BSTRG   strg, es, si, cx
                test    cx, cx
                jz      @@exit                  ;; string.len= 0?

                lea     eax, [edi + ecx - 1]
                cmp     eax, 100000h
                jb      @@huge_poke             ;; destine < 1M?

                FP2L    si, es                  ;; esi= (es*16)+si
                CALLPM  poke_blk32

@@exit:         ret

@@huge_poke:    push    ds
                mov     ax, es
                mov     ds, ax                  ;; ds:si -> string

                L2FP    di
                mov     eax, edi
                shr     eax, 16
                mov     es, ax                  ;; es:di -> dst

                mov     ax, cx
                and     ax, 3                   ;; % 4
                shr     cx, 2                   ;; / 4
                rep     movsd                   ;; put string
                mov     cx, ax
                rep     movsb

                pop     ds
                jmp     short @@exit
xmpokestr       endp

;;::::::::::::::
xmpoket         proc    uses di si es,\
                        dst:dword,\
                        _struct:far ptr,\
                        bytes:word

                mov     edi, dst
                les     si, _struct
                movzx   ecx, bytes

                lea     eax, [edi + ecx - 1]
                cmp     eax, 100000h
                jb      @@huge_poke             ;; destine < 1M?

                FP2L    si, es                  ;; esi= (es*16)+si
                CALLPM  poke_blk32

@@exit:         ret

@@huge_poke:    push    ds
                mov     ax, es
                mov     ds, ax                  ;; ds:si -> struct

                L2FP    di
                mov     eax, edi
                shr     eax, 16
                mov     es, ax                  ;; es:di -> dst

                mov     ax, cx
                and     ax, 3                   ;; % 4
                shr     cx, 2                   ;; / 4
                rep     movsd                   ;; put struct
                mov     cx, ax
                rep     movsb

                pop     ds
                jmp     short @@exit
xmpoket         endp

CODE32_SEGMENT
;;::::::::::::::
xmpokeb32       proc    near
                ;;  in: ebx= destine linear address
                ;;      al= byte to write

                mov     [ebx], al               ;; put byte
                ret
xmpokeb32       endp

;;::::::::::::::
xmpokei32       proc    near
                ;;  in: ebx= destine linear address
                ;;      ax= word to write

                mov     [ebx], ax               ;; put word
                ret
xmpokei32       endp

;;::::::::::::::
xmpokel32       proc    near
                ;;  in: ebx= destine linear address
                ;;      eax= dword to write

                mov     [ebx], eax              ;; put dword
                ret
xmpokel32       endp

;;::::::::::::::
xmpoked32       proc    near
                ;;  in: ebx= destine linear address
                ;;      edx:eax= qword to write

                mov     [ebx], eax              ;; put qword
                mov     [ebx+4], edx            ;; /
                ret
xmpoked32       endp

;;::::::::::::::
poke_blk32      proc    near uses es
                ;;  in: esi= source linear address
                ;;      edi= destine linear address
                ;;      ecx= bytes to write

                mov     eax, ds
                mov     es, eax                 ;; es= ds (base= 0, limit= 4G)

                mov     eax, ecx
                and     eax, 3                  ;; % 4
                shr     ecx, 2                  ;; / 4
                rep     movsd                   ;; poke
                mov     ecx, eax
                rep     movsb

                ret
poke_blk32      endp
CODE32_ENDS
                end
