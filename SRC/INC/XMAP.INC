;;
;; (~~`\_/'~~)
;;  ~`\ ~ /'~   map -- extended memory blocks mapping module
;;     > < map  part of B4G distribution / cannot be sold separately ;)
;;  _./ _ \._   copyleft Jul/2000 by v1ctor [av1ctor@yahoo.com.br]
;; (__./~\.__)
;;

ifndef          __xmap_inc__
                __xmap_inc__    equ 1

                ;; globals ::::::

                ;; from xmap.asm:
                ;; xmapmake&    (byval size as long)
                xmapmake        proto :dword

                ;; xmap         (byval lin as long,_
                ;;               byval bytes as long,_
                ;;               byval map as long)
                xmap            proto :dword, :dword, :far ptr

                ;; xmapflush    (byval map as long)
                xmapflush       proto :far ptr

                ;; xmapinval    (byval map as long)
                xmapinval       proto :far ptr


                ;; from xmappeek.asm:
                ;; xmappeekb%   (byval map as long,_
                ;;               byval ofs as long)
                xmappeekb       proto :far ptr, :dword

                ;; xmappeeki%   (byval map as long,_
                ;;               byval ofs as long)
                xmappeeki       proto :far ptr, :dword

                ;; xmappeekl&   (byval map as long,_
                ;;               byval ofs as long)
                xmappeekl       proto :far ptr, :dword

                ;; xmappeeks!   (byval map as long,_
                ;;               byval ofs as long)
                xmappeeks       proto :far ptr, :dword, :near ptr real4

                ;; xmappeekd#   (byval map as long,_
                ;;               byval ofs as long)
                xmappeekd       proto :far ptr, :dword, :near ptr qword

                ;; xmappeekstr$ (byval map as long,_
                ;;               byval ofs as long,_
                ;;               byval bytes as integer)
                xmappeekstr     proto :far ptr, :dword, :word

                ;; xmappeekt    (seg struct as any,_
                ;;               byval map as long,_
                ;;               byval ofs as long,_
                ;;               byval bytes as integer)
                xmappeekt       proto :far ptr, :far ptr, :dword, :word


                ;; from xmappoke.asm:
                ;; xmappokeb   (byval map as long,_
                ;;              byval ofs as long,_
                ;;              byval value as integer)
                xmappokeb       proto :far ptr, :dword, :word

                ;; xmappokei    (byval map as long,_
                ;;               byval ofs as long,_
                ;;               byval value as integer)
                xmappokei       proto :far ptr, :dword, :word

                ;; xmappokel    (byval map as long,_
                ;;               byval ofs as long,_
                ;;               byval value as long)
                xmappokel       proto :far ptr, :dword, :dword

                ;; xmappoked    (byval map as long,_
                ;;               byval ofs as long,_
                ;;               byval value as double)
                xmappoked       proto :far ptr, :dword, :qword

                ;; xmappokestr  (byval map as long,_
                ;;               byval ofs as long,_
                ;;               strg as string)
                xmappokestr     proto :far ptr, :dword, :near ptr STRG_DSC

                ;; xmappoket    (byval map as long,_
                ;;               byval ofs as long,_
                ;;               seg struct as any,
                ;;               byval bytes as integer)
                xmappoket       proto :far ptr, :dword, :far ptr, :word

endif   ;; __xmap_inc__
