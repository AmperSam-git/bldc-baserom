;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NSMB Coin Outline, by MarioE
;
; This is the coin outline from NSMB. It turns into a coin after a configurable
; amount of time after it is touched.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

db $42

JMP Main : JMP Main : JMP Main
JMP Return : JMP Return : JMP Return : JMP Return
JMP Main : JMP Main : JMP Main

!delay = $1F				; Coin delay

if read1($00FFD5) == $23	;sa-1 compatibility
  sa1rom
  !FreeRAM = $418D00
else
  !FreeRAM = $7F8D00
endif

print "A coin outline that turns into a coin after an amount of time."

Main:
	LDX #$EB			; 48 coin slots

.loop
	LDA !FreeRAM,x		; If the slot is not occupied:
	BNE .next

	REP #$20
	LDA $9A				; set X position,
	STA !FreeRAM+1,x
	LDA $98				; set Y position,
	STA !FreeRAM+3,x
	SEP #$20

	LDA #!delay			; and set the timer to !delay frames.
	STA !FreeRAM,x
	BRA .end

.next
	DEX #5				; If we didn't find a slot,
	CPX #$FB			; then check the next one.
	BNE .loop

.end
	%erase_block()

Return:
	RTL