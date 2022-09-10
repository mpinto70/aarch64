.text

test._sort_two.in_order:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    bl      dirty_x0_x18            // put random values in registers
    mov     x0, 10                  // left value
    mov     x1, 20                  // right value
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME
    mov     x9, 0x3                 // active result registers: x0, x1
    mov     x10, x0                 // expected return value in x0 is the original value
    mov     x11, x1                 // expected return value in x1 is the original value
    bl      check_call

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret

test._sort_two.inverted:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    bl      dirty_x0_x18            // put random values in registers
    mov     x0, 20                  // left value
    mov     x1, 10                  // right value
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME
    mov     x9, 0x3                 // active result registers: x0, x1
    mov     x10, x1                 // expected return value in x0 is the value in x1
    mov     x11, x0                 // expected return value in x1 is the value in x0
    bl      check_call

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret

test._sort_two.same:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    bl      dirty_x0_x18            // put random values in registers
    mov     x0, 10                  // left value
    mov     x1, 10                  // right value
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME
    mov     x9, 0x3                 // active result registers: x0, x1
    mov     x10, x0                 // expected return value in x0 is the original value
    mov     x11, x1                 // expected return value in x1 is the original value
    bl      check_call

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret
