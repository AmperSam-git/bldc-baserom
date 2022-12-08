;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Stacking blocks - by dtothefourth
;
; Falling block sprite that goes in one of four directions
; and then turns into a regular tile when hitting something
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!Tile = #$2E	;Tile to draw, defaults to the hit block graphics

!Palette  = 0	;Default palette

!PlaySound = 0	;Sound when triggered (coin)
!SFX 	   = #$01
!SFXBank   = $1DFC|!Base2

!Bounce	   = 0 	;Bounce effect like normal kaizo block
BounceY:
	db $FC,$FA,$F9,$F8,$F8,$F9,$FA,$FC,$00

!Dir    = 0		;Direction to fall - 0 = down, 1 = left, 2 = up, 3 = right
!Speed  = #$D0	;Initial speed if falling
!Accel  = #$03  ;Fall acceleration
!Max	= #$30  ;Fall max speed
!Pass	= 1		;If 1, act like clouds instead of fully solid while falling
!LandTile = #$0132 ;Tile to turn into on landing

Print "INIT ",pc
	LDA !Speed
	if !Dir == 0 || !Dir == 2
		if !Dir == 2
		EOR #$FF
		INC
		endif
		STA !AA,x
	else
		if !Dir == 1
		EOR #$FF
		INC
		endif
		STA !B6,x
	endif

	if !Pass
		LDA !190F,x
		ORA #$01
		STA !190F,x
	endif

	if !PlaySound
	LDA !SFX
	STA !SFXBank
	endif

	if !Bounce
	LDA #$08
	STA !1540,x
	endif

	RTL

Print "MAIN ",pc
	PHB
	PHK
	PLB
	JSR main
	PLB
	RTL


main:
	JSR GFX

	LDA #$00
    %SubOffScreen()

	LDA $9D
	BEQ +
	RTS
	+


	if !Dir == 0
		JSL $01801A|!BankB
		LDA !AA,x
		CLC
		ADC !Accel
		BMI +
		CMP !Max
		BCC +
		LDA !Max
		+
		STA !AA,x
	endif
	if !Dir == 1
		JSL $018022|!BankB
		LDA !B6,x
		SEC
		SBC !Accel
		BPL +
		CMP !Max*-1
		BCS +
		LDA !Max*-1
		+
		STA !B6,x
	endif
	if !Dir == 2
		JSL $01801A|!BankB
		LDA !AA,x
		SEC
		SBC !Accel
		BPL +
		CMP !Max*-1
		BCS +
		LDA !Max*-1
		+
		STA !AA,x
	endif
	if !Dir == 3
		JSL $018022|!BankB
		LDA !B6,x
		CLC
		ADC !Accel
		BMI +
		CMP !Max
		BCC +
		LDA !Max
		+
		STA !B6,x
	endif

	JSL $019138|!BankB

	LDA !1588,x
	if !Dir = 0
	BIT #$04
	endif
	if !Dir = 1
	BIT #$02
	endif
	if !Dir = 2
	BIT #$08
	endif
	if !Dir = 3
	BIT #$01
	endif
	BEQ +

	LDA !E4,x
	STA $9A
	LDA !14E0,x
	STA $9B
	LDA !D8,x
	STA $98
	LDA !14D4,x
	STA $99

	STZ $1933|!Base2

	STZ !14C8,x

	REP #$20

	if !Dir == 1
		LDA $9A
		CLC
		ADC #$000F
		STA $9A
	endif
		if !Dir == 2
		LDA $98
		CLC
		ADC #$000F
		STA $98
	endif

	LDA !LandTile
	%ChangeMap16()
	SEP #$20
	RTS

	+

	JSL $01B44F|!BankB
	if !Dir == 0
	BCC +
	LDA !AA,x
	CLC
	ADC #$10
	STA $7D
	+
	endif

	RTS

GFX:
	; DSS Modification
	lda #$77                 ; find or queue ExGFX D77
   	%FindAndQueueGFX()
   	bcs .dss_loaded
   	rts

.dss_loaded
	%GetDrawInfo()

	DEC $01

	if !Bounce
	LDA !1540,x
	BEQ +
	PHX
	TAX
	LDA BounceY,x
	if !Dir == 0
	CLC
	ADC $01
	STA $01
	endif
	if !Dir == 1
	EOR #$FF
	INC
	CLC
	ADC $00
	STA $00
	endif
	if !Dir == 2
	EOR #$FF
	INC
	CLC
	ADC $01
	STA $01
	endif
	if !Dir == 3
	CLC
	ADC $00
	STA $00
	endif
	PLX
	+
	endif

	LDA #(!Palette*2)
	STA $02

	LDA $00
	STA $0300|!Base2,y

	LDA $01
	STA $0301|!Base2,y

	lda !dss_tile_buffer+$00
	STA $0302|!Base2,y

	lda #$21                 ; yxppccct props; remember to use the second page!
	STA $0303|!Base2,y

	LDA #$00
	LDY #$02
	JSL $01B7B3|!BankB
	RTS