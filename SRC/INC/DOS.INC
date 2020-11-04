;;
;; dos.inc -- some DOS services and structs
;;

ifndef          __dos_inc__
                __dos_inc__     equ 1

                DOS_INT                 equ 21h
                DOS_INT_VECTOR_SET      equ 25h
                DOS_TSR                 equ 31h
                DOS_INT_VECTOR_GET      equ 35h
                DOS_FILE_CREATE         equ 3Ch
                DOS_FILE_OPEN           equ 3Dh
                DOS_FILE_CLOSE          equ 3Eh
                DOS_FILE_READ           equ 3Fh
                DOS_FILE_WRITE          equ 40h
                DOS_FILE_SEEK           equ 42h
                DOS_MEM_ALLOC           equ 48h
                DOS_MEM_FREE            equ 49h
                DOS_MEM_RESIZE          equ 4Ah
                DOS_EXEC                equ 4Bh
                DOS_EXIT                equ 4Ch
                DOS_RETCOD_GET          equ 4Dh
                DOS_MEM_STRATEGY        equ 58h
                DOS_FILE_FLUSH          equ 68h

                STD_IN                  equ 0
                STD_OUT                 equ 1
                STD_ERROR               equ 2

RUN             struct
                env_block       word    ?
                cmmd_line_of    word    ?
                cmmd_line_sg    word    ?
                fcb_1_of        word    ?
                fcb_1_sg        word    ?
                fcb_2_of        word    ?
                fcb_2_sg        word    ?
                child_SP        word    ?       ;; al=1
                child_SS        word    ?       ;; /
                child_IP        word    ?       ;; /
                child_CS        word    ?       ;; /
RUN             ends

MCB             struct
                _type           byte    ?       ;; 5Ah= last, 4Dh= otherwise
                owner_PSP       word    ?       ;; 0 if free
                _size           word    ?       ;; in paras (w/out header)
                                byte    11 dup (?)
MCB             ends

endif   ;; __dos_inc__
