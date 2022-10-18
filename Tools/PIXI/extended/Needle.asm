;Needle projectile used by SMM Flying Spiny

!GFX_FileNum = $91		;EXGFX number for this sprite

!TimeForBlink = $30

;easy hardcoded property setting.
!NeedleGFXProp = !PaletteC|!SP3SP4

!Palette8 = %00000000
!Palette9 = %00000010
!PaletteA = %00000100
!PaletteB = %00000110
!PaletteC = %00001000
!PaletteD = %00001010
!PaletteE = %00001100
!PaletteF = %00001110

!SP1SP2 = %00000000
!SP3SP4 = %00000001

;don't edit! Only edit !NeedleGFXProp from above. contains YX Flip data.
Props:
db !NeedleGFXProp,!NeedleGFXProp|$40,!NeedleGFXProp,!NeedleGFXProp|$80
db !NeedleGFXProp|$80,!NeedleGFXProp,!NeedleGFXProp|$C0,!NeedleGFXProp|$40

TileMap:
db $01,$01,$00,$00		;left/right and up/down
db $02,$02,$02,$02		;diagonal

offset:
db $00,$01,$10,$11

Print "MAIN ",pc
NeedleForSpeedle:
LDA $9D
BNE MaybeGFX

;%ExtendedHurt()		;hurt player and stuff
JSR Interaction			;

LDA #$01
%ExtendedSpeed()		;update position based on speed and stuff

MaybeGFX:
LDA $176F|!Base2,x		;
BEQ KillExtended		;erase
CMP #!TimeForBlink		;
BCS .NoBlink
AND #$01			;
BNE Return			;Blinking animation

.NoBlink
	lda #!GFX_FileNum        ; find or queue GFX
	%FindAndQueueGFX()
	bcs .gfx_loaded
	rts                      ; don't draw gfx if ExGFX isn't ready	
.gfx_loaded
%ExtendedGetDrawInfo()

LDA $01				;Tile's X position
STA $0200|!Base2,y		;

LDA $02				;Y position
STA $0201|!Base2,y		;ordinary stuff

LDA $1765|!Base2,x		;
TAX				;
PHX
LDA TileMap,x			;
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
STA $0202|!Base2,y		;

LDA Props,x			;
ORA $64				;
STA $0203|!Base2,y		;

TYA				;
LSR #2				;
TAY				;
LDA #$00			;sprite tile size = 8x8
STA $0420|!Base2,y		;

LDX $15E9|!Base2		;

Return:
RTL				;

KillExtended:
STZ !extended_num,x
RTL

;standart %ExtendedHurt isn't very good.
Interaction:
JSR GetExClipping

JSL $03B664|!BankB		;get mario's clipping

JSL $03B72B|!BankB		;
BCC .DiffRe			;

PHB
				;
LDA.b #$02			;	
PHA
				;
PLB
				;
PHK
				;
PEA.w .return-1
			;
PEA.w $B889-1
			;
JML $02A469|!BankB		
;hurt mario

.return
	
PLB				;

.DiffRe
RTS				;

GetExClipping:
LDA $171F|!Base2,x		;Get X position
;SEC				;Calculate hitbox
;SBC #$02			;
STA $04				;

LDA $1733|!Base2,x		;
;SBC #$00			;Take care of high byte
STA $0A				;

LDA #$06			;width
STA $06				;

LDA $1715|!Base2,x		;Y pos
CLC				;
ADC #$02			;
STA $05				;

LDA $1729|!Base2,x		;
ADC #$00			;
STA $0B				;

LDA #$06			;length
STA $07				;
RTS				;