;; this macro sets up the basic tile of the thwomp, $0300, $0301, $0303
macro SetupTile(xdisp, props)
	LDA $00
    CLC
    ADC.w <xdisp>,x
    STA.w $0300|!Base2,y
	
    LDA $01
    CLC 
    ADC.w ThwompDispY,x
    STA.w $0301|!Base2,y
	
    LDA.w <props>,x
    ORA $64
	ORA $03
    STA.w $0303|!Base2,y
endmacro

;; this macro setups up the facial expression of the thwomp
;; according to the direction where mario is coming from
;; if the thwomp is active, it'll just put the angry face
macro FacialExpression(isUpDown)
    PHX
	LDX $02
	CPX.b #$02
	BNE ?default
	if <isUpDown>
		LDA.b #!AngryUpDownThwompTile
	else
		LDA.b #!AngryLeftRightThwompTile
	endif
	?default
    PHA
    LDX $15E9|!addr
    LDA !extra_prop_1,x
    BEQ ?+
    BRA ?++
    ?+
    PLA
    ?++
	if <isUpDown>
		XBA
		PHY
		LDX $15E9|!addr
		%SubHorzPos()
		LDA EyeProperties,y
		PLY
		ORA $0303|!addr,y
		STA $0303|!addr,y
		XBA
	endif
	PLX
endmacro

;; this macro puts in $0A the num of tiles - 1 that we're gonna draw
;; $0A => 3 if mario not near, $0A => 4 if mario near
macro InitGfxLoop()
	STZ $0A
	LDA $02
	LDX.b #$05
	CMP.b #$00
	BEQ ?notNear
	INX
	?notNear
	STX $0A
endmacro

;; sets extra_prop_1 to 1
macro SetMadFlag()
	LDA #$01
	STA !extra_prop_1,x		;; set the flag to say that it's already been updated
endmacro

;; uploads the size manually to $0460
macro UploadSize()
	PHY
	TYA
	LSR #2
	TAY
	LDA.w TileSizes,x
	STA.w $0460|!Base2,y
	STA $0E
	PLY
endmacro

;; shifts the tile the draw to the right by a certain amount of tiles to change the color
macro AdjustIfMad()
	CPX #$06
	BEQ ?skip
	PHX
	PHA
	LDX $15E9|!addr
	LDA !extra_prop_1,x
	BEQ ?+
	PLA : INC : INC     ;; shift tile to draw by 1 16x16 tile
	BRA ?++
	?+
	PLA : ?++
	PLX
	?skip
endmacro

;; same as above
macro AdjustIfMadLR()
	CPX #$06
	BEQ ?skip
	PHX
	PHA
	LDX $15E9|!addr
	LDA !extra_prop_1,x
	BEQ ?+
	PLA : CLC : ADC #$03
	BRA ?++
	?+
	PLA : ?++
	PLX
	?skip
endmacro


;; redirects the mad thwomps to other graphic routines
macro RedirectJMP(first, second)
	LDX $15E9|!addr
	LDA !C2,x
	DEC
	BEQ ?+
	JMP <first>         ;; if C2 == 1 go original direction
	?+
	JMP <second>        ;; else other
endmacro