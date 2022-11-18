;-----------------------------------------------------------------------------------------
; Better Donut by AmperSam
;-----------------------------------------------------------------------------------------
; config
;-----------------------------------------------------------------------------------------

    !map16_block = $03A4        ; map16 value of the donut block in hex
    !sprite_tile = $C2          ; graphic tile to use for donut sprite
    !direction = 1              ; 0 = vertical, 1 = horizontal
    !speed_value = $E0          ;\ positive (00-7F) values = down/right,
    !max_speed = $D0            ;/ negative (80-FF) values = up/left

;-----------------------------------------------------------------------------------------
; definitions
;-----------------------------------------------------------------------------------------

; DO NOT CHANGE
if !direction == 1
    !position_change = !sprite_speed_x,x
else
    !position_change = !sprite_speed_y,x
endif

;-----------------------------------------------------------------------------------------
; init
;-----------------------------------------------------------------------------------------

print "INIT ",pc
    RTL

;-----------------------------------------------------------------------------------------
; main
;-----------------------------------------------------------------------------------------

print "MAIN ",pc
    PHB
    PHK
    PLB
    JSR Donut
    PLB
    RTL

;-----------------------------------------------------------------------------------------
; sprite routine
;-----------------------------------------------------------------------------------------

Donut:

    JSR donut_gfx

    LDA #$00
    %SubOffScreen()

    LDA $9D
    BNE return
    LDA !14C8,x
    CMP #$08
    BNE return

    LDA !position_change
    BEQ ++

    LDA !position_change
    CMP #!max_speed
    BMI +
    SEC
    SBC #$02
    STA !position_change
+
    if !direction == 1
        JSL $018022|!BankB      ;load x position subroutine
    else
        JSL $01801A|!BankB      ;load y position subroutine
    endif

    LDA #$01
    STA !1558,x
++
    JSL $01B44F|!BankB
    BCC draw_map16

    LDA !1558,x
    BNE +
    LDA #$28
    STA !1558,x
+
    DEC A
    STA !1558,x
    CMP #$01
    BNE +
    LDA #!speed_value
    STA !position_change
+
-
    JSL $01A7DC|!BankB
    BCC +
    LDA $77
    AND #$08
    BEQ +
    JSL $00F606|!BankB
+
return:
    RTS

draw_map16:
    LDA !position_change
    BNE -

    STZ !sprite_status,x
    STZ !1558,x

    LDA !sprite_y_low,x
    STA $98
    LDA !sprite_y_high,x
    STA $99
    LDA !sprite_x_low,x
    STA $9A
    LDA !sprite_x_high,x
    STA $9B

    PHP
    REP #$30
    LDA #!map16_block
    %ChangeMap16()
    PLP
    RTS

;-----------------------------------------------------------------------------------------
; graphics routine (edited for DSS)
;-----------------------------------------------------------------------------------------

donut_gfx:
   lda #$7B                 ; find or queue ExGFX D7B
   %FindAndQueueGFX()
   bcs .gfx_loaded
   rts                      ; don't draw gfx if ExGFX D7B isn't ready

.gfx_loaded
   %GetDrawInfo()

    LDA !position_change
    BNE +

    LDA $14
    AND #$02
    BNE +
    LDA !1558,x
    BEQ +

+   DEC $00
    lda $00
    sta $0300|!Base2,y
    lda $01
    sta $0301|!Base2,y
    lda !dss_tile_buffer+$00 ; load the first tile in the buffer
    sta $0302|!Base2,y
    lda #$25                 ; remember to use the second page!
    sta $0303|!Base2,y
    lda #$00
    ldy #$02
    jsl $01B7B3|!BankB
    rts
