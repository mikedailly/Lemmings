;
;	Bouncing Mine craft sprites by Jim Bagley, disassembled and added as a test
;
;

; ************************************************************************
;
;	Init sprite shapes, and locations
;
; ************************************************************************
InitSprites:
		; load sprite image data (we overwrite it later)
                LoadFile        SpriteFile, Sprites

		; Upload sprite graphics
                ld      hl, sprites
                ld      a,0               
AllSprites:               
                ; select pattern 2
                ld      bc, $303B
                out     (c),a
                push    af

                ; upload sprite image
                ld      de, 256
                ld      bc, $0055
UpLoadSprite:           
                ;ld      a,(hl)		; 7
                ;out     (c),a		; 12
                ;inc     hl		; 4 = 23                
                outi			; port=(hl), hl++, b--
                inc	b		; 4 = 20

                dec     de
                ld      a,d
                or      e               
                jr      nz, UpLoadSprite

                pop     af
                inc     a
                cp      $40
                jr      nz,AllSprites




	        ld      bc,$243b
	        ld      a,$15
	        out     (c),a
	        ld      bc,$253b
	        ld      a,$01                   ; enable sprites and under border
	        out     (c),a

	        ld      hl,SpriteData   ;$20c9
	        ld      b,$40
	        ld      de,$0000

l0016:  	push    bc  
	        ld      a,r
	        ld      c,a
	        ld      a,(de)
	        inc     de
	        xor     c
	        xor     l
	        and     $3f
	        add     a,$18
	        ld      (hl),a
	        inc     hl
	        ld      b,a
l0026:  	djnz    l0026
	        ld      a,r
	        ld      c,a
	        ld      a,(de)
	        inc     de
	        xor     c
	        xor     l
	        and     $7f
	        add     a,$18
	        ld      (hl),a
	        inc     hl
	        ld      (hl),$01
	        inc     hl
	        pop     bc
	        push    bc
	        push    af
	        ld      a,b
	        and     $0f
	        add     a,a
	        add     a,a
	        add     a,a
	        add     a,a
	        inc     a
	        ld      (hl),a
	        pop     af
	        inc     hl
	        ld      b,a
l0047:  	djnz    l0047
	        ld      a,r
	        and     $07
	        sub     $04
	        ld      (hl),a
	        inc     hl
	        ld      b,a
l0052:  	djnz    l0052
	        ld      a,r
	        and     $07
	        sub     $04
	        ld      (hl),a
	        inc     hl
	        pop     bc
	        djnz    l0016
	        ret



; ************************************************************************
;
;	Init sprite shapes, and locations
;
; ************************************************************************
BounceSprites:
	        ; select sprite 0
	        ld      bc,$303b
	        xor     a
	        out     (c),a


	        ld      h,$40                   ; number of sprites
	        ld      de,$0006                ; size of sprite struct
	        ld      ix,SpriteData           ;$20c9                ; sprite data
	        ld      bc,$0057



        	; move sprites
l0072:  	ld      a,(ix+$00)              ; get x
	        add     a,(ix+$04)           ; get speed
	        ld      (ix+$00),a              ; store new x
	        cp      $08
	        jr      c,l0083
	        cp      $a0     ;84
	        jr      c,l008b
l0083:  	ld      a,(ix+$04)
	        cpl     
	        inc     a
	        ld      (ix+$04),a
l008b:  	ld      a,(ix+$01)              ; get y
	        add     a,(ix+$05)
	        ld      (ix+$01),a              ; store y
	        cp      $08
	        jr      c,l009c
	        cp      $f5     ;a8
	        jr      c,l00a4
l009c:  	ld      a,(ix+$05)
	        cpl     
	        inc     a
	        ld      (ix+$05),a


        	; Setup sprite with new values
l00a4:  	ld      a,(ix+$00)
	        add     a,a
	        out     (c),a                           ; x low

	        ld      a,(ix+$01)                      ; y pos
	        out     (c),a
	                                         
	        xor     a,a                             ; get carry from above add
	        adc     a,$00
	        ld      a,(ix+$00)
	        srl     a
	        srl     a
	        srl     a
	        srl     a
	        srl     a
	        srl     a
	        srl     a
	        out     (c),a                           ; palette, x mirror, y mirror, rotate bit 0 = X MSB

	        ld      a,$40
	        sub     h
	        or      $80
	        out     (c),a                           ; bit 7 visible flag, 5-0 pattern

	        add     ix,de
	        dec     h
	        jr      nz,l0072

	        ret



        

