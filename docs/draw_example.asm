;
; ZX Spectrum Next - Lemming draw code ideas.
; 
;

ld  	a,(ix+*)
ld  	(iy+*),a = 36 = 36*29 = 1102   (one lemming "save")
ld  	d,EndBank   	; used to detect going off the bottom of the screen
ld  	a,BANK 		; Current "Y" screen bank
 
; HL = screen address. Each line 256 bytes long
ld  	e,*     	; 7						green
ld  	(hl),e		; 7	
inc 	l 		; 4				* *
inc 	l 		; 4	
ld  	(hl),e		; 7	
ld  	bc,** 		; 10
add 	hl,bc   	; 11

; next line down - check for Layer 2 bank swap
ld	a,h
and	$c0
or	$03+$08		; write to back buffer
ld	bc,$123b
out 	(c),a
ld	a,h
and	$3f		; wrap bank
ld	h,a



ld 	(hl),e	  	; 7				***
inc 	l 		; 4	
ld 	(hl),e		; 7	
inc 	l 		; 4	
ld 	(hl),e		; 7	
inc 	l 		; 4	
ld  	bc,** 		; 10  
add 	hl,bc   	; 11

ld 	(hl),e		; 7				 **
inc 	l 		; 4	
ld	e,*		; 7						white
ld 	(hl),e		; 7	
ld  	bc,** 		; 10			   
add 	hl,bc   	; 11
 
ld 	(hl),e		; 7				 ***
inc 	l 		; 4	
ld 	(hl),e		; 7					   
inc 	l 		; 4	
ld 	(hl),e		; 7				   
ld	bc,**		; 10
add 	hl,bc   	; 11

ld	(hl),e		; 7				***
inc 	l 		; 4	
ld	hl),e		; 7					   
inc	l 		; 4	
ld	e,*		; 7						blue
ld 	(hl),e		; 7				   
ld  	bc,** 		; 10
add 	hl,bc   	; 11
	
ld	(hl),*		; 10			***			white
inc 	l 		; 4	
ld	hl),e		; 7				   
inc	l 		; 4	
ld 	(hl),e		; 7			
ld  	bc,** 		; 10  
add 	hl,bc   	; 11

ld	(hl),*		; 7				****		white
inc 	l 		; 4						white
ld	(hl),*		; 7				   
inc	l 		; 4	
ld 	(hl),e		; 7						blue		   
inc	l 		; 4	
ld 	(hl),e		; 7				   		blue
inc	l 		; 4	
ld 	(hl),e		; 7				   		blue
ld  	bc,** 		; 10
add 	hl,bc   	; 11

ld 	(hl),e		; 7				****		blue		   
inc	l 		; 4	
ld 	(hl),e		; 7						blue		   
inc	l 		; 4	
ld 	(hl),e		; 7						blue		   
inc	l 		; 4	
ld 	(hl),e		; 7						blue		   
inc	l 		; 4	
ld  	bc,** 		; 10
add 	hl,bc   	; 11

ld	e,*		; 7 						white
ld 	(hl),e		; 7							
inc	l 		; 4	
ld 	(hl),e		; 7							
inc	l 		; 4	
inc	l 		; 4	
ld 	(hl),e		; 7							
inc	l 		; 4	
ld 	(hl),e		; 7							
ret	 		; 10 = 508 TStates = 0.52 scalines   (81 bytes)  (209 with next line code)









 
; HL = screen address. Each line 256 bytes long
; DE = dest (linear)

SaveWalkerFrame3:
ldi			; 16		* *
inc	l 		; 4
ldi 		; 16
ld 	bc,**	; 10
add hl,bc	; 11

ldi 		; 16		***
ldi 		; 16
ldi 		; 16
inc	bc 		; 6
add hl,bc	; 11


ldi 		; 16		 **
ldi 		; 16
add hl,bc	; 11

ldi 		; 16		***
ldi 		; 16
ldi 		; 16
ld 	bc,**	; 10
add hl,bc	; 11

ldi 		; 16		***
ldi 		; 16
ldi 		; 16
inc	bc		; 6
add hl,bc	; 11

ldi 		; 16		***
ldi 		; 16
ldi 		; 16
dec	bc		; 6
add hl,bc	; 11

ldi 		; 16	   *****
ldi 		; 16
ldi 		; 16
ldi 		; 16
ldi 		; 16
add hl,bc	; 11

ldi 		; 16		****
ldi 		; 16
ldi 		; 16
ldi 		; 16
add hl,bc	; 11

ldi 		; 16		****
ldi 		; 16
inc	l 		; 4
inc	l 		; 4
ldi 		; 16
ldi 		; 16  		= 612 T-States
ret 		; 10




ld 	a,(de)	; 7
ld 	(hl),a 	; 7
inc	e 		; 4
inc l 		; 4 = 22 



SaveWalkerFrame3:
ldi			; 16		* *
inc	e 		; 4
ldi 		; 16
ld 	bc,**	; 10
ex 	de,hl 	; 4
add hl,bc	; 11
ex 	de,hl 	; 4

ldi 		; 16		***
ldi 		; 16
ldi 		; 16
inc	bc 		; 6
add hl,bc	; 11


ldi 		; 16		 **
ldi 		; 16
add hl,bc	; 11

ldi 		; 16		***
ldi 		; 16
ldi 		; 16
ld 	bc,**	; 10
add hl,bc	; 11

ldi 		; 16		***
ldi 		; 16
ldi 		; 16
inc	bc		; 6
add hl,bc	; 11

ldi 		; 16		***
ldi 		; 16
ldi 		; 16
dec	bc		; 6
add hl,bc	; 11

ldi 		; 16	   *****
ldi 		; 16
ldi 		; 16
ldi 		; 16
ldi 		; 16
add hl,bc	; 11

ldi 		; 16		****
ldi 		; 16
ldi 		; 16
ldi 		; 16
add hl,bc	; 11

ldi 		; 16		****
ldi 		; 16
inc	l 		; 4
inc	l 		; 4
ldi 		; 16
ldi 		; 16  		= 612 T-States
ret 		; 10


