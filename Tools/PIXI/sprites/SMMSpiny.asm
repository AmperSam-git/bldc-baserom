;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Super Mario Maker. - Flying Spiny
;
;This is a flying spiny from SMM. it moves in a straight horizontal line with slight vertical movement.
;It also occasionally spawns needles.
;
;By RussianMan. Credit is optional.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!NeedleSprite = $06		;custom extended sprite

!BecomeEggTime = $90		;how long it takes to turn into egg
!SpinyEggTime = $40		;how long it'll stay in "spiny egg" mode (untill shooting needles)

!NeedleSpawnTime = $20		;how long it takes to spawn needles
!NeedleTime = $F0		;how long needles will stay on-screen untill they blink out of existence

!MaxUpDownSpd = $04		;how fast it moves when it moves up/down
!XSpeed = $09			;

!NeedleXSpeed = $0F		;
!NeedleYSpeed = $0F		;

MaxYSpd:
db !MaxUpDownSpd,-!MaxUpDownSpd

Accel:
db $01,-$01

XSpeedTable:
db !XSpeed,-!XSpeed

;first two - normal, 16x16, last two - spiny egg, 8x8
Tilemap:
db $00,$01			;turns out they use only one frame while not in "egg" form. but you can change that easily.
db $08,$0A

EggXDisp:
db $00,$08,$00,$08

EggYDisp:
db $00,$00,$08,$08

EggFlips:
db $00,$40,$80,$C0

Flips:
db $40,$00			;horizontal, normal spiny, depends on facing

;first 4 bytes for horz/vert needles, 4 last are for diagonal
;Right, Left, Up, down, Up-Right, Down-right, Up-left, Down-left
NeedleXDisp:
db $08,$00,$04,$04
db $08,$08,$00,$00

;same for this
NeedleYDisp:
db $04,$04,$00,$08
db $00,$08,$00,$08

NeedleXSpeed:
db !NeedleXSpeed,-!NeedleXSpeed,$00,$00
db !NeedleXSpeed,!NeedleXSpeed,-!NeedleXSpeed,-!NeedleXSpeed

NeedleYSpeed:
db $00,$00,-!NeedleYSpeed,!NeedleYSpeed
db -!NeedleYSpeed,!NeedleYSpeed,-!NeedleYSpeed,!NeedleYSpeed

;wing graphic tables
WingSize:
db $00,$02,$00,$02

WingXDisp:
db $FF,$F8,$07,$09

WingYDisp:
db $FF,$F7,$FF,$F7

WingProps:
db $76,$76,$36,$36

WingTiles:
db $5D,$4E,$5D,$4E

offset:
db $00,$01,$10,$11

!SpinyTimer = !1540,x
!NeedleState = !151C,x	;state for needles, where 0 - + pattern, 1 - x pattern
!VerticalDirection = !1570,x

Print "INIT ",pc
%SubHorzPos()			;common initial facing code
TYA				;
STA !157C,x			;

TYX				;
LDA.l XSpeedTable,x		;set speed only in init
LDX $15E9|!Base2		;
STA !B6,x			;means we don't set speed constantly in main = less cycles
				;(and since they don't interact with objects and can't change direction, it doesn't matter)

LDA #!BecomeEggTime		;become eggman
STA !SpinyTimer			;
RTL

Print "MAIN ",pc
PHB
PHK
PLB
JSR Spiny
PLB
RTL

Spiny:
JSR GFX				;

LDA !14C8,x			;WONDER WHAT THESE DO???7
EOR #$08			;
ORA $9D				;
BNE .Re				;
%SubOffScreen()			;

LDA $14				;
AND #$07			;
BNE .NoChange			;
;BNE .NoFrame			;both frame and Y-speed shenanigans use same frame counter check. why not combine?

LDA !1602,x			;
EOR #$01			;
STA !1602,x			;

.NoFrame
;LDA $14
;AND #$07
;BNE .NoChange

LDY !VerticalDirection		;
LDA !AA,x			;
CMP MaxYSpd,y			;
BEQ .Change			;
CLC : ADC Accel,y		;
STA !AA,x			;
BRA .NoChange			;

.Change
LDA !VerticalDirection		;
EOR #$01			;
STA !VerticalDirection		;

.NoChange
JSL $01A7DC|!BankB		;player
JSL $018022|!BankB		;X-speed
JSL $01801A|!BankB		;Y-speed

LDA !C2,x			;flag checks if we're in "egg" state
BEQ .OnlyTurnIntoEgg		;

LDA !SpinyTimer			;check when it should turn into normal
BEQ .BackToNormal		;
CMP #!NeedleSpawnTime		;check when it spawns needles
BEQ .Spawn			;

.Re
RTS				;

.Spawn
LDA !NeedleState		;
ASL #2				;
STA $0A				;

LDA !NeedleState		;change needle state for next spawn
EOR #$01			;
STA !NeedleState		;

LDY #$03			;4 needles

.SpawnLoop
JSR SpawnNeedle			;check slots n stuff

INC $0A				;next needle direction
DEY				;
BPL .SpawnLoop			;
RTS

.BackToNormal
STZ !C2,x			;
STZ !1602,x			;

LDA #!BecomeEggTime		;
STA !SpinyTimer			;
RTS				;

.OnlyTurnIntoEgg
LDA !SpinyTimer			;
BNE .NoTurn			;

LDA #!SpinyEggTime		;
STA !SpinyTimer			;

LDA !1602,x			;set proper tilemap
ORA #$02			;
STA !1602,x			;

INC !C2,x			;turn into egg

.NoTurn
RTS				;

SpawnNeedle:
PHY				;
LDY $0A				;set needle offset
LDA NeedleXDisp,y		;
STA $00				;

LDA NeedleYDisp,y		;
STA $01				;

LDA NeedleXSpeed,y		;
STA $02				;

LDA NeedleYSpeed,y		;
STA $03				;

LDA #!NeedleSprite+!ExtendedOffset
%SpawnExtended()		;
BCS .Terminate			;if no free sprite slot found, terminate (don't loop for the rest of needles if failed to spawn, reducing processor cost)
CPY #$FF			;just in case, since there is a bug with those spawn routines
BEQ .Terminate			;

LDA $0A				;
STA $1765|!Base2,y		;Misc. ram for extended sprites

LDA #!NeedleTime		;
STA $176F|!Base2,y		;set needle's timer
PLY				;
RTS				;

.Terminate
PLY				;
PLA				;
PLA				;
RTS				;

GFX:
lda #$08                 ; find or queue GFX
%FindAndQueueGFX()
bcs .gfx_loaded
rts                      ; don't draw gfx if ExGFX isn't ready

.gfx_loaded
%GetDrawInfo()			;

LDA !14C8,x			;if dead, don't animate
CMP #$08			;
BCC .NoAnim			;

LDA $14				;

.NoAnim
LSR #3				;
AND #$01			;
STA $02				;

LDA !157C,x			;\ i'm good at stealing code. twice
ASL				; | multiply the direction
CLC				; | add our frame index to index the tables
ADC $02				; |
TAX				;/
LDA $00				;\
CLC				; | wings x pos
ADC WingXDisp,x			; |
STA $0300|!Base2,y		;/

LDA $01				;\
CLC				; | wings y pos
ADC WingYDisp,x			; |
STA $0301|!Base2,y		;/

LDA WingTiles,x			;\  wings tilemap
STA $0302|!Base2,y		;/

LDA $64				;\
ORA WingProps,x			; | wings properties
STA $0303|!Base2,y		;/

TYA				;\
LSR #2				; | index into tilesize
TAY				;/
LDA WingSize,x			;\  variable size, depending on the wing frame
STA $0460|!Base2,y      	;/

LDX $15E9|!Base2		;restore sprite slot

LDA !15EA,x			;tile index
CLC : ADC #$04			;
TAY				;"INY #4"

LDA !157C,x			;
STA $02				;

LDA !15F6,x			;
ORA $64
STA $04				;

LDA !1602,x			;get proper tilemap
TAX				;
LDA Tilemap,x			;
STA $03				;
CPX #$02			;
BCS SpinyEggGfx			;check if it should turn into spiny egg (that's 4 8x8 tiles)

;Normal spiny gfx
LDA $00				;
STA $0300|!Base2,y		;

LDA $01				;
STA $0301|!Base2,y		;

LDA $03				;
TAX
lda !dss_tile_buffer,x
STA $0302|!Base2,y		;

LDX $02				;props
LDA $04				;
ORA Flips,x			;
;ORA $64
STA $0303|!Base2,y		;

PHY				;
TYA				;
LSR #2				;
TAY				;
LDA #$02			;16x16 tiles
STA $0460|!Base2,y		;
PLY				;

LDA #$01			;2 tiles

.DrawEnd
LDX $15E9|!Base2		;restore sprite slot

LDY #$FF			;different sizes (except when in egg form but whatev)
JSL $01B7B3|!BankB		;
RTS				;

SpinyEggGfx:
;ASL #2
;STA $03

LDX #$03			;4 tiles to draw

.loop
LDA EggXDisp,x			;
CLC : ADC $00			;
STA $0300|!Base2,y		;

LDA EggYDisp,x			;
CLC : ADC $01			;
STA $0301|!Base2,y		;

PHX
LDA $03				;
pha
and #$03
tax 
lda.l offset,x
sta $0F
pla
lsr #2
tax 
lda.l !dss_tile_buffer,x
ora $0F
plx 
STA $0302|!Base2,y		;

LDA EggFlips,x			;
ORA $04				;
;ORA $64			;less cycles per loop, yo
STA $0303|!Base2,y		;

PHY				;
TYA                     	;
LSR #2                  	;
TAY                     	;
LDA #$00     			;8x8 tiles
STA $0460|!Base2,y      	;
PLY				;

INY #4				;
DEX				;
BPL .loop			;

LDA #$04			;5 tiles
BRA GFX_DrawEnd			;efficiency or space? hmm... (to be fair only, like, a couple of cycles more used, so, eh)

;LDX $15E9|!Base2

;LDA #$04			;
;LDY #$FF			;custom sizes
;JSL $01B7B3|!BankB		;
;RTS				;