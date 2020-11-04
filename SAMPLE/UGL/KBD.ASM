;;
;; kbd.asm -- ISR to process multiple keys pressing
;;

                .model  medium, basic
                .386
                option  proc:private

                include ..\..\src\inc\equ.inc
                include ..\..\src\inc\dos.inc

                ;; kbdinit      (seg kbd as KEYBOARD)
                kbdinit         proto :far ptr

                ;; kbddone      ()
                kbddone         proto

.data
installed       byte    FALSE

.code
old_kbd_hdl     dword   ?
kbd_stc_ptr     dword   ?

;:::::::::::::::
kbd_handler     proc
                PS      ax, bx, si, ds
      
                sti

                lds     si, cs:kbd_stc_ptr      ;; ds:si -> kbd struct  
 
                in      al, 60h                 ;; read keyboard scancode
                mov     ah, al                  ;; save
                and     al, 7Fh

                ;; bx= kbd struct index ((scancode & 7Fh) * 2)
                xor     bh, bh
                mov     bl, al                  
                shl     bx, 1

                ;; ah=-1 or 0 if key pressed or realised
                shl     ah, 1
                sbb     ah, ah
                not     ah

                mov     ds:[si + bx], ah        ;; kbd[code]= scancode & 7Fh

                ;; kbd[0]= scancode if key pressed, 0 if not
                and     al, ah
                mov     ds:[si], al             
 
                cli
                mov     al, 20h                 ;; non-specific EOI for PIC
                out     20h, al
                sti             

                PP      ds, si, bx, ax
                iret
kbd_handler     endp 

;:::::::::::::::
kbdinit         proc    uses di es ds,\
                        kbd_stc:far ptr

                ;; check if already installed
                cmp     installed, TRUE
                je      @@exit
                mov     installed, TRUE

                ;; clear kbd struct
                les     di, kbd_stc             ;; es:di -> kbd struct
                mov     W kbd_stc_ptr+0, di     ;; save
                mov     W kbd_stc_ptr+2, es     ;; /
                xor     eax, eax
                mov     cx, (128*2) / 4
                rep     stosd

                ;; save old keyboard handler int. vector
                mov     ax, DOS_INT_VECTOR_GET*256 + 09h
                int     DOS_INT
                mov     W cs:old_kbd_hdl+0, bx
                mov     W cs:old_kbd_hdl+2, es

                ;; set new handler
                mov     ax, cs
                mov     ds, ax
                mov     dx, O kbd_handler       ;; ds:dx -> kbd_handler
                mov     ax, DOS_INT_VECTOR_SET*256 + 09h
                int     DOS_INT

@@exit:         ret
kbdinit         endp

;:::::::::::::::
kbddone         proc    uses ds

                ;; check if installed
                cmp     installed, FALSE
                je      @@exit
                mov     installed, FALSE

                ;; clear keyboard buffer
                mov     ax, 40h
                mov     ds, ax                  ;; ds= BIOS data area seg
                mov     ax, ds:[1Ch]
                mov     ds:[1Ah], ax            ;; head= tail

                ;; restore old keyboard handler int. vector
                lds     dx, cs:old_kbd_hdl      ;; ds:dx -> old vector
                mov     ax, DOS_INT_VECTOR_SET*256 + 09h
                int     DOS_INT

@@exit:         ret
kbddone         endp
                end
