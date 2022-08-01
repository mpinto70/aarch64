#include "local_unistd.h"

.global _start

.text
// return the greater of two parameters passed
// x19 - # of numbers
// x20 - pointer to cmd line arg
_start:
    // print command line arguments
    ldr     x19, [sp]       // # of command line paramters
    cmp     X19, 2
    b.lt    ._start.wrong_num_params
    sub     x19, x19, 1     // # of numbers

    add     x20, sp, 16     // skip argc and the program name

    add     x1, x19, 3      // assure that x1 is the first multiple
    lsr     x1, x1, 2       //      of 4 above or equal the # of
    lsl     x1, x1, 2       //      numbers
    mov     x21, 8          // # of bytes / int
    mul     x21, x21, x1    // space to reserve in stack
    sub     sp, sp, x21     // reserve the space

    // convert cmd line args to numbers and store in sp
    mov     x0, x20
    mov     x1, x19
    mov     x2, sp
    bl      _strings_to_ints
    cbnz    x0, ._start.param_not_number

    mov     x0, sp
    mov     x1, x19
    bl      _print_numbers

    mov     x0, sp
    add     x1, sp, x19, lsl 3
    bl      _quick_sort

    mov     x0, sp
    mov     x1, x19
    bl      _print_numbers

    bl      _print_random
    // exit success
    mov     x0, 0
    mov     x8, __NR_exit
    svc     0

    // error processing
    ._start.param_not_number:
    adr     x0, error_not_number
    bl      _print_z
    b       ._start.exit_error

    ._start.wrong_num_params:
    adr     x0, wrong_num_params
    bl      _print_z
    b       ._start.exit_error

    ._start.exit_error:
    add     sp, sp, x21
    mov     x0, 1
    mov     x8, __NR_exit
    svc     0

.data
    wrong_num_params:
        .asciz "Invalid number of parameters!\n"
    error_not_number:
        .asciz "Parameter not a number!\n"

.text

_print_random:
    stp     x29, x30, [sp, -128]!
    stp     x19, x20, [sp, 16]

    add     x19, sp, 32
    mov     x20, 10                 // # of iterations
    ._print_random.loop:
        cbz     x20, ._print_random.loop_end
        sub     x20, x20, 1

        mov     x0, x19
        mov     x1,2
        bl      _getrandom
        ldrh    w0, [x19]
        bl      _print_int
        bl      _break_line
        b       ._print_random.loop
    ._print_random.loop_end:

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 128     // restore x29, x30 (LR)
    ret
