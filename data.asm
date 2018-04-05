; *********************************************************************************************************
;
;	Data
;
; *********************************************************************************************************



; *****************************************************************************************************************************
; Interrupts
; *****************************************************************************************************************************
VBlank		db	0				; vblank counter
CursorOn	db	0				; flag to enable the IRQ cursor 
NewFrameFlag	db	0				; setting this will cause the sprite buffers to flip. Reset in IRQ

; *****************************************************************************************************************************
; Sprite manager
; *****************************************************************************************************************************

; burn a bit of space so that we can move to each new bit more easily
		org	((pc+255)&$ffffff00)		; align to the next 256 bytes
sprite_x	ds	256				 
sprite_y	ds	256				
sprite_flags	ds	256
sprite_shape	ds	256




; *****************************************************************************************************************************
; File system
; *****************************************************************************************************************************
filehandle:	db	0
file_size	dw	0,0
CurrentFBank	db	0
BlockFileSize	db	0,0,0,0
BankAddress 	dw	0

; Tile scrolling on counter
ScrollIndex:	db	0



; *****************************************************************************************************************************
; Object definitions
; *****************************************************************************************************************************
ObjectInfo:	ds	Obj_MaxSize*16;
	message	"Loaded = ",Obj_MaxSize

; *****************************************************************************************************************************
; Active Objects
; *****************************************************************************************************************************
ObjectData:
ObjActive	db	0	; object active?
ObjX		dw	0
ObjY		dw	0
ObjPtr		dw	0	; pointer to object structure
ObjFlags	db	0	; object flags
ObjFrame	db	0	; current animation frame	8
ObjFirstFrame	db	0	; first frame of animation	9
ObjEndFrame	db	0	; end frame of animation +1	10
ObjDelta	db	0	; animation delta (usuall 1)	11
ObjEndPtr
ObiInstSize	equ	ObjEndPtr-ObjectData
		ds	32*(ObjEndPtr-ObjX)
		message "objdta = ",ObjectData

ObjNumber	db	0	; number of active objects in this level

; *****************************************************************************************************************************
; File system
; *****************************************************************************************************************************
		// objects
Style0Objects	dw	obj1_1, obj1_2, obj1_3, obj1_4, obj1_5, obj1_6, obj1_7, obj1_8, obj1_9, obj1_10, obj1_11, obj1_12
Style1Objects	dw	obj1_1, obj1_2, obj1_3, obj1_4, obj1_5, obj1_6, obj1_7, obj1_8, obj1_9, obj1_10, obj1_11, obj1_12
Style2Objects	dw	obj1_1, obj1_2, obj1_3, obj1_4, obj1_5, obj1_6, obj1_7, obj1_8, obj1_9, obj1_10, obj1_11, obj1_12
Style3Objects	dw	obj1_1, obj1_2, obj1_3, obj1_4, obj1_5, obj1_6, obj1_7, obj1_8, obj1_9, obj1_10, obj1_11, obj1_12
Style4Objects	dw	obj1_1, obj1_2, obj1_3, obj1_4, obj1_5, obj1_6, obj1_7, obj1_8, obj1_9, obj1_10, obj1_11, obj1_12

		// 	xoff,yoff,  animations, -1 restart; -2 = stop at end, -3 = restart and stop
obj1_1		db	0,0,	0,  -1							// exit body		
obj1_2		db	0,0,	1,  -1							// entrance
obj1_3		db	0,0,	2,3,4,5,6,7,8,9,10,0,-2					// entrance opening
obj1_4		db	0,0,	11,12,13,14,15,16,17,18,19,20,21,22,23,24,-1		// green flag
obj1_5		db	0,0,	25,26,27,28,29,30,31,-1					// arrows left
obj1_6		db	0,0,	32,33,34,35,36,37,38,-1					// arrows right
obj1_7		db	0,0,	39,40,41,42,43,44,45,46,-1				// water
obj1_8		db	0,0,	47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,-3		// bear trap -3=restart and stop
obj1_9		db	0,0,	62,63,64,65,66,67,-1					// top of exit
obj1_10		db	0,0,	68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,-3	// boulder
obj1_11		db	0,0,	85,86,87,88,89,90,91,92,93,94,95,96,97,98,-1		// blue flag
obj1_12		db	0,0,	99,100,101,102,103,104,105,106,107,108,109,110,-3	// 10 ton weight trap

 
; *****************************************************************************************************************************
; Lemming data
; *****************************************************************************************************************************
LemmingXSpawn		dw	0
LemmingCounter		db	0
ReleaseRateCounter	db	0			; current,master
NextSpawnLemming	dw	0			; offset to Lemming struct
LemData			ds	LemDataSize
EndLemData


				; frame		count	offsets
WalkerLAnim:	LEMANIM		FWalkerL,	8, 	3,0
WalkerRAnim:	LEMANIM		FWalkerR,	8, 	3,0
FallerLAnim	LEMANIM		FFallerL,	4,	-3,0
FallerRAnim	LEMANIM		FFallerR,	4,	-3,0
FallerSplatter	LEMANIM		FSplatter,	17,	0,0		;+1 frame so processing code can detect



; *****************************************************************************************************************************
; File directory.....
; *****************************************************************************************************************************
LemTitle        File    "lemdat/lemtitle.256"		; title page
PanelFile       File    "lemdat/lempanel.256"		; Lemmings panel
PanelNumbers    File    "lemdat/panelnum.256"		; Lemmings panel
CursorsFile	File	"CURSOR.256"			; Cursors (cross and selection)
PointsFile	File	"lemdat/points.dat"			; nuke points...

; sprites
LemmingsFile	File	"lemdat/lemmings.spr"

; styles
style0		File	"lemdat/styles/style0.spr"
style1		File	"lemdat/styles/style1.spr"
style2		File	"lemdat/styles/style2.spr"
style3		File	"lemdat/styles/style3.spr"
style4		File	"lemdat/styles/style4.spr"
styleO0		File	"lemdat/styles/style0o.spr"
styleO1		File	"lemdat/styles/style1o.spr"
styleO2		File	"lemdat/styles/style2o.spr"
styleO3		File	"lemdat/styles/style3o.spr"
styleO4		File	"lemdat/styles/style4o.spr"
style0dat	File	"lemdat/styles/style0.dat"
style1dat	File	"lemdat/styles/style1.dat"
style2dat	File	"lemdat/styles/style2.dat"
style3dat	File	"lemdat/styles/style3.dat"
style4dat	File	"lemdat/styles/style4.dat"

; levels
level_0000	File	"lemdat/levels/LVL0000.LVL"
level_0001	File	"lemdat/levels/LVL0001.LVL"
level_0002	File	"lemdat/levels/LVL0002.LVL"
level_0003	File	"lemdat/levels/LVL0003.LVL"
level_0004	File	"lemdat/levels/LVL0004.LVL"
level_0005	File	"lemdat/levels/LVL0005.LVL"
level_0006	File	"lemdat/levels/LVL0006.LVL"
level_0007	File	"lemdat/levels/LVL0007.LVL"
;level_0008	File	"lemdat/levels/LVL0008.LVL"
;level_0009	File	"lemdat/levels/LVL0009.LVL"
level_0010	File	"lemdat/levels/LVL0010.LVL"
level_0011	File	"lemdat/levels/LVL0011.LVL"
level_0012	File	"lemdat/levels/LVL0012.LVL"
level_0013	File	"lemdat/levels/LVL0013.LVL"
level_0014	File	"lemdat/levels/LVL0014.LVL"
level_0015	File	"lemdat/levels/LVL0015.LVL"
level_0016	File	"lemdat/levels/LVL0016.LVL"
level_0017	File	"lemdat/levels/LVL0017.LVL"
level_0020	File	"lemdat/levels/LVL0020.LVL"
level_0021	File	"lemdat/levels/LVL0021.LVL"
level_0022	File	"lemdat/levels/LVL0022.LVL"
level_0023	File	"lemdat/levels/LVL0023.LVL"
level_0024	File	"lemdat/levels/LVL0024.LVL"
level_0025	File	"lemdat/levels/LVL0025.LVL"
level_0026	File	"lemdat/levels/LVL0026.LVL"
level_0027	File	"lemdat/levels/LVL0027.LVL"
level_0030	File	"lemdat/levels/LVL0030.LVL"
level_0031	File	"lemdat/levels/LVL0031.LVL"
level_0032	File	"lemdat/levels/LVL0032.LVL"
level_0033	File	"lemdat/levels/LVL0033.LVL"
level_0034	File	"lemdat/levels/LVL0034.LVL"
level_0035	File	"lemdat/levels/LVL0035.LVL"
level_0036	File	"lemdat/levels/LVL0036.LVL"

; first few levels
level_0091	File	"lemdat/levels/LVL0091.LVL"		; Just dig
level_0095	File	"lemdat/levels/LVL0095.LVL"		; Only floaters can survive this
level_0096	File	"lemdat/levels/LVL0096.LVL"		; Tailor-made for blockers
level_0092	File	"lemdat/levels/LVL0092.LVL"		; Now use miners and climbers
level_0093	File	"lemdat/levels/LVL0093.LVL"		; You need bashers this time
level_0094	File	"lemdat/levels/LVL0094.LVL"		; A task for blockers and bombers
level_0097	File	"lemdat/levels/LVL0097.LVL"		; Builders will help you here

level_0055	File	"lemdat/levels/LVL0055.LVL"		; Steel Works
level_0057	File	"lemdat/levels/LVL0057.LVL"		; It's hero time!


level1          File    "lemdat/level001.256"
level2          File    "lemdat/level002.256"
level3          File    "lemdat/level003.256"
level4          File    "lemdat/level004.256"
level91		File    "lemdat/level091.256"




