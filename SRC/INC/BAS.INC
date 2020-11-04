;;
;; bas.inc -- QB4.x, 7.x and VBDOS things
;; 

ifndef          __bas_inc__
                __bas_inc__     equ 1

STR_DSC         struct
        ifndef  __FAR_STRINGS__
                len             word    ?       ;; QB's near string descriptor
                ofs             word    ?
        else
                ofs_tb          word    ?       ;; QBX's far string descriptor
                seg_tb          word    ?
        endif
STR_DSC         ends

ifdef   __FAR_STRINGS__
FSTRG           struct                          ;; QBX's far string
                len             word    ?
                dat             byte    ?       ;; ...
FSTRG           ends
endif

                ;; B_ONEXIT funct_addr
                B_ONEXIT        proto :word, :word

                ;; setmem bytes
                B$SETM          proto :dword

                ;; locate 1(?), row, 1(?), col, 4(words on stack - 2)
                B$LOCT          proto :word, :word, :word, :word, :word

                ;; screen 1(?), mode, 2(?)
                B$CSCN          proto :word, :word, :word

                ;; width cols, -1(?)
                B$WIDT          proto :word, :word

                ;; end
                B$CEND          proto

;;::::::::::::::
;; get address and lenght of a BASIC string
;; ! ss must -> DGROUP
BSTRG           macro   strg_dsc:req, sg:req, offs:req, lgt
ifndef  __FAR_STRINGS__
                mov     offs, strg_dsc
        ifnb    <lgt>
                mov     lgt, ss:[offs].STR_DSC.len
        endif
                push    ss
                pop     sg
                mov     offs, ss:[offs].STR_DSC.ofs

else
                mov     offs, strg_dsc
                push    ss:[offs].STR_DSC.ofs_tb

                mov     offs, ss:[offs].STR_DSC.seg_tb
                mov     sg, ss:[offs]           ;; get strg seg from seg_tb

                pop     offs
                mov     offs, sg:[offs]         ;; get strg ofs from sg:ofs_tb
        ifnb    <lgt>
                mov     lgt, sg:[offs].FSTRG.len;; lgt= string length
        endif
                lea     offs, [offs].FSTRG.dat  ;; sg:offs -> string data
endif
endm

;;::::::::::::::
;; set a BASIC string descriptor with address and lenght
;; ! ss and string must -> DGROUP
;; ! offs -> string data, and could be destroyed
BSTRS           macro   dsc:req, offs:req, lgt:req
ifndef  __FAR_STRINGS__
                mov     ss:[dsc].STR_DSC.len, lgt
                mov     ss:[dsc].STR_DSC.ofs, offs
else
                sub     offs, 2                 ;; -> string len

                ;; set far string tables
                mov     b4g$fstr_seg_tb, ss
                mov     b4g$fstr_ofs_tb+2, offs
                
                mov     ss:[offs].FSTRG.len, lgt;; set string lenght

                ;; set far string descriptor
                mov     offs, O b4g$fstr_seg_tb
                mov     ss:[dsc].STR_DSC.seg_tb, offs
               
                mov     offs, O b4g$fstr_ofs_tb+2
                mov     ss:[dsc].STR_DSC.ofs_tb, offs
endif
endm

endif   ;; __bas_inc__
