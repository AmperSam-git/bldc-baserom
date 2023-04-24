;pokey's segment that hurt the player
;to be used with Throwaway Pokey, acts like a projectile

!Tile = $01

Print "MAIN ",pc
PHB
PHK
PLB
JSR YAY
PLB
Print "INIT ",pc
RTL

YAY:
JSR Graphics

LDA !14C8,x			;dead and freeze flag check
EOR #$08
ORA $9D
BNE .Re
%SubOffScreen()

JSL $01802A|!BankB		;gravity
JSL $01A7DC|!BankB		;interact with the player

.Re
RTS

Graphics:
lda #!dss_id_pokey
%FindAndQueueGFX()    ; find or queue GFX
bcs .gfx_loaded
rts                     ; don't draw gfx if ExGFX isn't ready
.gfx_loaded
%GetDrawInfo()

LDA $00
STA $0300|!addr,y

LDA $01
STA $0301|!addr,y

LDA.l !dss_tile_buffer+!Tile
STA $0302|!addr,y

LDA !15F6,x
ORA $64
STA $0303|!addr,y

LDY #$02
LDA #$00
JSL $01B7B3|!BankB
RTS