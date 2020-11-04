;; name: xmfill
;; desc: fill a memory block with a character
;;
;; type: sub
;; args: [in] blk:long,        | linear address of block to fill
;;            bytes:long,      | number of bytes to fill
;;            char:integer     | fill character
;; retn: none
;;
;; decl: xmfill (byval blk as long,_
;;               byval bytes as long,_
;;               byval char as integer)
;;
;; updt: jul/00 [v1ctor]
;; obs.: if address is less than 1M, no switch will be made

                include common.inc

.code
;;::::::::::::::::::                
xmfill          proc    uses di,\
                        blk:dword,\
                        bytes:dword,\
                        char:word

                mov     edi, blk
                mov     ecx, bytes
                mov     al, B char
                mov     ah, al
                mov     dx, ax
                shl     eax, 16
                mov     ax, dx                  ;; eax= char:char:char:char
                
                ;; destine < 1M?
                lea     edx, [edi + ecx - 1]
                cmp     edx, 100000h
                jb      @@fill_huge

                CALLPM  xmfill32

@@exit:         ret

@@fill_huge:    push    es

                L2FP    di                      ;; lin 2 farptr
                mov     edx, edi
                shr     edx, 16
                mov     es, dx                  ;; es:di -> destine

                mov     ebx, ecx                ;; ebx= bytes
                jmp     short @@test

@@loop:         sub     ebx, 65520              ;; bytes-= 65520

                mov     cx, 65520 / 4           ;; fill 16380 dwords
                rep     stosd

                add     dx, 65520 / 16          ;; es+= 65520
                mov     es, dx

@@test:         cmp     ebx, 65520
                jae     @@loop                  ;; bytes >= 65520? loop
            
                mov     cx, bx                  ;; else, fill remainder
                shr     cx, 2                   ;; / 4
                rep     stosd
                mov     cx, bx
                and     cx, 3                   ;; % 4
                rep     stosb

                pop     es
                jmp     short @@exit
xmfill          endp


CODE32_SEGMENT
;;::::::::::::::
xmfill32        proc    near
                ;;  in: eax= char:char:char:char
                ;;      ecx= bytes
                ;;      edi= block linear address (data)
                ;;      DF clear

                push    es

                mov     edx, ds
                mov     es, edx                 ;; es:edi ptr to block

                mov     edx, ecx
                shr     ecx, 2                  ;; / 4
                rep     stosd
                mov     ecx, edx
                and     ecx, 3                  ;; % 4
                rep     stosb

                pop     es
                ret
xmfill32        endp
CODE32_ENDS
                end
