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
		ld 	a,LevelBitmapBank
@CopyLoop:
		call 	SetBank
		push 	af

		xor 	a
		ld 	hl,$c000
		ld 	(hl),a
		ld 	bc,16383
		ld 	de,$c001
		ldir

		pop	af
		inc 	a
		cp 	LevelBitmapBank+20
		jr 	nz,@CopyLoop
		ret


; ************************************************************************
;
;	Function:	Level is loaded into several banks
;
; ************************************************************************
LoadLevelBitmap:
		call	GetSetDrive		; get drive we're going to....

		ld	a,(hl)			; get size (2048*160 = 327,680 = 320k)
		ld	(file_size),a
		inc	hl
		ld	a,(hl)
		ld	(file_size+1),a
		inc	hl
		ld	a,(hl)
		ld	(file_size+2),a
		inc	hl

		push	hl			; get name into IX
		pop	ix
		ld      b,FA_READ		; read mode
		call	fOpen			; open file
		jr	c,@ErrorOpening		; error?
		ld	(filehandle),a		; remember file handle

		ld	a,LevelBitmapBank	; first bank
@LoadAll:	call	SetBank
		push	af


		; read a block into the 1st bank
		ld	a,(filehandle)	
		ld	bc,2048*8		; load in 8 lines worth (16K exactly)
		ld	ix,LevelBitmapAddress	; read into bank at top of RAM
		call	fread
		jr	c,@ReadError
		

		pop	af			; get bank back
		inc	a			; next one
		cp	LevelBitmapBank+20
		jp	nz,@LoadAll

@EndLoad:
		ld	a,(filehandle)
		call	fClose

		push	af
		xor	a
		call	SetBank		; restore bank
		pop	af
		ret			; even if error, return. A holds error code



@ReadError:	push	af		; keep error code
		call	ResetBank
		pop	af

		pop	de		; throw away old AF
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
                xor	a			; clear carry
                sbc     hl,bc
@notpressed:
                ld      a,(Keys+VK_X)
                and     a
                jr      z,@notpressed2
                add	hl,bc
@notpressed2:
		ld      (ScrollIndex),hl
		jp	@SkipMouse


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
@NoLeft         ld      (ScrollIndex),hl
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
;port 107=datagear / port 11=MB02+
Z80DMAPORT	equ 107
SPECDRUM        equ 0ffdfh
CopyScreen:
		ld	a,$3+8			; $10-Layer1 over, 8-Layer2_2 write, 2-screen on, 1-Page in RAM, bank 0 of screen (3 banks in total)
		ld	(VRAMBank),a
		ld	bc,$123b
		out	(c),a

		ld	bc,240
		ld	(DMALen),bc

		ld	bc,LevelBitmapAddress
		add	hl,bc

		ld	de,8			; start at top of VRAM bank
		ld	a,LevelBitmapBank*2	; 20 banks to loop through
@CopyLoop:
		mmu6
		inc	a
		mmu7
		inc	a
		;call	SetBank			; 8 lines per bank
		push	af
		push	hl

		ld	b,8			; 8 lines per bank

		
@Copy8Lines:	push	bc

if USE_DMA=1

	; transfer the DMA "program"
		ld	(DMASrc),hl		; 16
		ld	(DMADest),de		; 20
		push	hl			; 11
		ld	hl,DMACopy 		; 10
		ld	bc,DMASIZE*256 + Z80DMAPORT	; 10
		otir				; 21*20  + 240*4
		pop	hl			; 10 = 1457
		ld	bc,2048			; 		offset to move to NEXT line in level bitmap



else
;		; copy a whole row (240 pixels)
		ld	c,255			; 7
		ldi				; 240*16
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
		ld	bc,2048-(256-16)	; offset to move to NEXT line in level bitmap
endif
		add	hl,bc			; move there
		ex	de,hl
if USE_DMA=1
		ld	bc,$100		;16	;$100			;16
else
		ld	bc,16		;16	;$100			;16
endif
		add	hl,bc
		ex	de,hl
		pop	bc			; get 8 line counter back	
		dec	b
		jr	z,@finishloop
		jp	@Copy8Lines
@finishloop
		ld	a,d			; overflowed the lower 16K?
		and	$c0			; if so we need to change bank
		jr	z,@SkipBankSwap
		ld	d,0

		ld	a,(VRAMBank)		; get current bank
		add	$40			; next one
		ld	(VRAMBank),a
		ld	bc,$123b		; set VRAM bank
		out	(c),a
@SkipBankSwap:
		pop	hl			; get back to start of bank
		pop	af
		cp	LevelBitmapBank*2+40
		jr	z,@FinishCopyLoop
		jp	@CopyLoop
@FinishCopyLoop:

		; leave screen on...
		ld	bc,$123b
		ld	a,$12
		out	(c),a

		call	ResetBank
		ret

VRAMBank	db	0
BankCount	db	0




DMACopy
	db $C3			;R6-RESET DMA
	db $C7			;R6-RESET PORT A Timing
        db $CB			;R6-SET PORT B Timing same as PORT A

        db $7D 			;R0-Transfer mode, A -> B
DMASrc  dw $1234		;R0-Port A, Start address				(source address)
DMALen	dw 240			;R0-Block length					(length in bytes)

        db $54 			;R1-Port A address incrementing, variable timing
        db $02			;R1-Cycle length port A
		  
        db $50			;R2-Port B address fixed, variable timing
        db $02 			;R2-Cycle length port B
		  
        ;db $C0			;R3-DMA Enabled, Interrupt disabled

	db $AD 			;R4-Continuous mode  (use this for block tansfer)
DMADest	dw $4000		;R4-Dest address					(destination address)
		  
	db $82			;R5-Restart on end of block, RDY active LOW
	 
	db $CF			;R6-Load
	db $B3			;R6-Force Ready
	db $87			;R6-Enable DMA
ENDDMA

DMASIZE      equ ENDDMA-DMACOPY




