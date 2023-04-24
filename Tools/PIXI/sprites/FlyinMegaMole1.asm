;=======================================================
; Flyin' Mega Mole
; By Erik557
;
; Description: A Mega Mole with fucking wings. Yup, we
; have come this far regarding janky ideas.
; This version emulates the green flying parakoopa, aka
; sprite 08.
;
; Uses first extra bit: NO
;=======================================================

;======================
; Defines and stuff
;======================

XSpeeds:
       db $0A,$F6

Tilemap:
       db $00,$01,$02,$03
       db $04,$05,$06,$07
WingsTiles:
       db $5D,$4E,$5D,$4E
WingProps:
       db $76,$76,$36,$36

;=================================
; INIT and MAIN Wrappers
;=================================

print "INIT ",pc
       %SubHorzPos()
       TYA
       STA !157C,x
       JSL $01ACF9|!BankB
       STA !1570,x
       RTL

print "MAIN ",pc
       PHB
       PHK
       PLB
       JSR flyinMegaMole
       PLB
       RTL

;========================
; Main routine
;========================

MainReturn:
       RTS

flyinMegaMole:
       JSR Graphics
       LDA !14C8,x
       EOR #$08
       ORA $9D
       BNE MainReturn
       LDA #$03
       %SubOffScreen()
       LDY !157C,x
       LDA XSpeeds,y
       STA !B6,x
       JSL $01801A|!BankB
       JSL $018022|!BankB

       LDY #$F8
       INC !1570,x
       LDA !1570,x
       AND #$20
       BEQ +
       LDY #$08
+      STY !AA,x
       LDA !1570,x
       LSR #2
       AND #$01
       STA !1602,x

       JSL $018032|!BankB
       JSL $01A7DC|!BankB
       BCC MainReturn
       %SubVertPos()
       LDA $0F
       CMP #$D8
       BPL .hurt
       LDA $7D
       BMI MainReturn
       LDA #$01
       STA $1471|!Base2
       STZ $7D
       LDA #$D6
       LDY $187A|!Base2
       BEQ +
       LDA #$C6
+      CLC
       ADC !D8,x
       STA $96
       LDA !14D4,x
       ADC #$FF
       STA $97
       LDY #$00
       LDA $1491|!Base2
       BPL +
       DEY
+      CLC
       ADC $94
       STA $94
       TYA
       ADC $95
       STA $95
       RTS

.hurt
       JSL $00F5B7|!BankB
       RTS

;========================
; Graphics routine
;========================

XDisp:
       db $00,$10,$00,$10
       db $10,$00,$10,$00
YDisp:
       db $F0,$F0,$00,$00
WingsSize:
       db $00,$02,$00,$02
WingsXDisp:
       db $02,$FA,$16,$18
WingsYDisp:
       db $FC,$F4,$FC,$F4

Graphics:
       lda #!dss_id_mega_mole
       %FindAndQueueGFX()
       bcs .gfx_loaded
       rts
.gfx_loaded
       %GetDrawInfo()

       LDA !1602,x          ;\  tile index for future uses
       STA $02              ;/
       LDA !157C,x          ;\
       ASL                  ; | multiply the direction
       CLC                  ; | add our frame index to index the tables
       ADC $02              ; |
       TAX                  ;/
       LDA $00              ;\
       CLC                  ; | wings x pos
       ADC WingsXDisp,x     ; |
       STA $0300|!Base2,y   ;/
       LDA $01              ;\
       CLC                  ; | wings y pos
       ADC WingsYDisp,x     ; |
       STA $0301|!Base2,y   ;/
       LDA WingsTiles,x     ;\  wings tilemap
       STA $0302|!Base2,y   ;/
       LDA $64              ;\
       ORA WingProps,x      ; | wings properties
       STA $0303|!Base2,y   ;/
       TYA                  ;\
       LSR #2               ; | index into tilesize
       TAY                  ;/
       LDA WingsSize,x      ;\  variable size, depending on the wing frame
       STA $0460|!Base2,y   ;/

       LDX $15E9|!Base2     ;   retrieve index
       LDA !15EA,x          ;\
       CLC                  ; | get new set of oam slots
       ADC #$04             ; |
       TAY                  ;/

       LDA !157C,x
       STA $02
       LDA !1570,x
       LSR #3
       AND #$01
       ASL #2
       STA $03

       LDX #$03
-      PHX
       LDA $02
       BNE +
       INX #4
+      LDA $00
       CLC
       ADC XDisp,x
       STA $0300|!Base2,y
       LDA $01,s
       TAX
       LDA $01
       CLC
       ADC YDisp,x
       STA $0301|!Base2,y
       TXA
       CLC
       ADC $03
       TAX
       LDA Tilemap,x
       TAX
       lda.l !dss_tile_buffer,x
       STA $0302|!Base2,y
       LDA #$01
       LDX $02
       BNE +
       ORA #$40
+      ORA $64
       STA $0303|!Base2,y
       PHY
       TYA
       LSR #2
       TAY
       LDA #$02
       STA $0460|!Base2,y
       PLY
       PLX
       INY #4
       DEX
       BPL -

       LDX $15E9|!Base2
       LDY #$FF
       LDA #$04
       JSL $01B7B3|!BankB
       RTS

