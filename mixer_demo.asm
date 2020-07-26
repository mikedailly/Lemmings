;
; Sample Mixer demo
; By Mike Dailly, (c) Copyright 2020 all rights reserved.
;
; Please see the readme for license details
;

                opt     Z80                                     ; Set Z80 mode
                opt     ZXNEXTREG

                include "includes.asm"

MixerVolumeBank	equ		16
SampleBank		equ		18


                seg     CODE_SEG, 4:$0000,$8000
                seg     MIXER_BANK,  MixerVolumeBank:$0000,$0000		; volume conversion goes here
                seg     SAMPLE_BANK,  SampleBank:$0000,$0000		; volume conversion goes here


                seg	CODE_SEG

; *****************************************************************************************************************************
; Start of game code
; *****************************************************************************************************************************
StartAddress:
	    di
	    ld      sp,StackStart&$fffe
	    ld      a,VectorTable>>8
	    ld      i,a
	    im      2
	    ei

	    NextReg 128,0           ; Make sure expansion bus is off.....
	    NextReg $07,3           ; Set to 28Mhz
	    NextReg $05,1			; 50Hz mode  (bit 1 needs to be read from OS)
	    ;NextReg $05,4			; 60Hz mode
	    NextReg	$08,%01001010   ; $50			; disable ram contention, enable specdrum, turbosound

	    NextReg $4a,0           ; transparent fallback
	    NextReg $4c,0           ; tile transparent colour


		call	Cls
		ld		a,7
		call	ClsATTR
		call	MixerInit			; initialise the mixer (takes a few frames)

		ld		a,SampleBank			; bank of sample
		ld		de,0					; bank offset
		ld		hl,SampleLength&$ffff	; sample length (low 2 bytes)
		ld		b,SampleLength>>16		; sample length high byte
		call	InitSample				; initialise the sample (pre-scale etc)

; ----------------------------------------------------------------------------------------------------
;               Main loop
; ----------------------------------------------------------------------------------------------------
MainLoop:
		xor	a
		ld	(FrameCount),a
		ld	(VBlank),a

WaitVBlank:
    	ld	a,(VBlank)
    	and	a
		jr	z,WaitVBlank    	

@wait:
		call	ReadRaster
		ld		de,30
		sbc		hl,de
		ld		a,h
		or		l
		jr		nz,@wait

 		call    ReadKeyboard

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

		ld		a,(ChannelToUse)		; the channel to play on
		inc		a	
		and		$3
		ld		(ChannelToUse),a
		ld		c,SampleBank			; the bank the 
		ld		hl,0					; sample offset into the bank
		ld		de,SampleLength&$ffff	; sample length (low 2 bytes)
		ld		b,SampleLength>>16		; sample length high byte
		call	MixerPlaySample
		jr		@SkipDebounce
@SkipPlay:
		xor		a
		ld		(Debounce),a
@SkipDebounce

		NextReg	$52,10
		NextReg	$53,11

		;ld		a,0
		;ld		de,$4001
		;call	PrintHex


;		nextreg $4a,%11111111
    	ld      a,1
    	out     ($fe),a 
		call	MixerProcess
		nextreg $4a,0
    	ld      a,0
    	out     ($fe),a


		;NextReg	$52,10
		;NextReg	$53,11

		jp      MainLoop


ChannelToUse		db		0
Debounce			db		0




        include "mixer_player.asm"
		
		seg	CODE_SEG
        include "utils.asm"
        include "maths.asm"
		include	"irq.asm"					; MUST start at $fd00


		seg	SAMPLE_BANK
SampleAddress:
;		incbin	"sample_12750.raw"				; sample at 6400Hz
		incbin	"sample_6400.raw"				; sample at 6400Hz
;		incbin	"sample_3750.raw"				; sample at 6400Hz
EndSampleAddress
SampleLength	equ	EndSampleAddress-SampleAddress

; *****************************************************************************************************************************
; save
; *****************************************************************************************************************************
		savenex "mixer_demo.nex",StartAddress,StackStart




