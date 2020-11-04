;;
;; addr.inc -- addresses conversions macros
;; 

ifndef          __addr_inc__
                __addr_inc__    equ 1

;;::::::::::::::
;; linear to far pointer with offset normalized (<= 15)
L2FP            macro   lin:req                 ;; lin= low word of a reg32

                ;; 1) 000000000000mmmm:llllllllllllllll
                ;; 2) mmmmllllllllllll:llll000000000000
                ;; 3) ssssssssssssssss:000000000000oooo

                ;; seg= lin \ 16; ofs= lin and 0Fh
                shl     e&lin&, 12              ;; 2)
                rol     lin, 4                  ;; 3)
endm

;;::::::::::::::
;; linear to far pointer with offset denormalized (>= 65520)
L2FPD           macro   lin:req                 ;; lin= low word of a reg32

                ;; 1) 000000000000mmmm:llllllllllllllll
                ;; 2) mmmmllllllllllll:llll000000000000
                ;; 3) ssssssssssssssss:000000000000oooo
                ;; 4) sssssssssssss000:oooooooooooooooo

                ;; seg= (lin \ 16) - 4095; ofs= (lin & 0Fh) + 65520
                shl     e&lin&, 12              ;; 2)
                rol     lin, 4                  ;; 3)
                sub     e&lin&, 0FFF0000h       ;; 4)
                or      lin, 65520              ;; /
endm

;;::::::::::::::
;; far pointer to linear
FP2L            macro   fp:req, segm            ;; fp= low word of a reg32
                ;; 1) ssssssssssssssss:oooooooooooooooo
                ;; 2) 000000000000ssss:ssssssssssss0000
                ;; 3) 000000000000mmmm:llllllllllllllll

                ;; lin = seg * 16 + ofs
        ifb     <segm>
                push    W 0
                push    fp
                shr     e&fp&, 12               ;; 2)
                and     e&fp&, not 15           ;; /
                add     e&fp&, [esp]            ;; 3)
                add     esp, 4
        else
                and     e&fp&, 00000FFFFh
                push    e&fp&
                mov     fp, segm
                shl     e&fp&, 4
                add     e&fp&, [esp]
                add     esp, 4
        endif
endm

endif   ;; __addr_inc__
