!GFX_FileNum = $90		;EXGFX number for this sprite

;cape interaction
Print "CAPE",pc
    LDA #$04
    STA $00			;x-clipping offset
    STA $02			;y-clipping offset

    LDA #$08
    STA $01			;width
    STA $03			;height

    %ExtendedCapeClipping()
    BCC CAPE_RETURN		;no interaction? BEGONE

    LDA #$07			;puff of smoke timer
    STA $176F|!addr,X

    LDA #$01			;Change the sprite into a puff of smoke.
    STA $170B|!addr,x

CAPE_RETURN:
RTL

Print "MAIN ",pc
PHB : PHK : PLB
JSR START_SPRITE_CODE
PLB
RTL

Tile:	db $02,$03
Prop:	db $05,$05

offset:
db $00,$01,$10,$11

START_SPRITE_CODE:
lda #!GFX_FileNum                  ;load boomerang projectile
%FindAndQueueGFX()
bcs .gfx_loaded
rts                      ; don't draw gfx if ExGFX isn't ready 

.gfx_loaded
%ExtendedGetDrawInfo()
PHX
LDA $1779|!Base2,x : AND #$7F : LSR #3 : TAX
LDA $01 : STA $0200|!Base2,y
LDA $02 : STA $0201|!Base2,y
PHX
LDA Tile,x
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
STA $0202|!Base2,y
LDA Prop,x : ORA $64 : STA $0203|!Base2,y
TYA : LSR #2 : TAY
LDA #$00 : STA $0420|!Base2,y
PLX
LDA $9D : BNE Return

INC $1779|!Base2,x
LDA $1779|!Base2,x : AND #$7F : CMP #$10 : BCC Animating
LDA $1779|!Base2,x : AND #$80 : STA $1779|!Base2,x
Animating:
LDA #$01
%ExtendedSpeed()
CLC
%ExtendedContact()
BCC Return
LDA $187A|!Base2
BEQ .No_Yoshi
%LoseYoshi()
RTS
.No_Yoshi:
JSL $00F5B7|!BankB
Return:
RTS