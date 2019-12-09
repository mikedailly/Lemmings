;
; Created on Sunday, 11 of June 2017 at 09:43 AM
;
; ZX Spectrum Next Framework V0.1 by Mike Dailly, 2017
;
; 
                opt             sna=StartAddress:StackStart                             ; save SNA,Set PC = run point in SNA file and TOP of stack
                opt             Z80                                                                             ; Set z80 mode

                include "includes.asm"


                ; IRQ is at $5c5c to 5e01
                include "irq.asm"       
               
StackEnd:
                ds      127
StackStart:     dw      0,0,0,0
                ds      128                     ; why do I need this?
                

StartAddress:
                di
                ld      sp,StackStart&$fffe

                ;ld      hl,VBlankIRQ            ; set IRQ routine to use
                ;ld      (IRQVector),hl
                ld      a,VectorTable>>8
                ld      i,a                     
                im      2                       ; Setup IM2 mode
                ei
                ld      a,0
                out     ($fe),a

                ; enable turbo mode  (not sure what 14Mhz is yet)
                ;ld      bc, $243B
                ;ld      a,7                     ; select reg 6
                ;out     (c),a
                ;ld      bc, $253B
                ;ld      a,1                     ; set 7Mhz turbo mode
                ;out     (c),a

                ld      a,7
                call    ClsATTR

                call    InitFilesystem

                ld      a,$e3                    ; Clear screen to transparent
                call    Cls256
                
                ;ld      hl,XeO3TitleFile
                ;call    Load256Screen           ; load screen and display it
                ld      hl,LemTitle
                call    Load256Screen           ; load screen and display it

                ;ld      a,$e3                   ; screen is transparent
                ;call    Cls256

                call    InitSprites
                ld      HL,LemmingsFile
                ld      a,2
                call    LoadBanked

                call    InitLevel
                call    InitPanel
                ld      bc,$243B
                ld      a,21
                out     (c),a
                ld      bc,$253B
                ld      a,1
                out     (c),a
                ld      a,1
                ld      (CursorOn),a



                ld      a,0                     ; black boarder
                out     ($fe),a



; -------------------------------------------------
;
;               Main loop
;                               
; -------------------------------------------------
MainLoop:       ld      a,(VBlank)              ; get current FPS
                ld      (fps),a
                xor     a
                ld      (VBlank),a

                ld      a,1                     ; Wait on VBlank....
                ld      (NewFrameFlag),a                
@WaitVBlank:    ld      a,(NewFrameFlag)        ; for for it to be reset
                and     a
                jr      nz,@WaitVBlank
                ;halt

                ld      de,$4000
                ld      a,(fps)
                call    PrintHex
                ;halt


                ; scroll maps
                ;ld      h,0
                ;ld      a,(counter)
                ;inc     a
                ;ld      (counter),a
                ;ld      l,a
                ;add     hl,hl
                ld      hl,650  ;-256
                ;add     hl,bc
                call    CopyScreen
                

                ld      a,7
                out     ($fe),a

                ld      b,100
                ld      a,(frame)
                inc     a
                and     7
                ld      (frame),a
                ld      l,a
                ld      h,0
@DrawLoop:
                push    bc
                ld      a,LemmingsBank
                call    SetBank
                
                push    hl

                ;;ld      hl,$0001
                ld      bc,10
                ld      a,40
                call    DrawBob
                ld      a,0
                call    SetBank
                pop     hl
                pop     bc
                djnz    @DrawLoop

                ;call    tester
                ld      a,0
                out     ($fe),a

                jp      MainLoop                ; infinite loop

counter         db      0
fps             db      0        
frame           db      0



tester:
                ld      a,VRAM_BASE_BANK
                call    SetBank

                ld      bc,$2000
                ld      a,255
                ld      ($c000),a
                ld      hl,$c000
                ld      de,$c001
                ldir

                ret




; *****************************************************************************************************************************
; includes modules
; *****************************************************************************************************************************
                include "Panel.asm"
                include "Scroll.asm"
                include "Bob.asm"
                include "Utils.asm"
                include "SpriteManager.asm"
                include "filesys.asm"
                include "data.asm"
EndOfCode


                org     $8000-1024
GraphicsBuffer:
                ds      1024

                ; wheres our end address?
                message "EndofCode = ",EndOfCode
                message "End of Buffer =",PC
        



