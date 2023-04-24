!GFX_FileNum = $A4 ; DSS ExGFX
!ExplodeTimer = $40
!Tile = $00

print "INIT ", pc
	rtl

print "MAIN ", pc
	phb
	phk
	plb
	jsr BombMain
	plb
	rtl

BombMain:
	jsr Graphics
	lda !14C8,x
	cmp #$08
	bne .return

	lda !1540,x
	beq .alive
	dec
	bne .explode
	stz !14C8,x
.return
	rts

.explode
	phb
	lda #$02
	pha
	plb
	jsl $028086
	plb
	rts
.alive
	lda $9D
	bne .return
	lda #$03
	%SubOffScreen()

	lda !1588,x
	and #$0F
	beq .noExplosion
	lda #!ExplodeTimer
	sta !1540,x
	lda #$09
	sta $1DFC|!Base2
.noExplosion
	jsl $01802A|!BankB
	jsl $018032|!BankB
	jsl $01A7DC|!BankB
	rts

Graphics:
    lda #!GFX_FileNum
    %FindAndQueueGFX()
    bcs .gfx_loaded
    rts
.gfx_loaded
	%GetDrawInfo()
	lda !1540,x
	bne .nodraw

	lda $00
	sta $0300|!Base2,y
	lda $01
	sta $0301|!Base2,y
	lda !dss_tile_buffer+!Tile
	sta $0302|!Base2,y
	lda !15F6,x
	ora $64
	sta $0303|!Base2,y

	ldy #$02
	lda #$00
	jsl $01B7B3|!BankB
.nodraw
	rts
