;; name: xmmovefill
;; desc: move a memory block to another and fill source
;;
;; type: sub
;; args: [in] src:long,        | linear address of source block
;;            bytes:long,      | number of bytes to move and fill
;;            dst:long,        | linear address of destine block
;;            char:integer     | character to fill source
;; retn: none
;;
;; decl: xmmovefill (byval src as long,_
;;                   byval bytes as long,_
;;                   byval dst as long,_
;;                   byval char as integer)
;;
;; updt: jul/00 [v1ctor]
;; obs.: if source and destine are less than 1M, no switch will be made

                include common.inc

.code
;;::::::::::::::
xmmovefill      proc    uses edi esi,\
                        src:dword,\
                        bytes:dword,\
                        dst:dword,\
                        char:word

                mov     esi, src
                mov     edi, dst
                mov     ecx, bytes
                mov     al, B char
                mov     ah, al
                mov     dx, ax
                shl     eax, 16
                mov     ax, dx                  ;; eax= char:char:char:char
                
                ;; destine < 1M?
                lea     edx, [esi + ecx - 1]
                cmp     edx, 100000h
                jae     @F
                lea     edx, [edi + ecx - 1]
                cmp     edx, 100000h
                jb      @@fill_huge

@@:             CALLPM  xmmovefill32

@@exit:         ret

@@fill_huge:    PS      bp, es, ds

                L2FP    si                      ;; lin 2 farptr
                mov     ebx, edi
                shr     ebx, 16
                mov     ds, bx                  ;; ds:si -> source

                L2FP    di                      ;; lin 2 farptr
                mov     edx, edi
                shr     edx, 16
                mov     es, dx                  ;; es:di -> destine

                mov     ebp, ecx                ;; ebp= bytes
                jmp     short @@test

@@loop:         sub     ebp, 65520              ;; bytes-= 65520

                mov     cx, 65520 / 4           ;; fill 16380 dwords
                push    dx
@@loop_mf:      mov     edx, ds:[si]
                mov     es:[di], edx
                mov     ds:[si], eax
                add     si, 4
                add     di, 4
                dec     cx
                jnz     @@loop_mf
                pop     dx

                add     bx, 65520 / 16          ;; ds+= 65520
                mov     ds, bx
                add     dx, 65520 / 16          ;; es+= 65520
                mov     es, dx

@@test:         cmp     ebp, 65520
                jae     @@loop                  ;; bytes >= 65520? loop
            
                mov     cx, bp                  ;; else, fill remainder
                shr     cx, 2                   ;; / 4
                jz      @@mod4
@@:             mov     edx, ds:[si]
                mov     es:[di], edx
                mov     ds:[si], eax
                add     si, 4
                add     di, 4
                dec     cx
                jnz     @B

@@mod4:         mov     cx, bp
                and     cx, 3                   ;; % 4
                jz      @@done
@@:             mov     ah, ds:[si]
                mov     es:[di], ah
                mov     ds:[si], al
                inc     si
                inc     di
                dec     cx
                jnz     @B

@@done:         PP      ds, es, bp
                jmp     @@exit
xmmovefill      endp


CODE32_SEGMENT
;;::::::::::::::
xmmovefill32    proc    near
                ;;  in: eax= char:char:char:char
                ;;      ecx= bytes
                ;;      esi= source block linear address (data)
                ;;      edi= destine  "     "       "      "
                ;;      DF clear

                mov     edx, eax                ;; edx= chr:chr:chr:chr

                mov     ebx, ecx                
                and     ecx, not 3              ;; / 4 
                jz      @@remainder
                add     esi, ecx
                add     edi, ecx                
                neg     ecx

@@loop_d:       mov     eax, [esi+ecx]          ;; get
                mov     [esi+ecx], edx          ;; fill
                mov     [edi+ecx], eax          ;; put
                add     ecx, 4
                jnz     @@loop_d

@@remainder:    and     ebx, 3                  ;; % 4
                jz      @@exit                  ;; any byte remaining?
                add     esi, ebx
                add     edi, ebx
                neg     ebx

@@loop_b:       mov     al, [esi+ebx]
                mov     [esi+ebx], dl
                mov     [edi+ebx], al
                inc     ebx
                jnz     @@loop_b

@@exit:         ret
xmmovefill32    endp
CODE32_ENDS
                end
