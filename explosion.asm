; ******************************************************************
; Init the explosion system - mainly loading the points file
; ******************************************************************
Iex
InitExplosion:
		LoadBank	PointsFile,PointsAddress,PointsBank
		


		;Make the points offset ALWAYS positive, offset the orginin by -$80


		; set animation bank
		ld		a,PointsBank
		NextReg	DRAW_BANK,a
		inc		a
		NextReg	DRAW_BANK+1,a

		; offset all points so they are all positive.... (add $80)
		ld		de,DRAW_BASE
		exx
		ld		b,53			; 53 frames
@Loop2:		
		exx
		ld		b,00			; only 80 points, so some redundent values
@Doloop:
		ld		a,(de)
		add		a,$80			; offset by 128
		ld		(de),a
		inc		e
		djnz	@Doloop

		inc		d
		exx
		djnz	@Loop2
		ret




; ******************************************************************
;
; Draw an explosion frame
;
; In:	HL  = X origin
;		E   = Y origin
;		A   = frame
;		
; Notes:	160 bytes per frame (80 points), 256 byte apart.
;			$00 for X = ignore point
;
;
; port $123b
;     bit 0  = WRITE paging on. $0000-$3fff write access goes to selected Layer 2 page 
;     bit 1  = Layer 2 ON (visible)
;     bit 3  = Page in back buffer (reg 19)
;     bit 6/7= VRAM Banking selection (layer 2 uses 3 banks) (0,$40 and $c0 only)
;
; ******************************************************************
expl
DrawExplosionFrame:	
		ld		d,0						; keep 16 bit signed from now on
		add		de,$ff80				; offset origin so all points are positive offsetsd
		ld		(@PointsYOrigin+1),de	; store Y

		ld		de,(ScrollIndex)		; 20
		and		a						; reset carry
		sbc		hl,de					; subtract world location
		add		hl,$ff80				; offset origin
		ld		(@PointsXOrigin+1),hl

		; should probably do a large BBOX clip here...8

		; point to correct frame
		add		a,Hi(DRAW_BASE)
		ld		d,a
		ld		e,0						; DE = frame address (once banked in)

		; set animation bank
		NextReg	DRAW_BANK,PointsBank
		NextReg	DRAW_BANK+1,1+PointsBank


		;
		; Draw all 80 points
		;
		ld		bc,$123b
		exx
		ld		b,80					; number of points to render
		ld		a,%10110110				; pixel colours
		ex		af,af'					; store pixel colour
@AllPoints:
		exx

		ld		a,(de)					; get X offset
		inc		e						; points are 256 byte aligned...
		and		a						; test for 0			
		jr		z,@NextPoint			; if X==$00 then ignore point

@PointsXOrigin:	
		ld		hl,$0000				; get X origin
		add		hl,a					; add positive  X offset to X origin
		ld		a,h
		and		a						; if high byte is NOT 0, then off screen
		jr		nz,@NextPoint			; clip to screen
		ld		a,l
		ld		(@XStore+1),a			; store X


		; now do Y
@PointsYOrigin:	
		ld		hl,$0000				; get Y origin
		ld		a,(de)					; Get Y offset (now positive)
		add		hl,a
		ld		a,h
		and		a						; if high byte is NOT 0, then off screen
		jr		nz,@NextPoint	

		ld		a,l						; get Y
		cp		160						; in panel area?
		jr		nc,@NextPoint
@XStore		
		ld		l,$00					; LOAD "X" (self-mod-code)
		ld 		h,a						; put Y into H


		; select correct bank
		and		$c0
		or		%00001011				; or in Layer 2 on, write on, back buffer on
		out		(c),a

		ld		a,h						; get offset into 16k bank
		and		$3f
		ld		h,a

		ex		af,af'					; get pixel colour
		ld		(hl),a					; store on screen
		rrca							; rotate pixel colour
		ex		af,af'					; store again

		inc		e						; points are 256 byte aligned...
		exx
		djnz	@AllPoints

		exx								; get BC back...
		ld		a,2
		out		(c),a
		ret		

@NextPoint:	
		inc		e						; points are 256 byte aligned...
		ex		af,af'
		rrca
		ex		af,af'
		exx
		djnz	@AllPoints

		exx								; get BC back...
		ld		a,2
		out		(c),a
		ret





