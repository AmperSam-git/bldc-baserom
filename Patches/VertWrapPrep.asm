; Vertical level wrap prep code
;  This extends the definition for $1B96 such that
;  negative values disable screen borders, but do
;  not activate the side exit.

if read1($00FFD5) == $23
	sa1rom
endif

org $00E991
	autoclean JML CheckSideExit
	
freecode
CheckSideExit:
	BPL .normal
	JML $00E9FB
  .normal
	REP #$20
	LDA $7E
	JML $00E995
	