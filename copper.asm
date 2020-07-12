COP_NOP                 equ     0
COP_PER_1               equ     5
COP_PER_2               equ     6
COP_TURBO               equ     7        
COP_PER_3               equ     8
COP_LAYER2_BANK         equ     18      ; layer 2 bank
COP_LAYER2_SBANK        equ     19      ; layer 2 shadow bank
COP_TRANSPARENT         equ     20      ; Global transparency color
COP_SPRITE              equ     21      ; Sprite and Layers system
COP_LAYER2_XOFF         equ     22
COP_LAYER2_YOFF         equ     23
COP_LAYER2_CLIP         equ     24
COP_SPRITE_CLIP         equ     25
COP_ULA_CLIP            equ     26
COP_CLIP_CNT            equ     28
COP_IRQ                 equ     34
COP_IRQ_RAST_LO         equ     35
COP_LOWRES_XOFF         equ     50
COP_LOWRES_YOFF         equ     51
COP_PALETTE_INDEX       equ     64
COP_PALETTE_COLOUR      equ     65      ; 8 bit palette colour
COP_PALETTE_FORMAT      equ     66      
COP_PALETTE_CONTROL     equ     67       
COP_PALETTE_COLOUR_9    equ     68      ; 9 bit palette colour
COP_MMU0                equ     80
COP_MMU1                equ     81
COP_MMU2                equ     82
COP_MMU3                equ     83
COP_MMU4                equ     84
COP_MMU5                equ     85
COP_MMU6                equ     86
COP_MMU7                equ     87
COP_DATA                equ     96
COP_CONTROL_LO          equ     97
COP_CONTROL_HI          equ     98


PAPER_INDEX     equ     16

; 1K copper
GameCopper:     
		WAIT    159,300                  ; wait until right border
		MOVE    COP_LAYER2_BANK,PanelBank        
		WAIT    159,340
		MOVE	COP_LAYER2_YOFF,32
		WAIT    400,0

GameCopperEnd:
GameCopperSize      equ     GameCopperEnd-GameCopper




