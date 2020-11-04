;; name: xmmove
;; desc: move a memory block to another
;;
;; type: sub
;; args: [in] src:long,        | linear address of source block
;;            bytes:long,      | number of bytes to move
;;            dst:long         | linear address of destine block
;; retn: none
;;
;; decl: xmmove (byval src as long,_
;;               byval bytes as long,_
;;               byval dst as long)
;;
;; updt: jul/00 [v1ctor]
;; obs.: source and destine can overlap
;;       if source and destine are less than 1M, no switch will be made

                include common.inc

.code
;;::::::::::::::::::                
xmmove          proc    uses edi esi,\
                        src:dword,\
                        bytes:dword,\
                        dst:dword

                mov     esi, src
                mov     edi, dst
                mov     ecx, bytes

                ;; source & destine < 1M?
                lea     eax, [esi + ecx - 1]
                cmp     eax, 100000h
                jae     @F
                lea     eax, [edi + ecx - 1]
                cmp     eax, 100000h
                jb      @@move_huge
@@:             CALLPM  xmmove32

@@exit:         ret

@@move_huge:    PS      es, ds                  ;; (0)

                ;; check if source & destine overlap
                cmp     esi, edi
                jae     @@mov_backward          ;; src >= dst?
                lea     eax, [esi + ecx]
                cmp     eax, edi
                ja      @@mov_forward           ;; src+bytes > dst?

@@mov_backward: L2FP    si                      ;; lin 2 farptr
                mov     ebx, esi
                shr     ebx, 16
                mov     ds, bx                  ;; ds:si -> source

                L2FP    di                      ;; lin 2 farptr
                mov     edx, edi
                shr     edx, 16
                mov     es, dx                  ;; es:di -> destine

                mov     eax, ecx                ;; eax= bytes
                jmp     short @@test_bw

@@loop_bw:      sub     eax, 65520              ;; bytes-= 65520

                mov     cx, 65520 / 4
                rep     movsd                   ;; move 16380 dwords

                add     bx, 65520 / 16          ;; ds+= 65520
                mov     ds, bx
                add     dx, 65520 / 16          ;; es+= 65520                
                mov     es, dx

@@test_bw:      cmp     eax, 65520
                jae     @@loop_bw               ;; bytes >= 65520? loop
            
                mov     cx, ax                  ;; else, move remainder
                shr     cx, 2                   ;; / 4
                rep     movsd
                mov     cx, ax
                and     cx, 3                   ;; % 4
                rep     movsb

                PP      ds, es                  ;; (0)
                jmp     short @@exit

@@mov_forward:  L2FPD   si                      ;; lin 2 farptr (denormalized)
                mov     ebx, esi
                sub     si, 4
                shr     ebx, 16
                mov     ds, bx                  ;; ds:si -> source

                L2FPD   di                      ;; lin 2 farptr (denormalized)
                mov     edx, edi
                sub     di, 4
                shr     edx, 16
                mov     es, dx                  ;; es:di -> destine
                
                std                             ;; move down
                mov     eax, ecx                ;; eax= bytes
                jmp     short @@test_fw

@@loop_fw:      sub     eax, 65504              ;; bytes-= 65504

                mov     ecx, 65504 / 4
                rep     movsd                   ;; 16376 dwords

                sub     bx, 65504 / 16          ;; ds-= 65504
                mov     ds, bx
                sub     dx, 65504 / 16          ;; es-= 65504
                mov     ds, bx
             
@@test_fw:      cmp     eax, 65504
                jae     @@loop_fw               ;; bytes >= 65504? loop

                mov     cx, ax                  ;; else, move remainder
                shr     cx, 2                   ;; / 4
                rep     movsd
                mov     cx, ax
                and     cx, 3                   ;; % 4
                add     si, 3
                add     di, 3
                rep     movsb

                PP      ds, es                  ;; (0)
                cld                             ;; restore default direction
                jmp     @@exit
xmmove          endp


CODE32_SEGMENT
;;::::::::::::::
xmmove32        proc    near
                ;;  in: ecx= bytes
                ;;      esi= source block linear address (data)
                ;;      edi= destine  "     "       "      "
                ;;      DF clear

                push    es

                mov     eax, ds
                mov     es, eax                 ;; es= ds (base= 0, limit= 4G)

                ;; check if source & destine overlap                
                cmp     esi, edi
                jae     @@mov_backward          ;; src >= dst?
                lea     eax, [esi + ecx]
                cmp     eax, edi
                ja      @@mov_forward           ;; src+bytes > dst?

@@mov_backward: mov     eax, ecx
                shr     ecx, 2                  ;; / 4
                rep     movsd
                mov     ecx, eax
                and     ecx, 3                  ;; % 4
                rep     movsb

@@exit:         pop     es
                ret

@@mov_forward:  std                             ;; move down
                lea     esi, [esi + ecx - 4]    ;; correct source 
                lea     edi, [edi + ecx - 4]    ;; and destine
                mov     eax, ecx
                shr     ecx, 2                  ;; / 4
                rep     movsd
                add     esi, 3
                add     edi, 3
                mov     ecx, eax
                and     ecx, 3                  ;; % 4
                rep     movsb
                cld                             ;; restore default direction
                jmp     short @@exit
xmmove32        endp
CODE32_ENDS
                end
