.text

.global main

main:
    stp     x29, x30, [sp, -16]!

    mov     x0, 154
    mov     x1, 256
    ldr     x8, =_right_pivot
    mov     x9, 1
    mov     x10, 154
    bl      check_equal

    mov     x0, 0
    ldp     x29, x30, [sp], 16
    ret

// prepare the frame with space for all registers and save them all.
// Notes
// * registers x19-x28 are saved on top of the stack
// * space is available to store the result (x0-x7) with save_result macro
.macro prepare_frame
    stp     x29, x30, [sp, -256]!
    // save registers that will be changed to check
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]
    stp     x25, x26, [sp, 64]
    stp     x27, x28, [sp, 80]
    // save expected result
    stp     x8, x9, [sp, 96]
    stp     x10, x11, [sp, 112]
    stp     x12, x13, [sp, 128]
    stp     x14, x15, [sp, 144]
    stp     x16, x17, [sp, 160]
    str     x18, [sp, 176]
.endm

// restore the frame to return from the current function
.macro restore_frame
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x25, x26, [sp, 64]
    ldp     x27, x28, [sp, 80]
    ldp     x29, x30, [sp], 256
.endm

// save results after calling function under test
.macro save_result
    stp     x0, x1, [sp, 192]
    stp     x2, x3, [sp, 208]
    stp     x4, x5, [sp, 224]
    stp     x6, x7, [sp, 240]
.endm

// check if a register \imm has expectation on result (0<= imm <= 7)
.macro is_reg_in_result imm
    ldr     x1, [sp, 104]       // load value of x9 saved value
    lsr     x0, x1, \imm
    and     x0, x0, 1
.endm

// load result for \xM in xN
.macro load_result xN, xM
    mov     \xN, 192                // begin of saved results
    add     \xN, \xN, \xM, lsl 3
    ldr     \xN, [sp, \xN]          // load saved result to x0
.endm

// load expected result for \imm in x1
.macro load_expected xN, xM
    mov     \xN, 112                // begin of expected results
    add     \xN, \xN, \xM, lsl 3
    ldr     \xN, [sp, \xN]          // load expected result to x1
.endm

.macro print_stderr
    mov     x0, 2       // STDERR
    // x1 has the address and x2 the size
    mov     x8, 64      // write
    svc     0
.endm

// print string \str of length \len
.macro print_str str, len
    ldr     x1, =\str
    ldr     x2, =\len
    print_stderr
.endm

// print integer value
// @param x0    value to be printed
_print_int:
    mov     x2, 0                   // size
    ldr     x3, =buffer             // write head into buffer (backwards)
    ldr     x4, =buffer_len
    add     x3, x3, x4
    cbz     x0, .print_int.zero

    mov     x4, 10

    .print_int.loop:
        cbz     x0, .print_int.str
        sub     x3, x3, 1
        add     x2, x2, 1

        udiv    x5, x0, x4          // x5 = xN / 10
        msub    x6, x5, x4, x0      // x6 = xN % 10 (the digit to be converted)
        add     x6, x6, '0'         // convert to char
        strb    w6, [x3]
        mov     x0, x5
        b       .print_int.loop

    .print_int.zero:
    sub     x3, x3, 1
    mov     x6, '0'
    strb    w6, [x3]
    mov     x2, 1

    .print_int.str:
    mov     x1, x3
    // x2 already has the size
    print_stderr
    ret

// print an int
.macro print_int xN
    mov     x0, \xN
    bl      _print_int
.endm

// print a line break
.macro print_ln
    ldr     x1, =line_break
    mov     x2, 1
    print_stderr
.endm

// test that a function call preserves registers states
// @param x0 - x7   params to function
// @param x8        function to call
// @param x9        bit mask for results set (bits 0-7)
// @param x10 - x17 expected results
check_equal:
    prepare_frame

    blr     x8                  // function under test

    save_result

    mov     x9, 0
    .check_equal.loop_result:
        cmp     x9, 8
        b.eq    .check_equal.loop_result.end
        is_reg_in_result    x9
        cbz     x0, .check_equal.loop_result.next

        load_result         x10, x9
        load_expected       x11, x9
        cmp                 x10, x11
        b.eq                .check_equal.loop_result.next
        print_str           eq_error_0, eq_error_0_len
        print_int           x9
        print_str           eq_error_1, eq_error_1_len
        print_int           x10
        print_str           eq_error_2, eq_error_2_len
        print_int           x11
        print_ln

        .check_equal.loop_result.next:
        add     x9, x9, 1
        b .check_equal.loop_result
    .check_equal.loop_result.end:

    restore_frame
    ret

.data
buffer:         //23456789 123456789 123456789 12
    .ascii      "                                "
buffer_len = . - buffer
line_break:
    .ascii      "\n"
eq_error_0:
    .asciz      "Error found in register x"
eq_error_0_len = . - eq_error_0
eq_error_1:
    .asciz      " / "
eq_error_1_len = . - eq_error_1
eq_error_2:
    .asciz      " != "
eq_error_2_len = . - eq_error_2

