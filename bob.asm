; ************************************************************************
;
;	Sprites must be banked into $c000
;
; ************************************************************************
BobBankOffset	dw	0
BobBank			db	0
BobXoff			db	0
BobYoff			db	0
BobWidth		dw	0	; dw so BC can load directly
LineDelta		dw 	0	; value to move to next line
BobHeight		db	0
BobSize			dw	0
BobXcoord		dw	0
BobYcoord		dw	0
BobBaseBank		db 	0
CurrentScanline dw 	0
BobFlags 		db 	0


; ************************************************************************
;
;	Draw sprites up to 256x256 in size into the large level bitmap (2048x160 bitmap)
;	This doesn't have to be super quick, it just has to work
;
;	hl = sprite number (354 lemmings...)
;	bc = X (0-1600)
;	de = Y
; 	a  = flags
;		2 = remove terrain
;		4 = upside down
;		8 = behind
;	Bank = base of graphics
; 
; ************************************************************************
DrawBobLevel:
		ld 		(BobFlags),a
		ld		(BobXcoord),bc
		ld		(BobYcoord),de
		ld 		a,StyleBank
		ld		(BobBaseBank),a			; get current bank and use that as the base

		NextReg	DRAW_BANK,a
		inc		a
		NextReg	DRAW_BANK+1,a

		; get base of "bob"
		add		hl,hl					; *4
		add		hl,hl
		add		hl,DRAW_BASE			; base of "bank" (and sprite table offsets)
		
		; W - Offset into bank (0 to $1FFF)
		; B - Bank number offset
		; B - 0
		ld		e,(hl)					; read the bank offset
		inc		hl
		ld 		d,(hl)					; de = bank offset (has $40 already ORd in)
		inc		hl		
		ld		(BobBankOffset),de 		; save bank offset
		

		ld 		a,(BobBaseBank)			; base bank
		ld		c,a
		ld		a,(hl)					; get sprite bank offset
		;add		a,a					; get 8K banks
		add		a,c
		ld		(BobBank),a
		NextReg	DRAW_BANK,a
		inc		a
		NextReg	DRAW_BANK+1,a

		;
		; B - X offset 
		; B - Y offset
		; B - Width
		; B - Height
		; W - Area (W*H)
		;
		ex		de,hl					; get bank offset
		ld		a,(hl)					;
		ld		(BobXoff),a
		ld 		c,a
		ld 		b,0
		push 	hl
		ld 		hl,(BobXcoord)
		add 	hl,bc
		ld 		(BobXcoord),hl
		pop 	hl
		inc		hl
		ld		a,(hl)					;
		ld		(BobYoff),a
		push 	hl
		ld 		hl,(BobYcoord)
		add 	hl,a
		add		hl,-4
		ld 		(BobYcoord),hl
		pop		hl
		inc		hl
		ld		a,(hl)			
		ld		(BobWidth),a
		ld 		(LineDelta),a
		xor 	a
		ld 		(LineDelta+1),a
		inc		hl
		ld		a,(hl)			
		ld		(BobHeight),a
		inc		hl
		ld 		a,(hl)
		ld 		(BobSize),a
		inc		hl
		ld 		a,(hl)
		ld 		(BobSize+1),a
		inc 	hl
		ld 		(CurrentScanline),hl			; base of actual graphic data

		;ld		a,h
		;cp		$60
		;jr		c,@LessThan
		;break
;@LessThan:
		; do basic CLIP here....

		; Flip sprite?
		;jp 	@DontFlip
		ld 		a,(BobFlags)
		and 	4
TestFlip
		;jp		@DontFlip
		;ret 	nz		
		jr		z,@DontFlip

		ld		hl,(CurrentScanline)	; Move to END of bob
		ld 		bc,(BobSize)			; Start address of graphic + size
		ld		a,h
		sub		Hi(DRAW_BASE)			; remove bank base address
		ld		h,a
		xor		a
		add 	hl,bc
		adc		a,0						; if we have a huge sprite... it's over 64k in size.
		and		a						; clc
		ld 		bc,(LineDelta)			; Now subtract off a line
		sbc 	hl,bc
		sbc		0
		srl		a						; 0-> >>1 ->C
		ld		a,h						
		rra								; C-> >>1 -> C
		swapnib
		and		$f						; get bank offset from start of graphic
		ld		c,a
		ld		a,(BobBank)				; add on base of bob
		add		a,c
		ld		(BobBank),a
		NextReg	DRAW_BANK,a
		inc		a
		NextReg	DRAW_BANK+1,a
		ld		a,h						; Now work out address in new bank
		and		$1f
		add		a,Hi(DRAW_BASE)
		ld		h,a
		ld 		(CurrentScanLine),hl

		ld 		a,(BobWidth)			; negate length of line so we go backwards
		neg
		ld 		(LineDelta),a
		ld 		a,255
		ld 		(LineDelta+1),a

@DontFlip:


		; Now draw the sprite
@DrawYLoop:
		ld		a,(BobYcoord)
		inc		a
		ld		(BobYCoord),a
		cp 		161									; +1 for prev line
		jr		c,@DontClipLine
		jp		@ClipLine
@DontClipLine:
		push	af
		
		; copy scanline to temp buffer
		ld		hl,(CurrentScanline)
		ld		a,(BobBank)
		NextReg	DRAW_BANK,a
		inc		a
		NextReg	DRAW_BANK+1,a
		

		ld		de,GraphicsBuffer		; ideally... we don't want a copy each line...
		ld		bc,(BobWidth)
		ldir 

		pop		af						; get BobYCoord coordinate back
		; get "bank" to draw scanline into
		dec		a						; back to current line
		push 	af
		and		3						; 4 lines per bank (2048 bytes per line in an 8K bank)
		add		a,a
		add		a,a						; *8 as one line = 2048 = $800 (high byte of *8)
		add		a,a
		or		Hi(DRAW_BASE)			; add on base address of bank
		ld 		d,a 					; get Y (line offset into bank) into D
		ld		e,0

		pop 	af						; get Y coord and work out bank
		srl 	a
		srl 	a 						; Y/4 = bank number (0 to 40)
		add		a,LevelBitmapBank		; add on the base of the level
		NextReg	DRAW_BANK,a				; only need one bank, as we're doing a single scanline (4 scanlines per bank)


		ld		hl,(BobXcoord)
		add 	hl,de
		ex		de,hl					; de = dest address

		ld 		hl,GraphicsBuffer		; Copied scanline
		ld 		a,(BobWidth)
		ld 		c,a

		ld 		a,(BobFlags)
		and 	a
		jr 		z,@NormalRender
		bit 	3,a
		jr 		nz,@Overwrite
		bit 	1,a
		jr 		nz,@RemoveBackground
		jr 		@NormalRender


; Remove the shape front the background
@RemoveBackground:
		xor 	a
@RenderLoop3:	ld 	a,(hl)
		cp		$e3
		jr 		z,@SkipWipe
		xor		a
		ld 		(de),a
@SkipWipe:	
		inc 	de
		inc 	hl
		dec 	c
		jr 		nz,@RenderLoop3
		jr 		@NextLine



; ---------------------------------------
; behind the background render
; ---------------------------------------
@Overwrite:
@RenderLoop2:	
		ld		a,(de)
		and 	a
		jr 		nz,@SkipByte
		ld		a,$e3		
		ldix				; A already 0.
		xor		a
		cp 		c
		jr 		nz,@RenderLoop2
		jr 		@NextLine
@SkipByte:	
		inc 	hl
		inc 	de
		dec 	c
		jr 		nz,@RenderLoop2
		jr 		@NextLine



; ---------------------------------------
; normal sprite render
; ---------------------------------------
@NormalRender:
		ld		b,0
		;ld		c,255
		ld		a,$e3
@RenderLoop:	
		ldirx
		;djnz	@RenderLoop
		;xor		a
		;cp 		c
		;jr 		nz,@RenderLoop



; ---------------------------------------
; Next line....
; ---------------------------------------
@NextLine:
@ClipLine:
		ld 		hl,(CurrentScanline)	; base of actual graphic data
		ld 		bc,(LineDelta)
		bit		7,b
		jr		z,@PositiveAdd

		add 	hl,bc
		ld		a,h
		cp		Hi(DRAW_BASE)
		jp		nc,@NoBankChange

		ld		a,(BobBank)
		dec		a
		ld		(BobBank),a
		ld		a,h
		and		$1f
		add		a,Hi(DRAW_BASE)
		ld		h,a	
		jr		@NoBankChange


@PositiveAdd:
		add 	hl,bc
		ld		a,h
		sub		Hi(DRAW_BASE)
		and		$e0
		jp		z,@NoBankChange
		swapnib
		srl		a
		ld		c,a
		ld		a,(BobBank)
		add		a,c
		ld		(BobBank),a
		ld		a,h
		and		$1f
		add		a,Hi(DRAW_BASE)
		ld		h,a		
@NoBankChange:
		ld 		(CurrentScanline),hl
		


		ld 		a,(BobHeight)
		dec 	a
		ld 		(BobHeight),a
		ret 	z
		jp		@DrawYLoop



bobgraphic	dw 	0

; ************************************************************************
;
;	Draw sprites upto 70x255 in size offsetting by the level position
;
;	hl = sprite number (354 lemmings...)
;	bc = X (0-1600)
;	de  = Y
; 	a  = flags;		
;		$40 = inside
;		$80 = behind
;	Bank = base of graphics
; 
; ************************************************************************
DrawLevelBob:
		;ld		hl,(LemFrameTest)
		;ld		bc,$300

		; offset by level offset
		push	af
		push	bc
		exx
		pop		hl
		ld		bc,(ScrollIndex)	; 20
		xor		a					; clear carry
		sbc		hl,bc			; subtract world location
		push	hl
		exx
		pop		bc
		pop		af


; ************************************************************************
;
;	Draw sprites upto 70x255 in size 
;
;	hl = sprite number 
;	bc = X (0-1600)
;	de  = Y
; 	a  = flags
;		2 = remove terrain
;		4 = upside down
;		$80 = behind
;	Bank = base of graphics
; 
; ************************************************************************
DrawBob:

		;ld	hl,(LemFrameTest)
		;ld	bc,$80

		ld 		(BobFlags),a
		ld		(BobDrawAll+1),a
		ld		(BobXcoord),bc
		ld		(BobYcoord),de
		ld 		a,ObjectsBank
		NextReg	DRAW_BANK,a

		; get base of "bob"
		ld		de,DRAW_BASE			; base of "bank" (and sprite table offsets)
		add		hl,hl					; *4
		add		hl,hl
		add		hl,de

		ld		e,(hl)					; read the bank offset
		inc		hl
		ld 		d,(hl)					; de = bank offset (has $40 already ORd in)
		inc		hl		
		ld		(BobBankOffset),de 		; save bank offset
		

		; This can be optimised out once we know where it's going to live....
		ld 		c,ObjectsBank			; base bank
		ld		a,(hl)					; bank offset is already in 8K sizes
		add		a,c						; add bank offset to base bank
		ld		(BobBank),a
		NextReg	DRAW_BANK,a				; page in BOB graphic
		inc		a
		NextReg	DRAW_BANK+1,a			; page in BOB graphic

		;
		; Now read sprite details
		;
		ld		a,(de)					; x offset
		;ld		(BobXoff),a
		ld		hl,(BobXcoord)
		add		hl,a					; add x offset
		ld		(BobXcoord),hl

		inc		de
		ld		a,(de)					; y offset
		ld		(BobYoff),a
		ld		hl,(BobYcoord)
		add		hl,a
		ld		(BobYcoord),hl

		inc		de						; 6
		ld		a,(de)					; width
		ld		(BobWidth),a
		ld		c,a
		ld		b,0

		inc		de
		ld		a,(de)					; height
		ld		(BobHeight),a
		inc		de
		ld		a,(de)					; size in byte
		ld		(BobSize),a
		inc		de
		ld		a,(de)					; size in byte
		ld		(BobSize+1),a
		inc		de
		ex		de,hl					; base of sprite data in HL
		ld		(bobgraphic),hl


		xor		a						; clear src modulo
		ld		(SourceModulo+2),a
		ld		(SourceModulo+3),a
		;
		; do clipping
		;
ClipLeft		
		ld		hl,(BobXcoord)
		ld		a,h
		test	$80						; if not negative, then not clipped
		jr		z,TestRightClip
		add		hl,bc					; add on width
		ld		a,h
		test	$80						; still negative?
		ret		nz						; still <0 then exit
		ld		a,l						; the value over 0 is the new width
		ld		(BobWidth),a
		ld		a,(BobXcoord)			; get pixels behind 0
		neg
		ld		(SourceModulo+2),a		; set source modulo
		ld		hl,(bobgraphic)
		add		hl,a
		ld		(bobgraphic),hl
		ld		hl,0					; set "X" coord

TestRightClip:
		ld		(BobXcoord),hl

		ld		a,h						; get X MSByte
		and		a
		ret		nz						; if X>=256 then fully clipped
		ld		a,(BobWidth)			; is right edge clipped?
		add		hl,a
		ld		a,h						; if h still == 0 then not off right
		and		a
		jr		z,@NoClip				;
		ld		a,(BobWidth)
		sub		l						; if off right, then L = number of pixels over
		ld		(BobWidth),a			; store new width		
		ld		a,(SourceModulo+2)
		add		a,l
		ld		(SourceModulo+2),a
@NoClip:
		ld		a,(BobXcoord)
		ld		e,a
		ld		a,(BobYcoord)
		ld		d,a
		;ld	d,$21

;		ld	de,$2160					; y,x

		ld		a,d						; $1fff = bank offset
		swapnib
		and		$0e
		srl		a						; get bank  (top p3 bits)
		ld		c,a
		ld		a,(Screen2Bank)			; bank screen into top block
		add		a,a
		add		a,c		
		NextReg	L2_BANK,a
		inc		a
		NextReg	L2_BANK+1,a
		dec		a
		ex		af,af'					; af' holds current bank
		ld		a,d
		and		$1f
		;or		Hi(L2_BASE)				; currently this is $0000
		ld		d,a


		;de = screen bank offset
		ld		hl,(bobgraphic)


		; Draw bob (normal)
		push	hl
		ld		a,(BobWidth)
		ld		c,a
		ld		b,0
		ld		hl,$100
		and		a
		sbc		hl,bc
		ld		(DestModulo+2),hl
		pop		hl

		ld		c,a
		ld		a,70 
		sub		c
		add		a,a						; 2 byte opcode
		ld		bc,BobRenderTower
		add		bc,a
		ld		(BobJmpOffset+1),bc
		ld		a,(BobHeight)
		ld		b,a
BobDrawAll:
		ld		a,$00
		bit		7,a
		jp		nz,RenderBehind
		bit		6,a
		jp		nz,RenderInside


		;jp	RenderInside
		ld		c,$ff					; dummy counter - will never overflow into B
		ld		a,$e3		
BobJmpOffset	
		jp		$1234
		
BobRenderTower	LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX		
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX
		LDIX



NextBobLine:
DestModulo	
		add		de,$0000
SourceModulo	
		add		hl,$0000
		ld		a,d
		bit		5,a								; cross out of the dest bank? ($6000-$7fff)
		jr		z,@NoBankChange		
		and		$1f
		;add		Hi(L2_BASE)					; currently $0000
		ld		d,a
		ex		af,af'							; get bank and increment
		inc		a
		NextReg	L2_BANK,a
		inc		a
		NextReg	L2_BANK+1,a
		dec		a		
		ex		af,af'							; and store it again....
@NoBankChange:
		dec		b
		jp		nz,BobDrawAll


		NextReg	L2_BANK,255
		NextReg	L2_BANK+1,255
		ret




; ------------------------------------------------------------------------------------------------------------
;
;	Render behind the background
;
RenderBehind:
		ld		a,(BobWidth)
		and		a
		ret		z
		push	bc
		ld		b,a
		ld		c,$ff
@DoAll:


		ld		a,(de)
		and		a
		jp		z,@DrawByte
		inc		de					; 
		inc		hl					; 20Ts when not drawing
		jp		@SkipLDIX
@DrawByte:
		ld		a,$e3				; 7
		ldix						; 16 = 23 when drawing
@SkipLDIX:


		djnz	@DoAll		
		pop		bc
		jp		NextBobLine



; ------------------------------------------------------------------------------------------------------------
;
;	Render inside the background
;
RenderInside:	
		ld		a,(BobWidth)
		and		a
		ret		z					; nothing to draw....
		push	bc

		ld		b,a
		ld		c,$ff


@DoAll:
		ld		a,(de)				; 7
		and		a					; 4
		jp		nz,@DrawByte		; 10
		inc		de					; 
		inc		hl					; 20Ts when not drawing
		jp		@SkipLDIX
@DrawByte:
		ld		a,$e3				; 7  (23Ts when drawing)
		ldix						; 16 = 44
@SkipLDIX:


		djnz	@DoAll				; 13/8
		pop		bc
		jp		NextBobLine





; ************************************************************************
;
;	Using a mask, remove a sprite shape from the background level
;
;	hl = mask pointer
;	bc = X (0-1600)
;	de  = Y
; 
; ************************************************************************
ClearBoblevel:		
		ld		a,(hl)				; get width
		ld		(MaskWidth),a
		inc		hl
		ld		a,(hl)
		ld		(MaskHeight),a
		inc		hl

		exx
		ld		a,(Maskheight)
		ld		b,a
@HeightLoop:	
		exx
		ld		(MaskAddress),hl	; store current Mask pointer

		ld		a,d					; Y negative? clip it
		and		a
		jr		nz,@Nextline
		ld		a,e
		cp		160
		ret		nc					; past panel area, clip - JUST STOP

		srl		a					; /4 to get BANK
		srl		a
		add		a,LevelBitmapBank	; add on base bank
		NextReg	DRAW_BANK,a
		ld		a,e					; get Y pos
		and		3
		add		a,a					; 1 line = $08
		add		a,a
		add		a,a
		add		a,Hi(DRAW_BASE)		; base of bank
		ld		h,a
		ld		l,0
		add		hl,bc				; add on X coord


		;
		; Main plotting loop
		;
		push	bc
		push	de
		ld		a,(MaskWidth)
		ld		b,a
		ld		de,(MaskAddress)

@WipeAll:	
		ld		a,(de)
		and		a
		jp		nz,@DontWipe
		ld		(hl),a
@DontWipe:	
		inc		hl
		inc		de
		djnz	@WipeAll

		pop		de
		pop		bc


@NextLine
		ld		hl,(MaskAddress)
		ld		a,(MaskWidth)
		add		hl,a
		inc		de						; y++


		exx	
		djnz	@HeightLoop
		ret


; ************************************************************************
;
;	Draw a small sprite into the level (simple)
;
;	hl = mask pointer
;	bc = X (0-1600)
;	de  = Y
; 
; ************************************************************************
RenderBoblevel:		
		ld		a,(hl)				; get width
		ld		(MaskWidth),a
		inc		hl
		ld		a,(hl)
		ld		(MaskHeight),a
		inc		hl


		exx
		ld		a,(Maskheight)
		ld		b,a
@HeightLoop:	
		exx
		ld		(MaskAddress),hl	; store current Mask pointer

		ld		a,d					; Y negative? clip it
		and		a
		jr		nz,@Nextline
		ld		a,e
		cp		160
		ret		nc					; past panel area, clip - JUST STOP

		srl		a					; /4 to get BANK
		srl		a
		add		a,LevelBitmapBank	; add on base bank
		NextReg	DRAW_BANK,a
		ld		a,e					; get Y pos
		and		3
		add		a,a					; 1 line = $08
		add		a,a
		add		a,a
		add		a,Hi(DRAW_BASE)		; base of bank
		ld		h,a
		ld		l,0
		add		hl,bc				; add on X coord


		;
		; Main plotting loop
		;
		push	bc
		push	de
		ld		a,(MaskWidth)
		ld		b,a
		ld		de,(MaskAddress)

@WipeAll:	
		ld		a,(de)
		ld		(hl),a
@DontWipe:
		inc		hl
		inc		de
		djnz	@WipeAll

		pop		de
		pop		bc


@NextLine
		ld		hl,(MaskAddress)
		ld		a,(MaskWidth)
		add		hl,a
		inc		de			; y++


		exx	
		djnz	@HeightLoop
		ret


MaskWidth	db	0
MaskHeight	db	0
MaskAddress	dw	0

