;
; Created on Sunday, 11 of June 2017 at 09:43 AM
; ZX Spectrum Next Lemmings by Mike Dailly, 2017-2020
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
                opt             ZXNEXTREG



ModVolumeBank        equ                16
ModFileBank          equ                18
ModSampleBank        equ                50




			include "includes.asm"



			seg     CODE_SEG, Code_Bank:$0000,$8000
			seg		MIXER_SEG,MixerCode_Bank:$0000,$c000				
			seg     SAMPLE_DATA,  SamplesBank:$0000,$0000                ; volume conversion goes here


			seg        CODE_SEG


			; IRQ is at $fefe to 5e01
			include "irq.asm"       
			


			org		$8000
			; starts at $8080
StartAddress:
			di    
			ld      sp,0+(StackStart+1)&$ffff			; Stack is last 128 bytes of memory.... (in IRQ.ASM)
			ld      a,VectorTable>>8
			ld      i,a               

			ld      a,%00000011             		; 28Mhz
			NextReg $07,a
			
			NextReg	$56,0
			NextReg	$57,1

			BORDER	4      
			call	FlipScreens             		; get front and bank buffer in order
			ld		a,$e3
			BORDER	3
			call	Cls256
			BORDER	2
			call	FlipScreens
			ld		a,$d3
			BORDER	1
			call    Cls256
			im      2                       ; Set up IM2 mode
			ei


			ld      a,0
			out     ($fe),a
			call    Init
			call    InitGame
			ei

			NextReg 8,%01001000				; disable RAM contention + DACs
			NextReg 20,$e3   				; global transparancy to $E3             
			NextReg 21,%0_0_0_010_0_1		; bit 0= sprites 0, bits 4,3,2 = (%010_00) S U L order
			NextReg 67,%00000000			; select palettes 
			NextReg	64,$18					; set BRIGHT black on ULA to transparent
			NextReg 65,$e3

			; enable Layer2
			ld      a,$02
			ld      bc,$123b
			out     (c),a    

; ************************************************************************************************************
;
;               Main loop
;                               
; ************************************************************************************************************
MainLoop:       
		; wait for a minimum of 3 frames....
		ld        a,(vblank)                 
		ld        (realfps),a      
		ld        a,1                     ; Wait on VBlank for new game frame....
		ld        (NewFrameFlag),a                
@WaitVBlank:
		ld        a,(NewFrameFlag)        ; for for it to be reset
		and       a
		jr        nz,@WaitVBlank


		;ld        a,VRAM_BASE_BANK
		;NextReg   18,a
		;NextReg   19,a
			
		
			

			
		;ld      a,1
		;out     ($fe),a

		; Scan keyboard
		call    	ReadKeyboard
		call    	ProcessMisc
			
			
			
		call    	DisplayMap              ; Display level bitmap



		call    	OpenTrapDoors
		call    	DrawLevelObjects
			
		call    	SpawnLemming
		call    	ProcessLemmings
			
		;ld      ix,LemData
		;ld      a,(MouseX)
		;ld      hl,(ScrollIndex)
		;add     hl,a
		;ex      de,hl
		;ld      a,(MouseY)
		;ld      hl,0
		;call    DrawLemmingFrame
			
			
		call    	ProcessInput
		call		DrawPanelNumbers_Force


		;ld      a,1
		;out     ($fe),a
		;call    GenerateMiniMap
		;ld      a,0
		;out     ($fe),a


		ld		a,(Keys+VK_S)
		and		a
		jr		z,@SkipPlay
		ld		a,(Debounce)
		and		a
		jr		nz,@SkipDebounce
		ld		a,255
		ld		(Debounce),a

		xor		a
		ld		(Keys+VK_S),a

		call	PlaySFX
		jr		@SkipDebounce
@SkipPlay:
		xor		a
		ld		(Debounce),a
@SkipDebounce



		NextReg		$52,10
		NextReg		$53,11

		;ld      	hl,$4001
		;ld      	de,DemoText
		;ld      	a,1
		;call    	DrawText
			
		;ld      	hl,$4023
		;ld      	de,DemoText2
		;ld      	a,1
		;call    	DrawText
		ld      	a,0
		out     	($fe),a
			
		jp      	MainLoop                ; infinite loop

counter     db      0
fps         db      0        
realfps     db      0        
frame       db      0

Debounce			db		0

; *****************************************************************************************************************************
; Process the small "misc" bits
; *****************************************************************************************************************************
ProcessMisc:
                ld      a,(Keys+VK_SPACE)
                and     a
                jr      z,@notpressed  

                call    ResetLevel            
                ret
@notpressed:
                ; draw frame rate
                ;ld      de,$4001
                ;ld      a,(realfps)      ;(MouseButtons)
                ;call    PrintHex

                ;ld      hl,$4003
                ;ld      de,DemoText
                ;ld      a,1
                ;call    DrawText

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
			ld      a,7+64				; white+bright-ink    black+bright-paper
			call    ClsATTR
			call    SetupAttribs
			call    InitFilesystem
			call    InitSprites

			NextReg	$56,MixerCode_Bank
			call	MixerInit
			NextReg	$56,0


			LoadBanked LemmingsFile,LemmingsBank
			call	InitExplosion

			ld      a,1                     ; enable IRQ cursor
			ld      (CursorOn),a             
			ret


RegisterSample:
			NextReg	$56,MixerCode_Bank
			call	MixerInit
			NextReg	$56,0

; *****************************************************************************************************************************
; Draw 2 columns down each side of the screen to hide lemming clipping
; *****************************************************************************************************************************
SetupAttribs:   
			ld      b,20
			ld      ix,$5800                ; attribute screen
			ld      de,32
			ld      a,0
@DrawColumns:
			ld      (ix+0),a                ; set the edges of the screen
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

PlaySFX:
		xor		a
		ld		c,SamplesBank			; the bank the 		
		ld		hl,0					; sample offset into the bank
		ld		de,LetsGoLength&$ffff	; sample length (low 2 bytes)
		ld		b,LetsGoLength>>16		; sample length high byte
		NextReg	$56,MixerCode_Bank	
		call	MixerPlaySample
		NextReg	$56,0
		ret
PlaySFX2:
		xor		a
		ld		c,Bank(OpenDoorSample)			; the bank the 		
		ld		hl,BankOff(OpenDoorSample)		; sample offset into the bank
		ld		de,OpenDoorSampleLength&$ffff	; sample length (low 2 bytes)
		ld		b,OpenDoorSampleLength>>16		; sample length high byte
		NextReg	$56,MixerCode_Bank	
		call	MixerPlaySample
		NextReg	$56,0
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
				seg		MIXER_SEG
				include "mixer_player.asm"


                ; where's our end address?
                message "EndofCode = ",EndOfCode
                message "End of Buffer =",PC



SampleText		seg		SAMPLE_DATA
LetsGo			incbin	"lemdat/sound/LETSGO.raw"
LetsGo_End
LetsGoLength	equ	LetsGo_End-LetsGo

OpenDoorSample	incbin	"lemdat/sound/DOOR.raw"
OpenDoorSample_End
OpenDoorSampleLength	equ	OpenDoorSample_End-OpenDoorSample


                ; Save the SNA out....
;                savesna "_LemmingsNext.snx",StartAddress,StackStart
                savenex "_LemmingsNext.nex",StartAddress,StackStart





        



