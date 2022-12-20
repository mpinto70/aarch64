.global _start

.text
_start:
    add     x19, sp, 0      // x19 points to # of cmd line arguments
    ldr     x20, [x19]      // # of command line arguments
    cmp     X20, 2
    b.ne    ._start.wrong_num_params
    ldr     x21, [x19, 16]  // buffer with cmd line arg

    mov     x0, x21         // addr of cmd arg
    bl      _strlen

    mov     x1, x0
    mov     x0, x21         // addr of cmd arg
    bl      _stoi
    cbnz    x0, ._start.param_not_number

    mov     x22, x1         // converted number

    mov     x0, x22
    bl      _allocate_memory
    // exit success
    mov     x0, 0
    mov     x8, 93          // __NR_exit
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
    mov     x0, 1
    mov     x8, 93          // __NR_exit
    svc     0

.data
    wrong_num_params:
        .asciz "Invalid number of parameters!\n"
    error_not_number:
        .asciz "Parameter not a number!\n"

.text
// @param x0    # of bytes to allocate
_allocate_memory:
    stp     x29, x30, [sp, -64]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    mov     x19, x0             // # of bytes

    mov     x0, 0
    mov     x8, 214             // __NR_brk
    svc     0

    mov     x20, x0             // pointer to begin of brk

    bl      _print_int
    bl      _break_line

    add     x0, x20, x19        // allocate x19 bytes
    mov     x8, 214             // __NR_brk
    svc     0

    mov     x21, x0             // new end of brk

    bl      _print_int
    bl      _break_line

    mov     x0, x20             // restore brk space to begin
    mov     x8, 214             // __NR_brk
    svc     0

    bl      _print_int
    bl      _break_line

    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x29, x30, [sp], 64
    ret
