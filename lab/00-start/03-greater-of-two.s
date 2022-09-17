#include "local_unistd.h"

.global _start

.text
// return the greater of two parameters passed
_start:
    // print command line arguments
    ldr     x19, [sp]   // number of command line paramters
    cmp     X19, 3
    b.ne    ._start.wrong_num_params

    add     x20, sp, 16 // skip argc and the program name

    // convert first parameter
    ldr     x0, [x20]
    bl      _strlen
    mov     x1, x0
    ldr     x0, [x20]
    bl      _stoi
    cbnz    x0, ._start.param_1_not_number
    mov     x21, x1     // save converted param 1

    add     x20, x20, 8
    // convert first parameter
    ldr     x0, [x20]
    bl      _strlen
    mov     x1, x0
    ldr     x0, [x20]
    bl      _stoi
    cbnz    x0, ._start.param_2_not_number
    mov     x22, x1     // save converted param 1

    // select greater and print it
    cmp     x21, x22
    b.lt    ._start.print_second
    mov     x0, x21     // print first
    b       ._start.print

    ._start.print_second:
    mov     x0, x22

    ._start.print:
    bl      _print_int
    bl      _break_line

    // exit success
    mov     x0, 0
    mov     x8, __NR_exit
    svc     0

    // error processing
    ._start.param_1_not_number:
    adr     x0, error_first
    bl      _print_z
    b       ._start.exit_error

    ._start.param_2_not_number:
    adr     x0, error_second
    bl      _print_z
    b       ._start.exit_error

    ._start.wrong_num_params:
    adr     x0, wrong_num_params
    bl      _print_z
    b       ._start.exit_error

    ._start.exit_error:
    mov     x0, 1
    mov     x8, __NR_exit
    svc     0

.data
    wrong_num_params:
        .asciz "Invalid number of parameters!\n"
    error_first:
        .asciz "First parameter is not a number!\n"
    error_second:
        .asciz "Second parameter is not a number!\n"
