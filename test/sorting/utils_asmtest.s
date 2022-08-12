.text

.global test._getsemirandom_64.ok

test._getsemirandom_64.ok:
    stp     x29, x30, [sp, -48]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    bl      _getsemirandom_64
    mov     x21, x0

    bl      dirty_x0_x18            // put random values in registers
    ldr     x8, =_getsemirandom_64
    ldr     x19, =test._getsemirandom_64.ok
    ldr     x20, =test._getsemirandom_64.ok.NAME
    mov     x9, 0x1                 // active result registers only x0
    ror     x10, x21, 1             // expected value for x0 is the original value rotated right
    bl      check_call

    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x29, x30, [sp], 48
    ret

.data
    test._getsemirandom_64.ok.NAME:
        .asciz      "test._getsemirandom_64.ok"
