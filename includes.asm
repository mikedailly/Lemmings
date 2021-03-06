; ************************************************************************
;
;	General equates and macros
;

DRAW_BANK				equ		$52
DRAW_BASE				equ		$4000

L2_BANK					equ		$50
L2_BASE					equ		$0000

USE_COPPER				equ		0
NextInstructions        equ     1

TBBLUE_REGISTER_SELECT	equ		$243b
SPRITE_CONTROL_REGISTER	equ		$15
CLIP_ULA_REGISTER		equ		$1a
CLIP_LAYER2_REGISTER	equ		$19
CLIP_SPRITE_REGISTER	equ		$18




; Set the border - used on start up to help debugging
BORDER		macro	
			ld		a,\0
			out		($fe),a
			endm

BREAK		macro
			db		$DD,$01
			endm

; hardware/registers
SpriteReg				equ	$57
SpriteShape				equ	$5b
Kempston_Mouse_Buttons	equ	$fadf
Kempston_Mouse_X		equ	$fbdf
Kempston_Mouse_Y		equ	$ffdf
Mouse_LB				equ	1			; 0 = pressed
Mouse_RB				equ	2
Mouse_MB				equ	4
Mouse_Wheel				equ	$f0



;
; Memory map
;
; $000000-$007FFF -  general (paging area)  (4 banks)
; $008000-$00FFFF -  game code (banks 0 and 1)
; $010000-$024000 -  Rest of 128K normal specturm RAM
; $024000-$03C000 -  Layer 2 double buffered screen. (banks 8,9,10  and 11,12,13)
; $03C000-$040000 -  Panel graphic  (bank $f)
; $040000-$048000 -  Lemmings sprites	(bank $10,$11)
; $048000-$050000 -  ***SPARE***
; $050000-$0A0000 -  2048x160 level bitmap (bank $14-$27)
;
;

;
;
; 1MB RAM (only 640K...) gives 64(40) banks... assume some of these for VRAM
;
; Layer 2 stuff


;		Seg  DataSeg,$8000,$8000
;		Seg  CodeSeg,Code_Bank:$0000,$0000


Code_Bank				equ		4					; 32K of code  (ZX128 banks 6 and 7 - 16k banks)
MixerCode_Bank			equ		12
VRAM_BASE_BANK			equ		8					; 2 layer 2 screens = 12 banks.   (bank 16 in 8K banks)  
LevelBank				equ		28
LevelAddress			equ		DRAW_BASE			; 2K
PanelNumbersBank		equ		28
PanelNumbersAddress		equ		DRAW_BASE+$800		; 400 bytes
PanelBank				equ		30
PanelAddress			equ		DRAW_BASE			; panel is 8K
LevelBitmapBank			equ		32					; level bitmap from bank 16 to 38 (22 banks). Last 2 banks are 0 for falling off the bottom
LevelBitmapAddress		equ		DRAW_BASE
StyleBank 				equ 	76					; start of style data (96K - 6 banks)
StyleBaseAddress 		equ 	DRAW_BASE
ObjectsBank 			equ 	StyleBank+12			; Level objects - load over the top of the styles (80k - 5 banks)
ObjectsBaseAddress 		equ 	DRAW_BASE
LemmingsBank			equ		ObjectsBank+10		; start of lemmings sprites 
LemmingAddress			equ		DRAW_BASE
PointsBank				equ		LemmingsBank+12		; (2 banks)
PointsAddress			equ		DRAW_BASE
CollisionBank			equ		PointsBank+4		; 4x4 array collision map (3 banks)
CollisionAddress		equ		DRAW_BASE+$2000		; (20480 bytes from 24576)
SamplesBank				equ		CollisionBank+3		; Start of sample data
SamplesAddress			equ		DRAW_BASE+$2000		; 
	
MAX_LEM					equ		100
	
LEM_NONE				equ		0
LEM_FALLER				equ		1
LEM_WALKER				equ		2
LEM_SPLATTER			equ		3
LEM_FLOATER				equ		4
LEM_PREFLOATER			equ		5
LEM_BLOCKER				equ		6
LEM_CLIMBER				equ		7
LEM_BOMBER				equ		8
LEM_BUILDER_SHRUG		equ		9
LEM_BUILDER				equ		10
LEM_BASHER				equ		11
LEM_MINER				equ		12
LEM_DIGGER				equ		13
LEM_PREBOMBER			equ		14
	

; used to quickly disguard lemmings for selection
SKILLMASK_CLIMBER		equ		1
SKILLMASK_FLOATER		equ		2
SKILLMASK_BOMBER		equ		4
SKILLMASK_BLOCKER		equ		8
SKILLMASK_BUILDER		equ		16
SKILLMASK_BASHER		equ		32
SKILLMASK_MINER			equ		64
SKILLMASK_DIGGER		equ		128
SKILLMASK_PERMANENT		equ		(SKILLMASK_CLIMBER|SKILLMASK_FLOATER|SKILLMASK_BOMBER)

;
; lemmings structure
;
					rsreset
LemType				rb	1
LemX				rw	1
LemY				rb	1
LemDir				rb	1		; left or right facing
LemFrameBase		rw	1		; keep base,count and offset together
LemFrameCount		rb	1		; so "SetAnim" function is quicker
LemFrameOffX		rb	1
LemFrameOffY		rb	1
LemFrame			rb	1
LemSkillMask		rb	1		; skill mask
LemBombCounter		rb	1
LemBombCounter_Frac	rb	1
LemSkillTemp		rb	9
LemStructSize		rb	0
LemDataSize		equ	LemStructSize*MAX_LEM


	message	"LemSize: ",LemStructSize
	message	"LemTotal: ",LemDataSize

; faller temp variables
LemFallCount		equ	LemSkillTemp



; 354 lemming sprites
; animation frame start
FWalkerR 			equ	0
FWalkerL			equ	8
FFallerR			equ	16
FFallerL			equ	20
FClimberR			equ	24
FClimberL			equ	32
FClimberFlipR		equ	40
FClimberFlipL		equ	48
FFloaterStartR		equ	56
FFloaterR			equ	60	; pingppong
FFloaterStartL		equ	64
FFloaterL			equ	68	; pingpong
FExploder			equ	72	; 16 frames
FSplatter			equ	88	; 16 frames
FBlocker			equ	104	; 16 frames
FDrowner			equ	120	; 16 frames
FFlamer				equ	136	; 14 frames
FExit				equ	150	; 8 frames
FBuilderRight		equ	158	; 16 frames
FBuilderLeft		equ	174	; 16 frames
FShruggerRight		equ	190	; 8 frames
FShruggerLeft		equ	198	; 8 frames
FDigger				equ	206	; 16 frames
FBasherRight		equ	222	; 32 frames
FBasherLeft			equ	254	; 32 frames
FMinerRight			equ	286	; 24 frames
FMinerLeft			equ	310	; 24 frames
FMinerMask			equ	334	; 1 frame
FExplosionMask		equ	335	; 1 frame
FBuilderBrick		equ	348	; 1 frame


FOne				equ	349	; 1 to 5 counter


;
; Object definitaion structure - 
;
				rsreset
Obj_Flags:		rb	1		; various flags
Obj_Anim:		rb	1		; sprite index into the object sprite pool
Obj_FirstFrame:	rb	1		; starting frame of the animation
Obj_Max:		rb	1		; max anim - offset from ObjAnim
Obj_Width:		rb	1		; original sprite width - not cropped width
Obj_Height:		rb	1		; original sprite height - not cropped width
Obj_CollWidth:	rb	1
Obj_CollHeight:	rb	1
Obj_CollType:	rb	1
Obj_Sound		rb	1
Obj_Padding		rb	6
Obj_MaxSize		rb	0		; size of struct
	

LoadFile	macro
		ld	hl,\0
		ld	ix,\1
		call	Load
		endm

; LoadBank File,AddOff,startBank
LoadBank	macro		
		ld	hl,\0
		ld	ix,\1
		ld	a,\2
		call	Load_Bank
		endm

; LoadBanked File,startBank
LoadBanked	macro
		ld 	hl,\0
		ld	a,\1
		call	Load_Banked
		endm

File		macro
		db	Filesize(\0)&$ff		; files can be upto 16MB (streaming level?), 
		db	(Filesize(\0)>>8)&$ff		; this gives 341 screens, or a 16x16 playing area - massive map
		db	(Filesize(\0)>>16)&$ff		; it's also really easy to extend... add another byte, and skip it in the file loading
		;db	"/"
		db	\0
		db	0
		;Message "file='",\0,"'  size=",Filesize(\0)
		endm


		// copper WAIT  VPOS,HPOS
WAIT		macro
		db	HI($8000+(\0&$1ff)+(( (\1/8) &$3f)<<9))
		db	LO($8000+(\0&$1ff)+(( (\1/8) &$3f)<<9))
		endm
		// copper MOVE reg,val
MOVE		macro
		db	HI($0000+((\0&$ff)<<8)+(\1&$ff))
		db	LO($0000+((\0&$ff)<<8)+(\1&$ff))
		endm
CNOP		macro
		db	0,0
		endm



LEMANIM		macro
		dw	\0
		db	\1,\2,\3
		endm



SetLayer2Clip	MACRO 
	        ld a,CLIP_LAYER2_REGISTER
	        ld bc,TBBLUE_REGISTER_SELECT
	        out (c),a
	        inc b
	        out (c),h
	        out (c),d
	        out (c),l
	        out (c),e
        ENDM
;-----------
;   hl = origin x/y
;   de = end x/y
;----------
SetULAClip	MACRO 
	        ld a,CLIP_ULA_REGISTER
	        ld bc,TBBLUE_REGISTER_SELECT
	        out (c),a
	        inc b
	        out (c),h
	        out (c),d
	        out (c),l
	        out (c),e

        ENDM
;-----------
;   hl = origin x/y
;   de = end x/y
;----------
SetSpriteClip	MACRO 
	        ld a,CLIP_SPRITE_REGISTER
	        ld bc,TBBLUE_REGISTER_SELECT	;$243B
	        out (c),a
	        inc b
	        out (c),h
	        out (c),d
	        out (c),l
	        out (c),e
        ENDM



DIVHL	macro		; unsigned (0 in the top)
	srl	h
	rr	l
	endm

SDIVHL	macro		; signed (maintains top bit)
	sra	h	
	rr	l
	endm

DIVDE	macro		; unsigned (0 in the top)
	srl	d
	rr	e
	endm

SDIVDE	macro		; signed (maintains top bit)
	sra	d	
	rr	e
	endm

DIVBC	macro		; unsigned (0 in the top)
	srl	b
	rr	c
	endm

SDIVBC	macro		; signed (maintains top bit)
	sra	b	
	rr	c
	endm



NEG_HL		macro
		xor	a
		sub	l
		ld	l,a
		sbc	a,a
		sub	h
		ld	h,a
		endm
NEG_DE		macro
		xor	a
		sub	e
		ld	e,a
		sbc	a,a
		sub	d
		ld	d,a
		endm
NEG_BC		macro
		xor	a
		sub	c
		ld	c,a
		sbc	a,a
		sub	b
		ld	b,a
		endm
NEG_DEHL	macro
		xor	a	; clear and reset carry
		sub	l
		ld	l,a

		ld	a,0
		sbc	a,h
		ld	h,a

		ld	a,0
		sbc	a,e
		ld	e,a

		ld	a,0
		sbc	a,d
		ld	d,a

		endm

NEG_HLDE	macro
		xor	a	; clear and reset carry
		sub	e
		ld	e,a

		ld	a,0
		sbc	a,d
		ld	d,a

		ld	a,0
		sbc	a,l
		ld	l,a

		ld	a,0
		sbc	a,h
		ld	h,a

		endm		


NEG_HLIX	macro
		xor	a	; clear and reset carry
		sub	ixl
		ld	ixl,a

		ld	a,0
		sbc	a,ixh
		ld	ixh,a

		ld	a,0
		sbc	a,l
		ld	l,a

		ld	a,0
		sbc	a,h
		ld	h,a

		endm	


NEG_HBC		macro
		xor	a	; clear and reset carry
		sub	c
		ld	c,a

		ld	a,0
		sbc	a,b
		ld	b,a

		ld	a,0
		sbc	a,h
		ld	h,a
		endm	


