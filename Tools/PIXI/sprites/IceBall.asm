
!GFX_FileNum = $90		;EXGFX number for this sprite
					
!FrozenTimer = 		$18BD|!Base2
					
					print "INIT ",pc
					LDA #$01 : STA !C2,x
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
					DEC !AA,x
					
+					LDA !1588,x
					BIT #$0C : BEQ NoGround
					
					LDA #$C8 : STA !AA,x
					CLC
					LDA !D8,x : ADC #$08 : STA !D8,x
					LDA !14D4,x : ADC #$00 : STA !14D4,x
					DEC !C2,x : BMI Erase
					
NoGround:			LDA !1588,x
					BIT #$03 : BEQ NoWall
					
Erase:				LDA #$01 : STA $1DF9|!Base2
Frozen:				LDA #$10 : STA $02
					LDA #$FC : STA $00 : STA $01
					LDA #$01
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
					LDA #$40 : STA !FrozenTimer
					LDA $187A|!Base2
					BEQ .No_Yoshi
					%LoseYoshi()
					LDA #$1C : STA $1DF9|!Base2
					BRA Frozen
.No_Yoshi:			JSL $00F5B7|!BankB
					LDA #$1C : STA $1DF9|!Base2
					BRA Frozen
					
RETURN:				RTS                     ; return
					
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; graphics routine 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					
TileMap:			db $01,$01,$01,$01
					
Property:			db $0D,$0D,$0D,$0D

offset:
db $00,$01,$10,$11
					
SUB_GFX:			
					lda #!GFX_FileNum        ; find or queue GFX
					%FindAndQueueGFX()
					bcs .gfx_loaded
					rts                      ; don't draw gfx if ExGFX isn't ready	
.gfx_loaded
					%GetDrawInfo()
					LDA !157C,x : STA $02
					PHX
					
					LDA !1602,x : LSR #2 : AND #$03 : TAX
					
					LDA $00 : STA $0300|!Base2,y	;X Position
					LDA $01 : STA $0301|!Base2,y	;Y Position
					
					PHX
					LDA TileMap,x
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
					STA $0302|!Base2,y	;
					
					LDA Property,x
					LDX $02 : BNE .No_Flip
					EOR #$40
.No_Flip:			ORA $64 : STA $0303|!Base2,y	;Property
					
					PLX
					LDY #$00 : LDA #$00
					JSL $01B7B3|!BankB
					RTS