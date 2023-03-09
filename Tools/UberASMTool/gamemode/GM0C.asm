init:
    jsl retry_load_overworld_init


    ; Reset some retry settings on return to overworld
    incsrc "../retry_config/ram.asm"
    incsrc "../retry_config/settings.asm"

    ; Reset to the default retry prompt type on return to OW
    lda.b #!default_prompt_type+1 : sta !ram_prompt_override

    rtl