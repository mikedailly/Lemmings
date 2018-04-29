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
; File system
; *****************************************************************************************************************************
filehandle:	db	0
file_size	dw	0,0
CurrentFBank	db	0
BlockFileSize	db	0,0,0,0
BankAddress 	dw	0

; Tile scrolling on counter
ScrollIndex:	dw	0
SkillMaskTable:	db	SKILLMASK_CLIMBER,SKILLMASK_FLOATER,SKILLMASK_BOMBER,SKILLMASK_BLOCKER,SKILLMASK_BUILDER,SKILLMASK_BASHER,SKILLMASK_MINER,SKILLMASK_DIGGER


; Delay for the trap door opening - 2 seconds
TrapDoorStartDelay	db	0
TrapDoorList		ds	4*3		; upto 4 entrances (4 bytes per)
			dw	0		; list termination
TrapDoorlistCurrent	dw	0	

; *****************************************************************************************************************************
; Object definitions 256 bytes
; *****************************************************************************************************************************
ObjectInfo:	ds	Obj_MaxSize*16	; style?.dat loaded into here

; *****************************************************************************************************************************
; Object Instances
; *****************************************************************************************************************************
		rsreset
oActive:	rb	1		; object active?
oX:		rw	1		; sprite index into the object sprite pool
oY:		rw	1		; starting frame of the animation
oPtr:		rw	1		; pointer to object structure
oFlags:		rb	1		; object flags
oFrame:		rb	1		; current animation frame	8
oFirstFrame:	rb	1		; first frame of animation	9
oMaxFrames:	rb	1		; end frame of animation +1	10
oDelta:		rb	1		; animation delta (usuall 1)	11
oObjID		rb	1		; object ID (0=trap door)	12
oInstSize	rb	0		; size of struct
	
ObjectData:	ds	32*oInstSize	; actual instance data
ObjNumber	db	0		; number of active objects in this level

; *****************************************************************************************************************************
; File system
; *****************************************************************************************************************************

 
; *****************************************************************************************************************************
; Lemming data
; *****************************************************************************************************************************
LemmingXSpawn		dw	0
LemmingCounter		db	0
ReleaseRateCounter	db	0	; actual release rate
MasterReleaseRate	db	0	; "master" value

NextSpawnLemming	dw	0			; offset to Lemming struct
LemData			ds	LemDataSize
EndLemData


CursorLemmingIndex	dw 	0			; pointer to lemmign struct
CursorWorldX 		dw 	0
CursorDistance		db	0			; distance current selection is from centre of cursor 


				; frame		count	offsets
WalkerLAnim:	LEMANIM		FWalkerL,	8, 	3,0
WalkerRAnim:	LEMANIM		FWalkerR,	8, 	3,0
FallerLAnim:	LEMANIM		FFallerL,	4,	-3,0
FallerRAnim:	LEMANIM		FFallerR,	4,	-3,0
SplatterAnim:	LEMANIM		FSplatter,	17,	0,0		;+1 frame so processing code can detect
DiggerAnim:	LEMANIM		FDigger,	16,	0,1		
PreBomberAnim:	LEMANIM		FExploder,	17,	2,0		;+1 frame so processing code can detect
BuilderRAnim:	LEMANIM		FBuilderRight,	16,	0,0		
BuilderLAnim:	LEMANIM		FBuilderLeft,	16,	0,0		



; *****************************************************************************************************************************
; File directory.....
; *****************************************************************************************************************************
LemTitle        File    "lemdat/lemtitle.256"		; title page
PanelFile       File    "lemdat/lempanel.256"		; Lemmings panel
PanelNumbers    File    "lemdat/panelnum.256"		; Lemmings panel
CursorsFile	File	"lemdat/cursor.256"		; Cursors (cross and selection)
PointsFile	File	"lemdat/points.dat"		; nuke points...

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


