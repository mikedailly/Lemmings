; ************************************************************************
;
;	Function:	Init the map. Load files and reset the scroll
;
; ************************************************************************
InitLevel:
		; load data first...
		;ld	hl,level1
		;call	LoadLevelBitmap
		call 	ClearLevelBitmap
		;call	ResetLevel
		ret

; ************************************************************************
;
;	Function:	Level is loaded into several banks
;
; ************************************************************************
ClearLevelBitmap:
		ld 		a,LevelBitmapBank
@CopyLoop:
		NextReg	DRAW_BANK,a
		inc		a
		NextReg	DRAW_BANK+1,a
		push 	af

		xor 	a
		ld		hl,DRAW_BASE
		ld		(hl),a
		ld		bc,16383
		ld		de,DRAW_BASE+1
		ldir

		pop		af
		inc 	a
		cp 		LevelBitmapBank+40
		jr 		nz,@CopyLoop
		ret


; ************************************************************************
;
;	Function:	Level is loaded into several banks
;
; ************************************************************************
LoadLevelBitmap:
		call	GetSetDrive		; get drive we're going to....

		ld		a,(hl)				; get size (2048*160 = 327,680 = 320k)
		ld		(file_size),a
		inc		hl
		ld		a,(hl)
		ld		(file_size+1),a
		inc		hl
		ld		a,(hl)
		ld		(file_size+2),a
		inc		hl

		push	hl			;	 get name into IX
		pop		ix
		ld      b,FA_READ		; read mode
		call	fOpen			; open file
		jr		c,@ErrorOpening		; error?
		ld		(filehandle),a		; remember file handle

		ld		a,LevelBitmapBank	; first bank
@LoadAll:	
		NextReg	DRAW_BANK,a
		inc		a
		NextReg	DRAW_BANK+1,a
		push	af


		; read a block into the 1st bank
		ld		a,(filehandle)	
		ld		bc,2048*8		; load in 8 lines worth (16K exactly)
		ld		ix,LevelBitmapAddress	; read into bank at top of RAM
		call	fread
		jr		c,@ReadError
		

		pop		af			; get bank back
		inc		a			; next one
		cp		LevelBitmapBank+20
		jp		nz,@LoadAll

@EndLoad:
		ld		a,(filehandle)
		call	fClose

		ret			; even if error, return. A holds error code



@ReadError:	
		pop		de		; throw away old AF
		ret

@ErrorOpening:	ret			; return with error code



; ************************************************************************
;
;	Function:	Reset the scroll back to the start
;
; ************************************************************************
;ResetLevel:
		ld	hl,0				; Set current position
		ld	(ScrollIndex),hl
		call	CopyScreen
		ret		


; ************************************************************************
; Function:	Handle the scrolling and display the map
; ************************************************************************
DisplayMap:              
		ld      hl,(ScrollIndex)
		ld      bc,8    

		ld      a,(Keys+VK_Z)
		and     a
		jr      z,@notpressed
		xor		a						; clear carry
		sbc     hl,bc
@notpressed:
		ld      a,(Keys+VK_X)
		and     a
		jr      z,@notpressed2
		add		hl,bc
@notpressed2:
		ld      (ScrollIndex),hl
		jp		@SkipMouse


		; scroll maps
		ld      hl,(ScrollIndex)
		ld      bc,8    
		ld      a,(MouseX)
		cp      255-8
		jr      c,@NoRight
		add     hl,bc
@NoRight
		ld      a,(MouseX)
		cp      8
		jr      nc,@NoLeft
		sbc     hl,bc
@NoLeft	
		ld      (ScrollIndex),hl
@SkipMouse:
		;
		; Fall through.....
		;

; ************************************************************************
;
; Function:	Copy a whole screens with of map onto Layer 2
;
; In:		hl  =  pixel column to draw - index into the map (0-1791)
;
; ************************************************************************
CopyScreen:
		; $01 = enable mapping for writes
		; $02 = enable layer 2 display
		; $08 = to map active layer 2 (nextreg 0x12), 1 to map shadow layer 2 (nextreg 0x13)
		ld		a,1+2+8 
		ld		(VRAMBank),a
		ld		bc,$123b
		out		(c),a

		add		hl,LevelBitmapAddress

		ld		de,8					; start at top of VRAM bank
		ld		a,LevelBitmapBank		; 20 banks to loop through
@CopyLoop:
		NextReg	DRAW_BANK,a
		inc		a
		NextReg	DRAW_BANK+1,a
		inc		a
		;ex		af,af'		; remember bank
		push	af
		push	hl
		ld		b,8			; 8 lines per bank

		
@Copy8Lines:	
		ld		c,255
		;push	bc

;		; copy a whole row (240 pixels)
		ldi					; 240*16
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi
		ldi

		add		hl,2048-(256-16)		; offset to move to NEXT line in level bitmap
		ld		a,16					; 15ts
		add		de,a

		;pop		bc					; get 8 line counter back	
		dec		b
		jr		z,@finishloop
		jp		@Copy8Lines
@finishloop
		ld		a,d						; overflowed the lower 16K?
		and		Hi(DRAW_BASE)			; if so we need to change bank (will increment above $4000)
		jr		z,@SkipBankSwap
		ld		d,0

		ld		a,(VRAMBank)		; get current VRAM bank
		add		$40					; next one
		ld		(VRAMBank),a
		ld		bc,$123b			; set VRAM bank
		out		(c),a

@SkipBankSwap:
		pop		hl					; get back to start of bank
		pop		af
		cp		LevelBitmapBank+40
		jp		nz,@CopyLoop

		; leave screen on...
		ld	bc,$123b
		ld	a,$02+8
		out	(c),a
		ret

VRAMBank	db	0
BankCount	db	0







