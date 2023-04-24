;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mini Chomp Shark, by yoshicookiezeus
;;
;; Description: This sprite travels in a straight line, eating tiles and replacing them
;; with tile 25.
;;
;; Uses first extra bit: YES
;; If the first extra bit is set, the sprite will eat its way through anything.
;; Otherwise, the sprite will disappear in a puff of smoke if it hits a solid tile.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!GFX_FileNum = $9D      	;DSS ExGFX number for this sprite

!Map16Tile = $0025

!Eat_TurnNThrow_Blks = 0      ;set to 1 to make the chomp eat only Turn blocks and Throw blocks.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite init JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			Print "INIT ",pc
			%SubHorzPos()
			TYA
			STA !157C,x
			RTL


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite code JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			Print "MAIN ",pc
			PHB			; \
			PHK			;  | main sprite function, just calls local subroutine
			PLB			;  |
			JSR SPRITE_CODE_START	;  |
			PLB			;  |
			RTL			; /


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite main code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


X_SPEED:		db $10,$F0
                ;db $18,$E8    ;speed from the original if you need it.

RETURN:			RTS
SPRITE_CODE_START:
            JSR SPRITE_GRAPHICS	; graphics routine
			LDA !14C8,x		; \
			EOR #$08		; / if status != 8, return
			ORA $9D			; \ if sprites locked, return
			BNE RETURN		; /
			%SubOffScreen()		; handle off screen situation

			LDY !157C,x		; \ set x speed based on direction
			LDA X_SPEED,y		;  |
			STA !B6,x		; /
			INC !1570,x

            STZ !AA,x		; No Y speed

			JSL $01802A|!BankB	; update position based on speed values (And yes, gravity is needed for Contact with blocks)
			JSL $01A7DC|!BankB	; interact with Mario

			LDA !extra_bits,x
			AND #$04
			BNE CONTINUE

			LDA !1588,x		; \ if sprite is in contact with an object...
			AND #$03		;  |
			BNE KILL		;  |
			;LDA #$04		;  | kill sprite...
			;STA !14C8,x		;  |
			;LDA #$1F		;  |
			;STA !1540,x		;  |
			;RTS			; /  and return

CONTINUE:	LDA !14E0,x		; \ if sprite is going outside level boundaries...
			CMP #$FF		;  |
			BNE RIGHTCHECK		;  |
			LDA !E4,x		;  |
			CMP #$10		;  |
			BCC EAT			;  |
			BRA KILL		;  |
RIGHTCHECK:	LDA !14E0,x		;  |
			CMP #$20		;  |
			BNE EAT			;  |
			LDA !E4,x		;  |
			CMP #$20		;  |
			BCS EAT			;  |
KILL:		LDA #$04		;  | kill sprite...
			STA !14C8,x		;  |
			LDA #$1F		;  |
			STA !1540,x		;  |
			RTS			; /  and return

EAT:
            LDA $1693|!Base2
if !Eat_TurnNThrow_Blks = 1
			CMP #$1E
			BEQ +
			CMP #$2E
			BEQ +
			LDA !1588,x
			AND #$03
			BEQ RETURN1
			BRA KILL
+
else
            CMP #$25
			BEQ RETURN1
endif

			LDA !1570,x
			AND #$0F
			;CMP #$07
			BNE RETURN1
			LDA !E4,x		; \ setup block properties
			STA $9A			;  |
			LDA !14E0,x		;  |
			STA $9B			;  |
			LDA !D8,x		;  |
			STA $98			;  |
			LDA !14D4,x		;  |
			STA $99			; /

			PHP
			REP #$30		; \ spawn tile 25
			LDA.W #!Map16Tile	;  |
			%ChangeMap16()		;  |
			PLP			; /

			PHB			;preserve current bank
			LDA #$02		;push 02
			PHA
			PLB			;bank = 02
			LDA #$00		;default shatter
			JSL $028663|!BankB	;shatter block
			PLB

RETURN1:		RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite graphics routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TILEMAP:            db $00,$01

SPRITE_GRAPHICS:    lda #!GFX_FileNum
					%FindAndQueueGFX()
					bcs .gfx_loaded
					rts
.gfx_loaded
					%GetDrawInfo()	    ; sets y = OAM offset
                    LDA !157C,x             ; \ $02 = direction
                    STA $02                 ; /
                    LDA $14                 ; \
                    LSR A                   ;  |
                    LSR A                   ;  |
                    CLC                     ;  |
                    ADC $15E9|!Base2        ;  |
                    AND #$01                ;  |
                    STA $03                 ;  | $03 = index to frame start (0 or 1)
                    PHX                     ; /

                    LDA !14C8,x
                    CMP #$02
                    BNE LOOP_START_2
                    STZ $03
                    LDA !15F6,x
                    ORA #$80
                    STA !15F6,x

LOOP_START_2:       LDA $00                 ; \ tile x position = sprite x location ($00)
                    STA $0300|!Base2,y      ; /

                    LDA $01                 ; \ tile y position = sprite y location ($01)
                    STA $0301|!Base2,y      ; /

                    LDA !15F6,x             ; tile properties xyppccct, format
                    LDX $02                 ; \ if direction == 0...
                    BEQ NO_FLIP             ;  |
                    ORA #$40                ; /    ...flip tile
NO_FLIP:            ORA $64                 ; add in tile priority of level
                    STA $0303|!Base2,y      ; store tile properties

                    LDX $03                 ; \ store tile
                    LDA TILEMAP,x           ;  |
					TAX
					lda.l !dss_tile_buffer,x
                    STA $0302|!Base2,y      ; /

		            ;INY #4

                    PLX                     ; pull, X = sprite index
                    LDY #$02                ; \ 460 = 2 (all 16x16 tiles)
                    LDA #$00                ;  | A = (number of tiles drawn - 1)
                    JSL $01B7B3|!BankB      ; / don't draw if offscreen
                    RTS                     ; return