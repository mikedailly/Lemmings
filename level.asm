; *****************************************************************************************************************************
; Level loading/storage
; *****************************************************************************************************************************
LoadLevel:
		;LoadBank	level_0023,LevelAddress,LevelBank	; Watch out, there's traps about
		LoadBank	level_0030,LevelAddress,LevelBank	; ship  -  Every Lemming for himself!!!
		;LoadBank	level_0055,LevelAddress,LevelBank	; Steel Works
		;LoadBank	level_0031,LevelAddress,LevelBank	; art gallery
		;LoadBank	level_0091,LevelAddress,LevelBank	; Just dig
		;LoadBank	level_0020,LevelAddress,LevelBank	; huge sprites

		ld		ix,LevelAddress
		ld 		a,(ix+$1b)

		; ------------------------------------
		; Style 0
		cp 		0
		jr 		nz,@NotDirt
@DefaultStyle:	
		LoadFile	style0dat,ObjectInfo			; load object info
		ld		hl,styleO0							; remember the object file to load
		push	hl
		LoadBanked	style0,StyleBank				; load style data
		jp 		@CarryOn
@NotDirt:
		; ------------------------------------
		; Style 1
		cp 		1
		jr 		nz,@NotFire
		LoadFile	style1dat,ObjectInfo
		ld		hl,styleO1
		push	hl
		LoadBanked	style1,StyleBank
		jp 		@CarryOn
@NotFire:
		; ------------------------------------
		; Style 2
		cp 		2
		jr 		nz,@NotMarble
		LoadFile	style2dat,ObjectInfo
		ld		hl,styleO2
		push	hl
		LoadBanked	style2,StyleBank
		jp 		@CarryOn
@NotMarble:
		; ------------------------------------
		; Style 3
		cp 	3
		jr 		nz,@NotPillars
		LoadFile	style3dat,ObjectInfo
		ld		hl,styleO3
		push	hl
		LoadBanked	style3,StyleBank
		jp 		@CarryOn
@NotPillars:
		; ------------------------------------
		; Style 4
		cp 		4
		jr 		nz,@NotDirtCrystal
		LoadFile	style4dat,ObjectInfo
		ld		hl,styleO4
		push	hl
		LoadBanked	style4,StyleBank
		jp		@CarryOn
@NotDirtCrystal
		; default - use style 0
		jp		@DefaultStyle

@CarryOn:	; get object style file back
		pop		hl
		ld		a,ObjectsBank
		call	Load_Banked



ResetLevel:
		call	InitLemmings					; reset the lemmings
		call	ClearLevel						; clear the level bitmap
		
		ld		ix,LevelAddress


		ld 		a,LevelBank
		NextReg	DRAW_BANK,a
		inc		a
		NextReg	DRAW_BANK+1,a
		

		ld		ix,LevelAddress
		ld		a,(ix+1)
		ld		(ReleaseRateBin),a
		ld		(MinReleaseBin),a
		push	af
		call	ConvertNumber
		ld		(MinReleaseRate),a
		ld		(ReleaseRate),a
		pop		af
		call	ConvertToDelay			; convert the "bin" to the "magic" delay value
		ld		(ReleaseRateCounter),a
		ld		(MasterReleaseRate),a


		ld		a,(ix+3)			; maximum number of lemmings to release
		ld		(MaxReleaseLemmingsBin),a
		call	ConvertNumber
		ld		(MaxReleaseLemmings),a

		ld		a,(ix+9)
		call	ConvertNumber
		ld		(ClimbersLeft),a
		ld		a,(ix+11)
		call	ConvertNumber
		ld		(FloatersLeft),a
		ld		a,(ix+13)
		call	ConvertNumber
		ld		(BombersLeft),a
		ld		a,(ix+15)
		call	ConvertNumber
		ld		(BlockersLeft),a
		ld		a,(ix+17)
		call	ConvertNumber
		ld		(BuildersLeft),a
		ld		a,(ix+19)
		call	ConvertNumber
		ld		(BashersLeft),a
		ld		a,(ix+21)
		call	ConvertNumber
		ld		(MinersLeft),a
		ld		a,(ix+23)
		call	ConvertNumber
		ld		(DiggersLeft),a

		push	ix
		call	DrawPanelNumbers_Force
		pop		ix



		; initialise objects
		ld		a,33				; 2 second pause (50*2/3)
		ld		(TrapDoorStartDelay),a
		
		ld		b,14				; clear entrance list
		ld		hl,TrapDoorList
		ld		(TrapDoorlistCurrent),hl
@WipeEntrances:	ld	(hl),0
		inc		hl
		djnz	@WipeEntrances



		push	ix
		ld		bc,$20
		add		ix,bc
		call	SetupLevelObjects
		pop		ix




		ld		a,(ix+$19)
		ld		l,a
		ld		a,(ix+$18)
		ld		h,a
		add		hl,16+32+16			; offset by 16, and add 32 to center screen on a 256 wide screen (instead of 320)
		ld		(ScrollIndex),hl
		ld		(LemmingXSpawn),hl

		call	CreateLevel

		; get object style file back
		;pop	hl
		;ld	a,	ObjectsBank
		;call	Load_Banked
		;call	GenerateMiniMap

		; init the release order
		ld		hl,TrapDoorList
		ld		(TrapDoorlistCurrent),hl

		ret ;jp		ResetBank


; *****************************************************************************************************************************
;	Clear the level bitmap area - will take some time.
; *****************************************************************************************************************************
ClearLevel:
		ld		a,LevelBitmapBank
@ClearLevelLoop:
		NextReg	DRAW_BANK,a
		
		ld		hl,DRAW_BASE
		ld		(hl),0
		ld		de,DRAW_BASE+1
		ld		bc,$2000-1
		ldir

		inc		a
		cp		StyleBank
		jr		nz,@ClearLevelLoop
		ret




; *****************************************************************************************************************************
; Convert the number from binary number (0-99) to BCD 
;	A = 8 bit binary number
;	A = BCD version
; *****************************************************************************************************************************
ConvertNumber:
		ld		b,0
@lp		cp		10
		jr		c,@LessThat10
		sub		10
		inc		b
		jr		@lp
@LessThat10:	ld	c,a
		ld		a,b
		swapnib					; *16
		and		$f0
		add		a,c				; add remainder
		ret


; *****************************************************************************************************************************
; Convert the 0-99 into a frame delay....Amiga did "odd" things here...
;	A = panel delay value
;	A = Frame delay value
; *****************************************************************************************************************************
ConvertToDelay:
		ld		b,a
		ld		a,99
		sub		b			; 99-num	
		srl		a			; /2
		neg					; negate
		add		a,53		; *magic*
		neg
		add		a,57		; *magic*
		ret


; *****************************************************************************************************************************
; Setup all level objects
;	iy = object instance data
;	ix = level data
; *****************************************************************************************************************************
SetupLevelObjects:
		ld		iy,ObjectData
		ld		a,0
		ld		(ObjNumber),a
		ld		e,32
@DoAll
		ld		c,(ix+1)			; min $FFF8. max $0638
		ld		b,(ix+0)
		ld		(iy+(oX+0)),c			; AMIGA format numbers!!
		ld		(iy+(oX+1)),b

		ld		l,(ix+3)			; min $FFD7. max $009f
		ld		h,(ix+2)
		ld		(iy+(oY+0)),l			; AMIGA format numbers!!
		ld		(iy+(oY+1)),h

		; get object index and store pointer to object
		ld		a,(ix+5)			; object ID (0 to $F).	0 always exit, 1 always start
		and		$0F				; mask off top
		cp		1
		jr		nz,@NotEntrance
		; If trap door, record where it opens....
		ld		hl,(TrapDoorlistCurrent)
		xor		a
		ld		a,24
		adc		a,c		
		ld		(hl),a
		inc		hl
		ld		a,0
		adc		a,b
		ld		(hl),a
		inc		hl		
		ld		a,(iy+(oY+0))
		add		a,8
		ld		(hl),a
		inc		hl
		;ld		a,(iy+(oY+1))			; ALWAYS on screen
		;ld		(hl),a
		;inc	hl
		ld		(TrapDoorlistCurrent),hl

		ld		a,1				; reload entrance ID
@NotEntrance:
		ld		(iy+oObjID),a			; store object index
		swapnib					; *16  (already masked)
						
		
		; add on base of object style data
		ld		hl,ObjectInfo
		add		hl,a
		ld		(iy+(oPtr+0)),l			; store object data pointer
		ld		(iy+(oPtr+1)),h

		; object flags
		ld		a,(ix+6)			
		ld		(iy+oFlags),a
		inc		hl				


		; now read out some object data
		ld		a,(hl)				; first frame of object
		ld		(iy+oFirstFrame),a		; set first frame
		inc		hl				; Skip first frame

		ld		a,(hl)				; get the starting frame of the anim
		ld		(iy+oFrame),a			; set current frame
		inc		hl

		ld		a,(hl)				; max frame
		ld		(iy+oMaxFrames),a

		ld		(iy+oDelta),1			; object delta

		; do this first?
		ld		a,(iy+(oX+0))			; if x and y ==0, then not active
		or		(iy+(oX+1))
		or		(iy+(oY+0))
		or		(iy+(oY+1))
		and 	a
		jr		z,@NotActive

		; do this above?
		add		bc,$0008			; add 8 to X to offset scroll mask
		ld		(iy+(oX+0)),c			; 
		ld		(iy+(oX+1)),b


		ld		bc,oInstSize			; another
		add		iy,bc

		ld		a,(ObjNumber)
		inc		a
		ld		(ObjNumber),a


@NotActive:
		ld		bc,8
		add		ix,bc

		dec		e
		jp		nz,@DoAll
		ret


level_bob_count		dw		0
; *****************************************************************************************************************************
; Create the level from the data....
; *****************************************************************************************************************************
CreateLevel:	
		ld		bc,LevelAddress+$760
		ld		ix,LevelAddress+$120	; start of level building data
@DrawAll	
		push	bc
		ld		a,(ix+0)
		cp		$ff
		jr		nz,@CarryOn
		ld		a,(ix+1)
		cp		$ff
		jr		z,@NextOne
@CarryOn:		
		ld 		a,(ix+3)
		;sra 	a
		and 	$3f	; terrain type 0-63
		ld 		l,a
		ld 		h,0


		ld 		a,(ix+0)		; get X MSnibble
		and 	$0f
		ld 		b,a 			; b = x high
		ld 		a,(ix+1)		; get low X
		ld 		c,a 			; BC = X
		ld 		a,(ix+2) 		; Y pos MSByte
		and 	$7f			
		add 	a,a 			; *2
		ld 		e,a 			; e = Y
		ld 		a,(ix+3) 		; Terrain byte
		add 	a,a 			; get bit 7 into carry
		ld 		a,e 			; get Y back
		adc 	$0 				; bring carry bit in
		ld 		e,a 			; E = Y
		ld 		d,0

		ld 		a,(ix+0)		; get bob flags
		sra 	a
		sra 	a
		sra 	a
		sra 	a				; /16 - get bob options

		call 	DrawBobLevel
@Skippie:

		push	hl
		ld		hl,(level_bob_count)
		inc		hl
		ld		(level_bob_count),hl
		pop		hl

		ld 		a,LevelBank					;	 restore banks
		NextReg	DRAW_BANK,a
		inc		a
		NextReg	DRAW_BANK+1,a


@NextOne:	
		ld 		bc,4
		add 	ix,bc
		pop		bc
		push	ix
		pop		hl
		sbc 	hl,bc
		ld 		a,h
		or 		l
		jr 		nz,@DrawAll
	
		ret


; *****************************************************************************************************************************
; 	GenerateMask - Build the mask the Lemming will walk on.
; *****************************************************************************************************************************
;GenerateMask:
		ld		a,PanelBank				; page in panel
		NextReg	DRAW_BANK,a
		ld 		de,$c000+(204+(10*256))	; start of panel "slot"

		ld		a,LevelBitmapBank		; page in bitmap to $e000
		ld 		c,20					; mini map is 20 pixels high
@BuildMap:
		NextReg	DRAW_BANK+1,a			; bank in

		ex		af,af'					; remmeber current bank
@Loop4:
		ld		b,50					; do 4 lines before changing bank
		ld 		hl,DRAW_BASE+$2000
@CopyRow
		ld 		a,(hl)
		and 	a
		jr 		z,@SkipPixel
		ld 		a,$10
@SkipPixel:	
		ld 		(de),a
		inc 	de
		ld 		a,32					; pixels are 32 pixels apart.
		add 	hl,a					; next opcode :)
		djnz	@CopyRow

		ld 		a,256-50				; next row in the panel
		add 	de,a

		ex		af,af'					; remmeber current bank
		add		a,2						; move on 2 banks - 8 lines
		dec		c
		jr		nz,@BuildMap
		ret		



; *****************************************************************************************************************************
;  Draw objects - draw all objects in the level
; *****************************************************************************************************************************
DrawLevelObjects
		ld		bc,(ScrollIndex)
		ld		(@ScrOffset+1),bc
		ld		ix,ObjectData
		ld		a,(ObjNumber)
		ld		b,a
		;ld	b,32
@DrawAll:
		push	bc

		; do a "quick" clip... as quick as we can...
		ld		l,(ix+(oX+0))				; bx = x
		ld		h,(ix+(oX+1))
@ScrOffset:	
		ld		bc,$1234					; 20
		xor		a							; clear carry
		sbc		hl,bc						; subtract world location		
		add		hl,72						; ball park clipping
		ld 		a,h
		and		$80
		jr		nz,@OffRight
		add		hl,-32
		ld 		a,h
		test	$80
		jr		nz,@DrawIt
		and		$fe
		jr		nz,@OffRight
@DrawIt:
		ld		c,(ix+(oX+0))				; bx = x
		ld		b,(ix+(oX+1))
		ld		e,(ix+(oY+0))				; de = y
		ld		d,(ix+(oY+1))
		ld		l,(ix+oFrame)				; hl = sprite
		ld		h,0
		ld		a,(ix+oFlags)				; a = flags (behind, flip etc)
		;xor		a
		call	DrawLevelBob

@OffRight:
		ld		a,(ix+oObjID)				; get object ID (0=entrance)
		cp		1
		jr		z,@DontAnimateEntrace
		ld		a,(ix+oFrame)				; get current frame
		add		a,(ix+oDelta)
		cp		(ix+oMaxFrames)		
		jr		nz,@NextFrame
		ld		a,(ix+oFirstFrame)
@NextFrame:	
		ld		(ix+oFrame),a
@DontAnimateEntrace:

@NotActive:
		ld		bc,oInstSize
		add		ix,bc
		pop		bc
		djnz	@DrawAll
		ret


; *****************************************************************************************************************************
;  Open Trap doors - scan all objects and open the doors.
; *****************************************************************************************************************************
OpenTrapDoors:
		ld		a,(TrapDoorStartDelay)
		cp		$ff
		ret		z				; already open?

		and		a				; zero? of so do animation
		jr		z,@DoAnimate
		dec		a
		ld		(TrapDoorStartDelay),a
		ret

@DoAnimate:
		ld		ix,ObjectData
		ld		a,(ObjNumber)
		ld		b,a

@AnimateAll:
		push	bc
		ld		a,(ix+oObjID)
		cp		1
		jr		nz,@NotTrapDoor

		ld		a,(ix+oFrame)
		add		a,(ix+oDelta)
		cp		(ix+oMaxFrames)	
		jr		nz,@NotEndOfAnim
		ld		a,$ff				; if so end of animation (all doors)
		ld		(TrapDoorStartDelay),a
		ld		a,(ix+oFirstFrame)		; get first frame...
@NotEndOfAnim:		
		ld		(ix+oFrame),a


@NotTrapDoor:
		ld		bc,oInstSize
		add		ix,bc

		pop		bc
		djnz	@AnimateAll
		ret




