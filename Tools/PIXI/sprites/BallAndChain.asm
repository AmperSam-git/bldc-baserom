;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Programmable Ball 'n Chain by dtothefourth
; Adapted from the disassembly by yoshicookiezeus
;
; Behaves like sprite 9E the ball and chain but with a lot of options
; and new behavior
;
; Uses 4 Extra Bytes
; Fill in the extension box in LM as follows:
; RR AA SS MD
; RR = radius (0-74)
; AA = angle divided by 32 (0-FF) Example: $0800 = right /32 -> $40 see below for more info
; SS = speed  0-7F counterclockwise 80-FF clockwise
; M  = momentum enabled - if not 0 spinning on ball changes speed
; D  = dynamic - see tables below for options
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!Radius = !extra_byte_1,x   ; distance of ball from center (recommended no more than $74)

!Angle  = !extra_byte_2,x ; initial angle ($0000-$1FFF) Note that's 1FFF not 1FF like most angles, as I've split it into 16 for more speed precision

;Angles: down = 0000, 800 is 90 degrees so 0800 = right, 1000 = up, 1800 = left
	; 0400 = 45 degrees down/right   0C00 = 45 degrees up/right etc

!Chain  = 1		 ; draw chain
!Space  = #$10   ; spacing of chain segments

!Speed  = !extra_byte_3,x ; positive = counter clockwise, negative = clockwise

!BounceInvul = #$10 ; Frames after bouncing on the ball with a spin jump to not hurt Mario
					; Helps prevent a low bounce on an upwards moving ball from killng you

!Despawn = 1 ; Despawn when off screen, frees up sprite slots but for long chains can disappear under you

;Momentum options - Spin jumping on the ball changes its speed
	!Boost = #$08 ; Speed added per jump
	!Max   = #$40 ; Maximum speed


;turnaround points to act like a pendulum, not recommended along with Dynamic mode
;first number is angle to turn around at counter clockwise, second  is clockwise
;0000-01FFF like angle above
TurnAround:
;dw $0400,$1BF0
dw $FFFF,$FFFF
;ball gfx
XOffset:		db $F8,$08,$F8,$08
YOffset:		db $F8,$F8,$08,$08
Tilemap:		db $01,$01,$01,$01
Properties:		db $33,$73,$B3,$F3

;chain gfx
!ChainTile  = #$00
!ChainProp  = #$33


;Dynamic animation options
; Allows the angle and length to be animated in phases
	;AnimFrames: ;how many frames each phase lasts, end with $00
	;db $08,$20,$20,$20,$20,$20,$20,$20,$08,$20,$20,$20,$20,$20,$20,$20,$00

	;AnimSpeed:  ;how much to change angle each frame
	;db $00,$08,$10,$18,$20,$18,$10,$08,$00,$F8,$F0,$E8,$E0,$E8,$F0,$F8

	;AnimLen:    ;how much to change length
	;db $00,$01,$01,$01,$01,$01,$01,$01,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF

	;AnimRate:	;how often to change length, ANDed with frame counter so use 1,3,7,F,1F,3F,etc
	;db $00,$03,$03,$03,$03,$03,$03,$03,$00,$03,$03,$03,$03,$03,$03,$03


	AnimFrames: ;how many frames each phase lasts, end with $00
	db $A0,$30,$A0,$30,$00

	AnimSpeed:  ;how much to change angle each frame
	db $78,$00,$88,$00

	AnimLen:    ;how much to change length
	db $01,$00,$FF,$00

	AnimRate:	;how often to change length, ANDed with frame counter so use 1,3,7,F,1F,3F,etc
	db $01,$01,$01,$01


			!RAM_FrameCounter	= $13
			!RAM_FrameCounterB	= $14
			!RAM_ScreenBndryXLo	= $1A
			!RAM_ScreenBndryYLo	= $1C
			!RAM_SpritesLocked	= $9D
			!RAM_SpriteNum		= !9E
			!RAM_SpriteSpeedY	= !AA
			!RAM_SpriteSpeedX	= !B6
			!RAM_SpriteState	= !C2
			!RAM_SpriteYLo		= !D8
			!RAM_SpriteXLo		= !E4
			!OAM_DispX		= $0300|!Base2
			!OAM_DispY		= $0301|!Base2
			!OAM_Tile		= $0302|!Base2
			!OAM_Prop		= $0303|!Base2
			!OAM_TileSize		= $0460|!Base2
			!RAM_SpriteYHi		= !14D4
			!RAM_SpriteXHi		= !14E0
			!RAM_SprOAMIndex	= !15EA
			!RAM_SpritePal		= !15F6


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite init JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			print "INIT ",pc
			LDA !Radius			;\ set ball n' chain radius
			STA !187B,x			;/

			LDA !Angle			;\ set initial angle ($0000-$1FFF)
			REP #$20
			ASL #5
			SEP #$20
			STA !1602,x			;/ $1602 is the low byte
			XBA
			STA !151C,x			; | $151C is the high byte


			LDA !Speed			;\ set initial speed
			STA !1504,x			;/ $1504 is the low byte
			BMI +
			LDA #$00
			STA !1510,x			; | $1510 is the high byte
			BRA ++
			+
			LDA #$FF
			STA !1510,x			; | $1510 is the high byte
			++

			LDA #$00
			STA !1594,x
			STA !15AC,x


			LDA.L AnimFrames
			STA !1540,x


			RTL				; return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite code JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			print "MAIN ",pc
			PHB
			PHK
			PLB
			JSR BallnChainMain
			PLB
			RTL


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BallnChainMain:
			if !Despawn
			LDA #$04
			%SubOffScreen()
			LDA !14C8,x
			BNE +
			RTS
			+
			endif

			LDA !RAM_SpritesLocked		;\ if sprites locked,
			BEQ +
			JMP CODE_02D653			;/ branch
			+

			LDA !extra_byte_4,x
			AND #$0F
			BNE +
			JMP NoDynamic
			+

			LDA !1540,x
			BNE NoStateChange	;


			INC !1594,x	; increment the sprite state
			-
			LDA !1594,x	;
			TAY		;
			LDA AnimFrames,y	;
			BNE +
			STZ !1594,x
			BRA -
			+
			STA !1540,x


			NoStateChange:	;
			LDA !1594,x	;
			TAY		;

			PHX
			TYX
			LDA AnimSpeed,y
			PLX
			CMP #$00
			BEQ +

			BMI ++

			XBA
			LDA #$00
			XBA
			BRA +++
			++

			XBA
			LDA #$FF
			XBA

			+++

			REP #$20
			STA $00
			SEP #$20

			LDA !151C,x
			XBA
			LDA !1602,x

			REP #$20
			CLC
			ADC $00
			AND #$1FFF
			SEP #$20

			STA !1602,x
			XBA
			STA !151C,x

			+

			PHX
			TYX
			LDA AnimRate,y
			PLX
			AND $13
			BNE +

			PHX
			TYX
			LDA AnimLen,y
			PLX
			CMP #$00
			BEQ +

			CLC
			ADC !187B,x
			STA !187B,x

			+

		NoDynamic:

			LDA !1504,x
			STA $00
			LDA !1510,x
			STA $01


			LDA !151C,x
			XBA
			LDA !1602,x

			REP #$20
			CLC
			ADC $00
			AND #$1FFF
			STA $02
			SEP #$20

			STA !1602,x
			XBA
			STA !151C,x

	Turn:

			REP #$20
			LDA $00
			BMI ++



			LDA TurnAround
			CMP #$FFFF
			BEQ +++
			CMP $02

			BPL +++

			SEC
			SBC $02
			EOR #$FFFF
			INC
			CMP $00
			BEQ ++++
			BPL +++
			++++
			LDA $00
			EOR #$FFFF
			INC

			SEP #$20
			STA !1504,x
			XBA
			STA !1510,x

			BRA +++
			++

			LDA $00
			EOR #$FFFF
			INC
			STA $00

			LDA TurnAround+2
			CMP #$FFFF
			BEQ +++
			CMP $02

			BMI +++

			SEC
			SBC $02
			CMP $00
			BEQ ++++
			BPL +++
			++++

			LDA $00
			SEP #$20
			STA !1504,x
			XBA
			STA !1510,x




			+++
			SEP #$20



CODE_02D653:		LDA !151C,x			; |
			STA $01				; | $00-$01 = ball n' chain angle
			LDA !1602,x			; |
			STA $00				;/

			REP #$30			; set 16-bit mode for accumulator and registers

			LDA $00				;\ $02-$03 = ball n' chain angle + 90 degrees
			LSR #4
			AND #$01FF
			STA $00


			CLC				; |
			ADC #$0080			; |
			AND #$01FF			; |
			STA $02				;/

			LDA $00				;\ $04-$05 = cosines of ball n' chain angle
			AND #$00FF			; |
			ASL				; |
			TAX				; |
			LDA $07F7DB,x			; | this is SMW's trigonometry table
			STA $04				;/

			LDA $02				;\ $06-$07 = cosines of ball n' chain angle + 90 degrees = sines for ball n' chain angle
			AND #$00FF			; |
			ASL				; |
			TAX				; |
			LDA $07F7DB,x			; |
			STA $06				;/

			SEP #$30			; set 8-bit mode for accumulator and registers

			LDX $15E9|!Base2			; get sprite index
            if !SA1
            STZ $2250
			LDA $04				;\ multiply $04...
			STA $2251
            STZ $2252			; |
			LDA !187B,x			; |
			LDY $05				; |\ if $05 is 1, no need to do the multiplication
			BNE CODE_02D6A3			; |/
			STA $2253			; | ...with radius of circle ($187B,x)
            STZ $2254
			NOP
            BRA $00
			ASL $2306			; Product/Remainder Result (Low Byte)
			LDA $2307			; Product/Remainder Result (High Byte)
            else
			LDA $04				;\ multiply $04...
			STA $4202			; |
			LDA !187B,x			; |
			LDY $05				; |\ if $05 is 1, no need to do the multiplication
			BNE CODE_02D6A3			; |/
			STA $4203			; | ...with radius of circle ($187B,x)
			JSR CODE_02D800			;/ waste some cycles while the result is calculated
			ASL $4216			; Product/Remainder Result (Low Byte)
			LDA $4217			; Product/Remainder Result (High Byte)
            endif
			ADC #$00
CODE_02D6A3:		LSR $01
			BCC CODE_02D6AA
			EOR #$FF
			INC A
CODE_02D6AA:		STA $04
            if !SA1
            STZ $2250
			LDA $06				;\ multiply $06...
			STA $2251 			; |
            STZ $2252
			LDA !187B,x			; |
			LDY $07				; |\ if $07 is 1, no need to do the multiplication
			BNE CODE_02D6C6			; |/
			STA $2253
            STZ $2254			; | ...with raidus of circle ($187B,x)
			NOP
            BRA $00
			ASL $2306			; Product/Remainder Result (Low Byte)
			LDA $2307			; Product/Remainder Result (High Byte)
            else
			LDA $06				;\ multiply $06...
			STA $4202 			; |
			LDA !187B,x			; |
			LDY $07				; |\ if $07 is 1, no need to do the multiplication
			BNE CODE_02D6C6			; |/
			STA $4203			; | ...with raidus of circle ($187B,x)
			JSR CODE_02D800			;/ waste some cycles while the result is calculated
			ASL $4216			; Product/Remainder Result (Low Byte)
			LDA $4217			; Product/Remainder Result (High Byte)
            endif
			ADC #$00
CODE_02D6C6:		LSR $03
			BCC CODE_02D6CD
			EOR #$FF
			INC A
CODE_02D6CD:		STA $06

			LDA !RAM_SpriteXLo,x		;\ preserve current sprite position (center of rotation)
			PHA				; |
			LDA !RAM_SpriteXHi,x		; |
			PHA				; |
			LDA !RAM_SpriteYLo,x		; |
			PHA				; |
			LDA !RAM_SpriteYHi,x		; |
			PHA				;/


			STZ $00				;\
			LDA $04				; |   x offset low byte
			BPL CODE_02D6E8			; |
			DEC $00				; |
CODE_02D6E8:		CLC				; |
			ADC !RAM_SpriteXLo,x		; | + x position of rotation center low byte
			STA !RAM_SpriteXLo,x		;/  = sprite x position low byte

			PHP				;\
			PHA				; |
			SEC				; |
			SBC !1534,x			; |
			STA !1528,x			; |
			PLA				; |
			STA !1534,x			; |
			PLP				;/

			LDA !RAM_SpriteXHi,x		;\    x position of rotation center high byte
			ADC $00				; | + adjustment for screen boundaries
			STA !RAM_SpriteXHi,x		;/  = x position of sprite high byte

			STZ $01				;\
			LDA $06				; |   y offset low byte
			BPL CODE_02D70B			; |
			DEC $01				; |
CODE_02D70B:		CLC				; |
			ADC !RAM_SpriteYLo,x		; | + y position of rotation center low byte
			STA !RAM_SpriteYLo,x		;/  = sprite y position low byte

			LDA !RAM_SpriteYHi,x		;\    y position of center of rotation high byte
			ADC $01				; | + adjustment for screen boundaries
			STA !RAM_SpriteYHi,x		;/  = sprite y position high byte



			JSL $01A7DC|!BankB			; interact with Mario
			BCS +
			JMP NoContact
			+

			print "hit ",pc

			LDA !15AC,x
			BEQ +
			DEC
			STA !15AC,x
			BRA +++
			+

			LDA $7D
			BMI ++

			+++

			LDA $140D|!Base2
			BNE +
			++
			JSL $00F5B7|!BankB      ; hurt Mario
			JMP NoContact
			+

			LDA !BounceInvul
			STA !15AC,x

			LDA $15		;pressing A?
			AND #$80	;
			BEQ BounceLow	;If he isn't, make him BounceLow.
			LDA #$A8	;If he is, launch him into the air!
			STA $7D		;
			BRA Sound	;Go to Sound.
		BounceLow:
			LDA #$C0	;
			STA $7D		;Make Mario bounce low.
		Sound:
			LDA #$02	;Set sound (Spin jumping off enemy)
			STA $1DF9|!addr	;I/O Port
			JSL $01AB99|!BankB	;Spin Jumping off spiked enemy effect.


			LDA !extra_byte_4,x
			AND #$F0
			BNE +
			JMP NoContact
			+

			LDA !1602,x			;/ $1602 is the low byte
			STA $04
			LDA !151C,x			; | $151C is the high byte
			STA $05

			REP #$20
			LDA $04
			CMP #$0800
			BMI Bottom
			CMP #$1800
			BMI Top
			BRA Bottom


		Top:
			SEP #$20
			LDA !E4,x
			STA $04
			LDA !14E0,x
			STA $05

			REP #$20
			LDA $04

			CMP $94
			SEP #$20
			BPL Neg
			BRA Pos


		Bottom:
			SEP #$20


			LDA !E4,x
			STA $04
			LDA !14E0,x
			STA $05

			REP #$20
			LDA $04

			CMP $94
			SEP #$20
			BPL Pos
			BRA Neg

		Pos:
			LDA !Boost
			CLC
			ADC !1504,x
			STA !1504,x
			STA $00
			LDA !1510,x
			ADC #$00
			STA $01

			LDA #$00
			XBA
			LDA !Max

			REP #$20
			CMP $00
			BPL +

			STA $00

			+

			SEP #$20
			LDA $00
			STA !1504,x
			LDA $01
			STA !1510,x




			BRA NoContact

		Neg:

			LDA !1504,x
			SEC
			SBC !Boost
			STA $00
			LDA !1510,x
			SBC #$00
			STA $01

			LDA #$FF
			XBA
			LDA !Max
			EOR #$FF
			INC

			REP #$20
			CMP $00
			BMI +

			STA $00

			+

			SEP #$20
			LDA $00
			STA !1504,x
			LDA $01
			STA !1510,x


NoContact:
			JSR BallnChainGFX



			LDA !15C4,x			;\ if sprite is off-screen,
			BEQ +
			JMP ReverseGFX
			+
			JMP GFX

GFX:
			PHX				; preserve sprite index



			LDA #$03
			STA $0F

			if !Chain

			LDA !187B,x
			CMP #$1A
			BPL ++
			JMP ++++
			++

			-
			CMP !Space
			BMI +
			SEC
			SBC !Space
			BRA -
			+
			STA $06

			LDA !1602,x			;/ $1602 is the low byte
			STA $04
			LDA !151C,x			; | $151C is the high byte
			STA $05

			REP #$20
			LDA $04
			LSR #4
			AND #$01FF


			EOR #$FFFF
			INC
			SEC
			SBC #$007F
			AND #$01FF
			STA $04
			SEP #$20

			;LDX #$!Chain-1
			-

			STX $0E


			%CircleX()
			LDA $00
			CLC
			ADC $07
			STA $0B

			%CircleY()
			LDA $01
			CLC
			ADC $09
			STA $0C

			PLX
			PHX

			LDA !14E0,x
			XBA
			LDA !E4,x

			LDX $0E

			REP #$20
			CLC
			ADC $07
			CLC
			ADC #$0010
			SEC
			SBC $1A
			BPL +

			--
			SEP #$20
			LDA #$F0
			STA $0301,y

			BRA ++
			+

			CMP #$0110
			BPL --

			SEP #$20

			LDA $0B
			STA $0300|!Base2,y

			LDA $0C
			STA $0301|!Base2,y

			PHX
			LDX #$00
			lda !dss_tile_buffer,x
			PLX
			STA $0302|!Base2,y
			LDA !ChainProp
			STA $0303|!Base2,y

			INY #4
			INC $0F
			++

			LDA $06
			CLC
			ADC !Space
			STA $06

			CLC
			ADC #$02

			CMP !187B,x
			BMI -


			;DEX
			;BPL -

			++++

			endif

			PLX				; retrieve sprite index

			PLA				;\ retrieve sprite position (center of rotation)
			STA !RAM_SpriteYHi,x		; |
			PLA				; |
			STA !RAM_SpriteYLo,x		; |
			PLA				; |
			STA !RAM_SpriteXHi,x		; |
			PLA				; |
			STA !RAM_SpriteXLo,x		;/


			LDY #$02			; the tiles drawn were 16x16
			LDA $0F
			JSL $01B7B3			; finish OAM write

			RTS

ReverseGFX:
			PLA				;\ retrieve sprite position (center of rotation)
			STA !RAM_SpriteYHi,x		; |
			PLA				; |
			STA !RAM_SpriteYLo,x		; |
			PLA				; |
			STA !RAM_SpriteXHi,x		; |
			PLA				; |
			STA !RAM_SpriteXLo,x		;/

			%GetDrawInfo()

			PHX				; preserve sprite index



			LDA #$FF
			STA $0F

			if !Chain
			LDA !Space
			STA $06

			LDA !1602,x			;/ $1602 is the low byte
			STA $04
			LDA !151C,x			; | $151C is the high byte
			STA $05

			REP #$20
			LDA $04

			LSR #4
			AND #$01FF

			EOR #$FFFF
			INC
			CLC
			ADC #$007F
			AND #$01FF
			STA $04
			SEP #$20

			-



			%CircleX()
			LDA $00
			CLC
			ADC $07
			STA $0B

			%CircleY()
			LDA $01
			CLC
			ADC $09
			STA $0C


			LDA !14E0,x
			XBA
			LDA !E4,x

			REP #$20
			CLC
			ADC $07
			CLC
			ADC #$0010
			SEC
			SBC $1A
			BPL +

			--
			SEP #$20
			LDA #$F0
			STA $0301,y

			BRA ++
			+

			CMP #$0110
			BPL --

			SEP #$20

			LDA $0B
			STA $0300|!Base2,y

			LDA $0C
			STA $0301|!Base2,y

			LDA !ChainTile
			STA $0302|!Base2,y
			LDA !ChainProp
			STA $0303|!Base2,y

			INY #4
			INC $0F
			++

			LDA $06
			CLC
			ADC !Space
			STA $06
			CMP !187B,x
			BMI -
			+++

			endif

			PLX				; retrieve sprite index


			LDY #$02			; the tiles drawn were 16x16
			LDA $0F
			JSL $01B7B3			; finish OAM write


			RTS


CODE_02D800:		NOP				;\ this routine exists for the sole purpose of wasting cycles
			NOP				; | while the multiplication or division registers do their work
			NOP				; |
			NOP				; |
			NOP				; |
			NOP				;/
Return02D806:		RTS				; return

BallnChainGFX:
			lda #$2E                ; find or queue GFX
			%FindAndQueueGFX()
			bcs .gfx_loaded
			rts                      ; don't draw gfx if ExGFX isn't ready
.gfx_loaded
			%GetDrawInfo()
			PHX				; preserve sprite index
			LDX #$03			; setup loop

CODE_02D819:		LDA $00				;\ set tile x position
			CLC				; |
			ADC XOffset,x			; |
			STA !OAM_DispX,y		;/

			LDA $01				;\ set tile y position
			CLC				; |
			ADC YOffset,x			; |
			STA !OAM_DispY,y		;/

			PHX
			LDA Tilemap,x			;\ set tile number
			TAX
			lda !dss_tile_buffer,x
			PLX
			STA !OAM_Tile,y			;/ this used to draw its data from the NOPs just above instead of from a proper table

			LDA Properties,x		;\ set tile properties
			STA !OAM_Prop,y			;/

			INY				;\ increase OAM index by four
			INY				; |
			INY				; |
			INY				;/

			DEX				;\ if tiles left to draw,
			BPL CODE_02D819			;/ go to start of loop

			PLX				; retrieve sprite index
			RTS				; return

CODE_02D870:		PHP				; preserve processor flags
			BPL CODE_02D876			;\ make sure value is positive
			EOR #$FF			; |
			INC A				;/
CODE_02D876:
            if !SA1
            STA $2252			; low byte of dividend is whatever was in the accumulator when the routine was called
			STZ $2251			; high byte of dividend is zero
            LDA #$01
            STA $2250
			LDA !187B,x			;\ divisor is half the radius of the circle
			LSR				; |
			STA $2253
            STZ $2254			;/
			NOP
            BRA $00
			LDA $2306			;\ $0E = low byte of result
			STA $0E				;/
			LDA $2307			; noone cares about the high byte, so why is it even loaded?
            else
            STA $4205			; low byte of dividend is whatever was in the accumulator when the routine was called
			STZ $4204			; high byte of dividend is zero
			LDA !187B,x			;\ divisor is half the radius of the circle
			LSR				; |
			STA $4206			;/
			JSR CODE_02D800			; wait
			LDA $4214			;\ $0E = low byte of result
			STA $0E				;/
			LDA $4215			; noone cares about the high byte, so why is it even loaded?
            endif

			ASL $0E				;\ what
			ROL				; |
			ASL $0E				; |
			ROL				; |
			ASL $0E				; |
			ROL				; |
			ASL $0E				; |
			ROL				;/

			PLP				; retrieve processor flags
			BPL Return02D8A0		;\ if original value was negative,
			EOR #$FF			; | invert result
			INC A				;/
Return02D8A0:		RTS				; return
