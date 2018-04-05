; ************************************************************************
;
;  reg 21
;     bit 4-2  - Layer order.
; 	ULS
; 	USL
; 	SUL
; 	SLU
; 	LUS
; 	LSU
; Function:	Init the sprite manager
;
; sprite_x	ds	64
; sprite_y	ds	64
; sprite_flags	ds	64
; sprite_shape	ds	64
;
; ************************************************************************
InitSprites:
		call	ClearSprites

		ret


ClearSprites:
		ld	hl,sprite_x
		ld	de,sprite_x+1
		ld	bc,255
		xor	a
		ld	(hl),a
		ldir
		ret



; ************************************************************************
;
; Function:	SetSpriteBank
;
; ************************************************************************


; ************************************************************************
;
; Function:	Set sprites from the "current" sprite bank
;
; ************************************************************************
SetSprites:	
		ld	bc,$303b		; set sprite 0 as first
		ld	a,0
		out	(c),a
		ld	de,-$2ff

		ld	hl,sprite_x		; base of sprite data
		ld	b,8
@UploadAll:	
		; now upload
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		add	hl,de
		

		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		add	hl,de

		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		add	hl,de

		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		add	hl,de

		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		add	hl,de

		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		add	hl,de

		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		add	hl,de

		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		inc	h
		ld	a,(hl)
		out	(SpriteReg),a
		add	hl,de

		dec	b
		ret	z
		jp	@UploadAll
		ret


