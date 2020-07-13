; ************************************************************************
;
; Function:     Main IRQ handler
;
; ************************************************************************

                org     $fd00
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



; You don't have to di/ei because the nextreg port 0x243b is now readable. 
; So in your isr you can read the port, do your thing, then restore the port before returning.

                ; only 164 bytes available here
                org     $fefe
IM2Routine:     push    hl
                push    de
                push    bc
                push    af


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
				NextReg	23,0					; set y scroll to 0 (panel is offset a bit)


                ld      a,(CursorOn)
                and     a
                call    nz,DisplayCursor
@NoCursor:      


ReturnFromIRQ:
        
                pop     af
                pop     bc
                pop     de
                pop     hl
                ei
                reti

; ************************************************************************
; Function:     Flip the screens!
; ************************************************************************
FlipScreens:   
                ld      a,(CursorShape)                 ; flip cursor
                ld      (CursorShape_Current),a

                ; Swap screen (banks) addresses around 
                ld      a,(Screen1Bank)
                push    af
                ld      a,(Screen2Bank)
                ld      (Screen1Bank),a
                pop     af
                ld      (Screen2Bank),a
                ret

Screen1Bank     db      8
Screen2Bank     db      11


StackStart:   	equ		$ffff


				; just below IRQ
                org     $fb00
GraphicsBuffer:	ds      256					; ALWAYS paged in

				ds		64
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


