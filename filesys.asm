; 
; Publicly available stuff..........
;
; esxDOS
;       setdrv  xor a
;		rst $08
;		db $89
;		ret
;
;       fopen   ld      b,$01:db 33
;       fcreate ld      b,$0c:push ix:pop hl:ld a,42:rst $08:db $9a:ld (handle),a:ret
;       fread   push ix:pop hl:db 62
;       handle  db 0:or a:ret z:rst $08:db $9d:ret
;       fwrite  push ix:pop hl:ld a,(handle):or a:ret z:rst $08:db $9e:ret
;       fclose  ld      a,(handle):or a:ret z:rst $08:db $9b:ret
;       fseek   ld a,(handle):or a:ret z:rst $08:db $9f:ret
;       // Seek BCDE bytes. A=handle
;       //      L=mode:         0-from start of file
;       //                      1-forward from current position
;       //                      2-back from current position
;       // On return BCDE=current file pointer.
;       // Does not currently return bytes
; 
; 

M_GETSETDRV  equ $89
F_OPEN       equ $9a
F_CLOSE      equ $9b
F_READ       equ $9d
F_WRITE      equ $9e
F_SEEK       equ $9f
F_FSTAT      equ $ac

FA_READ      equ $01
FA_APPEND    equ $06
FA_OVERWRITE equ $0C

; *******************************************************************************************************
;
;	Get/Set the drive (get default drive)
;
; *******************************************************************************************************
GetSetDrive:	
		push	af					; no idea what it uses....
		push	bc
		push	de
		push	hl
		push	ix

		xor		a					; set drive. 0 is default
		rst		$08
		db		$89
		ld		(DefaultDrive),a

		pop		ix
		pop		hl
		pop		de
		pop		bc
		pop		af
		ret




; *******************************************************************************************************
;	Function:	Open a file read for reading/writing
;	In:		ix = filename
;			b  = Open filemode
;	ret		a  = handle, 0 on error
; *******************************************************************************************************
fopen:	push	hl
		push	ix
		pop		hl
		ld		a,(DefaultDrive)
		rst		$08
		db		F_OPEN
		pop		hl
		ret

; *******************************************************************************************************
;	Function:	Open a file read for reading/writing
;	In:		ix = buffer to fill in
;			b  = Open filemode
;	ret		a  = handle, 0 on error
; *******************************************************************************************************
fstat:	push	hl
		push	ix
		pop		hl
		rst		$08
		db		F_FSTAT
		pop		hl
		ret


; *******************************************************************************************************
;	Function	Read bytes from the open file
;	In:		a   = file handle
;			ix  = address to read into
;			bc  = amount to read
;	ret:		carry set = error
; *******************************************************************************************************
fread:
		or   	a             ; is it zero?
		ret  	z             ; if so return		

        push	hl
        push	ix

        push	ix
		pop		hl
		rst		$08
		db		F_READ

		pop		ix
		pop		hl
		ret

; *******************************************************************************************************
;	Function:	Close open file
;	In:		a  = handle
;	ret		a  = handle, 0 on error
; *******************************************************************************************************
fclose:		
		or   	a             ; is it zero?
		ret  	z             ; if so return		
		rst		$08
		db		F_CLOSE
		ret




; *******************************************************************************************************
;	Function	Read bytes from the open file
;	In:		a   = file handle
;			L   = Seek mode (0=start, 1=rel, 2=-rel)
;			BCDE = bytes to seek
;	ret:		BCDE = file pos from start
; *******************************************************************************************************
fseek:
		push	ix
		push	hl
		rst		$08
		db		F_SEEK
		pop		hl
		pop		ix
		ret

; *******************************************************************************************************
; Init the file system
; *******************************************************************************************************
InitFileSystem:
		call    GetSetDrive
		ret


; *******************************************************************************************************
; Function:	Load into banked RAM
; In:		a  = 8K bank to load into 
;			hl = file data pointer
;			ix = address to load to (somewhere in the top 16K probably)
; *******************************************************************************************************
Load_Bank:	
		NextReg	DRAW_BANK,a
		inc		a
		NextReg	DRAW_BANK+1,a
	
; *******************************************************************************************************
; Function:	Load a whole file into memory	(confirmed working on real machine)
; In:		hl = file data pointer
;		ix = address to load to
; *******************************************************************************************************
Load:	ld		(LastFileName),hl
		call    GetSetDrive			; need to do this each time?!?!?

		push	bc
		push	de
		push	af


		; get file size
		ld		c,(hl)
		inc		hl
		ld		b,(hl)
		inc		hl
		inc		hl					; skip 3rd byte. On a "full load", it can never be more than 64k!!


		push	bc					; store size
		push	ix					; store load address


		push	hl					; get name into ix
		pop		ix
        ld      b,FA_READ			; mode open for reading
        call    fOpen
        jr		c,@error_opening	; carry set? so there was an error opening and A=error code
        cp		0					; was file handle 0?
        jr		z,@error_opening	; of so there was an error opening.

        pop		ix					; get load address back
        pop		bc					; get size back

        push	af					; remember handle
        call	fread				; read data from A to address IX of length BC                
		jr		c,@error_reading

		pop		af					; get handle back
		call	fClose				; close file
		jr		c,@error_closing

		pop		af					; normal exit
		pop		de
		pop		bc
		ret

;
; On error, display error code an lock up so we can see it
;
@error_opening:
		jp		DisplayError
		ld		de,$4002
		ld		a,$ff
		call	PrintHex		

		ld		a,0
@infloop2	
		out     ($fe),a
		inc 	a
		jp		@infloop2



		pop		ix
@error_reading:		
		pop		bc	; don't pop a, need error code

@error_closing:
		ld		de,$4002
		call	PrintHex		

		ld		a,0
@infloop	
		out     ($fe),a
		inc 	a
		jp		@infloop

@NormalError:  	
		pop		bc	; don't pop into A, return with error code
		pop		de
		pop		bc
		ret



; ******************************************************************************
; Function:	Load a 256 colour bitmap directly into the screen
;			Once loaded, enable and display it
; In:		hl = file data pointer
; ******************************************************************************
Load256Screen:
		ld		(LastFileName),hl
		push	bc
		push	de
		push	ix
		push	af

		; ignore file length... it's set for this (should be 256*192)
		inc		hl
		inc		hl
		inc		hl

		push	hl
		pop		ix
		ld      b,FA_READ
		call    fOpen
		jr		c,@error_opening	; error opening?
		cp		0
		jr		z,@error_opening	; error opening?
		ld		(LoadHandle),a		; store handle
		
		
		ld		e,3					; number of blocks
		ld		a,1					; first bank...
@LoadAll:
		ld      bc, $123b
		out		(c),a				; bank in first bank
		
		push	af
		
		ld		a,(LoadHandle)
		ld		bc,64*256
		ld		ix,0
		call	fread
		
		pop		af
		add		a,$40
		dec		e
		jr		nz,@LoadAll
		
		ld		a,(LoadHandle)
		call	fClose
		
		ld		bc, $123b
		ld		a,2
		out		(c),a                               
		jr		@SkipError 
@error_opening:
		ld		a,5
		out		($fe),a
@SkipError
		pop		af
		pop		ix
		pop		de
		pop		bc
		ret
LoadHandle	db	0





; *******************************************************************************************************
; Function:	Load a whole file into memory	
; In:		hl = file data pointer
;			a = starting bank
; *******************************************************************************************************
Load_Banked:	
		ld		(LastFileName),hl
		ld 		(CurrentFBank),a
		call    GetSetDrive		; need to do this each time?!?!?

		push	bc
		push	de
		

		; get file size
		ld		a,(hl)			; filesize is 3 bytes - upto 16Mb
		ld		(BlockFileSize),a
		inc		hl
		ld		a,(hl)
		ld		(BlockFileSize+1),a
		inc		hl
		ld		a,(hl)
		ld		(BlockFileSize+2),a
		inc		hl

		push	hl							; get name into ix
        pop		ix
        ld      b,FA_READ					; mode open for reading
        call    fOpen
        jr		c,@error_opening			; carry set? so there was an error opening and A=error code
        cp		0							; was file handle 0?
        jr		z,@error_opening			; of so there was an error opening.
		ld		(FileHandle),a


@NextBlock:
		ld		a,(CurrentFBank)
		NextReg	DRAW_BANK,a
		inc		a
		ld		(CurrentFBank),a

		ld		a,(BlockFileSize+2)			; if 3rd byte not zero, more than 8k to load
        and		a
        jr		nz,@MoreThan8K

        ld		a,(BlockFileSize+1)			; if 2nd byte > 8191, more than 8K to load
        cp		$1f
        jr		c,@LessThan8K
@MoreThan8K
        ld		bc,8192						; more than 8K, so
        jp		@LoadRemaining
@LessThan8K:
		ld		a,(BlockFileSize)			; if not.... read in the rest of the file
		ld		c,a
        ld		a,(BlockFileSize+1)
        ld		b,a

@LoadRemaining
		ld 		ix,DRAW_BASE  				; Get bank start
        ld		a,(FileHandle)
        call	fread						; read data from A to address IX of length BC                
		jr		c,@error_reading


        ; Sub 16K from size
        xor		a							; clear carry
        ld		hl,(BlockFileSize)
        ld		bc,8192
        sbc		hl,bc
        ld		(BlockFileSize),hl

        ld		a,(BlockFileSize+2)
        ld		h,0
        sbc		a,h
        ld		(BlockFileSize+2),a                
        jr		nc,@NextBlock


        ld		a,(FileHandle)				; get handle back
        call	fClose						; close file
        jr		c,@error_closing

		pop	de
		pop	bc
		ret


;
; On error, display error code an lock up so we can see it
;
@error_opening:
@error_reading:
@error_closing:
@NormalError:  			; don't pop into A, return with error code
		pop	de
		pop	bc
		ret



; *******************************************************************************************************
; Function:	Load a whole file into memory	(confirmed working on real machine)
; In:		hl = filename
; *******************************************************************************************************
;TestStat:	call    GetSetDrive		; need to do this each time?!?!?
;
;		ld	hl,filename
;		push	hl			; get name into ix
;                pop	ix
;                ld      b,FA_READ		; mode open for reading
;                call    fOpen
;                jr	c,@error_opening	; carry set? so there was an error opening and A=error code
;                cp	0			; was file handle 0?
;                jr	z,@error_opening	; of so there
;
;                push	af	
;                ld	hl,stat_buffer
;                push	hl
;                pop	ix
;                call	fStat
;
;                pop	af
                ;call	fClose
;
;@error_opening:
                ;ret



; *********************************************************************
;
; Function:	Display the file error message
;
; In:  		A = Error Code
; Out:		HL= Filename
;
; *********************************************************************
DisplayError:
		push	af

		; wipe screen, ready for error message
		ld		a,7
		call	ClsATTR
		call	Cls
		ld		a,%00010100			; make sure ULA screen is in front
		NextReg	$15,a				; make sure sprites are off
		
	
		pop		af					; get error code
		ld		hl,$4000			; y,x
		call	DisplayErrorCode
		
		ld		hl,(LastFileName)	; filename
		ld		de,$1000			; y,x
		pixelad						; get address into HL
		pop		de



ErrorLoop:
		ld		a,0
@infloop	
		out     ($fe),a
		inc 	a
		jp		@infloop



; *********************************************************************
;
; Function:	Draw a text message
;
; In:  		A  = Error Code
;			HL = Screen address
; Out:		DE = TEXT,0 to print
;			HL = dest screen address
;
; *********************************************************************
DisplayErrorCode:
		push	hl
		ld		b,a
		dec		b
		and		a
		jr		z,@CodeZero
		ld		hl,File_ErrorMessages
@KeepGoing		
		ld		a,(hl)
		inc		hl
		and		a
		jr		nz,@KeepGoing
		djnz	@KeepGoing
@CodeZero:	
		ex		de,hl
		pop    	hl

DrawText:
		ld		a,(de)		
		inc		de
		and		a
		ret		z
		sub		32
		;cp	$20
		;jr	z,@NextChar


		push	de
		ld		e,a
		ld		d,0
		ex		de,hl
		add		hl,hl			; character *8
		add		hl,hl
		add		hl,hl
		add		hl,$3d00
		ex		de,hl

		
		push	hl
		ld		b,8
@DrawChar:	
		ld		a,(de)
		ld		(hl),a
		pixeldn
		inc		de
		djnz	@DrawChar
		pop		hl
		pop		de
@NextChar
		inc		hl
		jr		DrawText

@EndOfMessage:
		pop		hl
		pop		de
		ret


		

File_ErrorMessages:

File_EOK:			db	"OK",0
File_ENONSENSE		db	"Nonsense in command",0
File_ESTEND			db	"ESTEND",0
File_EWRTYPE		db	"EWRTYPE",0
File_ENOENT			db	"No such file or directory",0
File_EIO			db	"I/O error",0
File_EINVAL			db	"Invalid file name",0
File_EACCES			db	"Access Denied",0
File_ENOSPC			db	"No space left on device",0
File_ENXIO			db	"Request beyond the limits of the device",0
File_ENODRV			db	"No such drive",0
File_ENFILE			db	"Too many files open in system",0
File_EBADF			db	"Bad file descriptor",0
File_ENODEV			db	"No such device",0
File_EOVERFLOW		db	"EOVERFLOW",0
File_EISDIR			db	"EISDIR",0
File_ENOTDIR		db	"No such directory",0
File_EEXIST			db	"EEXIST",0
File_EPATH			db	"Invalid path",0
File_ENOSYS			db	"ENOSYS",0
File_ENAMETOOLONG	db	"ENAMETOOLONG",0
File_ENOCMD			db	"ENOCMD",0
File_EINUSE			db	"EINUSE",0
File_ERDONLY		db	"ERDONLY",0
File_EVERIFY		db	"EVERIFY",0
File_ELOADKO		db	"ELOADKO",0
File_ENOTEMPTY		db	"ENOTEMPTY",0
File_EMAPRAM		db	"MAPRAM is active",0
					db	$ff
File_EUNKNOWN_ERROR	db	"Unknown file error",0
DemoText			db	"Demo V0.1",0
DemoText2			db	"ZX Spectrum Next Lemmings",0
DemoText3			db	"     Prototype V0.1",0
	
DefaultDrive:		db	0
LastFileName		dw	0		; last filename to be loaded


