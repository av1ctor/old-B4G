;;
;; useless graphic library -- shows how to make your own pmode assembly
;;                            library together with B4G lib
;;

                .model  medium, basic
                .386
                option  proc:private

                include ..\..\src\inc\equ.inc
                include ..\..\src\inc\bas.inc
                include ..\..\src\inc\core.inc
                include ..\..\src\inc\xmem.inc

BITMAP          struct
                xmin            dword ?
                ymin            dword ?
                xmax            dword ?
                ymax            dword ?
                wdt             dword ?
                hgt             dword ?
                _data           dword ?
BITMAP          ends


                ;; UGLalloc     (seg bmp as BITMAP,_
                ;;               byval wdt as long,_
                ;;               byval hgt as long)
                UGLalloc        proto :far ptr BITMAP, :dword, :dword

                ;; UGLput       (seg src as BITMAP,_
                ;;               byval x as long,_
                ;;               byval y as long,_
                ;;               seg dst as BITMAP)
                UGLput          proto :far ptr BITMAP, :dword, :dword,\
                                      :far ptr BITMAP


                gd_cnt  = 0
;;::::::::::::::
;; generate optimized movs loops
gen_d           macro   prefx:=<0>, sufx:=<0>
                gen_d_gen %gd_cnt, prefx, sufx
                gd_cnt  = gd_cnt + 1
endm
;;::::::::::::::
gen_d_gen       macro   cnt, prefx, sufx

loop_&cnt:      mov     ecx, edx

                ;; align on dword boundarie
        ifidni  <prefx>, <b>
                movsb
        else
        ifidni  <prefx>, <w>
                movsw
        else
        ifidni  <prefx>, <bw>
                movsb
                movsw
        endif
        endif
        endif

                rep     movsd                   ;; moves middle

                ;; moves remainder
        ifidni  <sufx>, <b>
                movsb
        else
        ifidni  <sufx>, <w>
                movsw
        else
        ifidni  <sufx>, <wb>
                movsw
                movsb
        endif
        endif
        endif

                add     esi, eax                ;; src+=lf+rg gaps
                add     edi, ebx                ;; dst+=dst.wdt-width
                dec     ebp                     ;; next line
                jnz     loop_&cnt               ;; last one?
                jmp     @@exit
endm

                gdt_cnt = 0
;;::::::::::::::
;; generate jump table for optimized loops
gen_d_tb        macro   tb_name:req
tb_name         label   dword
        repeat  gd_cnt
                gen_d_tb_gen %gdt_cnt
                gdt_cnt = gdt_cnt + 1
        endm
                gd_cnt  = 0
                gdt_cnt = 0
endm
;;::::::::::::::
gen_d_tb_gen    macro   cnt
                dword   loop_&cnt
endm


.code
;;::::::::::::::
UGLalloc        proc    bmp:far ptr BITMAP,\
                        wdt:dword,\
                        hgt:dword

                movzx   eax, W bmp+2
                shl     eax, 4
                movzx   ebx, W bmp
                add     ebx, eax                ;; ebx= bmp linear addr

                mov     eax, wdt
                mov     edx, hgt

                CALLPM  UGLalloc32
                ret
UGLalloc        endp

;;::::::::::::::
UGLput          proc    uses di si\
                        src:far ptr BITMAP,\
                        x:dword, y:dword,\
                        dst:far ptr BITMAP

                mov     ecx, x
                mov     ebx, y

                movzx   eax, W src+2
                shl     eax, 4
                movzx   esi, W src
                add     esi, eax                ;; esi= source linear addr

                movzx   eax, W dst+2
                shl     eax, 4
                movzx   edi, W dst
                add     edi, eax                ;; edi= destine linear addr

                CALLPM  UGLput32
                ret
UGLput          endp

CODE32_SEGMENT
;;::::::::::::::
UGLalloc32      proc    near
                ;;  in: ebx -> bmp struct
                ;;      eax= width
                ;;      edx= height

                mov     [ebx].BITMAP.wdt, eax   ;; save width
                mov     [ebx].BITMAP.hgt, edx   ;; save height
                xor     ecx, ecx
                mov     [ebx].BITMAP.xmin, ecx  ;; bmp.xmin= 0
                mov     [ebx].BITMAP.ymin, ecx  ;; bmp.ymin= 0
                lea     ecx, [eax-1]
                mov     [ebx].BITMAP.xmax, ecx  ;; bmp.xmax= bmp.wdt-1
                lea     ecx, [edx-1]
                mov     [ebx].BITMAP.ymax, ecx  ;; bmp.ymax= bmp.hgt-1

                mul     edx                     ;; bmp size= wdt*hgt
                call    xmcalloc32
                mov     [ebx].BITMAP._data, eax ;; save pointer (0 if error)

                ret
UGLalloc32      endp

;;::::::::::::::
UGLput32        proc    near uses ebp es
                ;;  in: esi -> source struct
                ;;      edi -> destine struct
                ;;      ecx= x
                ;;      ebx= y
                lf_gap          equ D [esp]
                rg_gap          equ D [esp+4]
                sub     esp, 4 + 4              ;; alloc temp spc f/ gaps

                mov     eax, ds
                mov     es, eax                 ;; es= ds (base:0; limit:4G)

                ;; clipping ::::::::::::::::::::
                xor     eax, eax
                mov     lf_gap, eax             ;; lf_gap=0
                mov     rg_gap, eax             ;; rg_gap=0
           
                mov     edx, [esi].BITMAP.wdt
                mov     ebp, [esi].BITMAP.hgt

                mov     eax, [edi].BITMAP.xmax
                sub     eax, ecx
                js      @@exit                  ;; x > dst.xmax?

                inc     eax
                cmp     eax, edx
                jge     @F                      ;; x + src.wdt <= dst.xmax?
             
                sub     edx, eax
                mov     rg_gap, edx             ;; rg_gap=src.wdt-(dst.xmax-x+1)
                mov     edx, eax                ;; src.wdt= dst.xmax - x + 1

@@:             mov     eax, [edi].BITMAP.xmin
                sub     eax, ecx
                jle     @@vert_clip             ;; x >= dst.xmin?

                sub     edx, eax                ;; src.wdt-= dst.xmin - x
                jle     @@exit                  ;; x + src.wdt < dst.xmin?
             
                mov     lf_gap, eax             ;; lf_gap= dst.xmin - x
                mov     ecx, [edi].BITMAP.xmin  ;; x= dst.xmin

@@vert_clip:    mov     eax, [edi].BITMAP.ymax
                sub     eax, ebx
                js      @@exit                  ;; y > dst.ymax?

                inc     eax
                cmp     eax, ebp
                jge     @F                      ;; y + src.hgt <= dst.ymax?
                mov     ebp, eax                ;; src.hgt= dst.ymax - y + 1
 
@@:             mov     eax, [edi].BITMAP.ymin
                sub     eax, ebx
                jle     @F                      ;; y >= dst.ymin?

                sub     ebp, eax                ;; src.hgt-= (dst.ymin - y)
                jle     @@exit                  ;; y + src.hgt < dst.ymin?

                mov     ebx, [edi].BITMAP.ymin  ;; y= dst.ymin
                jmp     short @@end_clipping
        
@@:             xor     eax, eax                ;; up_gap= 0

@@end_clipping: ;; esi= src._data + (up_gap * org src.wdt) + lf_gap
                imul    eax, [esi].BITMAP.wdt
                add     eax, lf_gap
                mov     esi, [esi].BITMAP._data
                add     esi, eax

                mov     eax, [edi].BITMAP.wdt
                ;; edi= dst._data + (y * org dst.wdt) + x
                imul    ebx, eax
                add     ebx, ecx
                mov     edi, [edi].BITMAP._data
                add     edi, ebx

                mov     ebx, eax
                sub     ebx, edx                ;; ebx= org dst.wdt-src.wdt

                ;; jump to optimized loop ::::::
                push    ebp                     ;; save height
                mov     eax, edi
                and     eax, 3
                mov     ebp, 4
                sub     ebp, eax
                and     ebp, 3                  ;; ebp= (4-(destine & 3)) & 3

                mov     ecx, edx
                sub     edx, ebp                ;; correct width
                sar     edx, 2                  ;; width /= 4
                pop     ebp                     ;; restore height
                jz      @@lt_four               ;; width < 4?

                shl     eax, 2
                and     ecx, 3                  ;; ecx= width & 3
                add     ecx, eax                ;; ecx+= (dst & 3)*4+(wdt & 3)

                mov     eax, lf_gap
                add     eax, rg_gap             ;; eax= left+right gaps

                jmp     cs:loop_tb[ecx * 4]
                        
                ;; destine & 3 = 0
                gen_d                           ;; width & 3 = 0
                gen_d   ,b                      ;; width & 3 = 1
                gen_d   ,w                      ;; width & 3 = 2
                gen_d   ,wb                     ;; width & 3 = 3

                ;; destine & 3 = 1
                gen_d   bw,b                    ;; width & 3 = 0
                gen_d   bw,w                    ;; width & 3 = 1
                gen_d   bw,wb                   ;; width & 3 = 2
                gen_d   bw                      ;; width & 3 = 3
                
                ;; destine & 3 = 2
                gen_d   w,w                     ;; width & 3 = 0
                gen_d   w,wb                    ;; width & 3 = 1
                gen_d   w                       ;; width & 3 = 2
                gen_d   w,b                     ;; width & 3 = 3

                ;; destine & 3 = 3
                gen_d   b,wb                    ;; width & 3 = 0
                gen_d   b                       ;; width & 3 = 1
                gen_d   b,b                     ;; width & 3 = 2
                gen_d   b,w                     ;; width & 3 = 3

@@lt_four:      mov     edx, ecx
                mov     eax, lf_gap
                add     eax, rg_gap             ;; eax= left+right gaps

@@loop:         mov     ecx, edx
                rep     movsb
                add     esi, eax
                add     edi, ebx
                dec     ebp
                jnz     @@loop

@@exit:         add     esp, 4 + 4              ;; free stack (gaps)
                ret

                gen_d_tb loop_tb
UGLput32        endp
CODE32_ENDS
                end
