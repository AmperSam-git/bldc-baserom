Throw_Sprite_Tiles:		db $05,$08,$00,$00,$0B,$09,$0A,$00
						db $00,$06,$00,$05,$09,$09,$0A,$00
						db $00,$05,$00,$00,$00

Throw_Sprite_Palette:	db $07,$C9,$04,$0C,$07,$0B,$03,$09
						db $09,$05,$04,$07,$07,$07,$C9,$04
						db $0C,$07,$C3,$04,$0C

Throw_Sprite_Size:		db $02,$02,$00,$00,$02,$02,$02,$00
						db $00,$02,$00,$02,$02,$02,$02,$00
						db $00,$02,$02,$00,$00

Throw_Sprite_X_LOffset:	db $0A,$0A,$00,$00,$06,$06,$06,$00
						db $00,$06,$00,$0A,$0C,$0C,$0C,$00
						db $00,$0A,$0A,$00,$00

Throw_Sprite_X_ROffset:	db $F6,$F6,$00,$00,$FA,$FA,$FA,$00
						db $00,$FA,$00,$F6,$F4,$F4,$F4,$00
						db $00,$F6,$F6,$00,$00

Throw_Sprite_Y_Offset:	db $F2,$F2,$80,$80,$F2,$F2,$F2,$80	; 80 = Do not show spawn sprites
						db $80,$F2,$80,$F2,$EA,$EA,$EA,$80
						db $80,$F2,$F2,$80,$80



Wing_TileMap:			db $C6,$4E			; Draw wings between the 2nd and 3rd tiles.
Wing_Size:				db $02,$00			;
Wing_X_Offset:			db $08,$F8,$08,$00	; $Left ,$Right,$Left ,$Right
Wing_Y_Offset: 		 	db $F0,$F0,$F8,$F8	; $16x16,$16x16,$08x08,$08x08
!Wing_TileNum =			$01


Walk_Animation_Num:		db $00,$00,$00,$00,$04,$04,$00,$04
						db $04,$04,$00,$00,$0A,$0A,$0A,$0A
						db $0A,$04

Setup_Animation_Num:	db $02,$02,$02,$02,$06,$06,$02,$08
						db $08,$06,$02,$02,$0C,$0C,$0C,$0C
						db $0C,$06

First_Tile_Num:		db $00,$03,$06,$0A,$0E,$11,$14,$18
					db $1C,$1F,$22,$26,$2A,$2F

Use_Tiles:			db $02,$02,$03,$03,$02,$02,$03,$03
					db $02,$02,$03,$03,$04,$04

TileMap:			db $00,$08,$0A			;00 00-02 Walk
					db $00,$09,$0B			;01 03-05
					db $00,$01,$08,$0A		;02 06-09 Throw
					db $00,$01,$09,$0B		;03 0A-0D
					db $00,$08,$0A			;04 0E-10 OtherColor Walk
					db $00,$09,$0B			;05 11-13
					db $00,$01,$08,$0A		;06 14-17 OtherColor Throw
					db $00,$01,$09,$0B		;07 18-1B
					db $01,$08,$0A			;08 1C-1E OtherColor FlameSpit
					db $01,$09,$0B			;09 1F-21
					db $02,$03,$04,$05		;0A 22-25 SledgeWalk
					db $02,$03,$06,$07		;0B 26-29
					db $00,$00,$01,$04,$05	;0C 2A-3E SledgeThrow
					db $00,$00,$01,$06,$07	;0D 2F-33

Size:				db $02,$00,$00			;00 00-02
					db $02,$00,$00			;01 03-05
					db $00,$02,$00,$00		;02 06-09
					db $00,$02,$00,$00		;03 0A-0D
					db $02,$00,$00			;04 0E-10
					db $02,$00,$00			;05 11-13
					db $00,$02,$00,$00		;06 14-17
					db $00,$02,$00,$00		;07 18-1B
					db $02,$00,$00			;08 1C-1E
					db $02,$00,$00			;09 1F-21
					db $02,$02,$02,$02		;0A 22-25
					db $02,$02,$02,$02		;0B 26-29
					db $00,$02,$02,$02,$02	;0C 2A-3E
					db $00,$02,$02,$02,$02	;0D 2F-33

X_Offset_L:			db $00,$00,$08			;00 00-02
					db $00,$00,$08			;01 03-05
					db $00,$00,$00,$08		;02 06-09
					db $00,$00,$00,$08		;03 0A-0D
					db $00,$00,$08			;04 0E-10
					db $00,$00,$08			;05 11-13
					db $00,$00,$00,$08		;06 14-17
					db $00,$00,$00,$08		;07 18-1B
					db $00,$00,$08			;08 1C-1E
					db $00,$00,$08			;09 1F-21
					db $FB,$0B,$FB,$0B		;0A 22-25
					db $FB,$0B,$FB,$0B		;0B 26-29
					db $00,$FB,$0B,$FB,$0B	;0C 2A-3E
					db $00,$FB,$0B,$FB,$0B	;0D 2F-33

X_Offset_R:			db $00,$08,$00			;00 00-02
					db $00,$08,$00			;01 03-05
					db $00,$00,$08,$00		;02 06-09
					db $00,$00,$08,$00		;03 0A-0D
					db $00,$08,$00			;04 0E-10
					db $00,$08,$00			;05 11-13
					db $00,$00,$08,$00		;06 14-17
					db $00,$00,$08,$00		;07 18-1B
					db $00,$08,$00			;08 1C-1E
					db $00,$08,$00			;09 1F-21
					db $0B,$FB,$0B,$FB		;0A 22-25
					db $0B,$FB,$0B,$FB		;0B 26-29
					db $00,$0B,$FB,$0B,$FB	;0C 2A-3E
					db $00,$0B,$FB,$0B,$FB	;0D 2F-33

Y_Offset:			db $F8,$08,$08			;00 00-02	; 80 = Follow Throw_Sprite ...
					db $F8,$08,$08			;01 03-05
					db $80,$F8,$08,$08		;02 06-09
					db $80,$F8,$08,$08		;03 0A-0D
					db $F8,$08,$08			;04 0E-10
					db $F8,$08,$08			;05 11-13
					db $80,$F8,$08,$08		;06 14-17
					db $80,$F8,$08,$08		;07 18-1B
					db $F8,$08,$08			;08 1C-1E
					db $F8,$08,$08			;09 1F-21
					db $F0,$F0,$00,$00		;0A 22-25
					db $F0,$F0,$00,$00		;0B 26-29
					db $80,$F0,$F0,$00,$00	;0C 2A-3E
					db $80,$F0,$F0,$00,$00	;0D 2F-33

Dire_XOffset:		db $34,$00

