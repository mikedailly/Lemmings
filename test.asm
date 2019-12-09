; 
		opt             sna=StartAddress:StackStart 
                opt             Z80                                                                             ; Set z80 mode
                ;opt             ZXNEXT
                ;opt             ZXNEXTREG

                ;include "includes.asm"


                ; IRQ is at $5c5c to 5e01
                ;include "irq.asm"       





                org     $7000
               
StackEnd:
                ds      127
StackStart:     db      0,0,0,0

                org     $8100

StartAddress:   
                di
                ;ld      sp,StackStart&$fffe
                ;ld      a,VectorTable>>8
                ;ld      i,a                     
                ;im      2                       ; Setup IM2 mode
                ;ei
                ;ld      a,0
                ;out     ($fe),a


                ld      a,5
@lp1:
                out     ($fe),a
                inc     a

                JP      @lp1


                ;savesna "test.sna",StartAddress

