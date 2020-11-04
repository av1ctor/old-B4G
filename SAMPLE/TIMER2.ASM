                .model  medium, basic
                
.code
;;::::::::::::::
                public  TIMER2
TIMER2          proc    uses es
                
                mov     ax, 40h
                mov     es, ax                  ;; es= BIOS data area segment

                mov     ax, es:[6Ch]            ;; LSW
                mov     dx, es:[6Eh]            ;; MSW

                ret
TIMER2          endp
                end


'':::
funtion timer2& static
    def seg = &h40
    lswlsb% = peek(&h6c+0)
    lswmsb% = peek(&h6c+1)
    mswlsb% = peek(&h6c+2)
    mswmsb% = peek(&h6c+3)
    timer2& = (mswmsb% * &h1000000&) + _
              (mswlsb% * &h10000&) + _
              (lswmsb% * &h100&) + _
              lswlsb%
end function
