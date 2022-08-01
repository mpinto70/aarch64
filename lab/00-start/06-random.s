#include "local_unistd.h"

.global _start

.text
_start:
    // print command line arguments
    bl      _print_random
    // exit success
    mov     x0, 0
    mov     x8, __NR_exit
    svc     0

.text
_print_random:
    stp     x29, x30, [sp, -128]!
    stp     x19, x20, [sp, 16]

    add     x19, sp, 32
    mov     x20, 100                 // # of iterations
    ._print_random.loop:
        cbz     x20, ._print_random.loop_end
        sub     x20, x20, 1

        mov     x0, 50
        mov     x1, 100
        bl      _getrandom_between
        bl      _print_int
        bl      _break_line
        b       ._print_random.loop
    ._print_random.loop_end:

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 128      // restore x29, x30 (LR)
    ret
