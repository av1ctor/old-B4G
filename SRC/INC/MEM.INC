;;
;; mem.inc -- conventional memory "manager" (almost :})
;;

ifndef          __mem_inc__
                __mem_inc__     equ 1

                ;; globals ::::::

                ;; from malloc.asm:
                ;; malloc&      (byval bytes as long)
                malloc          proto :dword


                ;; from mfree.asm:
                ;; mfree        (seg fptr as long)
                mfree           proto :far ptr dword


                ;; from mrealloc.asm:
                ;; mrealloc%    (seg fptr as long,_
                ;;               byval bytes as long)
                mrealloc        proto :far ptr dword, :dword


                ;; from mavail.asm:
                ;; mavail&      ()
                mavail          proto


                ;; from addr.asm:
                ;; farptr&      (byval segm as integer,_
                ;;               byval offs as integer)
                farptr          proto :word, :word

                ;; segment%     alias "_segment" (byval fptr as long)
                _segment        proto :far ptr

                ;; offset&      alias "_offset" (byval fptr as long)
                _offset         proto :far ptr

endif   ;; __mem_inc__
