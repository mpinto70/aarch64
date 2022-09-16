.global main

.text
// sort the numbers passed in command line
main:
    stp     x29, x30, [sp, -48]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    mov     x21, xzr        // no stack allocation yet

    // print command line arguments
    mov     x19, x0         // # of command line paramters
    cmp     X19, 2          // at least two parameters
    b.lt    .main.wrong_num_params
    sub     x19, x19, 1     // # of numbers (skip program name)

    add     x20, x1, 8      // skip argc and the program name

    add     x22, x19, 1     // assure that space is 16 bytes aligned
    lsr     x22, x22, 1     //  x22 = / x19         if x19 is even
    lsl     x22, x22, 1     //        \ x19 + 1     if x19 is odd
    mov     x21, 8          // # of bytes / int
    mul     x21, x21, x22   // space to reserve in stack

    sub     sp, sp, x21     // reserve the space

    // convert cmd line args to numbers and store in sp
    mov     x0, x20
    mov     x1, x19
    mov     x2, sp
    bl      ._strings_to_ints
    cbnz    x0, .main.param_not_number

    mov     x0, sp
    mov     x1, x19
    bl      ._print_numbers

    adr     x0, separator
    bl      _print_out_z

    mov     x0, sp
    add     x1, sp, x19, lsl 3
    adr     x2, _middle_pivot
    bl      _quick_sort

    mov     x0, sp
    mov     x1, x19
    bl      ._print_numbers

    // exit success
    mov     x0, 0
    b       .main.exit

    // error processing
    .main.param_not_number:
    adr     x0, error_not_number
    bl      _print_err_z
    b       .main.exit_error

    .main.wrong_num_params:
    adr     x0, wrong_num_params
    bl      _print_err_z
    b       .main.exit_error

    .main.exit_error:
    mov     x0, 1
    b       .main.exit

    .main.exit:
    add     sp, sp, x21     // give saved space back

    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x29, x30, [sp], 48
    ret

.data
    separator:
        .asciz "----------------------------------------\n"
    wrong_num_params:
        .ascii "Invalid number of parameters!\n"
        .ascii "\n"
        .ascii "Prints numbers sorted\n"
        .ascii "\n"
        .ascii "quick_sort <num> [<num> ...]\n"
        .ascii "\n"
        .asciz ""
    error_not_number:
        .asciz "Parameter not a number!\n"

.text
/// convert an array of null terminated strings into an array of ints
/// @param x0   array of pointer to strings
/// @param x1   # of elements
/// @param x2   array of ints (with space for at least x1 elements)
/// @return x0  0 - success / 1 - error
._strings_to_ints:
    stp     x29, x30, [sp, -48]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    mov     x20, x0     // array of strings (will be incremented)
    mov     x21, x1     // # of strings (will be decremented)
    mov     x22, x2     // array of ints (will be incremented)
    ._strings_to_ints.loop_strs:
        cbz     x21, ._strings_to_ints.loop_strs_end
        // convert current arq
        ldr     x0, [x20]
        mov     x1, x22
        bl      _strz_to_uint64
        cbnz    x0, ._strings_to_ints.param_not_number

        add     x22, x22, 8     // next number
        add     x20, x20, 8     // next arg
        sub     x21, x21, 1     // one less arg
        b       ._strings_to_ints.loop_strs
    ._strings_to_ints.loop_strs_end:

    mov     x0, xzr
    b ._strings_to_ints.exit
    // error processing
    ._strings_to_ints.param_not_number:
    mov     x0, 1
    b       ._strings_to_ints.exit

    ._strings_to_ints.exit:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x29, x30, [sp], 48
    ret

/// print an array of ints
/// @param x0   address of array
/// @param x1   # of elements
/// @return NONE
._print_numbers:
    stp     x29, x30, [sp, -80]!
    stp     x20, x21, [sp, 16]
    stp     x22, x23, [sp, 32]

    mov     x20, x0             // pointer to numbers (will be incremented)
    mov     x21, x1             // # of elements (will be decremented)
    add     x22, sp, 48         // buffer to converted string (32 bytes)
    ._print_numbers.loop_print:
        cbz     x21, ._print_numbers.loop_print_end
        // convert current arq
        ldr     x0, [x20]
        mov     x1, x22
        mov     x2, 32
        bl      _uint64_to_str

        mov     x1, x0          // number of chars in converted number
        mov     x0, x22         // pointer to buffer
        bl      _print_out_n

        sub     x21, x21, 1     // one less arg
        add     x20, x20, 8

        adr     x0, space
        mov     x1, 1
        bl      _print_out_n

        b       ._print_numbers.loop_print
    ._print_numbers.loop_print_end:
    bl      _brk_ln_out

    ldp     x20, x21, [sp, 16]
    ldp     x22, x23, [sp, 32]
    ldp     x29, x30, [sp], 80
    ret

.data
    space:
        .ascii " "
