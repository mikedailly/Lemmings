
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
		ld	d,4				; how many to copy	
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
		ld	ix,MinReleaseRate
		ld	iy,PanelScoreOffsets
@DrawAllPanelNumbers:		
		push	bc
		ld	c,(iy+0)
		ld	b,0
		ld	hl,$2900
		add	hl,bc
		ld	a,(ix+0)
		and	a
		jr	z,@DontDraw
		call	DrawPanelNumber
@DontDraw:
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
MaxReleaseLemmingsBin	db	0	; max number of lemmings to release (BIN)
MaxReleaseLemmings	db	0	; max number of lemmings to release
MinReleaseBin		db	0	; Binary "minimum"
ReleaseRateBin		db	0	; raw value (not display one)

; Panel numbers - DONT reorder!
MinReleaseRate		db	0
ReleaseRate		db	0	; panel values
ClimbersLeft		db	0
FloatersLeft		db	0
BombersLeft		db	0
BlockersLeft		db	0
BuildersLeft		db	0
BashersLeft		db	0
MinersLeft		db	0
DiggersLeft		db	0

ButtonDown		db	0	; mouse button down?
ButtonPressed		db	0	; button pressed this frame?



; ************************************************************************
;
; Function:	Load and init the panel
;
; ************************************************************************
ProcessInput:
		xor	a
		ld	(ButtonPressed),a	; clear pressed flag
		ld	a,(ButtonDown)
		and	$f
		jp	z,@TestButton		; button pressed already processed?

		ld	a,(MouseButtons)
		test	2			; LEFT button
		jp	z,@TestSlots		; if button still down, return

		xor	a			; button not perssed, so clear flag
		ld	(ButtonDown),a
		ret

@TestButton:	ld	a,(MouseButtons)
		test	2			; LEFT button
		jp	nz,@TestSlots		; not pressed?
		ld	(ButtonDown),a
		dec	a
		ld	(ButtonPressed),a	; button pressed this frame



@TestSlots:

		; Once mouse button pressed, check to see where the cursor is
		ld	a,(MouseY)
		cp	168
		jp	c,AssignSkill		; if less then the panel, then assign Lemming a skill

		ld	a,(MouseX)
		swapnib				; shift right 16
		and	$f			; clear top bits...
		sub	2
		ld	b,a			; remember slot
		jp	m,@ReleaseSpeed		; if first 2 boxes...return

		cp	8			; panel slot > 7 then not a skill
		jp	nc,@pauseNuke	

		ld	a,(ButtonPressed)
		and	$ff
		ret	z			; button not pressed
		ld	a,b			; get panel slot back
		ld	(PanelSelection),a	; set selected skill
		ret

		;
		; Check release rate panels
		;
@ReleaseSpeed:	ld	a,(MouseButtons)
		test	2			; LEFT button
		ret	nz

		ld	a,b
		cp	$fe			; 0-2 = $FE. Release DOWN
		jr	nz,@RateUp
		ld	a,(MinReleaseBin)	; rate down
		ld	b,a
		ld	a,(ReleaseRateBin)
		cp	b
		ret	z			; if the same, then don't decrease
		dec	a
@UpdateReleaseRate:
		ld	(ReleaseRateBin),a	
		push	af			; Now convert back into panel display number 
		call	ConvertNumber
		ld	(ReleaseRate),a
		pop	af
		call	ConvertToDelay		; convert into the frame delay value
		;ld	(ReleaseRateCounter),a	; don't wipe "current" counter
		ld	(MasterReleaseRate),a
		ret
@RateUp
		ld	a,(ReleaseRateBin)	; else release UP
		cp	99
		ret	z
		inc	a
		jp	@UpdateReleaseRate
@pauseNuke:
		ret



AssignSkill:
		ld	a,(ButtonPressed)
		and	$ff
		ret	z			; not pressed?


		ld 	ix,(CursorLemmingIndex)
		ld	a,ixh
		and	$ff
		ret	z			; no lemming selected


		ld	a,(PanelSelection)	; get skill
		cp	2
		jr	nz,@NotBomber			; not bomber?

		ld	a,(ix+LemBombCounter)
		and	a
		ret	nz			; already a bomber?

		jp	SetStatePreBomber	; set bomber state


@NotBomber:
		cp	7
		;jr	nz,@NotADigger		; not digger
		ret	nz
		ld	a,LEM_DIGGER		; swap lemming to a digger
		jp	SetState		; set bomber state

@NotADigger:	cp	9			; not nuke
		ret	nz

		ld	a,(ButtonPressed)
		and	$ff
		ret	z

		ld	a,(NukeCounter)
		cp	255
		jr	nz,@CounterActive
		xor	a
		ld	(NukeCounter),a		; active double click counter
@CounterActive:	
		cp	25/3
		jr	c,@DoNuke
		ld	a,-1
		ld	a,(NukeCounter)
@DoNuke

NukeCounter	db	0

	