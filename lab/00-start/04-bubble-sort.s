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
    mov     x1, x19
    bl      _bubble_sort

    mov     x0, sp
    mov     x1, x19
    bl      _print_numbers

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
_sort_two:
    cmp     x0, x1
    b.le    ._sort_two.exit
    mov     x2, x0
    mov     x0, x1
    mov     x1, x2
    ._sort_two.exit:
    ret

/// sort an array of ints (inplace) with bubble sort algorithm
/// @param x0   address of array
/// @param x1   # of elements
/// @return NONE
_bubble_sort:
    stp     x29, x30, [sp, -64]!    // store x29, x30 (LR) on stack and reserve 32 bytes
    stp     x19, x20, [sp, 16]      // sotre x19 and x20 to restore at the end
    stp     x21, x22, [sp, 32]      // sotre x21 and x22 to restore at the end
    stp     x23, x24, [sp, 48]      // sotre x23 and x24 to restore at the end

    mov     x19, x0                 // x19 points to begin of array
    sub     x20, x1, 1              // x20 is the end of iterations
    ._bubble_sort.outer_loop:
        cbz     x20, ._bubble_sort.outer_loop_end
        mov     x21, xzr                // first element for the pair comparison
        ._bubble_sort.inner_loop:
            cmp     x21, x20
            b.eq    ._bubble_sort.inner_loop_end
            add     x22, x21, 1
            ldr     x0, [x19, x21, lsl 3]
            ldr     x1, [x19, x22, lsl 3]
            bl      _sort_two
            str     x0, [x19, x21, lsl 3]
            str     x1, [x19, x22, lsl 3]
            add     x21, x21, 1
            b       ._bubble_sort.inner_loop
        ._bubble_sort.inner_loop_end:
        sub     x20, x20, 1
        b ._bubble_sort.outer_loop
    ._bubble_sort.outer_loop_end:

    ldp     x23, x24, [sp, 48]
    ldp     x21, x22, [sp, 32]
    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 64      // restore x29, x30 (LR)

    ret
