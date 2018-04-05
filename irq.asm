; ************************************************************************
;
; Function:     Main IRQ handler
;
; ************************************************************************

; You don't have to di/ei because the nextreg port 0x243b is now readable. 
; So in your isr you can read the port, do your thing, then restore the port before returning.

                ; only 164 bytes available here
                org     $5c5c
IM2Routine:     push    hl
                push    de
                push    bc
                push    af

                ld      bc,$123b
                in      a,(c)
                push    af
if NextInstructions=0
                ld      bc,$243b
                in      a,(c)
                push    af
endif                

                db      $c3                     ; jp $0000
IRQVector:      dw      VBlankIRQ
                
ReturnFromIRQ
reset_next_port:
if NextInstructions=0
                pop     af
                ld      bc,$243b
                out     (c),a
endif
                pop     af
                ld      bc,$123b
                out     (c),a
        
                pop     af
                pop     bc
                pop     de
                pop     hl
                ei
                reti
                org     $5d00
VectorTable:            
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine




; ************************************************************************
;
; Function:     VBlank IRQ
;
; ************************************************************************
VBlankIRQ:      
                call    ReadMouse                

                ld      a,(VBlank)                     ; simple frame counter
                inc     a
                ld      (VBlank),a

                


                ; New frame? Time to update sprite buffers?
                ld      a,(NewFrameFlag)
                and     a
                jr      z,@CurrentBuffer                ; no flag set? use current buffer
                xor     a
                ld      (NewFrameFlag),a                ; clear flag
                call    FlipScreens

                call    SetSprites                      ; set current sprite bank (double buffered)
@CurrentBuffer:
                ld      a,(CursorOn)
                and     a
                jr      z,@NoCursor
                call    DisplayCursor
@NoCursor:      
                jp      ReturnFromIRQ


yscrtest        db      0
; ************************************************************************
; Function:     Flip the screens!
; ************************************************************************
FlipScreens:   
                ld      a,(CursorShape)                 ; flip cursor
                ld      (CursorShape_Current),a

                ld      a,(Screen1Bank)
                push    af
                ld      a,(Screen2Bank)
                ld      (Screen1Bank),a
                ld      (CopperGameScreen+1),a
;                NextRegA 18
                pop     af
                ld      (Screen2Bank),a
if USE_COPPER = 1 
                NextRegA 19
else
SetScreens:
                ; Swap screen (banks) addresses around 
                ld      bc,$243B                        
                ld      a,18
                out     (c),a
                ld      bc,$253B
                ld      a,(Screen1Bank)
                out     (c),a

                ld      bc,$243B                        
                ld      a,19
                out     (c),a
                ld      bc,$253B
                ld      a,(Screen2Bank)
                out     (c),a
endif
                ld      a,$02
                ld      bc,$123b
                out     (c),a    



if USE_COPPER = 1
                ld      hl,GameCopper
                ld      de,GameCopperSize
                call    UploadCopper       
                NextReg $62,%11000000    
endif
                ret

Screen1Bank     db      8
Screen2Bank     db      11

; ************************************************************************
;
; Function:     Display the cursor
;
; ************************************************************************
DisplayCursor:
                ld      bc,$303b                ; set sprite 0 as first
                ld      a,0                     ; first sprite
                out     (c),a
                

                ld      a,(MouseX)
                add     a,32-8                
                out     (SpriteReg),a
                ld      a,0
                adc     0
                push    af
                ld      a,(MouseY)
                add     a,32-8
                out     (SpriteReg),a
                pop     af                
                out     (SpriteReg),a
                ld      a,(CursorShape_Current)
                or      $80
                out     (SpriteReg),a

                ret
CursorShape             db      0
CursorShape_Current     db      0


