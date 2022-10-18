;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Magikoopa's magic that teleports
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; defines and tables
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!fixed		= 0		; Teleport to a fixed level? 0 = false, 1 = true. if false, use screen teleport.

;only used for fixed teleport
!level		= $0105		; Change this if needed.
!secondary	= 0		; Secondary exit? 0 = false, 1 = true.
!water		= 0		; If secondary exit, water level? 0 = false, 1 = true.

;is that a bird? is that a plane? no, that's easy prop defines! (don't edit them)
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

MagicPalette:
db !PaletteA|!SP3SP4
db !PaletteB|!SP3SP4
db !PaletteC|!SP3SP4
db !PaletteD|!SP3SP4

Displacement:
db $00,$01,$02,$05,$08,$0B,$0E,$0F
db $10,$0F,$0E,$0B,$08,$05,$02,$01

offset:
db $00,$01,$10,$11

!Tile1 = $01
!Tile2 = $02
!Tile3 = $03

!Sprite1 = $78		;Sprite with very rare chance to spawn. 1-up by default
!Sprite2 = $21		;Sprite with a little bit bigger chance to spawn. Moving Coin by default.
!Sprite3 = $27		;Sprite with a bigger chance to spawn. Thwimp by default.
!Sprite4 = $07		;Sprite that have very big chance to spawn. Yellow Koopa by default.

!SpriteStatus = $08	;Check 14C8 for more info. It's status of the sprite that'll be spawn out of the block magic hits.

!SoundEffect = $01	;Hit Block By default

!SoundPort = $1DF9|!addr	;Sound Effect RAM.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine wrapper
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
PHB
PHK
PLB
JSR MagikoopaMagicMain
PLB
print "INIT ",pc
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MagikoopaMagicMain:
LDA $9D			; if sprites are not locked...
BEQ NormalRt		; run the normal code
JMP AlternateMain	; else, run the alternate code

NormalRt:		;

JSR ShowStars		; show some small star graphics

JSL $01801A|!BankB	; update sprite Y position without gravity
JSL $018022|!BankB	; update sprite X position without gravity

LDA !AA,x		;
PHA			; preserve the sprite's Y speed
LDA #$FF		;
STA !AA,x		; so we can temporarily set it to FF
JSL $019138|!BankB	; for the object contact routine
PLA			;
STA !AA,x		;

LDA !1588,x		;
AND #$08		; if the sprite is not touching the ceiling...
BEQ AlternateMain	;
LDA !15A0,x		; or it is offscreen horizontally...
BNE AlternateMain	; skip to the other part of the main routine

LDA #!SoundEffect	;
STA !SoundPort		; play the "hit block" sound effect (by default anyway)
STZ !14C8,x		; erase the sprite

LDA $185F|!Base2	; check the tile number that the sprite is touching
SEC			;
SBC #$11		;
CMP #$1D		; if it is not between a certain range (111-12D)...
BCS NoGen		; don't erase it or generate a sprite
JSL $01ACF9|!BankB	; get a random number
ADC $148E|!Base2	;
ADC $7B			; add a little more randomness to the mix
ADC $13			;

LDY #!Sprite1		; 78 = 1-Up mushroom
CMP #$35		; if our random number was 35...
BEQ StoreSpriteNum	; then generate a 1-Up mushroom
LDY #!Sprite2		; 21 = moving coin
CMP #$08		; if our random number was less than 08...
BCC StoreSpriteNum	; then generate a moving coin
LDY #!Sprite3		; 27 = Thwimp
CMP #$F7		; if our random number was F7 or greater...
BCS StoreSpriteNum	; then generate a Thwimp
LDY #!Sprite4		; 07 = yellow Koopa
StoreSpriteNum:		; if our random number was anything else...
TYA			; Note that I (RussianMan) had to add this line, because simple STY !9E,x doesn't work on SA-1.
STA !9E,x	; then generate a sprite

LDA #!SpriteStatus	; normal status (or not)
STA !14C8,x		;

JSL $07F7D2|!BankB	; initialize sprite tables

Continue:
LDA $9B			; block X position high byte
STA !14E0,x		; sprite X position high byte
LDA $9A			; block X position low byte
AND #$F0		; directly on a tile
STA !E4,x		; sprite X position low byte
LDA $99			; block Y position high byte
STA !14D4,x		; sprite Y position high byte
LDA $98			; block Y position low byte
AND #$F0		; directly on a tile
STA !D8,x		; sprite Y position low byte

LDA #$02		; tile to generate = blank tile
STA $9C			;

JSL $00BEB0|!BankB	; generate a tile

NoGen:			;

STZ $00 : STZ $01
LDA #$1B : STA $02
LDA #$01
%SpawnSmoke()		;

RTS			;

AlternateMain:

JSL $01803A|!BankB	; interact with the player and with other sprites
BCC .Continue

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;teleport.asm (Teleport Pack by Alcaro & MarioE)
if !fixed
	REP #$20
	LDA #!level|(((!water<<3)|(1<<2)|(!secondary<<1))<<8)
	PHA
	STZ $88

;%teleport()
	SEP #$30

	if !EXLEVEL
		JSL $03BCDC|!bank
	else
		LDX $95
		PHA
		LDA $5B
		LSR
		PLA
		BCC +
		LDX $97
	+
	endif
	PLA
	STA $19B8|!addr,x
	PLA
	ORA #$04
	STA $19D8|!addr,x

	LDA #$06
	STA $71

	LDX $15E9|!addr
else
	LDA #$06
	STA $71
	STZ $88
	STZ $89
endif

.Continue
LDA $13			;
LSR			;
LSR			;
AND #$03		; palette index
TAY			;
LDA MagicPalette,y	; change the palette of the magic every 4 frames
STA !15F6,x		;

JSR MagikoopaMagicGFX

LDA #$00
%SubOffScreen()		;someone forgot suboffscreen...

LDA !D8,x		;
SEC			;
SBC $1C			;
CMP #$E0		; if the sprite is too far offscreen...
BCC NoStars		;
STZ !14C8,x		; erase it

NoStars:		;
RTS

ShowStars:		;

LDA $13			;
AND #$03		; if the frame isn't a multiple of 4...
ORA !186C,x		; the sprite is offscreen vertically...
ORA $9D			; or sprites are locked...
BNE NoStars		; don't show any stars

JSL $01ACF9|!BankB	; get a random number
AND #$0F		; between 00 and 0F
CLC			;
LDY #$00		;
ADC #$FC		;
BPL NoDecY1		;
DEY			;

NoDecY1:		;
CLC			;
ADC !E4,x		; set the position of the stars
STA $02			;
TYA			;
ADC !14E0,x		;
PHA			;
LDA $02			;
CMP $1A			;
PLA			;
SBC $1B			;
BNE NoStars		;

LDA $148E|!Base2	;
AND #$0F		;
CLC			;
ADC #$FE		;
ADC !D8,x		;
STA $00			;
LDA !14D4,x		;
ADC #$00		;
STA $01			;

JSL $0285BA|!BankB	; show small stars routine

RTS			;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; graphics routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MagikoopaMagicGFX:
lda #$2D              ; find or queue GFX
%FindAndQueueGFX()
bcs .gfx_loaded
rts                      ; don't draw gfx if ExGFX isn't ready 
.gfx_loaded
%GetDrawInfo()

LDA $14		; some preliminary stuff
LSR		;
AND #$0F	; get an index for the X displacement
STA $03		;
CLC		;
ADC #$0C	; get an index for the Y displacement
AND #$0F	;
STA $02		;

LDA $01		;
SEC		;
SBC #$04		; offset the sprite's X and Y position
STA $01		;
LDA $00		; by -4 each
SEC		;
SBC #$04		;
STA $00		;

LDX $02			;
LDA $01			;
CLC			;
ADC Displacement,x	; set the Y displacement of the first tile
STA $0301|!Base2,y		;

LDX $03
LDA $00			;
CLC			;
ADC Displacement,x	; set the X displacement of the first tile
STA $0300|!Base2,y		;

LDA $02			;
CLC			;
ADC #$05		; Y index 5 places down
AND #$0F		;
STA $02			;

TAX			;
LDA $01			;
CLC			;
ADC Displacement,x	; set the Y displacement of the second tile
STA $0305|!Base2,y		;

LDA $03			;
CLC			;
ADC #$05		; X index 5 places down
AND #$0F		;
STA $03			;

LDX $03
LDA $00			;
CLC			;
ADC Displacement,x	; set the X displacement of the second tile
STA $0304|!Base2,y		;

LDA $02			;
CLC			;
ADC #$05		; Y index 5 places down
AND #$0F		;
STA $02			;

TAX			;
LDA $01			;
CLC			;
ADC Displacement,x	; set the Y displacement of the third tile
STA $0309|!Base2,y		;

LDA $03			;
CLC			;
ADC #$05		; X index 5 places down
AND #$0F		;
STA $03			;

LDX $03
LDA $00			;
CLC			;
ADC Displacement,x	; set the X displacement of the third tile
STA $0308|!Base2,y		;

LDA #!Tile1		;
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
STA $0302|!Base2,y		; first tile number

LDA #!Tile2		;
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
STA $0306|!Base2,y		; second tile number

LDA #!Tile3		;
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
STA $030A|!Base2,y		; third tile number

LDX $15E9|!Base2		;
LDA !15F6,x		; sprite palette/GFX page
ORA $64			; add in sprite priority
STA $0303|!Base2,y		; tile properties for the first tile
STA $0307|!Base2,y		; tile properties for the second tile
STA $030B|!Base2,y		; tile properties for the third tile

LDY #$00			; 8x8 tiles
LDA #$02			; 3 of them
%FinishOAMWrite()

RTS			;