; Frees up all of the RAM from 7F0000 to 7F7FFF for use during levels
; Based on / adapted from Free 7F4000 by RPG Hacker and Free $7F0000 (OW Event Restore) by Erik/Kaijyuu

if read1($00FFD5) == $23	;sa-1 compatibility
  sa1rom
  !addr = $6000
  !BankB = $000000
else
  !addr = $0000
  !BankB = $800000
endif

org $00A0B9|!BankB
	autoclean jsl HandleOWReload
	nop #2


org $04DC6A
        JSL $04DD40|!BankB
        NOP
org $04DD56
        RTL
org $00A0BF
        autoclean JML ow_event_restore

freecode

ow_event_restore:
        LDA $0DBE|!addr
        BPL +
        INC $1B87|!addr
+       STA $0DB4|!addr,x

        PHX
        PHY
        PEA.w ($04|(!BankB>>16))|($00|!BankB>>16<<8)
        PLB
        JSL $04DD40|!BankB
        PLB
        PLY
        PLX

        JML $00A0CA|!BankB



; Hijacks OW load to make it reload some tilemap data if necessary

HandleOWReload:


	JSL $04DAAD|!BankB
	STZ $0DDA|!addr
	LDX $0DB3|!addr
	RTL
