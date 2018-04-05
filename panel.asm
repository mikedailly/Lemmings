
; ************************************************************************
;
; Function:	Load and init the panel
;
; ************************************************************************
InitPanel:
		; load cursors first - as the sprite data gets over written
		di
		LoadBank	CursorsFile,PanelAddress,PanelBank
		;LoadBank	CursorsFile,$4000,0
		ei
		ld	e,0				; which sprite shape to copy to
		ld	d,2				; how many to copy	
		ld	hl,$c000			; copy from where?
		call	UploadSprites
		
		LoadBank	PanelFile,PanelAddress,PanelBank
		LoadBank	PanelNumbers,PanelNumbersAddress,PanelNumbersBank

		jp	ResetBank



; ************************************************************************
;
; Function:	Copy the panel to the screen. 256x32 pixels
;
; ************************************************************************
CopyPanelToScreen:
		;ld	a,6
		;out	($fe),a
		;ld	a,PanelBank*2
		;mmu6
		ld	a,PanelBank
		call	SetBank

		; set lower bank of Layer 2 screen
		ld	bc,$123b
		ld	a,$83+8
		out	(c),a


		ld	hl,PanelAddress
		ld	de,256*32
		ld	bc,8192

if USE_DMA=1
		ld	(DMASrc),hl
		ld	(DMADest),de
		ld	(DMALen),bc
		
		ld	hl,DMACopy 
		ld	bc,DMASIZE*256 + Z80DMAPORT
		otir
else
		ldir
endif
		call	DrawPanelNumbers

		;ld	a,0
		;out	($fe),a

		ld	bc,$123b
		ld	a,$2
		out	(c),a

		ret

; ************************************************************************
; Draw the panel numbers
; ************************************************************************
DrawPanelNumbers:

		ld	a,PanelNumbersBank
		call	SetBank

		ld	b,10
		ld	ix,ReleaseRate
		ld	iy,PanelScoreOffsets
@DrawAllPanelNumbers:		
		push	bc
		ld	c,(iy+0)
		ld	b,0
		ld	hl,$2900
		add	hl,bc
		ld	a,(ix+0)
		call	DrawPanelNumber
		inc	ix
		inc	iy
		pop	bc
		djnz	@DrawAllPanelNumbers

		;ld	a,$01
		;ld	hl,$2903	; Current release rate
		;call	DrawPanelNumber
 		ret	
;
; Draw panel number
;
DrawPanelNumber:
		push	af
		push	hl
		srl	a
		srl	a
		srl	a
		srl	a
		call	DrawNumber
		pop	hl
		ld	bc,5
		add	hl,bc
		pop	af
DrawNumber
		and	$f
		push	hl
		ld	hl,PanelOffsets
		add	a,a
		ld	c,a
		ld	b,0
		add	hl,bc
		
PanelNumOffset	ld	c,(hl)
		inc	hl
		ld	b,(hl)
		pop	hl
		ex	de,hl
		ld	hl,PanelNumbersAddress
		add	hl,bc
		
		ld	b,8
@DrawLoop:	push	bc
		ldi			; 14 * 5 = 70
		ldi
		ldi
		ldi
		ldi
		ld	bc,256-5	; 10
		ex	de,hl		; 4
		add	hl,bc		; 11
		ex	de,hl		; 4 = 29  (99)
		pop	bc
		djnz	@DrawLoop
		ret

PanelOffsets		dw	0,40*1,40*2,40*3,40*4,40*5,40*6,40*7,40*8,40*9	; offset to the graphics
PanelScoreOffsets:	db	3,19,35,51,67,83,99,115,131,147			; pixel X coords on panel
MaxReleaseLemmings	db	0	; max number of lemmings to release
ReleaseRate		db	0	; panel values
MinReleaseRate		db	0
ClimbersLeft		db	0
FloatersLeft		db	0
BombersLeft		db	0
BlockersLeft		db	0
BuildersLeft		db	0
BashersLeft		db	0
MinersLeft		db	0
DiggersLeft		db	0




