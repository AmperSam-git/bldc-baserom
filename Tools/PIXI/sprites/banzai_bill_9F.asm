;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; SMW Banzai Bill (sprite 9F), by imamelia
;;
;; This is a disassembly of sprite 9F in SMW, the Banzai Bill.
;;
;; Uses first extra bit: YES
;;
;; If the first extra bit is set, the sprite will face the player initially.  If not, it will
;; act like the original Banzai Bill and not show up at all when the player is on the
;; wrong side.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;(Small config by Rykon-V73)Edit the GFX and palette here:

!BBillHorzSpeed = 	$E8

;Change sound effect here:

!BanzaiSFX	= 	$09
!BanzaiSongBank =	$1DFC

!BanzaiPal1	=	$33	;uses palette 3 on 2nd GFX page. For the 1st palette and GFX page 1, set to $30.
!BanzaiPal2	=	$B3	;uses palette 3 on 2nd GFX page. For the 1st palette and GFX page 1, set to $B0.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!XSpeed = !BBillHorzSpeed

print "INIT ",pc
%SubHorzPos()
TYA		;
BEQ MaybeErase	; if the sprite isn't facing the player, it might be erased
STA !157C,x	;
FinishInit:		;
LDA #!BanzaiSFX		;
STA !BanzaiSongBank|!Base2	; play the bullet sound effect
RTL		;

MaybeErase:	;
LDA !7FAB10,x	;
AND #$04	; if the extra bit is set...
BNE FinishInit	; don't erase the sprite
LDA !14C8,x	;
CMP #$08		; if the sprite is in status 07 or less...
BCC EraseSprite1	;
LDA !161A,x	;
CMP #$FF		;
BEQ EraseSprite1	;
TAX
LDA #$00		;
STA !1938,x
LDX $15E9|!Base2
EraseSprite1:	;
STZ !14C8,x	;
RTL

print "MAIN ",pc
PHB : PHK : PLB
JSR BanzaiBillMain
PLB
RTL

BanzaiBillMain:
JSR BanzaiBillGFX	; draw the sprite

LDA !14C8,x	;
CMP #$02		; if the sprite status is 02...
BEQ Return0	; return
LDA $9D		; if sprites are locked...
BNE Return0	; return

%SubOffScreen()

LDA #!XSpeed	;
LDY !157C,x	; if the sprite is facing right...
BNE NoFlipSpeed	;
EOR #$FF		; flip its X speed
INC		; (this wasn't in the original; I added it to account for my modification)
NoFlipSpeed:	;
STA !B6,x		; store the X speed value

JSL $018022|!BankB	; update sprite X position without gravity
JSL $01A7DC|!BankB	;
Return0:		;
RTS		;

XDisp:
db $00,$10,$20,$30,$00,$10,$20,$30,$00,$10,$20,$30,$00,$10,$20,$30
db $30,$20,$10,$00,$30,$20,$10,$00,$30,$20,$10,$00,$30,$20,$10,$00
YDisp:
db $00,$00,$00,$00,$10,$10,$10,$10,$20,$20,$20,$20,$30,$30,$30,$30

Tilemap:
db $00,$01,$02,$03
db $04,$07,$0A,$0B
db $05,$06,$0A,$0B
db $08,$09,$02,$03

TileProp:
db !BanzaiPal1,!BanzaiPal1,!BanzaiPal1,!BanzaiPal1,!BanzaiPal1,!BanzaiPal1,!BanzaiPal1,!BanzaiPal1,!BanzaiPal1,!BanzaiPal1,!BanzaiPal1,!BanzaiPal1,!BanzaiPal1,!BanzaiPal1,!BanzaiPal2,!BanzaiPal2

BanzaiBillGFX:
lda #$1D                 ; find or queue GFX
%FindAndQueueGFX()
bcs .gfx_loaded
rts                      ; don't draw gfx if ExGFX isn't ready

.gfx_loaded
%GetDrawInfo()

LDA !157C,x	;
STA $02		; save the sprite direction

LDX #$0F		; 16 tiles to draw
GFXLoop:		;

PHX		;
LDA $02		; if the sprite is facing right...
BNE NoChangeDisp	;
TXA		;
CLC		;
ADC #$10	; change the index for the X displacement
TAX		;
NoChangeDisp:	;

LDA $00		;
CLC		;
ADC XDisp,x	; set the X displacement of the tiles
STA $0300|!Base2,y	;
PLX

LDA $01		;
CLC		;
ADC YDisp,x	; set the Y displacement of the tiles
STA $0301|!Base2,y	;

PHX
LDA Tilemap,x	; set the tile number
TAX
lda !dss_tile_buffer,x
PLX
STA $0302|!Base2,y	;

LDA TileProp,x	; set the tile properties
PHX		;
LDX $02		;
BNE NoFlip	;
EOR #$40		;
NoFlip:		;
PLX		;
STA $0303|!Base2,y	;

INY #4		; increment the OAM index
DEX		; decrement the tile counter
BPL GFXLoop	; if there are more tiles to draw, run the loop again

LDX $15E9|!Base2
LDY #$02		; the tiles are 16x16
LDA #$0F		; and we drew 16 tiles
JSL $01B7B3|!BankB	;
RTS		;