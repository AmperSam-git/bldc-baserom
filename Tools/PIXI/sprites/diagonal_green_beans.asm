;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Edit of the green beans (wall springboards or pea bouncers) disassembly by imamelia to make them diagonal
;;
;; Changes made by Djief
;;
;; Uses first extra bit: YES
;;
;; If the extra bit is clear, the springboard will be attached to the left wall like sprite 6B.
;; If the extra bit is set, the springboard will be attached to the right wall like sprite 6C.
;;
;; Uses extra byte : YES
;;
;; First extra byte determines if angled up or down, 00 = up, 01 = down
;; Second extra byte sets the number of bounces, max 4, 0 = infinite
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; defines and tables
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!KillDelay = $10		; number of frames before removing the beans on the last jump, numbers above $78 will bug out (and also let you bounce back on it before it actually gets removed) recommended to keep at $10 or lower
!DisplayNumbers = 1		; set to 1 to display the number of bounces instead of the first bean if not infinite bounces
!BeanTilePage2 = 0		; set to 1 if the bean tile is on the second page, 0 for first page
!NumberTilesPage2 = 1	; set to 1 if the numbers tiles are on the second page, 0 for first page
TileMap:				;tiles to use, first one is the bean tile then number 1 to 4
db $3D,$B6,$B5,$B4,$B3		; default values are using GFX00 on 1st slot and GFX20 on 4th slot

!SoundID = $08			; Sound to use for the bounce
!SoundBank = $1DFC		; sound bank to use for the bounce

!KillSoundID = $08		; Sound to use for the sprite kill
!KillSoundBank = $1DF9	; sound bank to use for the sprite kill

!Bounces = !extra_byte_2	;just a redefine

YBounceSpeed:
db $B6,$B5,$B2,$AC,$A6,$A0,$9A,$94	;up diagonal
db $B6,$B5,$B2,$AE,$AA,$A6,$A2,$9E	;down diagonal

XBounceSpeed:
db $F6,$F5,$F2,$EC,$E6,$E0,$DA,$D4	;up diagonal
db $0A,$0C,$10,$18,$20,$28,$30,$38	;down diagonal

BouncePhysics:
db $01,$01,$03,$05,$07

YSpeedSet:
db $00,$FF,$EC,$E8,$DC,$D6,$D0,$CA

XSpeedSet:
db $00,$00,$FC,$F8,$F4,$F2,$F0,$EE

XDisp:
db $00,$00,$00,$00,$00,		$00,$00,$00,$00,$01
db $00,$00,$00,$01,$02,		$00,$00,$01,$02,$03
db $00,$00,$01,$03,$04,		$00,$01,$02,$03,$05
db $00,$01,$03,$04,$06,		$00,$02,$04,$06,$08

YDisp:
db $00,$00,$00,$00,$00,		$00,$00,$00,$01,$01
db $00,$00,$00,$01,$02,		$00,$00,$00,$01,$03
db $00,$00,$01,$02,$05,		$00,$01,$02,$04,$07
db $00,$01,$03,$06,$0A,		$00,$02,$04,$08,$0C



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; init routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc

LDA !7FAB10,x	;
AND #$04	;
LSR		;
LSR		;
STA !1510,x	;
BEQ EndInit	;

LDA !E4,x	;
SEC		;
SBC #$08		;
STA !E4,x		;
LDA !14E0,x	;
SBC #$00		;
STA !14E0,x	;

EndInit:		;
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine wrapper
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
PHB
PHK
PLB
JSR WallSpringboardMain
PLB
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WallSpringboardMain:

LDA #$00
%SubOffScreen()		;
JSR WallSpringboardGFX	;

LDA $9D			;
BNE Return00		; return if sprites are locked

LDA !Bounces,x				;\ If boucnes are negative we're killing the sprite after a delay
BPL .NormalBehavior			;|
DEC : STA !Bounces,x		;|
CMP #$FE-!KillDelay			;|
BNE .NormalBehavior			;|
LDA #$04					;|
STA !14C8,x					;|
LDA #$1F					;|
STA !1540,x					;|
JSL $07FC3B|!BankB			;|
LDA #!KillSoundID			;|
STA !KillSoundBank|!Base2	;/
RTS

.NormalBehavior
LDA !1534,x		; $1534,x = timer to set the player's Y speed?
BEQ NoSetYSpeed		;
DEC !1534,x		;
BIT $15			; if the player isn't jumping...
BPL NoSetYSpeed		; don't set his/her Y speed
STZ !1534,x		;
LDY !151C,x		;
LDA !extra_byte_1,x	; if down diagonal use second line of table
BEQ .SetSpeed
TYA : CLC : ADC #$08 : TAY
.SetSpeed
LDA YBounceSpeed,y	; set the player's Y speed
STA $7D			;

LDA !1510,x		; invert X speed if beans facing other way
LSR
LDA XBounceSpeed,y
BCC .noXInvert
EOR #$FF : INC
.noXInvert
STA $7B

LDA #!SoundID		;
STA !SoundBank|!Base2	; play a "boing" sound effect

LDA !Bounces,x : BEQ NoSetYSpeed		;If not infinite bounces decrease the amount of bounces left
DEC : STA !Bounces,x : BNE NoSetYSpeed	;If no more bounce set the kill flag
DEC : STA !Bounces,x

NoSetYSpeed:		;

LDA !1528,x		;
JSL $0086DF|!BankB	;

dw Return00		;
dw State01		;
dw State02		;

Return00:		;
RTS			;

State01:

LDA !1540,x		;
BEQ Continue00		;
DEC			;
BNE Return00		;
INC !1528,x		;
LDA #$01			;
STA !157C,x		;
RTS			;

Continue00:		;

LDA !C2,x		;
BMI Label00		;
CMP !151C,x		;
BCS Continue01		;
Label00:			;
CLC			;
ADC #$01		;
STA !C2,x		;
RTS			;

Continue01:		;

LDA !151C,x		;
STA !C2,x		;
LDA #$08			;
STA !1540,x		;
RTS			;

State02:

INC !1570,x	;
LDA !1570,x	;
AND #$03	;
BNE Label01	;
DEC !151C,x	;
BEQ ZeroSpriteState	;
Label01:		;
LDA !151C,x	;
EOR #$FF		;
INC		;
STA $00		;
LDA !157C,x	;
AND #$01	;
BNE DecState4	;

LDA !C2,x	;
CLC		;
ADC #$04	;
STA !C2,x	;
BMI Return01	;
CMP !151C,x	;
BCS Continue02	;
RTS		;

Continue02:	;

LDA !151C,x	;
STA !C2,x	;
INC !157C,x	;
Return01:		;
RTS		;

DecState4:

LDA !C2,x	;
SEC		;
SBC #$04		;
STA !C2,x	;
BPL Return01	;
CMP $00		;
BCC Continue03	;
RTS

Continue03:

LDA $00		;
STA !C2,x	;
INC !157C,x	;
RTS		;

ZeroSpriteState:

STZ !C2,x	;
STZ !1528,x	;
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; graphics routine, plus some other stuff
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WallSpringboardGFX:

%GetDrawInfo()		;
LDA #$18
STA $0E
LDA #$04		;
STA $02			;

LDA !1510,x		;
STA $05			;
LDA !extra_byte_1,x ;store extra byte in $07 to be used when x is changed
STA $07
if !DisplayNumbers == 1
	LDA !Bounces,x ;store bounces in $06 to be used when x is changed
	STA $06
endif

LDA !C2,x		;
STA $03			;
BPL NoInvertState	;
EOR #$FF		;
INC			;
NoInvertState:		;
STA $04			;
LDY !15EA,x		;

GFXLoop:		;

LDA $04			;
ASL #2			;
ADC $04			;
ADC $02			;

TAX			;

LDA $07 : EOR #$FF : INC ; invert displacement if either springing up or down diagonal but not both
EOR $03			;
ASL			;
LDA $07 : BEQ .LoadX ; use X value for Y if down giagonal
LDA YDisp,x : BRA .CheckInvertX
.LoadX
LDA XDisp,x		;
.CheckInvertX
BCC NoInvertX		;
EOR #$FF		;
INC			;
NoInvertX:		;
CLC : ADC $0E : STA $0D
LDA $05			;
LSR			;
LDA $0D
BCC NoInvert00		;
EOR #$FF		;
INC			;
NoInvert00:		;
STA $08			;
CLC			;
ADC $00			;
STA $0300|!Base2,y		;

LDA $07	; if down diagonal invert Y placement
LSR
LDA $0E
BCC .NoVerticalFlip
EOR #$FF : INC
.NoVerticalFlip
STA $0C
LDA $03			;
ASL			;
LDA $07 : BEQ .LoadY ; if down diagonal use X displacement instead of Y
LDA XDisp,x : BRA .CheckInvertY
.LoadY
LDA YDisp,x	;
.CheckInvertY
BCC NoInvert01	;
EOR #$FF		;
INC		;
NoInvert01:	;
SEC : SBC $0C
STA $09		;
CLC		;
ADC $01		;
STA $0301|!Base2,y	;

if !DisplayNumbers == 1						;\ if first bean and between 1 and 4 bounces left we display the number rather a bean
	LDA $02 : BNE .DrawBean					;|
	LDX $06 : BEQ .DrawBean : BMI .DrawBean	;|
											;|
	LDA TileMap,x							;|
	STA $0302|!Base2,y						;|
											;|
	LDA $64		;							;|
	if !NumberTilesPage2 == 1				;|
		ORA #$01							;|
	endif									;|
	ORA #$0A	;							;|
	STA $0303|!Base2,y	;					;|
	BRA .EndLoop							;/
endif

.DrawBean
LDX #$00
LDA TileMap,x	;
STA $0302|!Base2,y	;

LDA $64		;
if !BeanTilePage2 == 1
	ORA #$01
endif
ORA #$0A	;
STA $0303|!Base2,y	;

.EndLoop
LDX $15E9|!Base2	;
PHY		;
JSR Interaction	;
PLY		;
INY #4		;
DEC $02		;
BMI EndGFX	;
LDA $0E : SEC : SBC #$06 : STA $0E
JMP GFXLoop	;

EndGFX:		;

LDY #$00		;
LDA #$04		;
JSL $01B7B3|!BankB	;
Return02:		;
RTS

Interaction:

LDA $71			;
CMP #$01		;
BCS Return02		;
LDA $81			;
ORA $7F			;
ORA !15A0,x		;
ORA !186C,x		;
BNE Return02		;

LDA $7E			;
CLC			;
ADC #$02		;
STA $0A			;

LDA $187A|!Base2	;
CMP #$01		;
LDA #$10		;
BCC Label02		;
LDA #$20		;
Label02:		;
CLC			;
ADC $80			;
STA $0B			;

LDA $0300|!Base2,y		;
SEC			;
SBC $0A			;
CLC			;
ADC #$08		;
CMP #$14		;
BCS Return03		;

LDA $19			;
CMP #$01		;
LDA #$1A		;
BCS Label03		;
LDA #$1C		;
Label03:		;
STA $0F			;

LDA $0301|!Base2,y	;
SEC			;
SBC $0B			;
CLC			;
ADC #$08		;
CMP $0F			;
BCS Return03		;
LDA $7D			;
BMI Return03		;

LDA #$1F		;
PHX			;
LDX $187A|!Base2	;
BEQ Label04		;
LDA #$2F		;
Label04:		;
STA $0F			;
PLX			;

LDA $0301|!Base2,y	;
SEC			;
SBC $0F			;
PHP			;
CLC			;
ADC $1C			;
STA $96			;
LDA $1D			;
ADC #$00		;
PLP			;
SBC #$00		;
STA $97			;

STZ $72			;
LDA #$02		;
STA $1471|!Base2	;
LDA !1528,x		;
BEQ SetPhysics		;
CMP #$02		;
BEQ SetPhysics	;

LDA !1540,x	;
CMP #$01		;
BNE Return03	;
LDA #$08		;
STA !1534,x	;
LDY !C2,x	;
LDA YSpeedSet,y	;
STA $7D		;
LDA $07
EOR $05	;determines which direction to bounce
LSR
LDA XSpeedSet,y
BCC .NoXSpeedInvert
EOR #$FF : INC
.NoXSpeedInvert
STA $7B

Return03:
RTS

SetPhysics:

STZ $7B			;
LDY $02			;
LDA BouncePhysics,y	;
STA !151C,x		;
LDA #$01			;
STA !1528,x		;
STZ !1570,x		;
RTS			;