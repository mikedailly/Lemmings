
; *****************************************************************************************************************************
; Masks
;
;	NON ZERO 	wipe
;	ZERO		wipe
;
; *****************************************************************************************************************************
DiggerMask:		
		db		9,3
		db		0,0,0,0,0,0,0,0,0
		db		0,0,0,0,0,0,0,0,0
		db		0,0,0,0,0,0,0,0,0

BomberMask	db		16,22
		db		2,2,2,2,2, 0,0,0,0,0, 2,2,2,2,2,2
		db		2,2,2,2, 0,0,0,0,0,0,0,0, 2,2,2,2
		db		2,2,2, 0,0,0,0,0,0,0,0,0,0, 2,2,2
		db		2,2,2, 0,0,0,0,0,0,0,0,0,0, 2,2,2
		db		2,2, 0,0,0,0,0,0,0,0,0,0,0,0, 2,2
		db		2,2, 0,0,0,0,0,0,0,0,0,0,0,0, 2,2
		db		2, 0,0,0,0,0,0,0,0,0,0,0,0,0,0, 2
		db		2, 0,0,0,0,0,0,0,0,0,0,0,0,0,0, 2
		db		2, 0,0,0,0,0,0,0,0,0,0,0,0,0,0, 2		
		db		 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 2
		db		 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		db		 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		db		 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		db		 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		db		 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		db		 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		db		2, 0,0,0,0,0,0,0,0,0,0,0,0,0,0, 2
		db		2, 0,0,0,0,0,0,0,0,0,0,0,0,0,0, 2
		db		2, 0,0,0,0,0,0,0,0,0,0,0,0,0,0, 2
		db		2,2, 0,0,0,0,0,0,0,0,0,0,0,0, 2,2
		db		2,2,2, 0,0,0,0,0,0,0,0,0,0, 2,2,2
		db		2,2,2,2,2, 0,0,0,0,0,0, 2,2,2,2,2


BuilderStep:		
		db		6,1
		db		255,255,255,255,255,255