;
; Created on Sunday, 11 of June 2017 at 09:43 AM
; ZX Spectrum Next Lemmings by Mike Dailly, 2017-2018
;
; While copyright over the source is reserved, users may use 
; all or part of it in other products, for free or commercial gain.
; Credit must be given for any parts used.
;
; However no one may ever "SELL/RENT" the source/binary, or any version of
; LEMMINGS, without prior written approval
;
; Current contributors
; --------------------
; MJD  -  Mike Dailly
;
;


                opt             Z80                                                                             ; Set z80 mode
                opt             ZXNEXT
                ;opt             ZXNEXTREG

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
                ld      a,VectorTable>>8
                ld      i,a               

                ld      a,%00000010             ; 14Mhz
                NextReg $07,a

                BORDER          4      
                call    FlipScreens             ; get front and bank buffer in order
                ld      a,$e3
                BORDER          3
                call    Cls256
                BORDER          2
                call    FlipScreens
                ld      a,$d3
                BORDER          1
                call    Cls256
                im      2                       ; Set up IM2 mode
                ei

                ld      a,7+(64)        ; bright white on black
                call    ClsATTR

                ld      a,0
                out     ($fe),a
                call    Init

                call    InitGame

; ************************************************************************************************************
;
;               Main loop
;                               
; ************************************************************************************************************
MainLoop:       
                ; wait for a minimum of 3 frames....
;@WaitForFrameCount:
;                ld      a,(VBlank)              ; get current FPS
;                cp      3
;                jr      c,@WaitForFrameCount
;                ld      (fps),a                 ; store frame count
;                xor     a                       ; clear IRQ frame counter
;                ld      (VBlank),a

                ld      a,1                     ; Wait on VBlank for new game frame....
                ld      (NewFrameFlag),a                
@WaitVBlank:    ld      a,(NewFrameFlag)        ; for for it to be reset
                and     a
                jr      nz,@WaitVBlank

                ; Scan keyboard
                call    ReadKeyboard
                call    ProecssMisc



                call    DisplayMap              ; Display level bitmap
                ;call    GenerateMiniMap

                call    OpenTrapDoors
                call    DrawLevelObjects

                call    SpawnLemming
                call    ProcessLemmings

                ld      ix,LemData
                ld      a,(MouseX)
                ld      hl,(ScrollIndex)
                add     hl,a
                ex      de,hl
                ld      a,(MouseY)
                ld      hl,0
                call    DrawLemmingFrame


                call    ProcessInput

if USE_COPPER = 0
                call    CopyPanelToScreen
endif
                call    ResetBank

                jp      MainLoop                ; infinite loop

counter         db      0
fps             db      0        
frame           db      0




; *****************************************************************************************************************************
; Process the small "misc" bits
; *****************************************************************************************************************************
ProecssMisc:
                ld      a,(Keys+VK_SPACE)
                and     a
                jr      z,@notpressed  

                call    ResetLevel            
                ret
@notpressed:
                ; draw frame rate
                ld      de,$4001
                ld      a,(fps)
                call    PrintHex


;               HL = frame to draw
;               IX = Lem structure
;               DE = X
;               A  = Y                
 

                ; do this last....
                ld      a,(NukeStarted)
                and     a
                ret     z                       ; not new, then RETURN
                dec     a
                ld      (NukeStarted),a
                ld      ix,(NukeIndex)
                call    SetStateBomberCountDown ; set bomber state
                ld      bc,LemStructSize
                add     ix,bc
                ld      (NukeIndex),ix
                ret


; *****************************************************************************************************************************
; Initialise the game start up crap
; *****************************************************************************************************************************
Init:   
                ; make sure top line is free of SNA data
                ld      b,32
                ld      hl,$4000
                xor     a
@lp1            ld      (hl),a
                inc     l
                djnz    @lp1


                ld      a,7+(64)
                call    ClsATTR
                call    SetupAttribs

                call    InitFilesystem

                call    InitSprites
                ;ld      a,LemmingsBank
                ;NextReg

                LoadBanked LemmingsFile,LemmingsBank
                CALL    InitExplosion


                ; enable bitmaps
                ld      a,$02
                ld      bc,$123b
                out     (c),a    


                ; Enable sprites
                NextReg 21,1+8                  ; bit 0= sprites 0, bits 4,3,2 = (%010_00) S U L order

                ld      a,1                     ; enable IRQ cursor
                ld      (CursorOn),a


                NextReg 20,$e3
                
                NextReg 64,$18                  ; set BRIGHT BLACK to transparent
                NextReg 65,$e3

if USE_COPPER = 1 
                ld      hl,GameCopper
                ld      de,GameCopperSize
                call    UploadCopper
                NextReg $62,%11000000
endif                
                ret


; *****************************************************************************************************************************
; includes modules
; *****************************************************************************************************************************
SetupAttribs:   
                ld      b,20
                ld      ix,$5800                ; attribute screen
                ld      de,32
                ld      a,0;    //64
@DrawColumns:   ld      (ix+0),a                ; set the edges of the screen
                ld      (ix+31),a
                add     ix,de
                djnz    @DrawColumns
                ret


; *****************************************************************************************************************************
; Init the game/level
; *****************************************************************************************************************************
InitGame:
                xor     a
                ld      (LemmingCounter),a
                ld      (PanelSelection),a
                call    InitLemmings
                call    InitLevel
                call    InitPanel
                call    LoadLevel
                ret

; *****************************************************************************************************************************
; includes modules
; *****************************************************************************************************************************
                include "lemming.asm"
                include "Panel.asm"
                include "level.asm"
                include "Scroll.asm"
                include "Bob.asm"
                include "explosion.asm"
                include "Utils.asm"
                include "SpriteManager.asm"
                include "filesys.asm"
                include "Copper.asm"
                include "data.asm"
                include "masks.asm"

EndOfCode


                org     $c000-256
GraphicsBuffer:
                ds      256

                ; where's our end address?
                message "EndofCode = ",EndOfCode
                message "End of Buffer =",PC



                ; Save the SNA out....
                savesna "_LemmingsNext.sna",StartAddress,StackStart





        



