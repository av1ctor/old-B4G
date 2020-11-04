;;
;; (~~`\_/'~~)
;;  ~`\ ~ /'~    xfile -- file management module
;;     > < file  part of B4G distribution / cannot be sold separately ;)
;;  _./ _ \._    copyleft Jul/2000 by v1ctor [av1ctor@yahoo.com.br]
;; (__./~\.__)
;;

ifndef          __xfile_inc__
                __xfile_inc__   equ 1

                ;; open modes:
                F_READ          equ 1
                F_WRITE         equ 2
                F_CREATE        equ 4
                F_APPEND        equ 8

                ;; seek origins:
                S_START         equ 0
                S_CURRENT       equ 1
                S_END           equ 2

XFILE           struct
                prev            dword   ?
                next            dword   ?
                handle          word    ?
                mode            word    ?
                state           word    ?
                buffer          dword   ?
                buff_size       dword   ?
XFILE           ends

                ;; globals ::::::

                ;; from xfopen.asm:
                ;; xfopen%      (seg xf as XFILE,_
                ;;               flname as string,_
                ;;               byval mode as integer,_
                ;;               byval buffSize as integer)
                xfopen          proto :far ptr XFILE, :near ptr STR_DSC,\
                                        :word, :dword

                ;; from xfclose.asm:
                ;; xfclose      (seg xf as XFILE)
                xfclose         proto :far ptr XFILE


                ;; from xfread.asm:
                ;; xfread&      (seg xf as XFILE,_
                ;;               byval dst as long,_
                ;;               byval bytes as long)
                xfread          proto :far ptr XFILE, :dword, :dword

                global  xfread32:near32


                ;; from xfwrite.asm:
                ;; xfwrite&     (seg xf as XFILE,_
                ;;               byval src as long,_
                ;;               byval bytes as long)
                xfwrite         proto :far ptr XFILE, :dword, :dword

                global  xfwrite32:near32


                ;; from xfseek.asm:
                ;; xfseek&      (seg xf as XFILE,_
                ;;               byval origin as integer,_
                ;;               byval bytes as long)
                xfseek          proto :far ptr XFILE, :word, :dword


                ;; from xfpos.asm:
                ;; xfpos&       (seg xf as XFILE)
                xfpos           proto :far ptr XFILE


                ;; from xfsize.asm:
                ;; xfsize&      (seg xf as XFILE)
                xfsize          proto :far ptr XFILE


                ;; from xfflush.asm:
                ;; xfflush      (seg xf as XFILE)
                xfflush         proto :far ptr XFILE

endif   ;; __xfile_inc__
