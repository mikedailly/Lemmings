; *****************************************************************************************************************************
; Reset lemmings for next level
; *****************************************************************************************************************************
InitLemmings:
		; Wipe lemming data
		ld	hl,LemData
		ld	de,LemData+1
		ld	bc,LemDataSize-1
		xor	a
		ld	(hl),a
		ldir

		ld	hl,LemData
		ld	(NextSpawnLemming),hl	; Lemming release index
		xor	a
		ld	(LemmingCounter),a
		ret


; *****************************************************************************************************************************
; Process all lemmings
; *****************************************************************************************************************************
SpawnLemming:
		ld	a,(TrapDoorStartDelay)		; if trap door not open...
		cp	$ff
		ret	nz


		ld	a,(ReleaseRateCounter)
		dec	a
		jp	nz,@Exit
		ld	a,(LemmingCounter)
		cp	100	;100
		jr	z,@Exit
		inc	a
		ld	(LemmingCounter),a
				
		
		; set new falling lemming
		ld	ix,(NextSpawnLemming)
		ld	a,1
		ld	(ix+LemDir),a		
		ld	a,LEM_FALLER
		call	SetState

		ld	iy,(TrapDoorlistCurrent)
		ld	a,(iy+0)
		or	(iy+1)
		jr	nz,@GetPosition
		ld	iy,TrapDoorList
@GetPosition:		
		ld	l,(iy+0)			; X low
		ld	h,(iy+1)			; X high
		ld	a,(iy+2)			; Y (always >0 and <160)
;		ld	hl,(LemmingXSpawn)
;		add	hl,105-209
;		add	hl,48	;105
		ld	(ix+LemX),l
		ld	(ix+(LemX+1)),h
		ld	(ix+LemY),a
		ld	bc,3
		add	iy,bc
		ld	(TrapDoorlistCurrent),iy
		
		; set bomber
		;ld	a,50/3
		;ld	(ix+LemBombCounter_Frac),a
		;ld	a,5
		;ld	(ix+LemBombCounter),a



		ld	bc,LemStructSize
		add	ix,bc
		ld	(NextSpawnLemming),ix
		ld	a,(MasterReleaseRate)		; from panel
		;ld	a,10
@Exit:
		ld	(ReleaseRateCounter),a
		ret


; *****************************************************************************************************************************
; Process all lemmings
; *****************************************************************************************************************************
ProcessLemmings:
		xor	a				; clear index
		ld 	(CursorLemmingIndex),a		; if high byte is 0, then nothing selected
		ld 	(CursorLemmingIndex+1),a
		ld	(CursorShape),a	
		ld	a,64
		ld	(CursorDistance),a

		ld 	a,(MouseX)
		ld 	hl,(ScrollIndex)
		add 	hl,a
		add 	hl,-8				; 8 pixels offset at the start of the screen
		ld 	(CursorWorldX),hl




		ld	b,MAX_LEM
		ld	ix,LemData
DoAllLemmings:
		push	bc

		; get type and get lookup in table
		ld	a,(ix+LemType)
		and	a
		jp	z,NextLemming_NotActive	; Not active
		ld	hl,SkillJumpTable
		add	a,a
		add	hl,a

		; jump to function
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ex	de,hl
		jp	(hl)

Lemming_Draw:
		ld	a,(ix+LemType)			; Does this lemming have a type to draw?
		and	a
		jr	z,NextLemming_NoDraw
		call	DrawLemming

		;ld	a,(ix+LemY)
		;ld	l,(ix+LemX)
		;ld	h,(ix+LemX+1)
		;call	PlotLevelPixel

		ld	a,(ix+LemFrame)			; Animate lemming
		inc	a
		cp	(ix+LemFrameCount)
		jr	nz,@NextFrame	
		xor	a
@NextFrame:	ld	(ix+LemFrame),a

NextLemming_NoDraw:
		ld	a,(ix+LemBombCounter)
		and	a
		jr	z,@NotBomber
		call	DrawCounter



@NotBomber:
		; cursor detection - check on Y
		;ld 	a,(CursorLemmingIndex+1)		; already found one?
		;and	a
		;jp	nz,AlreadyFoundOne			; might want to get the one closest to the centre of the cursor.....?
		ld	a,(ix+LemSkillMask)
CurrentSkillmask:
		and	SKILLMASK_BOMBER
		jp	nz,NextLemming_NotActive		; don't select this lemming


		ld	a,(MouseY)
		sub	(ix+LemY)
		add	5
		jp	p,@positiveY				; if still positive, skip neg
		neg
@positiveY:	cp	8+5
		jp	nc,NextLemming_NotActive

		; cursor detect on X coordinate		
		ld 	hl,(CursorWorldX)
		ex 	de,hl
		ld	l,(ix+LemX)
		ld	h,(ix+LemX+1)
		sbc	hl,de
		jp	p,@positiveX				; if positive, skip "NEG HL"
		ld	a,$ff					; neg HL
		xor	l
		ld	l,a
		ld	a,$ff
		xor	h
		ld	h,a
		inc	hl
@positiveX:		
		ld	a,h
		and	a		
		jr	nz,NextLemming_NotActive		; if h!=0 then too large
		ld	a,l
		cp	8+2					; if A>=8 then too large
		jr	nc,NextLemming_NotActive

		ld	a,(CursorDistance)
		cp	l
		jr	c,AlreadyFoundOne
		ld	a,l
		ld	(CursorDistance),a
		ld 	(CursorLemmingIndex),ix
		ld	a,1
		ld	(CursorShape),a
DontDoCursorCheck:
AlreadyFoundOne:

NextLemming_NotActive:
		ld	bc,LemStructSize
		add	ix,bc
		pop	bc
		dec	b
		jp	nz,DoAllLemmings
		ret



SkillJumpTable	dw	NextLemming_NotActive
		dw	ProcessLemFaller
		dw	ProcessLemWalker
		dw	ProcessLemSplatter
		dw	0 ;ProcessLemFloater
		dw	0 ;ProecssLemPreFloater
		dw	0 ;ProcessLemBlocker
		dw	0 ;ProcessLemClimber
		dw	ProcessLemBomber
		dw	ProcessLemBuilderShrug
		dw	ProcessLemBuilder
		dw	0 ;ProcessLemBasher
		dw	0 ;ProcessLemMiner
		dw	ProcessLemDigger
		dw	ProcessLemPreBomber


; *****************************************************************************************************************************
; Function:	Faller
; *****************************************************************************************************************************
ProcessLemFaller:
		ld	a,(ix+LemY)
		ld	l,(ix+LemX)		; get X
		ld	h,(ix+(LemX+1))
		call	GetPixel		; DE = pixel, bank set

		; count pixels falling
		ld	b,0
@NextLine:
		ld	a,(hl)
		and	a
		jr	nz,@HitGround
		inc	b
		ld	a,4
		cp	b
		jr	z,@KeepFalling		; 4 pixel fall?	(only fall a max 4 pixels at once)
		
		add	hl,$800			; move down a line
		ld	a,h			; crossed from $c000 to $0000
		test	$f8
		jr	nz,@NextLine
		or	$c0
		ld	h,a
		ld	a,(CurrentBank)
		inc	a
		ld	(CurrentBank),a
		add	a,a
		mmu6
		inc 	a
		mmu7		
		jp	@NextLine


@KeepFalling:
		; move Y down by upto 4 pixels at a time
		ld	a,(ix+LemY)
		add	a,b
		ld	(ix+LemY),a
		cp	160+10
		jp	nc,KillLemming		; off bottom of the screen?

		; Keep track of how far we've fallen
		ld	a,(ix+LemFallCount)
		add	a,b
		ld	(ix+LemFallCount),a
		jp	Lemming_Draw		

@HitGround:
		; move Y down by upto 4 pixels at a time
		ld	a,(ix+LemY)
		add	a,b
		ld	(ix+LemY),a

		; Keep track of how far we've fallen
		ld	a,(ix+LemFallCount)
		add	a,b
		cp	54
		;jr	nc,@ChangeToSplatter
		ld	(ix+LemFallCount),a
		ld	a,LEM_WALKER
		call	SetState
		jp	Lemming_Draw		
@ChangeToSplatter:
		ld	a,LEM_SPLATTER
		call	SetState
		jp	Lemming_Draw


; *****************************************************************************************************************************
; Function:	Walker
; *****************************************************************************************************************************
ProcessLemWalker:
		; move left/right
		ld	l,(ix+LemX)		; 19
		ld	h,(ix+(LemX+1))		; 19
		ld	a,(ix+LemDir)		; 19
		and	a
		jp	nz,@MoveRight
		dec	hl
		jp	@updown
@MoveRight:	inc	hl
@updown:
		ld	(ix+LemX),l		; 19
		ld	(ix+(LemX+1)),h		; 19



		ld	a,(ix+LemY)		; 19
		ld	c,a			; remember Y
		dec	a			; y-1
		call	GetPixel		; DE = pixel, bank set

		; count pixels climing/falling
		ld	b,0

		ld	de,$0408		; 10
		; check first pixel at feet - if empty, then fall
		ld	a,(hl)
		and	a
		jp	z,@DoFalling_skip	; jp instead of jr - 2 T-States quicker
		;ld	de,$0508
		inc	d
		jp	@DoClimbing_skip
@NextLineClimbing
		ld	a,(hl)
		and	a
		jp	z,@ClimbUp		; if no more pixels to climb, exit loop
@DoClimbing_skip
		dec	c
		inc	b
		ld	a,d			; faster loading of 5 - save 3 T-States
		cp	b
		jp	z,@HitWall		; 4 pixel fall?	(only fall a max 4 pixels at once)

		ld	a,h
		sub	e			; sub 8 = hl-$800
		ld	h,a
		;add	hl,-$800		; move UP a line
		;ld	a,h			; crossed from $c000 to $0000
		test	$40			; in top 2 banks? if dropped into $bX then need to change bank
		jr	nz,@NextLineClimbing
		or	$40			; bring bank into top 2 banks
		ld	h,a
		ld	a,(CurrentBank)
		dec	a
		ld	(CurrentBank),a
		add	a,a
		mmu6
		inc 	a
		mmu7		
		jp	@NextLineClimbing


@HitWall	;
		; Check for climber here
		;
		ld	a,c
		add	a,5
		ld	c,a
		ld	a,(ix+LemDir)		; flip direction
		xor	1
		ld	(ix+LemDir),a
		;call	SetWalkerDirection_NoLoad

@ClimbUp:	; Normal walker "climb"
		ld	(ix+LemY),c
		jp	DrawWalker		




		;
		; Walker falling
		;
@NextLineFalling:
		; check first pixel - if empty, then fall
		ld	a,(hl)
		and	a
		jp	nz,@HitGround

		inc	c
		inc	b
		ld	a,d			; faster loading of 4 (save 3 t-states)
		cp	b
		jp	z,SetFaller		; 4 pixel fall?	(only fall a max 4 pixels at once)

@DoFalling_skip:
		ld	a,h
		add	a,e			; add $8 = hl+$800
		ld	h,a	
		;add	hl,$800			; move DOWN a line
		;ld	a,h			; crossed from $c000 to $0000
		test	$f8			; in top 2 banks? if dropped into $bX then need to change bank
		jr	nz,@NextLineFalling
		or	$c0			; bring bank into top 2 banks
		ld	h,a
		ld	a,(CurrentBank)
		inc	a
		ld	(CurrentBank),a
		add	a,a
		mmu6
		inc 	a
		mmu7		
		jp	@NextLineFalling
@HitGround:
		ld	(ix+LemY),c		; 19
		jp	DrawWalker		

DrawWalker:	
		ld	e,(ix+LemX)
		ld	a,(ix+LemDir)
		and	a
		jp	nz,@GoingRight
		ld	a,e		; frame = 7-(x&7)
		and	7
		ld	c,a
		ld	a,7
		sub	c
		add	a,FWalkerL
		ld	l,a
		ld	h,0
		jp	@DrawLem
@GoingRight	
		ld	a,e		; frame = X&7
		and	7
		add	a,FWalkerR
		ld	l,a
		ld	h,0
@DrawLem:	
		ld	d,(ix+LemX+1)	
		ld	a,(ix+LemY)	
		call	DrawLemmingFrame

		jp	NextLemming_NoDraw

SetFaller:
		ld	a,LEM_FALLER
		call	SetState
		jp	Lemming_Draw	

; *****************************************************************************************************************************
; Function:	Process a lemming building
; *****************************************************************************************************************************
ProcessLemBuilderShrug:
		ld	a,(ix+LemFrame)
		cp	8			; Last Frame?
		jp	nz,Lemming_Draw
		
		ld	a,LEM_WALKER
		call	SetState

		jp	Lemming_Draw


; *****************************************************************************************************************************
; Function:	Process a lemming building
; *****************************************************************************************************************************
ProcessLemBuilder:
		ld	a,(ix+LemY)
		ld	l,(ix+LemX)		; get X
		ld	h,(ix+(LemX+1))
		call	GetPixel		; DE = pixel, bank set

		ld	a,(ix+LemFrame)
		cp	10			; Brick goes down on frame 9 or 10... try 10
		jr	z,@BrickFrame
		ld	a,(ix+LemFrame)
		cp	16			; Brick goes down on frame 9 or 10... try 10
		jr	z,@MoveBuilder
		jp	Lemming_Draw
@MoveBuilder:
		ld	a,(ix+LemSkillTemp)
		and	$ff
		jp	nz,@BricksLeft
		ld	a,LEM_BUILDER_SHRUG
		call	SetState
		jp	Lemming_Draw
@BricksLeft:
		xor	a
		ld	(ix+LemFrame),a

		ld	l,(ix+LemX)
		ld	h,(ix+(LemX+1))

		ld	a,(ix+LemDir)		; left or right?
		and	a
		jr	z,@FaceLeftMove
		inc	hl
		inc	hl
		jr	@SkipLeftMove
@FaceLeftMove:
		dec	hl
		dec	hl
@SkipLeftMove
		ld	(ix+LemX),l
		ld	(ix+(LemX+1)),h

		ld	a,(ix+LemY)
		dec	a
		cp	$FF
		jp	z,KillLemming
		ld	(ix+LemY),a
		jp	Lemming_Draw

@BrickFrame:
		ld	hl,BuilderStep
		; Draw builer step
		ld	e,(ix+LemY)
		ld	d,0
		dec	de
		ld	l,(ix+LemX)
		ld	h,(ix+(LemX+1))

		ld	a,(ix+LemDir)		; left or right?
		and	a
		jr	z,@FaceLeft
		dec	hl
		dec	hl
		jr	@SkipLeftOffset
@FaceLeft:
		add	hl,-6
@SkipLeftOffset:
		ld	b,h
		ld	c,l
		ld	hl,BuilderStep
		call	RenderBoblevel
		ld	a,(ix+LemSkillTemp)
		dec	a
		ld	(ix+LemSkillTemp),a

		jp	Lemming_Draw

; *****************************************************************************************************************************
; Function:	Process a lemming digging
; *****************************************************************************************************************************
ProcessLemDigger:
		ld	a,(ix+LemY)
		ld	l,(ix+LemX)		; get X
		ld	h,(ix+(LemX+1))
		call	GetPixel		; DE = pixel, bank set

@NextLine:
		ld	a,(hl)			; if no ground under them, then turn into faller
		and	a
		jp	z,SetFaller

		ld	a,(ix+LemFrame)
		cp	0
		jr	z,@DigFrame
		cp	13
		jp	nz,Lemming_Draw
		
@DigFrame:		
		; remove part of the level
		ld	l,(ix+LemY)
		ld	h,0
		add	hl,-2
		ex	de,hl
		ld	l,(ix+LemX)
		ld	h,(ix+(LemX+1))
		add	hl,-6
		ld	b,h
		ld	c,l
		ld	hl,DiggerMask
		call	ClearBoblevel

		ld	a,(ix+LemY)
		inc	a
		ld	(ix+LemY),a

		jp	Lemming_Draw



; *****************************************************************************************************************************
; Function:	Process a Splatter
ProcessLemSplatter:
		ld	a,(ix+LemFrame)
		cp	16
		jp	nz,Lemming_Draw
KillLemming:	xor	a			; kill lemming
		call	SetState
		jp	Lemming_Draw


; *****************************************************************************************************************************
; Function:	Process a Splatter
ProcessLemPreBomber:
		ld	a,(ix+LemFrame)
		cp	16
		jp	nz,Lemming_Draw
		
		; remove part of the level
		ld	l,(ix+LemY)
		ld	h,0
		add	hl,-14
		ex	de,hl

		ld	l,(ix+LemX)
		ld	h,(ix+(LemX+1))
		add	hl,-8
		ld	b,h
		ld	c,l
		ld	hl,BomberMask
		push	bc
		call	ClearBoblevel
		pop	hl

		ld	bc,(ScrollIndex)
		sbc	hl,bc
		add	hl,8
		ld	a,h
		and	a
		jr	nz,@OffScreen
		ld	a,l
		ld	(ExplosionX),a
		ld	a,(ix+LemY)
		add	a,16
		ld	(ExplosionY),a

@OffScreen:
		ld	a,LEM_BOMBER
		call	SetState

		jp	Lemming_Draw


; *****************************************************************************************************************************
; Function:	Process a Bomber
ProcessLemBomber:
		ld	a,(ix+LemFrame)
		inc	a
		cp	53
		jp	z,KillLemming

                ld      h,(ix+LemX+1)
                ld      l,(ix+LemX)
		ld      e,(ix+LemY)

                ld      (ix+LemFrame),a
                call    DrawExplosionFrame
                jp	DontDoCursorCheck		; bombers shouldn't be detected



; *****************************************************************************************************************************
; Function:	Get pixel address (in level bitmap)
; IN:		a  = Y
;		HL = X
; Ret:		HL = address, bank set
; Uses		af,de,hl
; *****************************************************************************************************************************
GetPixel:
		; Get bank pixel is on
		ld	e,a			; save Y
		add 	a,a
		add	a,a
		add	a,a
		;and 	$3f			; don't need to and as $3F+$C0=$FF
		or	$c0 			; add on base address (always here)
		ld 	d,a 			; get Y (line offset into bank) into D
		ld	a,e			; Get Y coordinate back
		ld	e,0
		srl 	a			; 0 put into bit 7,
		srl 	a
		srl 	a 			; /8 = bank
		;and	$1f			; 0 put into bit 7 so no need for AND
		add	a,LevelBitmapBank	; add on the base of the level
		add	hl,de			

		ld	(CurrentBank),a		; remember bank
		add	a,a
		mmu6
		inc 	a
		mmu7
		ret	


; *****************************************************************************************************************************
; Function:	Set up a new animation
; IN:		HL = pointed to animation
;		ix = Lemming struct
; Changes:	a,hl
; *****************************************************************************************************************************
SetAnim:	ld	a,(hl)
		ld	(ix+LemFrameBase),a
		inc	hl
		ld	a,(hl)
		ld	(ix+LemFrameBase+1),a
		inc	hl
		ld	a,(hl)
		ld	(ix+LemFrameCount),a
		inc	hl
		ld	a,(hl)
		ld	(ix+LemFrameOffX),a
		inc	hl
		ld	a,(hl)
		ld	(ix+LemFrameOffY),a
		xor	0
		ld	(ix+LemFrame),a
		ret




; *****************************************************************************************************************************
; Set Lemming State
;	a = LEM_????? type
;	ix= Lemming struct
; *****************************************************************************************************************************
SetState:	ld	(ix+LemType),a

		add	a,a
		ld	hl,StateJumpTable
		add	hl,a
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ex	de,hl

		; all types need to reset the frame index
		xor	a
		ld	(ix+LemFrame),a

		; a ALWAYS = 0 on entry to function
		jp	(hl)

; -----------------------------------------------------
; Set NONE state
SetStateNone:	ret


; -----------------------------------------------------
; Set faller state
SetStateFaller:
		ld	a,(ix+LemSkillMask)	; set skill mask
		and	SKILLMASK_PERMANENT	; get rid of whatever we were doing before
		ld	(ix+LemSkillMask),a

		ld	(ix+LemFallCount),a	; a=0 on entry
		ld	a,(ix+LemDir)		; left or right?
		and	a
		jr	z,@FaceLeft		; if 0, then left
		ld	hl,FallerRAnim
		jp	SetAnim
@FaceLeft:	ld	hl,FallerLAnim
		jp	SetAnim


; -----------------------------------------------------
; Set walker state
SetStateWalker:
		ld	a,(ix+LemSkillMask)	; set skill mask
		and	SKILLMASK_PERMANENT	; get rid of whatever we were doing before
		ld	(ix+LemSkillMask),a

SetWalkerDirection:
		ld	a,(ix+LemDir)		; left or right?
SetWalkerDirection_NoLoad:
		and	a
		jr	z,@FaceLeft		; if 0, then left		
		ld	hl,WalkerRAnim
		jp	SetAnim
@FaceLeft:	ld	hl,WalkerLAnim
		jp	SetAnim


; -----------------------------------------------------
; Set faller state
SetStateSplatter:
		; stop it being assignable once its splatting
		ld	a,SKILLMASK_CLIMBER|SKILLMASK_FLOATER|SKILLMASK_BOMBER|SKILLMASK_BUILDER|SKILLMASK_BASHER|SKILLMASK_MINER|SKILLMASK_DIGGER
		ld	(ix+LemSkillMask),a

		ld	hl,SplatterAnim
		jp	SetAnim

; -----------------------------------------------------
; Set digger state
SetStateDigger:
		ld	a,(ix+LemSkillMask)	; set skill mask
		and	SKILLMASK_PERMANENT	; get rid of whatever we were doing before
		or	SKILLMASK_DIGGER
		ld	(ix+LemSkillMask),a

		xor	a			; frame is actually stored in here..
		ld	(ix+LemSkillTemp),a

		ld	hl,DiggerAnim
		jp	SetAnim


; -----------------------------------------------------
; Set builder shrugger state
SetStateBuilderShrug:
stateshrug
		ld	a,(ix+LemSkillMask)	; set skill mask
		and	SKILLMASK_PERMANENT	; get rid of whatever we were doing before
		ld	(ix+LemSkillMask),a

		ld	a,(ix+LemDir)		; left or right?
		and	a
		jr	z,@FaceLeft

		ld	hl,BuilderRShrug
		jp	SetAnim
@FaceLeft:
		ld	hl,BuilderLShrug
		jp	SetAnim


; -----------------------------------------------------
; Set builder state
SetStateBuilder:
		ld	a,(ix+LemSkillMask)	; set skill mask
		and	SKILLMASK_PERMANENT	; get rid of whatever we were doing before
		or	SKILLMASK_BUILDER
		ld	(ix+LemSkillMask),a

		;ld	a,0
		;ld	(ix+LemDir),a

		ld	a,12			; Number of bricks..
		ld	(ix+LemSkillTemp),a

		ld	a,(ix+LemDir)		; left or right?
		and	a
		jr	z,@FaceLeft

		ld	hl,BuilderRAnim
		jp	SetAnim
@FaceLeft:
		ld	hl,BuilderLAnim
		jp	SetAnim

; -----------------------------------------------------
; Set faller state
SetStatePreBomber:
		; stop it being assignable once its splatting
		ld	a,SKILLMASK_CLIMBER|SKILLMASK_FLOATER|SKILLMASK_BOMBER|SKILLMASK_BUILDER|SKILLMASK_BASHER|SKILLMASK_MINER|SKILLMASK_DIGGER
		ld	(ix+LemSkillMask),a

		ld	hl,PreBomberAnim
		jp	SetAnim
; -----------------------------------------------------
; Set bomber state
SetStateBomber:
		ld	a,255			; increments pre-first draw
		ld	(ix+LemFrame),a
                
		; pre-offset the lemming location to centre the explosion
                ld      h,(ix+LemX+1)
                ld      l,(ix+LemX)
                add	hl,8
                ld      (ix+LemX+1),h
                ld      (ix+LemX),l

		ld      a,(ix+LemY)		
		sub	3
		ld      (ix+LemY),a

		ld	hl,PreBomberAnim
		jp	SetAnim

; -----------------------------------------------------
; Set PRE-bomber state. Puts the counter above the head
; ix = Lemming to set
SetStateBomberCountDown:
		ld	a,50/3
		ld	(ix+LemBombCounter_Frac),a
		ld	a,5
		ld	(ix+LemBombCounter),a
		ld	a,(ix+LemSkillMask)	; set skill mask
		or	SKILLMASK_BOMBER
		ld	(ix+LemSkillMask),a
		ret

; -----------------------------------------------------
; state jump table
StateJumpTable:
		dw	SetStateNone		; 0 - LEM_NONE	
		dw	SetStateFaller		; 1 - LEM_FALLER
		dw	SetStateWalker		; 2 - LEM_WALKER
		dw	SetStateSplatter	; 3 - LEM_SPLATTER
		dw	0			; 4 - LEM_FLOATER		
		dw	0			; 5 - LEM_PREFLOATER	
		dw	0			; 6 - LEM_BLOCKER		
		dw	0			; 7 - LEM_CLIMBER		
		dw	SetStateBomber		; 8 - LEM_BOMBER		
		dw	SetStateBuilderShrug	; 9 - LEM_BUILDER_SHRUG
		dw	SetStateBuilder		; 10 - LEM_BUILDER
		dw	0			; 11 - LEM_BASHER		
		dw	0			; 12 - LEM_MINER		
		dw	SetStateDigger		; 13 - LEM_DIGGER		
		dw	SetStatePreBomber	; 14 - LEM_PREBOMBER


; *****************************************************************************************************************************
; Draw a lemming
; *****************************************************************************************************************************
DrawLemming:
		ld	l,(ix+LemFrameBase)
		ld	h,(ix+(LemFrameBase+1))
		ld	a,(ix+LemFrame)
		add	hl,a

		ld	e,(ix+LemX)
		ld	d,(ix+(LemX+1))

		ld	a,(ix+LemY)

; *****************************************************************************************************************************
; Draw a lemming frame
;
;		HL = frame to draw
;		IX = Lem structure
;		DE = X
;		A  = Y
; *****************************************************************************************************************************
DrawLemmingFrame:
;		ld	(HLLemFrame),hl		; DEBUG code
;		ld	(DEXPOS),de
;		ld	(IXVAL),ix
;		ld	(A_YPOS),a
		push	af
		push	de
		ld	a,LemmingsBank*2	; first bank holds offset table
		mmu6				; bank in

		
		ld 	b,h
		ld 	c,l
		add	hl,hl			; *4
		add	hl,hl
		add	hl,bc			; *5
		add	hl,$c000		; HL = address
		
		ld	e,(hl)			; get draw function address
		inc	hl
		ld	d,(hl)
		ld	(CallLemming+1),de

		inc	hl
		ld	a,(hl)			; get draw function bank offset
		inc	hl
		add	a,LemmingsBank*2

		ld	b,(hl)			; get x,y orgin offsets  (b=x,c=y)
		inc	hl
		ld	c,(hl)
		mmu6


		pop	hl			; get X coordinate back
		ld      de,(ScrollIndex)
		ccf
		sbc	hl,de			; subtract from scroll offset
		add	hl,16
		ld	a,(ix+LemFrameOffX)
		test	$80
		jr	z,@DoPlus
		ld	e,a
		ld	d,-1
		add	hl,de
		jp	@SkipAdd
@DoPlus:	add	hl,a
@SkipAdd:	ld	a,c			; save Y offset
		ld	c,b
		ld	b,0
		ccf
		sbc	hl,bc
		

		ld	c,a			; get Y offset back into c
		ld	a,h
		and	a
		jr	nz,ClipLemming
		ld	a,l
		cp	$f8			; right clip
		jr	nc,ClipLemming

		pop	af
		;sub	c
		;add	a,c
		dec	a
		cp	176			; if Y > 176 then clip
		ret	nc
		ld	h,a

		; HL = screen address [y,x]


		;
		; Common drawing code....
		;
		ld	bc,$123b
		ld	a,h			
		and	$c0
		or	$03+8
		out	(c),a

		ex	af,af'
		ld	a,h
		and	$3f
            	ld	h,a

CallLemming:	jp	$0000
		

ClipLemming	pop	af
		ret


;ResetDraw	ld	hl,(HLLemFrame)
;		ld	de,(DEXPOS)
;		ld	ix,(IXVAL)
;		ld	a,(A_YPOS)
;		jp	DrawLemmingFrame


HLLemFrame	dw	0
DEXPOS		dw	0
IXVAL		dw	0
A_YPOS		db	0

; *****************************************************************************************************************************
; Draw the bomber counter
;		HL = X coordinate
;		A  = Y coordinate
; *****************************************************************************************************************************
DrawCounter
		ld	a,(ix+LemBombCounter_Frac)
		dec	a
		jr	nz,@NotZero
		ld	a,(ix+LemBombCounter)
		dec	a
		ld	(ix+LemBombCounter),a
		jr	z,@DoBoom
		ld	a,50/3
@NotZero:	ld	(ix+LemBombCounter_Frac),a

		ld	e,(ix+LemX)
		ld	d,(ix+(LemX+1))

		ld	a,(ix+LemBombCounter)
		ld	hl,FOne-1
		add	hl,a
		ld	a,(ix+LemY)
		sub	10
		jp	DrawLemmingFrame
@DoBoom:	
		ld	l,(ix+LemY)
		ld	h,0
		add	hl,-14
		ex	de,hl

		; remove part of the level
		ld	l,(ix+LemX)
		ld	h,(ix+(LemX+1))
		add	hl,-8
		ld	b,h
		ld	c,l
		ld	hl,BomberMask
		;call	ClearBoblevel

		ld	a,LEM_PREBOMBER
		jp	SetState

; *****************************************************************************************************************************
; Plot a pixel in level coorindates
;		HL = X coordinate
;		A  = Y coordinate
; *****************************************************************************************************************************
PlotLevelPixel:
		ld      de,(ScrollIndex)
		sbc	hl,de			; subtract from scroll offset
		add	hl,8			; add 8 to counter the black-out side border area
		ld	c,a
		ld	a,h
		and	a
		ret	nz			; clip left/right
		ld	h,c
		ex	de,hl
		pixelad
		setae
		or	(hl)
		ld	(hl),a
		ret



