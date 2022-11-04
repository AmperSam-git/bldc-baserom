;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; graphics configuration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

EyeProperties:
    db $40, $00

!AngryUpDownThwompTile = $03
!AngryLeftRightThwompTile = $05

ThwompDispX:                    ;$01AF40    | X position offsets for each of the Thwomp's tiles.
    db $FC, $0C, $0C, $FC, $0C, $0C, $00                  ; Seventh byte is used only when the Thwomp isn't using its normal expression. Same for the below.

RightThwompDispX:                          
    db $04, $FC, $FC, $04, $FC, $FC, $00

LeftThwompDispX:
    db $FF, $0F, $0F, $FF, $0F, $0F, $03

ThwompDispY:                    ;$01AF45    | Y position offsets for each of the Thwomp's tiles.
    db $00, $00, $08, $10, $10, $18, $08

ThwompDownTiles:
    db $00, $00, $02, $01, $04, $06, $02

ThwompUpTiles:
    db $01, $06, $04, $00, $02, $00, $02

ThwompLeftTiles:
    db $06, $20, $21, $07, $22, $23, $04

ThwompRightTiles:
    db $06, $20, $21, $07, $22, $23, $04

ThwompUpProps:
    db $81, $C1, $C1, $81, $C1, $C1, $81

ThwompDownProps:
    db $01, $41, $41, $01, $41, $41, $01

ThwompRightProps:
    db $41, $41, $41, $41, $41, $41, $41

ThwompLeftProps:
    db $01, $01, $01, $01, $01, $01, $01

TileSizes:
    db $02, $00, $00, $02, $00, $00, $02
	
offset:
db $00,$01,$10,$11