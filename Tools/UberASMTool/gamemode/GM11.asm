init:
    %invoke_sa1(dynamic_spriteset_init)
    jsl retry_level_init_1_init
    jsl retry_level_transition_init
    rtl
