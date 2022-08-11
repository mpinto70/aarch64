.text

.global main

main:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    mov     x19, xzr

    bl      test_right_pivot
    add     x19, x19, x0
    bl      test_left_pivot
    add     x19, x19, x0
    bl      test_middle_pivot
    add     x19, x19, x0

    mov     x0, 1       // STDOUT
    ldr     x1, =line_break
    mov     x2, 1
    mov     x8, 64
    svc     0

    mov     x0, x19
    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret

test_right_pivot:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    bl      dirty_x0_x18            // put random values in registers
    mov     x0, 0xff00              // parameters to FUT
    mov     x1, 0xff80
    ldr     x8, =_right_pivot       // FUT
    ldr     x19, =test_right_pivot  // base address for error messages
    ldr     x20, =test_right_pivot_name
    mov     x9, 0x1                 // active result registers only x0
    sub     x10, x1, 16             // expected value for x0 is x1 - 16
    bl      check_call

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret

test_left_pivot:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    bl      dirty_x0_x18            // put random values in registers
    mov     x0, 0xff00              // parameters to FUT
    mov     x1, 0xff80
    ldr     x8, =_left_pivot        // FUT
    ldr     x19, =test_left_pivot   // base address for error messages
    ldr     x20, =test_left_pivot_name
    mov     x9, 0x1                 // active result registers only x0
    mov     x10, x0                 // expected value for x0 is x0
    bl      check_call

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret

test_middle_pivot:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    bl      dirty_x0_x18            // put random values in registers
    mov     x0, 0xff00              // parameters to FUT
    mov     x1, 0xff80
    ldr     x8, =_middle_pivot      // FUT
    ldr     x19, =test_middle_pivot // base address for error messages
    ldr     x20, =test_middle_pivot_name
    mov     x9, 0x1                 // active result registers only x0
    mov     x10, 0xff38             // expected value for x0 is x0
    bl      check_call

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret

.data
    test_right_pivot_name:
        .asciz      "test_right_pivot"
    test_left_pivot_name:
        .asciz      "test_left_pivot"
    test_middle_pivot_name:
        .asciz      "test_middle_pivot"
    line_break:
        .ascii      "\n"
