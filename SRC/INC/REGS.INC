;;
;; regs.inc -- registers structs
;;

ifndef          __regs_inc__
                __regs_inc__    equ 1

RDD             struct                          ;; 32-bit registers
                _edi            dword   ?
                _esi            dword   ?
                _ebp            dword   ?
                                dword   0
                _ebx            dword   ?
                _edx            dword   ?
                _ecx            dword   ?
                _eax            dword   ?
RDD             ends

RDW             struct                          ;; 16-bit registers
                _di             word    ?, ?
                _si             word    ?, ?
                _bp             word    ?, ?
                                dword   0
                _bx             word    ?, ?
                _dx             word    ?, ?
                _cx             word    ?, ?
                _ax             word    ?, ?
RDW             ends

RDB             struct                          ;; 8-bit registers
                                dword   1 + 1 + 1 dup (?)
                                dword   0
                _bl             byte    ?
                _bh             byte    ?, ?, ?
                _dl             byte    ?
                _dh             byte    ?, ?, ?
                _cl             byte    ?
                _ch             byte    ?, ?, ?
                _al             byte    ?
                _ah             byte    ?, ?, ?
RDB             ends

REGS            union                           ;; all together
                                RDD     <>
                                RDW     <>
                                RDB     <>
REGS            ends

                ;; some flags
                C_FLG           equ 0000000001b ;; carry
                P_FLG           equ 0000000100b ;; parity
                Z_FLG           equ 0001000000b ;; zero
                S_FLG           equ 0010000000b ;; sign
                T_FLG           equ 0100000000b ;; trap
                I_FLG           equ 1000000000b ;; interrupt

endif   ;; __regs_inc__
