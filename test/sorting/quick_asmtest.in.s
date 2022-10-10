.text

.macro prepare_func
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    bl      dirty_x0_x18            // put random values in registers
.endm

.macro finish_func
    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
.endm

test._right_pivot.ok:
    prepare_func

    mov     x0, 0xff00              // begin of array (param 0)
    mov     x1, 0xff80              // end of array (param 1)
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME
    mov     x9, 0x1                 // active result registers only x0
    sub     x10, x1, 16             // expected return value is end - 16
    bl      check_call

    finish_func
    ret

test._left_pivot.ok:
    prepare_func

    mov     x0, 0xff00              // begin of array (param 0)
    mov     x1, 0xff80              // end of array (param 1)
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME
    mov     x9, 0x1                 // active result registers only x0
    mov     x10, x0                 // expected return value is begin of array
    bl      check_call

    finish_func
    ret

test._middle_pivot.ok.rounded.down:
    prepare_func

    mov     x0, 0xff00              // begin of array (param 0)
    mov     x1, 0xff80              // end of array (param 1)
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME
    mov     x9, 0x1                 // active result registers only x0
    mov     x10, 0xff38             // expected return value is middle (begin + end - 8) / 2 (aligned to 8 bytes)
    bl      check_call

    finish_func
    ret

test._middle_pivot.ok.exact:
    prepare_func

    mov     x0, 0xff00              // begin of array (param 0)
    mov     x1, 0xff78              // end of array (param 1)
    ldr     x8, =FUNCTION_UNDER_TEST
    ldr     x19, =UNIT_TEST_ADDRESS
    ldr     x20, =UNIT_TEST_NAME
    mov     x9, 0x1                 // active result registers only x0
    mov     x10, 0xff38             // expected return value is middle (begin + end - 8) / 2 (aligned to 8 bytes)
    bl      check_call

    finish_func
    ret
