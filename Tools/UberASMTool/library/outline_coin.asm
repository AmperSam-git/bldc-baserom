if read1($00FFD5) == $23	;sa-1 compatibility
  sa1rom
  !FreeRAM = $418D00
else
  !FreeRAM = $7F8D00
endif

main:
	LDX #$EB			; 48 coin slots

.loop
	LDA !FreeRAM,x		; If the timer is nonzero,
	BEQ .next

	DEC					; decrement timer.
	STA !FreeRAM,x
	BNE .next			; If the timer turned to zero,

	REP #$20
	LDA !FreeRAM+1,x	; Get X position,
	STA $9A
	LDA !FreeRAM+3,x	; Get Y position,
	STA $98
	SEP #$20

	LDA #$06
	STA $9C
	JSL $00BEB0			; And create a coin

.next
	DEX #5				; Check the next slot
	CPX #$FB
	BNE .loop
	RTL