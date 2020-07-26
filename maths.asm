
; ****************************************************************************************
; multiplication of two 16-bit numbers into a 32-bit product
;
; enter : de = 16-bit multiplicand = y
;         hl = 16-bit multiplicand = x
;
; exit  : hlde = 32-bit product
;         carry reset
;
; uses  : af, bc, de, hl
; ****************************************************************************************
Mul_16x16:
	ld		b,l                 ; x0
	ld		c,e                 ; y0
	ld		e,l                 ; x0
	ld		l,d
	push	hl                  ; x1 y1
	ld		l,c                 ; y0

	; bc = x0 y0
	; de = y1 x0
	; hl = x1 y0
	; stack = x1 y1

	mul	                      	; y1*x0
	ex		de,hl
	mul                       	; x1*y0

	xor		a                   ; zero A
	add		hl,de               ; sum cross products p2 p1
	adc		a,a                 ; capture carry p3

	ld		e,c                 ; x0
	ld		d,b                 ; y0
	mul                       	; y0*x0

	ld		b,a                 ; carry from cross products
	ld		c,h                 ; LSB of MSW from cross products

	ld		a,d
	add		a,l
	ld		h,a
	ld		l,e                 ; LSW in HL p1 p0

	pop		de
	mul                       	; x1*y1

	ex		de,hl
	adc		hl,bc
	ret


; ****************************************************************************************
; multiplication of two 24-bit by numbers into a 32-bit product
;
; enter : hbc = 16-bit multiplicand = y
;           l = 8-bit multiplicand = x
;
; exit  : hlde = 32-bit product
;         carry reset
;
;	l*h<<16 + l*b<<8 + l*c
; uses  : af, bc, de, hl
; ****************************************************************************************
SMul_24x8:
	bit		7,h
	push	af
	jr		z,@NotNegative
	NEG_HBC
@NotNegative:


	ld		e,l	;l*h<<16
	ld		d,h
	mul
	push	de	; de = answer
	ld		e,l
	ld		d,b	; l*b<<8
	mul
	push	de	; de = answer
	ld		e,l
	ld		d,c	; l*c
	mul

	xor		a
	ex		de,hl	; hl = l*c
	pop		bc	; bc = l*b
	;pop	de	; de = l*h


	; Now add  00hl
	;          0bc0
	;          de00
	xor		a
	ld		d,c
	ld		e,a
	add		hl,de
	pop		de	; de=l*h
	push	hl	; save low answer

	ex		de,hl	; de=l*h
	ld		c,b
	ld		b,a
	adc		hl,bc
	pop		de

	pop		af
	ret		z
	NEG_HLDE
	ret




; ****************************************************************************************
; multiplication of two 16-bit numbers into a 32-bit product
;
; enter : de = signed 15-bit multiplicand = y
;         hl = signed 15-bit multiplicand = x
;
; exit  : dehl = siged 31-bit product
;
; ****************************************************************************************
SMul_16x16:
	SMul_16x16_macro
	ret





; ****************************************************************************************
;
; hlix >= $ 01 00 00 00
;   bc >= $       01 00
;
; hlix = answer
; de   = remainder
;
; ****************************************************************************************
Div_32x16
	ld 		de,0  			; 10
	ld 		a,32  			; 7
div32_16loop:
	add		ix,ix  			; 15
	adc		hl,hl  			; 15
	ex		de,hl  			; 4
	adc		hl,hl  			; 15
	or 		a   			; 4
	sbc 	hl,bc  			; 15
	inc 	ix   			; 10
	jr 		nc,@cansub  	; 12/7
	add 	hl,bc  			; 11
	dec 	ix  			; 10
@cansub:
	ex 		de,hl  			; 4
	dec 	a   			; 4
	jr 		nz,div32_16loop ; 12/7
	ret   					; 10



SDiv_32x16
	ld		a,h
	xor		b
	and		$80
	push	af				; negate on return?
	bit		7,b				; negate de?
	jr		z,@NotNegDE
	NEG_BC
@NotNegDE:
	bit		7,h				; negate hl?
	jr		z,@NotNegHL
	NEG_HLIX
@NotNegHL:
	call	Div_32x16
	pop		af
	ret		z
	NEG_HLIX
	ret



