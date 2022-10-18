					print "INIT ",pc
					RTL
					
					print "MAIN ",pc
					PHB : PHK : PLB
					JSR START_SPRITE_CODE
					PLB
					RTL
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RETURN_:			RTS
START_SPRITE_CODE:	JSR SUB_GFX
					LDA #$00 : %SubOffScreen()
					LDA !14C8,x	: CMP #$08 : BNE RETURN_
					LDA $9D : BNE RETURN_
					
					INC !1602,x
					JSL $01802A|!BankB
					
+					LDA !1588,x
					BIT #$0C : BEQ NoGround
					
					LDA #$D8 : STA !AA,x
					CLC
					LDA !D8,x : ADC #$08 : STA !D8,x
					LDA !14D4,x : ADC #$00 : STA !14D4,x
					
NoGround:			LDA !1588,x
					BIT #$03 : BEQ NoWall
					
					LDA #$10 : STA $02
					LDA #$FC : STA $00 : STA $01
					LDA #$01 : STA $1DF9|!Base2
					%SpawnSmoke()
					STZ !14C8,x
					RTS
					
NoWall:				JSL $03B69F|!BankB
					LDA #$06 : STA $06 : STA $07
					LDA $05 : SEC : SBC #$01 : STA $05
					LDA $0B : SBC #$00 : STA $0B
					JSL $03B664|!BankB
					JSL $03B72B|!BankB
					BCC RETURN
					LDA $187A|!Base2
					BEQ .No_Yoshi
					%LoseYoshi()
					BRA RETURN
.No_Yoshi:			JSL $00F5B7|!BankB
					
RETURN:				RTS                     ; return
					
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; graphics routine 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					
TileMap:			db $2C,$2D,$2C,$2D
					
Property:			db $04,$04,$C4,$C4
					
SUB_GFX:			%GetDrawInfo()
					LDA !157C,x : STA $02
					PHX
					
					LDA !1602,x : LSR #2 : AND #$03 : TAX
					
					LDA $00 : STA $0300|!Base2,y	;X Position
					LDA $01 : STA $0301|!Base2,y	;Y Position
					
					LDA TileMap,x : STA $0302|!Base2,y	;
					
					LDA Property,x
					LDX $02 : BNE .No_Flip
					EOR #$40
.No_Flip:			ORA $64 : STA $0303|!Base2,y	;Property
					
					PLX
					LDY #$00 : LDA #$00
					JSL $01B7B3|!BankB
					RTS