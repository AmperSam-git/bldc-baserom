; It just checks whether Mario carries a sprite in his hands or Yoshi in his mouth, nothing else.

; Outputs:
; X: Slot of the sprite ($FF if no carried key found)
; C: Set if key is carried
; Clobbers: A, X

	LDX #$FF		; Failsafe
	LDA $187A|!addr	; Riding?
	BNE .Yoshi
	LDA $1470|!addr	; Failsafe
	ORA $148F|!addr
	BNE .Passed		; k
BRA .Ded			; Not even trying

.Yoshi
	LDA $18AC|!addr	; Failsafe
	BEQ .Ded		; Not even trying
.Passed
if !sa1
	LDX.b #22-1		; Defines when
else
	LDX.b #12-1
endif
-	LDA !14C8,x
	CMP #$07		; In mouth?
	BEQ .Maybe
	CMP #$0B		; In hands?
	BNE .Nope
.Maybe
	LDA !9E,x		; Only keys
	CMP #$80		; (or their imitators)
	BEQ .Ded
.Nope
	DEX
	BPL -
.Ded
	CPX #$00
RTL
