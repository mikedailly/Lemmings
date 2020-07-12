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

IRQVector:      jp      VBlankIRQ               
ReturnFromIRQ:
        
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
                ld      a,(VBlank)
                cp      3
                jr      c,@CurrentBuffer
                ld      (fps),a
                xor     a
                ld      (VBlank),a
                ld      (NewFrameFlag),a                ; clear flag

                ; if >= frame 3, then flip screen+sprites
                call    FlipScreens
@CurrentBuffer:

                ; Swap screen (banks) addresses around 
                ld      a,(Screen1Bank)
                NextReg 18,a
                ld      a,(Screen2Bank)
                NextReg 19,a
				NextReg	23,0					; set y scroll to 0


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
                ld      a,(ExplosionX)
                ld      (SysExplosionX),a
                ld      a,(ExplosionY)
                ld      (SysExplosionY),a
                ld      a,$ff                   ; disable explosion for the next game frame
                ld      (ExplosionY),a


                ; Swap screen (banks) addresses around 
                ld      a,(Screen1Bank)
                push    af
                ld      a,(Screen2Bank)
                ld      (Screen1Bank),a
;                ld      (CopperGameScreen+1),a
                ;NextReg 18,a
                pop     af
                ld      (Screen2Bank),a
                ;NextReg 19,a


;if USE_COPPER = 1
;                ld      hl,GameCopper
;                ld      de,GameCopperSize
;                call    UploadCopper       
;                NextReg $62,%11000000    
;endif
                ret

Screen1Bank     db      8
Screen2Bank     db      11

; ************************************************************************
;
; Function:     Display the cursor
;               Higher priorities are higher sprite numbers
;               Sprite 1 us under sprite 2
;
; ************************************************************************
DisplayCursor:
                ld      bc,$303b                ; set sprite 0 as first
                ld      a,0                     ; first sprite
                out     (c),a
                

                ; Explosion...
                ld      a,(SysExplosionY)
                cp      $ff
                jp      nz,@Active
                xor     a
                out     (SpriteReg),a           ; disable sprite 1
                out     (SpriteReg),a
                out     (SpriteReg),a
                out     (SpriteReg),a

                out     (SpriteReg),a           ; disable sprite 2
                out     (SpriteReg),a
                out     (SpriteReg),a
                out     (SpriteReg),a

                out     (SpriteReg),a           ; disable sprite 3
                out     (SpriteReg),a
                out     (SpriteReg),a
                out     (SpriteReg),a

                out     (SpriteReg),a           ; disable sprite 4
                out     (SpriteReg),a
                out     (SpriteReg),a
                out     (SpriteReg),a
                jp      @SkipExpSetup
@Active:
                ld      a,(SysExplosionX)
                ld      l,a
                ld      h,0
                add     hl,24
                ld      a,l
                out     (SpriteReg),a           ; x
                ld      a,(SysExplosionY)
                out     (SpriteReg),a           ; y
                ld      a,h
                out     (SpriteReg),a           ; msb
                ld      a,$86                   ; exp-shape top left 
                out     (SpriteReg),a           

                ld      a,l
                out     (SpriteReg),a           ; x
                ld      a,(SysExplosionY)
                add     a,16                    ; lower left sprite
                out     (SpriteReg),a           ; y
                ld      a,h
                out     (SpriteReg),a           ; msb
                ld      a,$87                   ; exp-shape lower left
                out     (SpriteReg),a           

                add     hl,16
                ld      a,l
                out     (SpriteReg),a           ; x
                ld      a,(SysExplosionY)
                out     (SpriteReg),a           ; y
                ld      a,h
                out     (SpriteReg),a           ; msb
                ld      a,$88                   ; exp-shape top right
                out     (SpriteReg),a           

                ld      a,l
                out     (SpriteReg),a           ; x
                ld      a,(SysExplosionY)
                add     a,16                    ; lower right sprite
                out     (SpriteReg),a           ; y
                ld      a,h
                out     (SpriteReg),a           ; msb
                ld      a,$89                   ; exp-shape lower right
                out     (SpriteReg),a  
@SkipExpSetup:

                ; Draw Panel selection
                ld      a,(PanelSelection)
                swapnib                         ; *16
                add     a,32+32                 ; 32 border
                push    af
                out     (SpriteReg),a
                ld      a,168                   ; start of panel
                add     a,32
                out     (SpriteReg),a
                xor     a
                out     (SpriteReg),a           ; set high X
                ld      a,$82                   ; set shape + enable
                out     (SpriteReg),a

                ; low part of selection icon
                pop     af
                out     (SpriteReg),a
                ld      a,168+16                   ; start of panel
                add     a,32
                out     (SpriteReg),a
                xor     a
                out     (SpriteReg),a           ; set high X
                ld      a,$83                   ; set shape + enable
                out     (SpriteReg),a


                ;
                ; Do the cursor last so it's on top of everything
                ;
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
CursorShape				db      0
ExplosionX				db      0
ExplosionY				db      -1              ; -1 to disable

CursorShape_Current		db      0
PanelSelection			db      0
SysExplosionX			db      0
SysExplosionY			db      -1              ; -1 to disable


