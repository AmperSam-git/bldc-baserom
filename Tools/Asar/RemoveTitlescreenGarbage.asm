lorom
if read1($00FFD5) == $23
	sa1rom
endif

org $009AA4
autoclean JSL Mymain

freespace noram
Mymain:
JSL $04F675
JML $7F8000
