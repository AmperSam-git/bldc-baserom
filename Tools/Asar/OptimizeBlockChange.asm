;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Optimized block change - imamelia, mario90
;; This rewrites the original block change routine and allows many more blocks to be changed
;; in a single frame without overflowing V-blank (black bars on the top of the screen)
;;
;; v1.1: fix bugs in vertical levels and blocks on layer 2 (spooonsss)
;;
;; VRAM base address = $3000
;; small-scale upload table = $7FB700 (index at $06F9)
;; large-scale upload table = $7FB800 (index at $06FB)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Not sure if there's a better way to detect this lol
assert read1($0FF0A0) == $4C, "You need to edit the ROM in Lunar Magic at least once."

if read1($00FFD5) == $23
	sa1rom
	!sa1 = 1
	!base1	= $3000
	!base2	= $6000
	!base3	= $000000
else
	lorom
	!sa1 = 0
	!base1	= $0000
	!base2	= $0000
	!base3	= $800000
endif
	!dp		= !base1
	!addr	= !base2
	!bank	= !base3

;You can change the ram here if needed
;lorom
!VRAMUploadTblSmall = $7FB700
!VRAMUploadTblLarge = $7FB800
!VRAMUploadTblSmallIndex = $06F9
!VRAMUploadTblLargeIndex = $06FB

;SA-1
!VRAMUploadTblSmallSA1 = $40A000
!VRAMUploadTblLargeSA1 = $40A100
!VRAMUploadTblSmallIndexSA1 = $66F9
!VRAMUploadTblLargeIndexSA1 = $66FB

if !sa1
!VRAMUploadTblSmall = !VRAMUploadTblSmallSA1
!VRAMUploadTblLarge = !VRAMUploadTblLargeSA1
!VRAMUploadTblSmallIndex = !VRAMUploadTblSmallIndexSA1
!VRAMUploadTblLargeIndex = !VRAMUploadTblLargeIndexSA1
endif

org $00C13E
BlockChangeRewrite:
;  $0C/$0E = tile X/Y position
;  $06     = 16-bit VRAM position
	LDX !VRAMUploadTblSmallIndex
	CPX #$0100
	BCS Return

	SEC
	LDA $1933|!addr
	BEQ .layer1_position
.layer2_position
	LDA $0E
	SBC $20
	BRA +
.layer1_position
	LDA $0E
	SBC $1C
+
	CLC
	; these values match the scrolling tilemap loader
	ADC.w #$0010-1 ; show partial blocks
	CMP.w #$0100 ; tilemap is 32*8 = 0x100 px tall
	BCS Return
	LDA $1933|!addr
	BNE .Layer2
.Layer1
	autoclean JML SetLayer1Addr
.Layer2
	autoclean JML SetLayer2Addr
warnpc $00C17A

org $00C17A
Label00C17A:
; inserted by LM:
; JSL $06f5d0
; NOP
org $00C17F
	STA $04
	LDA [$04]
	STA !VRAMUploadTblSmall+2,x
	LDY #$0002
	LDA [$04],y
	STA !VRAMUploadTblSmall+6,x
	LDY #$0004
	LDA [$04],y
	STA !VRAMUploadTblSmall+10,x
	LDY #$0006
	LDA [$04],y
	STA !VRAMUploadTblSmall+14,x
	TXA
	CLC
	ADC #$0010
	STA !VRAMUploadTblSmallIndex
Return:
	RTS

; We want an NMI hijack that runs in most game modes (also mode7), not in lag frames, and is late enough
; This hijack is at the end of ControllerUpdate
; UberASM NMI is too early due to LM hijack loading tilemap upon e.g. horizontal scroll:
;  org $0586F7 JML $1FB12C  map16 data is used to load tilemap data into buffer at $7F820B ("CheckLayerUpdates")
;  Then sprite code (e.g. growing pipe) runs, which populates !VRAMUploadTblSmall
;  UberASM NMI hijack runs, uploading !VRAMUploadTblSmall to vram
;  org $008209 JSL LM NMI hijack runs, using pre-update map16 tilemap data ("UploadBGData")
;      $1FA64D STA $4322     [004322] A:820b
;      $1FA655 STY $420B

org $008650
; Controller is read in global_code.asm instead
ControllerUpdate:
	autoclean JML NMIHijack
.rts
	RTS

freecode

SetLayer1Addr:
	LDA $06
	XBA
	CMP #$3800
	BCS .End
	AND #$07FF
	ORA #$3000
.End
StoreAddress:
	STA !VRAMUploadTblSmall,x
	INC
	STA !VRAMUploadTblSmall+8,x
	CLC
	ADC #$001F
	STA !VRAMUploadTblSmall+4,x
	INC
	STA !VRAMUploadTblSmall+12,x
	JML Label00C17A|!bank


SetLayer2Addr:
	LDA $06
	XBA
	CMP #$3800
	BCS .End
	AND #$07FF
	ORA #$3800
.End
	BRA StoreAddress

NMIHijack:
	REP #$10
	LDX !VRAMUploadTblSmallIndex
	BEQ .SkipUploadSmallTable
	JSR RunVRAMUploadSmall
.SkipUploadSmallTable
	LDX !VRAMUploadTblLargeIndex
	BEQ .SkipUploadLargeTable
	JSR RunVRAMUploadLarge
.SkipUploadLargeTable
	SEP #$10
	JML ControllerUpdate_rts|!bank

RunVRAMUploadSmall:
	LDA #$80
	STA $2115
	STX $4325
	LDX #$1604
	STX $4320
	LDX.w #!VRAMUploadTblSmall
	STX $4322
	LDA.b #!VRAMUploadTblSmall>>16
	STA $4324
	LDA #$04
	STA $420B
	LDX #$0000
	STX !VRAMUploadTblSmallIndex
	RTS

RunVRAMUploadLarge:
	PHB
	PEA.w (!VRAMUploadTblLarge>>16)|(!VRAMUploadTblLarge>>8)
	PLB
	PLB
	REP #$20
	STZ $00
	LDX #$0000
.Loop
	LDA.w !VRAMUploadTblLarge+10,x
	BEQ .NoDelay
	DEC.w !VRAMUploadTblLarge+10,x
	LDY $00
	LDA.w !VRAMUploadTblLarge,x
	STA.w !VRAMUploadTblLarge,y
	LDA.w !VRAMUploadTblLarge+2,x
	STA.w !VRAMUploadTblLarge+2,y
	LDA.w !VRAMUploadTblLarge+4,x
	STA.w !VRAMUploadTblLarge+4,y
	LDA.w !VRAMUploadTblLarge+6,x
	STA.w !VRAMUploadTblLarge+6,y
	LDA.w !VRAMUploadTblLarge+8,x
	STA.w !VRAMUploadTblLarge+8,y
	LDA.w !VRAMUploadTblLarge+10,x
	STA.w !VRAMUploadTblLarge+10,y
	LDA $00
	CLC
	ADC #$000C
	STA $00
	BRA .NextEntry
.NoDelay
	LDA.w !VRAMUploadTblLarge,x
	STA $004320
	LDA.w !VRAMUploadTblLarge+2,x
	STA $004322
	LDA.w !VRAMUploadTblLarge+4,x
	STA $004324
	LDA.w !VRAMUploadTblLarge+5,x
	STA $004325
	LDA.w !VRAMUploadTblLarge+7,x
	STA $002115
	LDA.w !VRAMUploadTblLarge+8,x
	STA $002116
	LDA.w !VRAMUploadTblLarge-1,x
	BPL $04
	LDA $002139
	SEP #$20
	LDA #$04
	STA $00420B
	REP #$20
.NextEntry
	TXA
	CLC
	ADC #$000C
	TAX
	CMP.l !VRAMUploadTblLargeIndex
	BCC .LoopJump
.Break
	PLB
	LDA $00
	STA !VRAMUploadTblLargeIndex
	RTS
.LoopJump
	JMP .Loop
