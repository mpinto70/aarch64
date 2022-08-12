.text

.global test._right_pivot.ok
.global test._left_pivot.ok
.global test._middle_pivot.ok

test._right_pivot.ok:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    bl      dirty_x0_x18            // put random values in registers
    mov     x0, 0xff00              // parameters to FUT
    mov     x1, 0xff80
    ldr     x8, =_right_pivot
    ldr     x19, =test._right_pivot.ok
    ldr     x20, =test._right_pivot.ok.NAME
    mov     x9, 0x1                 // active result registers only x0
    sub     x10, x1, 16             // expected value for x0 is x1 - 16
    bl      check_call

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret

test._left_pivot.ok:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    bl      dirty_x0_x18            // put random values in registers
    mov     x0, 0xff00              // parameters to FUT
    mov     x1, 0xff80
    ldr     x8, =_left_pivot
    ldr     x19, =test._left_pivot.ok
    ldr     x20, =test._left_pivot.ok.NAME
    mov     x9, 0x1                 // active result registers only x0
    mov     x10, x0                 // expected value for x0 is x0
    bl      check_call

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret

test._middle_pivot.ok:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    bl      dirty_x0_x18            // put random values in registers
    mov     x0, 0xff00              // parameters to FUT
    mov     x1, 0xff80
    ldr     x8, =_middle_pivot
    ldr     x19, =test._middle_pivot.ok
    ldr     x20, =test._middle_pivot.ok.NAME
    mov     x9, 0x1                 // active result registers only x0
    mov     x10, 0xff38             // expected value for x0 is x0
    bl      check_call

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret

.data
    test._right_pivot.ok.NAME:
        .asciz      "test._right_pivot.ok"
    test._left_pivot.ok.NAME:
        .asciz      "test._left_pivot.ok"
    test._middle_pivot.ok.NAME:
        .asciz      "test._middle_pivot.ok"
