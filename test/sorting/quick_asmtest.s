.text

.global main

main:
    stp     x29, x30, [sp, -16]!

    bl      dirty_x0_x18        // put random values in registers
    mov     x0, 0xff0000000     // parameters to FUT
    mov     x1, 0xff8000000
    ldr     x8, =_right_pivot   // FUT
    ldr     x18, =main          // base address for error messages
    mov     x9, 0x1             // active result registers only x0
    sub     x10, x1, 16         // expected value for x0
    bl      check_call

    mov     x0, 0
    ldp     x29, x30, [sp], 16
    ret

// fills registers x0 to x8 with strange values
dirty_x0_x18:
    stp     x29, x30, [sp, -16]!

    bl      _getrandom_64
    ror     x1, x0, 3
    ror     x2, x1, 3
    ror     x3, x2, 3
    ror     x4, x3, 3
    ror     x5, x4, 3
    ror     x6, x5, 3
    ror     x7, x6, 3
    ror     x8, x7, 3
    ror     x9, x8, 3
    ror     x10, x9, 3
    ror     x11, x10, 3
    ror     x12, x11, 3
    ror     x13, x12, 3
    ror     x14, x13, 3
    ror     x15, x14, 3
    ror     x16, x15, 3
    ror     x17, x16, 3
    ror     x18, x17, 3

    ldp     x29, x30, [sp], 16
    ret

// prepare the frame with space for all registers and save them all.
// Notes
// * registers x19-x28 are saved on top of the stack
// * space is available to store the result (x0-x7) with save_result macro
.macro prepare_frame
    stp     x29, x30, [sp, -416]!
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
    ldp     x29, x30, [sp], 416
.endm

// save results after calling function under test
.macro save_result
    stp     x0, x1, [sp, 192]
    stp     x2, x3, [sp, 208]
    stp     x4, x5, [sp, 224]
    stp     x6, x7, [sp, 240]
.endm

// fills registers x19 to x28 with strange values and save them
.macro save_x19_to_x28_random
    mov     x19, 0x7fffffffffffffff
    ror     x20, x19, 7
    ror     x21, x20, 7
    ror     x22, x21, 7
    ror     x23, x22, 7
    ror     x24, x23, 7
    ror     x25, x24, 7
    ror     x26, x25, 7
    ror     x27, x26, 7
    ror     x28, x27, 7

    stp     x19, x20, [sp, 256]
    stp     x21, x22, [sp, 272]
    stp     x23, x24, [sp, 288]
    stp     x25, x26, [sp, 304]
    stp     x27, x28, [sp, 320]
.endm

// save x19 to x28 after calling FUT
.macro save_x19_to_x28_result
    stp     x19, x20, [sp, 336]
    stp     x21, x22, [sp, 352]
    stp     x23, x24, [sp, 368]
    stp     x25, x26, [sp, 384]
    stp     x27, x28, [sp, 400]
.endm

// check if a register \imm has expectation on result (0<= imm <= 7)
.macro is_reg_in_result imm
    ldr     x1, [sp, 104]       // load value of x9 saved value
    lsr     x0, x1, \imm
    and     x0, x0, 1
.endm

// load result for \xM in \xN
.macro load_result xN, xM
    mov     \xN, 192                // begin of saved results
    add     \xN, \xN, \xM, lsl 3
    ldr     \xN, [sp, \xN]          // load saved result to xN
.endm

// load expected result for \xM in \xN
.macro load_expected xN, xM
    mov     \xN, 112                // begin of expected results
    add     \xN, \xN, \xM, lsl 3
    ldr     \xN, [sp, \xN]          // load expected result to xN
.endm

// load result for \xM in \xN
.macro load_reg_result xN, xM
    mov     \xN, 336                // begin of saved reg results
    add     \xN, \xN, \xM, lsl 3
    ldr     \xN, [sp, \xN]          // load saved reg result to xN
.endm

// load expected result for \xM in \xN
.macro load_reg_expected xN, xM
    mov     \xN, 256                // begin of expected reg results
    add     \xN, \xN, \xM, lsl 3
    ldr     \xN, [sp, \xN]          // load expected result to xN
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

// will put a thousand separator in address pointed by x3 - 1
// will decrement x3, increment x2 and change x6
.macro thousand_separator
    sub     x3, x3, 1
    add     x2, x2, 1
    mov     x6, '\''
    strb    w6, [x3]
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
    mov     x7, 3

    .print_int.loop:
        cbz     x0, .print_int.str
        sub     x3, x3, 1
        add     x2, x2, 1
        sub     x7, x7, 1

        udiv    x5, x0, x4          // x5 = x0 / 10
        msub    x6, x5, x4, x0      // x6 = x0 % 10 (the digit to be converted)
        add     x6, x6, '0'         // convert to char
        strb    w6, [x3]
        mov     x0, x5
        cbnz    x7, .print_int.loop.no_thousand
        mov     x7, 3
        thousand_separator
        .print_int.loop.no_thousand:
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

// print hex value
// @param x0    value to be printed
_print_hex:
    mov     x2, 0                   // size
    ldr     x3, =buffer             // write head into buffer (backwards)
    ldr     x4, =buffer_len
    add     x3, x3, x4
    cbz     x0, .print_hex.zero

    mov     x7, 4
    .print_hex.loop:
        cbz     x0, .print_hex.str
        sub     x3, x3, 1
        add     x2, x2, 1
        sub     x7, x7, 1

        and     x6, x0, 0xf
        mov     x5, 10
        cmp     x6, x5
        b.ge    .print_hex.loop.if_hexa
        mov     x4, '0'         // base digit
        b       .print_hex.loop.if_hexa_end
        .print_hex.loop.if_hexa:
        mov     x4, 'a'         // base hexa
        sub     x6, x6, 10
        .print_hex.loop.if_hexa_end:

        add     x6, x6, x4
        strb    w6, [x3]
        lsr     x0, x0, 4

        cbnz    x7, .print_hex.loop.no_thousand
        mov     x7, 4
        thousand_separator
        .print_hex.loop.no_thousand:

        b       .print_hex.loop

    .print_hex.zero:
    sub     x3, x3, 1
    mov     x6, '0'
    strb    w6, [x3]
    mov     x2, 1

    .print_hex.str:
    sub     x3, x3, 1
    mov     x6, 'x'
    strb    w6, [x3]
    sub     x3, x3, 1
    mov     x6, '0'
    strb    w6, [x3]
    add     x2, x2, 2       // space for '0x'
    mov     x1, x3
    // x2 already has the size
    print_stderr
    ret

// print an int
.macro print_hex xN
    mov     x0, \xN
    bl      _print_hex
.endm

// print a line break
.macro print_ln
    ldr     x1, =line_break
    mov     x2, 1
    print_stderr
.endm

// print error message for validation (dirties x11 - x16)
// @param x0    # of register (from x9)
// @param x1    lhs value
// @param x2    rhs value
// @param x3    comparison error message
// @param x4    comparison error message length
print_error:
    stp     x29, x30, [sp, -16]!
    add     x11, sp, 16     // get address of old stack
    mov     x12, x0
    mov     x13, x1
    mov     x14, x2
    mov     x15, x3
    mov     x16, x4
    print_str           error_in_register, error_in_register_len
    print_int           x12
    print_str           separator, separator_len
    print_int           x13
    mov                 x1, x15
    mov                 x2, x16
    print_stderr
    print_int           x14
    print_str           error_location, error_location_len
    ldr                 x14, [x11, 8]        // return address of caller x30
    sub                 x14, x14, 4         // move to calling
    ldr                 x13, [x11, 176]      // base address of calling function x18
    sub                 x14, x14, x13
    print_hex           x14
    print_str           left_paren, left_paren_len
    lsr                 x14, x14, 2
    print_int           x14
    print_str           right_paren, right_paren_len
    print_ln

    ldp     x29, x30, [sp], 16
    ret

// print error message for validation (dirties x11 - x16)
// @param x0    # of register (from x9)
// @param x1    lhs value
// @param x2    rhs value
// @param x3    comparison error message
// @param x4    comparison error message length
print_hex_error:
    stp     x29, x30, [sp, -16]!
    add     x11, sp, 16     // get address of old stack
    mov     x12, x0
    mov     x13, x1
    mov     x14, x2
    mov     x15, x3
    mov     x16, x4
    print_str           error_in_register, error_in_register_len
    print_int           x12
    print_str           separator, separator_len
    print_hex           x13
    mov                 x1, x15
    mov                 x2, x16
    print_stderr
    print_hex           x14
    print_str           error_location, error_location_len
    ldr                 x14, [x11, 8]        // return address of caller x30
    sub                 x14, x14, 4         // move to calling
    ldr                 x13, [x11, 176]      // base address of calling function x18
    sub                 x14, x14, x13
    print_hex           x14
    print_str           left_paren, left_paren_len
    lsr                 x14, x14, 2
    print_int           x14
    print_str           right_paren, right_paren_len
    print_ln

    ldp     x29, x30, [sp], 16
    ret

// check that callee registers are preserved (x19-x28)
.macro check_callee_registers
    mov     x9, 0
    .check_callee_registers.loop_registers:
        cmp                 x9, 10
        b.eq                .check_callee_registers.loop_registers.end

        load_reg_result     x1, x9
        load_reg_expected   x2, x9
        cmp                 x1, x2
        b.eq                .check_callee_registers.loop_registers.next
        add                 x0, x9, 19
        ldr                 x3, =eq_error
        ldr                 x4, =eq_error_len
        bl                  print_hex_error

        .check_callee_registers.loop_registers.next:
        add     x9, x9, 1
        b .check_callee_registers.loop_registers
    .check_callee_registers.loop_registers.end:
.endm

// check that callee registers are preserved (x19-x28)
.macro check_call_results
    mov     x9, 0
    .check_call_results.loop_result:
        cmp                 x9, 8
        b.eq                .check_call_results.loop_result.end
        is_reg_in_result    x9
        cbz                 x0, .check_call_results.loop_result.next

        load_result         x1, x9
        load_expected       x2, x9
        cmp                 x1, x2
        b.eq                .check_call_results.loop_result.next
        mov                 x0, x9
        ldr                 x3, =eq_error
        ldr                 x4, =eq_error_len
        bl                  print_error

        .check_call_results.loop_result.next:
        add     x9, x9, 1
        b .check_call_results.loop_result
    .check_call_results.loop_result.end:
.endm

// test that a function call preserves registers states
// @param x0 - x7   params to function
// @param x8        function to call
// @param x9        bit mask for results set (bits 0-7)
// @param x10 - x17 expected results
// @param x18       base address
check_call:
    prepare_frame

    save_x19_to_x28_random
    blr     x8                  // function under test
    save_result
    save_x19_to_x28_result

    check_callee_registers

    check_call_results

    restore_frame
    ret

.data
buffer:         //23456789 123456789 123456789 12
    .ascii      "                                "
buffer_len = . - buffer
line_break:
    .ascii      "\n"
error_in_register:
    .asciz      "Error found in register x"
error_in_register_len = . - error_in_register
separator:
    .asciz      " ==> "
separator_len = . - separator
eq_error:
    .asciz      " != "
eq_error_len = . - eq_error
error_location:
    .asciz      " <== offset "
error_location_len = . - error_location
left_paren:
    .asciz      " ("
left_paren_len = . - left_paren
right_paren:
    .asciz      ") "
right_paren_len = . - right_paren
