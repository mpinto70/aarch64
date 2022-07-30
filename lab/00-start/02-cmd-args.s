#include "local_unistd.h"

.global _start

.text
_start:
    // print command line arguments
    ldr     x19, [sp]
    mov     x20, sp

    .loop_cmd:
        add     x20, x20, 8
        ldr     x0, [x20]
        bl      _print_ln

        sub     x19, x19, 1
        cbz     x19, .loop_cmd_end    // no more args
        b       .loop_cmd
    .loop_cmd_end:

    // print hello world.
    adr     x0, hello_txt
    bl      _print_z

    // convert number to string
    adr     x0, number
    ldr     x1, =number_len
    bl      _stoi
    mov     x0, x1
    bl      _print_int
    bl      _break_line

    // print a value
    mov     x0, 0xffffffffffffffff
    bl      _print_int
    bl      _break_line

    mov     x0, 0
    mov     x8, __NR_exit
    svc     0

.data
    hello_txt:
        .asciz "Polarizacao eh meu pau em sua mao!\n"
    hello_len = . - hello_txt
    number:
        .ascii "123456789"
    number_len = . - number
