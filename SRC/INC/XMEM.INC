;;
;; (~~`\_/'~~)
;;  ~`\ ~ /'~   xmem -- extended memory blocks management module
;;     > < mem  part of B4G distribution / cannot be sold separately ;)
;;  _./ _ \._   copyleft Jul/2000 by v1ctor [av1ctor@yahoo.com.br]
;; (__./~\.__)
;;

ifndef          __xmem_inc__
                __xmem_inc__    equ 1

                ;; globals ::::::

                ;; from linear.asm:
                ;; linear&      (byval segm as integer,_
                ;;               byval offs as integer)
                linear          proto :word, :word


                ;; from xmalloc.asm:
                ;; xmalloc&     (byval bytes as long)
                xmalloc         proto :dword

                global  xmalloc32:near32


                ;; from xmcalloc.asm:
                ;; xmcalloc&    (byval bytes as long)
                xmcalloc        proto :dword

                global  xmcalloc32:near32


                ;; from xmrealloc.asm:
                ;; xmrealloc%   (seg blk as long,_
                ;;               byval bytes as long)
                xmrealloc       proto :far ptr dword, :dword

                global  xmrealloc32:near32


                ;; from xmfree.asm:
                ;; xmfree       (seg blk as long)
                xmfree          proto :far ptr dword

                global  xmfree32:near32


                ;; from xmavail.asm:
                ;; xmavail&     ()
                xmavail         proto


                ;; from xmfill.asm:
                ;; xmfill       (byval blk as long,_
                ;;               byval bytes as long,_
                ;;               byval char as integer)
                xmfill          proto :dword, :dword, :word

                global  xmfill32:near32


                ;; from xmmove.asm:
                ;; xmmove       (byval src as long,_
                ;;               byval bytes as long,_
                ;;               byval dst as long)
                xmmove          proto :dword, :dword, :dword

                global  xmmove32:near32


                ;; from xmmovefill.asm:
                ;; xmmovefill   (byval src as long,_
                ;;               byval bytes as long,_
                ;;               byval dst as long,_
                ;;               byval char as integer)
                xmmovefill      proto :dword, :dword, :dword, :word

                global  xmmovefill32:near32


                ;; from xmpeek.asm:
                ;; xmpeekb%     (byval src as long)
                xmpeekb         proto :dword

                ;; xmpeeki%     (byval src as long)
                xmpeeki         proto :dword

                ;; xmpeekl&     (byval src as long)
                xmpeekl         proto :dword

                ;; xmpeeks!     (byval src as long)
                xmpeeks         proto :dword, :near ptr real4

                ;; xmpeekd#     (byval src as long)
                xmpeekd         proto :dword, :near ptr qword

                ;; xmpeekstr$   (byval src as long,_
                ;;               byval bytes as integer)
                xmpeekstr       proto :dword, :word

                ;; xmpeekt      (seg struct as any,_
                ;;               byval src as long,_
                ;;               byval bytes as integer)
                xmpeekt         proto :far ptr, :dword, :word


                ;; from xmpoke.asm:
                ;; xmpokeb      (byval dst as long,_
                ;;               byval value as integer)
                xmpokeb         proto :dword, :word

                ;; xmpokei      (byval dst as long,_
                ;;               byval value as integer)
                xmpokei         proto :dword, :word

                ;; xmpokel      (byval dst as long,_
                ;;               byval value as long)
                xmpokel         proto :dword, :dword

                ;; xmpoked      (byval dst as long,_
                ;;               byval value as double)
                xmpoked         proto :dword, :qword

                ;; xmpokestr    (byval dst as long,_
                ;;               strg as string)
                xmpokestr       proto :dword, :near ptr STRG_DSC

                ;; xmpoket      (byval dst as long,_
                ;;               seg struct as any,_
                ;;               byval bytes as integer)
                xmpoket         proto :dword, :far ptr, :word


                ;; from xmdump.asm:
                xmdump          proto :dword

endif   ;; __xmem_inc__
