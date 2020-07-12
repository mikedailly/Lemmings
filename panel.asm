
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
		ld	d,10				; how many to copy	
		ld	hl,$c000			; copy from where?
		call	UploadSprites
		
		LoadBank	PanelFile,PanelAddress,PanelBank
		LoadBank	PanelNumbers,PanelNumbersAddress,PanelNumbersBank

		;jp	ResetBank


StartPanelCopper:
		ld      hl,GameCopper
		ld      de,GameCopperSize
		call    UploadCopper       
		NextReg $62,%11000000  
		ret


; ************************************************************************
;
; Function:	Copy the panel to the screen. 256x32 pixels
;
; ************************************************************************
CopyPanelToScreen:
		ld	a,PanelBank
		call	SetBank

		; set lower bank of Layer 2 screen
		ld	bc,$123b
		ld	a,$83+8
		out	(c),a



		ld	hl,PanelAddress
		ld	de,256*32
		ld	bc,8192
		ldir

		call	DrawPanelNumbers

		ld	bc,$123b
		ld	a,$2
		out	(c),a

		ret

; ************************************************************************
; Draw the panel numbers
; ************************************************************************
DrawPanelNumbers:
		ld		a,(PanelDirty)
		and		a
		ret		z

DrawPanelNumbers_Force:
		xor		a
		ld		(PanelDirty),a

		ld		a,PanelNumbersBank*2		; the numbers
		Nextreg	$56,a
		ld		a,PanelBank*2				; the panel itself
		NextReg	$57,a

		ld		b,10
		ld		ix,MinReleaseRate
		ld		iy,PanelScoreOffsets
@DrawAllPanelNumbers:		
		push	bc
		ld		c,(iy+0)
		ld		b,0
		ld		hl,$e900					; 2900
		add		hl,bc

		ld		a,(ix+0)
		and		a
		jr		z,@DontDraw
		call	DrawPanelNumber
@DontDraw:
		inc		ix
		inc		iy
		pop		bc
		djnz	@DrawAllPanelNumbers
 		ret	


;
; Draw panel number
; HL = dest address
;
DrawPanelNumber:
		push	af
		push	hl
		swapnib
		and		$f
		call	DrawNumber
		pop		hl
		add		hl,5
		pop		af
DrawNumber
		and		$f
		push	hl
		ld		hl,PanelOffsets
		add		a,a
		ld		c,a
		ld		b,0
		add		hl,bc
		
PanelNumOffset	
		ld		c,(hl)
		inc		hl
		ld		b,(hl)
		pop		hl
		ex		de,hl
		ld		hl,PanelNumbersAddress
		add		hl,bc
		
		ld		b,8
		ld		c,255		; stops B from overflowiung
@DrawLoop:	
		ldi					; 14 * 5 = 70
		ldi
		ldi
		ldi
		ldi
		add		de,256-5	; 10
		djnz	@DrawLoop
		ret





; *****************************************************************************************************************************
; 	Generate mini-map
; *****************************************************************************************************************************
GenerateMiniMap:
		NextReg	$56,PanelBank*2			; page in panel
		ld 		c,20					; mini map is 20 pixels high
		exx
		
		ld 		de,$c000+(204+(10*256))	; start of panel "slot"
		ld		a,LevelBitmapBank*2		; page in bitmap to $e000
		ld		c,$10
		exx
@BuildMap:
		exx
		NextReg	$57,a
		ex		af,af'			; remember current bank
@Loop4:
		ld		b,50			; do 4 lines before changing bank
		ld 		hl,$e000
@CopyRow
		ld 		a,(hl)
		and 	a
		jr 		z,@SkipPixel
		ld 		a,c		;$10			; set colour to "green"
@SkipPixel:	
		ld 		(de),a
		inc 	de
		ld 		a,32			; pixels are 32 pixels apart.
		add 	hl,a
		djnz	@CopyRow

		ld 		a,256-50		; next row in the panel
		add 	de,a

		ex		af,af'			; remember current bank again
		add		a,2				; move on 2 banks - 8 lines
		exx		
		dec		c
		jr		nz,@BuildMap
		ret		


; ************************************************************************
;
; Function:	Load and init the panel
;
; ************************************************************************
ProcessInput:
		; count double click
		ld		a,(DoubleClipCounterCurrent)
		cp		$ff							; double click counter maxed out?
		jr		z,@MaxCount
		inc		a
		ld		(DoubleClipCounterCurrent),a
		cp		$0b							;  < 1 second for a double click
		jr		c,@DontClearNukeFlag		; over... not clicknig
		xor		a
		ld		(NukeFlag),a				; clear nuke flag

@MaxCount:
@DontClearNukeFlag:



		xor		a
		ld		(ButtonPressed),a			; clear pressed flag
		ld		a,(ButtonDown)
		and		$f
		jp		z,@TestButton				; button pressed already processed?

		ld		a,(MouseButtons)
		test	2							; LEFT button
		jp		z,@TestSlots				; if button still down, return

		xor		a								; button not perssed, so clear flag
		ld		(ButtonDown),a
		ret

@TestButton:	
		ld		a,(MouseButtons)
		bit		1,a							; LEFT button
		jp		nz,@TestSlots				; not pressed?
		ld		(ButtonDown),a
		dec		a
		ld		(ButtonPressed),a			; button pressed this frame

		ld		a,0
		ld		(DoubleClipCounterCurrent),a




@TestSlots:
		; Once mouse button pressed, check to see where the cursor is
		ld		a,(MouseY)
		cp		168
		jp		c,AssignSkill				; if less then the panel, then assign Lemming a skill

		ld		a,(MouseX)
		swapnib								; shift right 16
		and		$f							; clear top bits...
		sub		2
		ld		b,a							; remember slot
		jp		m,@ReleaseSpeed				; if first 2 boxes...return

		cp		8							; panel slot > 7 then not a skill
		jp		nc,DoPauseNukeCheck	

		xor		a							; flag as NOT the nuke button
		ld		(NukeFlag),a

		; Select the skill on the panel
		ld		a,(ButtonPressed)
		and		$ff
		ret		z							; button not pressed


		ld		a,b							; get panel slot back
		ld		(PanelSelection),a			; set selected skill
		; get "mask"
		ld		hl,SkillMaskTable
		add		hl,a		
		ld		a,(hl)
		ld		(CurrentSkillmask+1),a
		call	MakePanelDirty
		ret
		;
		; Check release rate panels
		;
@ReleaseSpeed:	
		ld		a,(MouseButtons)
		test	2							; LEFT button
		ret		nz

		ld		a,b
		cp		$fe							; 0-2 = $FE. Release DOWN
		jr		nz,@RateUp
		ld		a,(MinReleaseBin)			; rate down
		ld		b,a
		ld		a,(ReleaseRateBin)
		cp		b
		ret		z							; if the same, then don't decrease
		dec		a

@UpdateReleaseRate:
		ld		(ReleaseRateBin),a	
		push	af							; Now convert back into panel display number 
		call	ConvertNumber
		ld		(ReleaseRate),a
		pop		af
		call	ConvertToDelay				; convert into the frame delay value
		;ld	(ReleaseRateCounter),a			; don't wipe "current" counter
		ld		(MasterReleaseRate),a
		jp		MakePanelDirty

@RateUp
		ld		a,(ReleaseRateBin)			; else release UP
		cp		99
		ret		z
		inc		a
		jp		@UpdateReleaseRate
		;ret


		; Assign skill to an actual lemming
AssignSkill:	
		ld		a,(ButtonPressed)
		and		$ff
		ret		z							; not pressed?


		ld 		ix,(CursorLemmingIndex)
		ld		a,ixh
		and		$ff
		ret		z							; no lemming selected


		ld		a,(PanelSelection)			; get skill
		cp		2
		jr		nz,@NotBomber				; not bomber?

		ld		a,(ix+LemBombCounter)
		and		a
		ret		nz							; already a bomber?

		jp		SetStateBomberCountDown		; set bomber state


@NotBomber:
		cp		4
		jr		nz,@NotBuilder
		ld		a,LEM_BUILDER
		jp		SetState
		
@NotBuilder:
		cp		7
		jr		nz,@NotADigger				; not digger
		;ret	nz
		ld		a,LEM_DIGGER				; swap lemming to a digger
		jp		SetState					; set bomber state

@NotADigger:	
		ret




		;
		; Do pause and nuke
		;
DoPauseNukeCheck:
		; Check for pause....
		cp		8
		jr		nz,@TestNukeButton			; not digger
		xor		a							; flag as NOT the nuke button
		ld		(NukeFlag),a
		ret

@TestNukeButton:
		; check for NUKE
		ld		a,(ButtonPressed)
		and		$ff
		ret		z

		ld		a,(NukeFlag)				; was it clicked last time?
		and		a
		jr		z,FirstNukeClick

		ld		a,MAX_LEM					; Nuke Started is also the counter...
		ld		(NukeStarted),a
		ld		ix,LemData
		ld		(NukeIndex),ix
		ld		a,100
		ld		(LemmingCounter),a
		ret


FirstNukeClick:	
		ld		a,$ff
		ld		(NukeFlag),a
		ret


MakePanelDirty:
		ld		a,255
		ld		(PanelDirty),a
		ret	



DoubleClipCounterCurrent	db	0
NukeFlag			db	0
NukeStarted			db	0
NukeIndex			dw	0




PanelOffsets			dw	0,40*1,40*2,40*3,40*4,40*5,40*6,40*7,40*8,40*9	; offset to the graphics
PanelScoreOffsets:		db	3,19,35,51,67,83,99,115,131,147			; pixel X coords on panel
MaxReleaseLemmingsBin	db	0	; max number of lemmings to release (BIN)
MaxReleaseLemmings		db	0	; max number of lemmings to release
MinReleaseBin			db	0	; Binary "minimum"
ReleaseRateBin			db	0	; raw value (not display one)

; Panel numbers - DONT reorder!
MinReleaseRate		db	0
ReleaseRate			db	0	; panel values
ClimbersLeft		db	0
FloatersLeft		db	0
BombersLeft			db	0
BlockersLeft		db	0
BuildersLeft		db	0
BashersLeft			db	0
MinersLeft			db	0
DiggersLeft			db	0

ButtonDown			db	0	; mouse button down?
ButtonPressed		db	0	; button pressed this frame?
PanelDirty			db	0	; retrun numbers?
