;
; Sample Mixer for sound effect playback
; By Mike Dailly, (c) Copyright 2020 all rights reserved.
;

MIXER_Z80_DMA_DATAGEAR_PORT			equ $6b


;===========================================================================
; hl = source
; bc = length
; set port to write to with NEXTREG_REGISTER_SELECT_PORT
; prior to call
;
; Function:	Upload a set of sprites
; In:		HL = Sample address
; used		A
;===========================================================================
MixerPlayDMASample:	
		ld	(MixerSampleAddress),hl

		; Now set the transfer going...
		ld hl,MixerSoundDMA
		ld b,$16
		ld c,MIXER_Z80_DMA_DATAGEAR_PORT
		otir
		ret


MixerDMAReadLen:
		ld		a,$6
		call	MixerDMAReadRegister
		ld		l,a
		in		a,(MIXER_Z80_DMA_DATAGEAR_PORT)
		ld		h,a
		ret

MixerDMAReadRegister:
		push	af
		ld		a,$bb
		out		(MIXER_Z80_DMA_DATAGEAR_PORT),a
		pop		af
		out		(MIXER_Z80_DMA_DATAGEAR_PORT),a
		in		a,(MIXER_Z80_DMA_DATAGEAR_PORT)
		ret
		

;===========================================================================
;
;===========================================================================
MixerSoundDMA:
		db $c3			; Reset Interrupt circuitry, Disable interrupt and BUS request logic, unforce internal ready condition, disable "MUXCE" and STOP auto repeat
		db $c7			; Reset Port A Timing TO standard Z80 CPU timing
		
		db $ca			; unknown

		db $7d			; R0-Transfer mode, A -> B, write adress + block length
MixerSampleAddress:	
		db $00,$60				; src
MixerSampleLength:
		dw MixerSamplesPerFrame		; length
				
		db $54			; R1-read A time byte, increment, to memory, bitmask
		db $02			; R1-Cycle length port A

		db $68			; R2-write B time byte, increment, to memory, bitmask
		db $22			; R2-Cycle length port B + NEXT extension
MixerDMASampleRate:
		db (MixerDMABaseFreq) / (((MixerSamplesPerFrame)*MixerTVRate))		; set PreScaler 875000kHz/freq = ???
		;db	66

		db $cd			; R4-Dest destination port
MixerDMADestPort:
		;db $fe,$00		; $FFDF = SpecDrum
		db $df,$ff		; $FFDF = SpecDrum

		db $82			; R5-Restart on end of block, RDY active LOW
		db $bb			; R6
		db $08			; R6 Read mask enable (Port A address low)
		
		db $cf			; Load starting address for both potrs, clear byte counter
		db $b3			; Force internal ready condition 
		db $87			; enable DMA



; ******************************************************************************
; Function:	Save the MMUs we're going to overwrite
; Out:		a = register to read
; Out:		a = value in register
; ******************************************************************************
MixerSaveMMUs:
		push	bc
		ld		a,$50
		call	ReadNextReg
		ld		(MixerMMUStore),a

		ld		a,$51
		call	ReadNextReg
		ld		(MixerMMUStore+1),a

		ld		a,$52
		call	ReadNextReg
		ld		(MixerMMUStore+2),a

		ld		a,$53
		call	ReadNextReg
		ld		(MixerMMUStore+3),a
		pop		bc
		ret


; ******************************************************************************
; Function:	restore all MMUs
; ******************************************************************************
MixerRestoreMMUs:
		push	bc
		ld		a,(MixerMMUStore)
		NextReg	$50,a
		ld		a,(MixerMMUStore+1)
		NextReg	$51,a
		ld		a,(MixerMMUStore+2)
		NextReg	$52,a
		ld		a,(MixerMMUStore+3)
		NextReg	$53,a
		pop		bc
		ret
		


		include	"maths.asm"

