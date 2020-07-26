;
; Sample Mixer for sound effect playback
; By Mike Dailly, (c) Copyright 2020 all rights reserved.
;

; mixer file data

MIXER_BANK				equ	$52						; which 2xMMU banks to use (this one and the next)
MIXER_ADD				equ	$4000					; base address of this bank (where samples are paged in)
MIXER_VOL_BANK			equ	$50						; which 2xMMU banks to use for volumes (this one and the next)
MIXER_VOL_ADD			equ	$0000					; base of volume banks
MIXER_SAMPLE_BANK		equ	$32						; base bank for recording
MIXER_BASE_ADDRESS		equ	$4000					; base bank for recording

MixerNumChannels		equ	1						; number of mixer channels

MixerDMABaseFreq		equ	875000					; DMA base freq
MixerTVRate				equ	50						; framerate

; (71 the LOWEST value possible - timings change onm HDMI/VGA etc)
; 3 demo values. Use one, then change which sample you include in mixer_demo.asm at the bottom.
;MixerSamplesPerFrame	equ	255						; 255 samples per frame  (12750 Hz)
MixerSamplesPerFrame	equ	128						; 128 samples per frame  (6400 Hz)
;MixerSamplesPerFrame	equ	75						; 75 samples per frame   (3750 Hz)
MixerPlaybackFreq		equ	MixerSamplesPerFrame*MixerTVRate	; freq 128*50 = 6400Hz


						rsreset
Sample_Bank				rb	1						; the current bank of the sample
Sample_Address			rw	1						; the address/offset of the sample
Sample_Length			rb	3						; the length of the sample (3 bytes)
Sample_Padding			rb	2						; round up to 8 bytes
Sample_size				rb	0						; size of the sample structure



; Mod file data
MixerDMAValue			db	0						; 875000/(samples_per_frame*TVRate)
MixerMMUStore			db	0,0,0,0					; backup the MMU regs
MixerFrame				db	0						; buffer index
MixerDestbuffer			dw	0						; which buffer are we using?
MixerChannels			db	Sample_size*MixerNumChannels


; debug (allows wrting the whole tune to a single sample for saving via debugger)
MixerTuneBank			db	MIXER_SAMPLE_BANK
MixerTuneAddress		dw	MIXER_BASE_ADDRESS



; These 2 banks of data must always be paged in, but can be anywhere....
						;align	256
;MixerSamplePlayback		ds	MixerSamplesPerFrame
;						align	256
;MixerSamplePlayback2	ds	MixerSamplesPerFrame















