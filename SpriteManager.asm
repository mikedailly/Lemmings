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
;
; ************************************************************************
InitSprites:
		xor	a
		ld	bc,$303b
		ld	a,0
		out	(c),a

		ld	b,64
@WipeSprites:	out	(SpriteReg),a
		out	(SpriteReg),a
		out	(SpriteReg),a
		out	(SpriteReg),a
		djnz	@WipeSprites

		ret

