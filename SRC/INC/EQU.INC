;;
;; equ.inc -- some shortcuts
;; 

ifndef          __equ_inc__
                __equ_inc__     equ 1

                ;; TASM things (yes, i wrote this lib first in TASM)
                global                  equ externdef
                large                   equ <>
                small                   equ <>
                largestack              equ <>
                smallstack              equ <>

                FALSE                   equ 0
                TRUE                    equ -1
                NULL                    equ 0

                S                       equ seg
                O                       equ offset
                F                       equ far ptr
                N                       equ near ptr
                Q                       equ qword ptr
                R                       equ real4 ptr
                D                       equ dword ptr
                W                       equ word ptr
                B                       equ byte ptr
                T                       equ type

;;::::::::::::::
;; push multiple (why MASM doesn't have it, damn)
PS              macro args:vararg
                local a
        for     a, <args>
                push    a
        endm
endm

;;::::::::::::::
;; pop multiple (same shit as above)
PP              macro args:vararg
                local a
        for     a, <args>
                pop     a
        endm
endm

;;::::::::::::::
;; make dx:ax= eax
EAX2DXAX        macro
                mov     edx, eax
                shr     edx, 16
endm

endif   ;; __equ_inc__
