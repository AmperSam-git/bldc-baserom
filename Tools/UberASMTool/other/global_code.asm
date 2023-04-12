; Note that since global code is a single file, all code below should return with RTS.

load:
	rts
init:
	rts
main:

; same idea as Controller Read Optimization https://www.smwcentral.net/?p=section&a=details&id=32580
ControllerUpdate:          ;-----------| Routine to read controller data and upload to $15-$18. Part of NMI.
    LDA.w $4218            ;$008650    |\\
    AND.b #$F0             ;$008653    ||| Get controller 1 data 2.
    STA.w $0DA4|!addr      ;$008655    ||/
    TAY                    ;$008658    ||\
    EOR.w $0DAC|!addr      ;$008659    ||| Get controller 1 data 2, one frame.
    AND.w $0DA4|!addr      ;$00865C    |||
    STA.w $0DA8|!addr      ;$00865F    |||
    STY.w $0DAC|!addr      ;$008662    |//
    LDA.w $4219            ;$008665    |\\ Get controller 1 data 1.
    STA.w $0DA2|!addr      ;$008668    ||/
    TAY                    ;$00866B    ||\
    EOR.w $0DAA|!addr      ;$00866C    ||| Get controller 1 data 1, one frame.
    AND.w $0DA2|!addr      ;$00866F    |||
    STA.w $0DA6|!addr      ;$008672    |||
    STY.w $0DAA|!addr      ;$008675    |//
    LDA.w $421A            ;$008678    |\\
    AND.b #$F0             ;$00867B    ||| Get controller 2 data 2.
    STA.w $0DA5|!addr      ;$00867D    ||/
    TAY                    ;$008680    ||\
    EOR.w $0DAD|!addr      ;$008681    ||| Get controller 2 data 2, one frame.
    AND.w $0DA5|!addr      ;$008684    |||
    STA.w $0DA9|!addr      ;$008687    |||
    STY.w $0DAD|!addr      ;$00868A    |//
    LDA.w $421B            ;$00868D    |\\ Get controller 2 data 1.
    STA.w $0DA3|!addr      ;$008690    ||/
    TAY                    ;$008693    ||\
    EOR.w $0DAB|!addr      ;$008694    ||| Get controller 2 data 1, one frame.
    AND.w $0DA3|!addr      ;$008697    |||
    STA.w $0DA7|!addr      ;$00869A    |||
    STY.w $0DAB|!addr      ;$00869D    |//
    LDX.w $0DA0|!addr      ;$0086A0    |\
    BPL CODE_0086A8        ;$0086A3    || If $0DA0 is set to use separate controllers, use the current player number as the controller port to accept input from.
    LDX.w $0DB3|!addr      ;$0086A5    |/
CODE_0086A8:               ;            |
    LDA.w $0DA4|!addr,X    ;$0086A8    |\
    AND.b #$C0             ;$0086AB    || Set up $15, sharing the top two bits of controller data 2 (for A/X).
    ORA.w $0DA2|!addr,X    ;$0086AD    ||
    STA $15                ;$0086B0    |/
    LDA.w $0DA4|!addr,X    ;$0086B2    |\ Set up $17.
    STA $17                ;$0086B5    |/
    LDA.w $0DA8|!addr,X    ;$0086B7    |\
    AND.b #$40             ;$0086BA    || Set up $16, sharing the top two bits of controller data 2 (for A/X).
    ORA.w $0DA6|!addr,X    ;$0086BC    ||
    STA $16                ;$0086BF    |/
    LDA.w $0DA8|!addr,X    ;$0086C1    |\ Set up $18.
    STA $18                ;$0086C4    |/

	rts
;nmi:
;	rts
