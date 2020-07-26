;
; Sample Mixer for sound effect playback
; By Mike Dailly, (c) Copyright 2020 all rights reserved.
;

; ********************************************************************************************
; Process the mixer - process and actually play the current mod file.
; ********************************************************************************************
MixerProcess:
		ld		a,(MixerFrame)
		add		a,Hi(MixerSamplePlayback)
		ld		h,a
		ld		l,Lo(MixerSamplePlayback)
		call	MixerPlayDMASample

		call	MixerSaveMMUs


;------------------------------------------------------------------
; Process all samples
;------------------------------------------------------------------
DoSamples:
		; which buffer do we mix into the final samples into?
		ld		a,(MixerFrame)
		xor		1
		ld		(MixerFrame),a
		add		a,Hi(MixerSamplePlayback)
		ld		h,a
		ld		l,Lo(MixerSamplePlayback)
		ld		(MixerDestbuffer),hl

		
		; Clear destination buffer, we need to do this because if samples are ending it'll leave data in the buffer
		ld		b,MixerSamplesPerFrame
		ld		a,128
@Clear	ld		(hl),a
		inc		hl
		djnz	@Clear


;------------------------------------------------------------------
; Mix in the samples
;------------------------------------------------------------------
		ld		b,MixerNumChannels
		ld		ix,MixerChannels
MixerCopyAllChannels:
		push	bc

		ld		a,(ix+Sample_Address)
		or		(ix+(Sample_Address+1))
		jp		z,ChannelNotInUse


		ld		l,(ix+Sample_Length)
		ld		h,(ix+(Sample_Length+1))
		xor		a
		ld		a,(ix+(Sample_Length+2))
		ld		de,MixerSamplesPerFrame
		sbc		hl,de
		sbc		a,0
		jr		nc,NotEndMixer

		;break
		; how many bytes over did we go?
		NEG_HL
		ex		de,hl
		xor		a
		sbc		hl,de	
		ld		a,MixerSamplesPerFrame			
		cp		l
		jp		nc,FreeSlot
		ld		b,l						; get number of bytes to copy into L
		jp		SkipNotEnd
NotEndMixer
		ld		(ix+Sample_Length),l
		ld		(ix+(Sample_Length+1)),h
		ld		(ix+(Sample_Length+2)),a

		ld		b,MixerSamplesPerFrame
SkipNotEnd:
		ld		c,b								; remember number of bytes being copied
		ld		e,(ix+Sample_Address)
		ld		d,(ix+(Sample_Address+1))
		ld		a,(ix+Sample_Bank)
		NextReg	MIXER_BANK,a
		inc		a
		NextReg	MIXER_BANK+1,a
		ld		hl,(MixerDestbuffer)

@CopySample:
		ld		a,(de)
		;add		a,(hl)							; don't mix!
		ld		(hl),a
		inc		l
		inc		de
		djnz	@CopySample
		
		; number of byte
		ld		a,MixerSamplesPerFrame
		cp		c
		jr		z,NotEndOfSample
FreeSlot
		xor		a
		ld		(ix+Sample_Address),a				; release sample
		ld		(ix+(Sample_Address+1)),a

NotEndOfSample:
		ld		a,d
		sub		Hi(MIXER_ADD)
		srl		a
		swapnib
		and		$f
		add		a,(ix+Sample_Bank)
		ld		(ix+Sample_Bank),a
		ld		a,d
		and		$1f
		add		a,Hi(MIXER_ADD)
		ld		d,a
		ld		(ix+Sample_Address),e
		ld		(ix+(Sample_Address+1)),d

ChannelNotInUse:
		ld		bc,Sample_Size
		add		ix,bc
		pop		bc
		dec		b
		jp		nz,MixerCopyAllChannels








;------------------------------------------------------------------
;   Scale sample buffer down for "raw" buffer playback
;------------------------------------------------------------------
SkipSampleEnd:
		jp		MixerRestoreMMUs			; comment out to record sample to memory (DEBUG)

		
		; DEBUG - record sample into memory
		ld		b,MixerSamplesPerFrame
		ld		hl,(MixerDestbuffer)
		ld		a,(MixerTuneBank)
		NextReg	MIXER_SAMPLE_BANK,a			; lets me record the sample to memory for saving out via debugger
		inc		a
		NextReg	MIXER_SAMPLE_BANK+1,a
		ld		de,(MixerTuneAddress)
		

MixerScaleSample:
		ld		a,(hl)
		inc		l
		ld		(de),a
		inc		de
		djnz	MixerScaleSample

		
		ld		a,d
		sub		Hi(MIXER_ADD)
		swapnib
		and		$f
		srl		a
		ld		b,a
		ld		a,(MixerTuneBank)
		add		a,b
		ld		(MixerTuneBank),a
		
		ld		a,d
		and		$1f
		add		a,Hi(MIXER_ADD)
		ld		d,a
		ld		(MixerTuneAddress),de

		jp		MixerRestoreMMUs



