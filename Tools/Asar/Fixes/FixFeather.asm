;Getting a feather during auto-scroll fix
;As you might know, if Mario gets a feather outside the display during auto-scroll, the game freezes.
;To fix this problem, patch this file to your ROM using Asar. 
;Patch created by: Romi

;SA-1 detector - don't change this.
if read1($00FFD5) == $23
	sa1rom
	!addr = $6000
else
	lorom
	!addr = $0000
endif

org $01C5AE
	LDA #$03
	STA $71
	LDA #$18
	STA $1496|!addr
	LDA $81
	ORA $7F
	BNE $2E