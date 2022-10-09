.text

test._convert_hex_digit.ok:
    stp     x29, x30, [sp, -48]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    bl      dirty_x0_x18            // put random values in registers
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME

    mov     x9, 0x3                 // active result registers: x0, x1
    mov     x10, 0                  // expected value for x0 = 0
    mov     x11, 0                  // expected value for x1 = 0
    mov     x0, '0'
    bl      check_call

    bl      dirty_x0_x18            // put random values in registers
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME

    mov     x9, 0x3                 // active result registers: x0, x1
    mov     x10, 0                  // expected value for x0 = 0
    mov     x11, 9                  // expected value for x1 = 9
    mov     x0, '9'
    bl      check_call

    bl      dirty_x0_x18            // put random values in registers
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME

    mov     x9, 0x3                 // active result registers: x0, x1
    mov     x10, 0                  // expected value for x0 = 0
    mov     x11, 10                 // expected value for x1 = 10
    mov     x0, 'A'
    bl      check_call

    bl      dirty_x0_x18            // put random values in registers
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME

    mov     x9, 0x3                 // active result registers: x0, x1
    mov     x10, 0                  // expected value for x0 = 0
    mov     x11, 15                 // expected value for x1 = 15
    mov     x0, 'F'
    bl      check_call

    bl      dirty_x0_x18            // put random values in registers
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME

    mov     x9, 0x3                 // active result registers: x0, x1
    mov     x10, 0                  // expected value for x0 = 0
    mov     x11, 10                 // expected value for x1 = 10
    mov     x0, 'a'
    bl      check_call

    bl      dirty_x0_x18            // put random values in registers
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME

    mov     x9, 0x3                 // active result registers: x0, x1
    mov     x10, 0                  // expected value for x0 = 0
    mov     x11, 15                 // expected value for x1 = 15
    mov     x0, 'f'
    bl      check_call

    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x29, x30, [sp], 48
    ret

test._convert_hex_digit.error:
    stp     x29, x30, [sp, -48]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    bl      dirty_x0_x18            // put random values in registers
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME

    mov     x9, 0x1                 // active result registers: x0
    mov     x10, 1                  // expected value for x0 = 1
    mov     x0, '/'                 // before '0'
    bl      check_call

    bl      dirty_x0_x18            // put random values in registers
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME

    mov     x9, 0x1                 // active result registers: x0
    mov     x10, 1                  // expected value for x0 = 1
    mov     x0, ':'                 // after '9'
    bl      check_call

    bl      dirty_x0_x18            // put random values in registers
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME

    mov     x9, 0x1                 // active result registers: x0
    mov     x10, 1                  // expected value for x0 = 1
    mov     x0, '@'                 // before 'A'
    bl      check_call

    bl      dirty_x0_x18            // put random values in registers
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME

    mov     x9, 0x1                 // active result registers: x0
    mov     x10, 1                  // expected value for x0 = 1
    mov     x0, 'G'                 // after 'F'
    bl      check_call

    bl      dirty_x0_x18            // put random values in registers
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME

    mov     x9, 0x1                 // active result registers: x0
    mov     x10, 1                  // expected value for x0 = 1
    mov     x0, '`'                 // before 'a'
    bl      check_call

    bl      dirty_x0_x18            // put random values in registers
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME

    mov     x9, 0x1                 // active result registers: x0
    mov     x10, 1                  // expected value for x0 = 1
    mov     x0, 'g'                 // after 'f'
    bl      check_call

    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x29, x30, [sp], 48
    ret
