!GFX_FileNum = $90		;EXGFX number for this sprite

					print "INIT ",pc
					RTL
					
					print "MAIN ",pc
					PHB : PHK : PLB
					JSR START_SPRITE_CODE
					PLB
					RTL
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlopeMaxSpeed:		db $E0,$E0,$F0,$F8,$00,$08,$10,$20,$20
SlopeSpeed:			db $C0,$C0,$E8,$F8,$00,$08,$18,$40,$40

RETURN_:			RTS
START_SPRITE_CODE:	JSR SUB_GFX
					LDA #$00 : %SubOffScreen()
					LDA !14C8,x	: CMP #$08 : BNE RETURN_
					LDA $9D : BNE RETURN_
					
					INC !1602,x
					JSL $01802A|!BankB
					
					LDA !15B8,x	: BEQ Horizontal
					CLC : ADC #$04 : TAY : CLC
					LDA !15B8,x : BMI Right_Climbing
					
Left_Climbing:		LDA !B6,x : CMP SlopeMaxSpeed,y : BPL NoChangeSpeed
					CLC : ADC SlopeSpeed,y
					CMP SlopeMaxSpeed,y : BPL OverMaxSpeed
					BRA ChangeSpeed
					
Right_Climbing:		LDA !B6,x : CMP SlopeMaxSpeed,y : BMI NoChangeSpeed
					CLC : ADC SlopeSpeed,y
					CMP SlopeMaxSpeed,y : BMI OverMaxSpeed
					BRA ChangeSpeed
					
OverMaxSpeed:		LDA SlopeMaxSpeed,y
ChangeSpeed:		STA !B6,x

NoChangeSpeed:
Horizontal:			LDA !1588,x
					BIT #$04 : BEQ NoGround
					
					LDA #$B0 : STA !AA,x
					
NoGround:			LDA !1588,x
					BIT #$03 : BEQ NoWall
					
					LDA !B6,x : EOR #$FF : INC : STA !B6,x
					
NoWall:				JSL $01A7DC|!BankB
					
RETURN:				RTS                     ; return
					
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; graphics routine 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					
TileMap:			db $03,$04,$03,$04
					
Property:			db $05,$05,$C5,$C5
					
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
					TAX
					lda.l !dss_tile_buffer,x
					PLX
					STA $0302|!Base2,y	;
					
					LDA Property,x
					LDX $02 : BNE .No_Flip
					EOR #$40
.No_Flip:			ORA $64 : STA $0303|!Base2,y	;Property
					
					PLX
					LDY #$02 : LDA #$00
					JSL $01B7B3|!BankB
					RTS