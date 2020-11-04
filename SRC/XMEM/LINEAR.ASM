;; name: linear
;; desc: convert a far pointer (segment:offset) to linear address
;;
;; type: function
;; args: [in] segm:integer,    | far pointer segment part
;;            offs:integer     |  "     "    offset   "
;; retn: long                  | linear address
;;
;; decl: linear&   (byval segm as integer,_
;;                  byval offs as integer)
;;   or: linearex& alias "linear" (seg array as any)
;;   or: fp2lin&   alias "linear" (byval fptr as long)
;;
;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

.code
;;::::::::::::::
linear          proc    segm:word,\
                        offs:word

                mov     ax, segm
                mov     dx, ax
                shl     ax, 4
                shr     dx, 12
                add     ax, offs
                adc     dx, 0                   ;; dx:ax= (segm * 16) + offs

                ret
linear          endp
                end
