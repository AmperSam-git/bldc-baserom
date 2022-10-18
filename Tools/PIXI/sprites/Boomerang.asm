!GFX_FileNum = $82		;EXGFX number for boomerang
					
TileMap:			db $00,$01,$00,$01
					;db $E8,$EA,$E8,$EA	;SpritePage4
					;db $4B,$4E,$4B,$4E	;MikeyK
					
Property:			db $C9,$09,$09,$C9
					;db $09,$09,$C9,$C9	;SpritePage4_PaletteC
					;db $03,$03,$C3,$C3	;SpritePage4_Palette9
					;db $C3,$03,$03,$C3	;MikeyK
					
					print "INIT ",pc
					LDA #$6E : STA !1540,x
					
					LDA !B6,x : BPL Init_NoFlip
					EOR #$FF : INC
					LSR #2 : EOR #$FF : INC : STA !C2,x
					RTL
					
Init_NoFlip:		LSR #2 : STA !C2,x
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
					LDA !14C8,x	: CMP #$08 : BNE RETURN
					LDA $9D : BNE RETURN
					
					INC !1602,x
					LDA !1504,x : BNE KeepSpeed
					LDY #$09
					LDA !1540,x : BEQ YSpeed_0
					CMP #$60 : BCS KeepSpeed
					AND #$3F : BEQ ChangeSpeed
					CMP #$20 : BEQ FlipSpeed
					BRA KeepSpeed
YSpeed_0:			INC !1504,x : LDY #$00
ChangeSpeed:		LDA !B6,x : SEC : SBC !C2,x : STA !B6,x
					TYA : STA !AA,x
					BRA KeepSpeed
					
FlipSpeed:			LDA !B6,x : EOR #$FF : INC : STA !B6,x
					DEC !AA,x
					
KeepSpeed:			LDA !AA,x : PHA
					JSL $01802A|!BankB
					PLA : STA !AA,x
					
					JSL $01A7DC|!BankB
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
					
SUB_GFX:			
					lda #!GFX_FileNum                  ;load boomerang projectile
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
					lda !dss_tile_buffer,x
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