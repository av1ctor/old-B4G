;; name: farptr
;; desc: return a segment:offset as a far pointer
;;
;; type: function
;; args: [in] segm:integer,    | far pointer segment part
;;            offs:integer     |  "     "    offset   "
;; retn: long                  | far pointer
;;
;; decl: farptr&   (byval segm as integer,_
;;                  byval offs as integer)
;;   or: farptrex& alias "farptr" (seg array as any)
;;

;; name: segment or offset
;; desc: returns a segment or offset of a far pointer
;;
;; type: function
;; args: [in] fptr:long        | far pointer
;; retn: integer or long       | segment or offset of fptr
;;
;; decl: segment% alias "_segment" (byval fptr as long)
;;       offset&  alias "_offset"  (byval fptr as long)
;;

;; updt: jul/00 [v1ctor]
;; obs.: none

                include common.inc

.code
;;::::::::::::::
farptr          proc    segm:word,\
                        offs:word
                mov     ax, offs
                mov     dx, segm
                ret
farptr          endp

;;::::::::::::::
_segment        proc    fptr:far ptr
                mov     ax, W fptr+2
                ret
_segment        endp

;;::::::::::::::
_offset         proc    fptr:far ptr
                mov     ax, W fptr
                xor     dx, dx
                ret
_offset         endp
                end
