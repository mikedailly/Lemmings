;
; Sample Mixer for sound effect playback
; By Mike Dailly, (c) Copyright 2020 all rights reserved.
;

; ********************************************************************************************
;	A  = root bank of MOD file (tune always starts at 0)
;   B  = InitSamples (0 = no)
; ********************************************************************************************
MixerInit:
		di
		Call	MixerDetectDMALength

	
		; clear samples
		ld		b,MixerNumChannels
		ld		ix,MixerChannels
		ld		de,Sample_size
		xor		a		
@lp1	ld		(ix+Sample_Bank),a
		djnz	@lp1

		; restore SpecDrumPort
		ld		hl,$ffdf					; set the SpecDrum Port
		ld		(MixerDMADestPort),hl
		ld		hl,MixerSamplesPerFrame			; set number of samples per frame
		ld		(MixerSampleLength),hl
		ld		a,(MixerDMAValue)				; set DMA value
		ld		(MixerDMASampleRate),a


		ld		b,MixerNumChannels
		ld		ix,MixerChannels
		xor		a
@ClearChannels:
		ld		(ix+Sample_Bank),a
		ld		(ix+Sample_Address),a
		ld		(ix+(Sample_Address+1)),a
		ld		(ix+Sample_Length),a
		ld		(ix+(Sample_Length+1)),a
		ld		(ix+(Sample_Length+2)),a
		djnz	@ClearChannels
		ei
		ret

; ********************************************************************************************
; Function:	Detect how many bytes the DMA can send a frame at the desired frequency calculation
;			and adjust it so it's as close as we can get
; ********************************************************************************************
MixerDetectDMALength:
		ld		a,MixerSamplesPerFrame
		ld		hl,$fdfd				; use a non-existent port
		ld		(MixerDMADestPort),hl	
	
		; (DMABaseFreq) / (((SamplesPerFrame)*TVRate))	
		ld		e,MixerSamplesPerFrame
		ld		d,MixerTVRate
		mul
		ld		c,e
		ld		b,d
		ld		hl,$000D
		ld		ix,$59F8
		call	Div_32x16
		ld		a,ixl

		; Go OVER the calculated value in case the perfect match is up just a bit....
		add		a,10
		jr		nc,@Skip
		ld		a,$ff				; can't go above $ff no matter what - largest DMA Prescaler value
@Skip:
		ld		(MixerDMAValue),a
	
		ld		hl,MixerSamplesPerFrame
		ld		(MixerSampleLength),hl

		
	; ------------------------------------------------------------------------------------------------
	; Loop around multiple DMA transfers and detect when we've managed to transfer everything
	; ------------------------------------------------------------------------------------------------
MixerTryDMAAgain:
		call	MixerWaitForRasterPos

		ld		a,(MixerDMAValue)
		ld		(MixerDMASampleRate),a			; store DMA prescaler value into DMA program
		ld		hl,0
		call	MixerPlayDMASample

	; make sure we're past the scan line...
		ld		b,0
@lppp2:
		nop
		nop
		djnz	@lppp2

		; wait a frame
		call	MixerWaitForRasterPos

		; now read how far we got...
		call	MixerDMAReadLen		
		
		; debug code
		;push	hl
		;push	hl
		;ld		a,h
		;ld		de,$4004
		;call	PrintHex
		;pop		hl
		;ld		a,l
		;ld		de,$4006
		;call	PrintHex
		;ld		a,(MixerDMAValue)
		;ld		de,$4001
		;call	PrintHex
		;pop		hl


		; now check to see if we transferred all the data
		ld		a,Hi(MixerSamplesPerFrame)
		cp		h
		jr		nz,SizeNotFound
		ld		a,Lo(MixerSamplesPerFrame)
		cp		l
		jr		nz,SizeNotFound

		; DMA size found
		ret

SizeNotFound
		ld		b,0
@lppp23:
		nop
		nop
		djnz	@lppp23

		; wait another frame
		call	MixerWaitForRasterPos

		ld		b,0
@lppp4:
		nop
		nop
		djnz	@lppp4


		ld		a,(MixerDMAValue)
		dec		a
		ret		z
		ld		(MixerDMAValue),a
		jp		MixerTryDMAAgain

@FoundSize:
		ret

; ********************************************************************************************
;	Wait for raster $30
; ********************************************************************************************
MixerWaitForRasterPos:
		call	ReadRaster
		xor		a
		cp		h
		jr		nz,MixerWaitForRasterPos
		ld		a,$30
		cp		l
		jr		nz,MixerWaitForRasterPos
		ret


; ******************************************************************************
;
; Function:	Read the current Raster into HL
; Out:		hl = address
;
; ******************************************************************************
ReadRaster:
		; read MSB of raster first
		ld	a,$1e
		ld	bc,$243b	; select NEXT register
		out	(c),a
		inc	b			; $253b to access (read or write) value
		in	a,(c)
		and	1
		ld	h,a

		; now read LSB of raster
		ld	a,$1f
		dec	b
		out	(c),a
		inc	b
		in	a,(c)
		ld	l,a
		ret

; ********************************************************************************************
;	Play a sample. Stops any sample currently playing on that channel
;
;	In:		a  = Channel
;			c  = bank
;			hl = address
;			bde = length
;
; ********************************************************************************************
MixerPlaySample:
		add		a,a
		add		a,a
		add		a,a					;*8
		add		a,Lo(MixerChannels)
		ld		ixl,a
		ld		a,Hi(MixerChannels)
		adc		a,0
		ld		ixh,a

		add		hl,MIXER_ADD					; add on base of bank

		ld		(ix+Sample_Bank),c
		ld		(ix+Sample_Address),l
		ld		(ix+(Sample_Address+1)),h
		ld		(ix+Sample_Length),e
		ld		(ix+(Sample_Length+1)),d
		ld		(ix+(Sample_Length+2)),b
		ret



; ********************************************************************************************
;	Play a sample. Stops any sample currently playing on that channel
;
;	In:		a  = bank
;			de = address
;			bhl= length
;
; ********************************************************************************************
InitSample:
		push	af
		call	MixerSaveMMUs
		pop		af
		ld		ix,len_temp
		ld		(ix+0),a		; store base bank
		NextReg	MIXER_BANK,a
		inc		a
		NextReg	MIXER_BANK+1,a

		add		de,MIXER_ADD		; add on base of sample
		ld		a,b					; high byte of length into AF'
		ld		bc,1
ScaleSamples:
		ex		af,af'				; swap out "high" byte of length
		ld		a,(de)
		sra		a					; scale sample down by 4 times, to allow faster mixing
		sra		a
		ld		(de),a
		inc		de		

		; check for bank swap
		ld		a,d
		sub		Hi(MIXER_ADD)
		srl		a
		swapnib
		and		$7
		jp		z,@NoBankSwap
		add		a,(ix+0)
		ld		(ix+0),a

		NextReg	MIXER_BANK,a
		inc		a
		NextReg	MIXER_BANK+1,a

		ld		a,d
		and		$1f
		add		a,Hi(MIXER_ADD)
		ld		d,a


@NoBankSwap:
		ex		af,af'				; get high byte back again
		and		a					; clear carry		
		sbc		hl,bc
		sbc		a,0		
		jr		nc,ScaleSamples		; still some left
		ret

len_temp	db	0,0,0,0			// bank, 3 byte length

; ********************************************************************************************
;	Include the rest of the Mixer
; ********************************************************************************************

		include	"mixer_tick.asm"
		include	"mixer_misc.asm"
		include	"mixer_data.asm"

		; ------------------------------------------------------------------------------------------------
		; the MOD volumes must be bank aligned as they are paged in and "D" points to the base, 
		; while E is the sample byte to scale to the desired volume
		; ------------------------------------------------------------------------------------------------
		;Seg		MIXER_BANK	
;VolumeTable:
		;incbin	"mixer_volume.dat"			; sample*volume conversion



