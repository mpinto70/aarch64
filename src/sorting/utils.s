.global _getrandom
.global _getrandom_64
.global _getsemirandom_64
.global _getrandom_between
.global _getsemirandom_between
.global _get_seeded_between
.global _swap_numbers

.text
// generates random bytes
// @param[out] x0   begin of buffer to receive the random bytes
// @param x1        # of bytes in buffer
// @return          the return of system call
_getrandom:
    mov     x2, 0
    mov     x8, 278     // ssize_t getrandom(void *buf, size_t buflen, unsigned int flags)
    svc     0
    ret

.text
// Creates a random number of 64 bits
// @return x0   the 64 bit random number
_getrandom_64:
    stp     x29, x30, [sp, -128]!

    add     x0, sp, 32
    mov     x1, 8
    bl      _getrandom

    ldr     x0, [sp, 32]

    ldp     x29, x30, [sp], 128      // restore x29, x30 (LR)
    ret

// Creates a semi random number of 64 bits
// @return x0   the 64 bit random number
_getsemirandom_64:
    stp     x29, x30, [sp, -64]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    ldr     x19, =_getsemirandom_64_ror_cnt
    ldr     x21, =_getsemirandom_64_seed

    ldr     x20, [x19]
    cbz     x20, ._getsemirandom_64.new_random
    ldr     x22, [x21]
    b       ._getsemirandom_64.finish

    ._getsemirandom_64.new_random:
    bl      _getrandom_64
    mov     x22, x0
    mov     x20, 64
    b       ._getsemirandom_64.finish

    ._getsemirandom_64.finish:
    ror     x22, x22, 1
    sub     x20, x20, 1
    str     x22, [x21]
    str     x20, [x19]

    mov     x0, x22

    ldp     x21, x22, [sp, 32]
    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 64
    ret

.data
    _getsemirandom_64_ror_cnt: .dword 0
    _getsemirandom_64_seed: .dword 0

.text

// generates random number between two numbers with parameterized generator
// @param x0    min
// @param x1    max
// @param x2    generator function
// @return x0   the random number in [x0, x1[
_get_parameterized_random_between:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    mov     x19, x0
    mov     x20, x1

    blr     x2

    mov     x10, x0
    sub     x11, x20, x19       // interval
    udiv    x12, x10, x11       // x12 = x10 / size
    msub    x13, x12, x11, x10  // x13 = x10 % interval

    add     x0, x19, x13

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret


// generates random number between two numbers
// @param x0    min
// @param x1    max
// @return x0   the random number in [x0, x1[
_getrandom_between:
    stp     x29, x30, [sp, -16]!

    adr     x2, _getrandom_64
    bl      _get_parameterized_random_between

    ldp     x29, x30, [sp], 16
    ret

// generates a semi random number between two numbers
// @param x0    min
// @param x1    max
// @return x0   the random number in [x0, x1[
_getsemirandom_between:
    stp     x29, x30, [sp, -16]!

    adr     x2, _getsemirandom_64
    bl      _get_parameterized_random_between

    ldp     x29, x30, [sp], 16
    ret

// get the value in interval with seed
// @param x0    min
// @param x1    max
// @param x2    seed
// @return x0   the seeded number in [x0, x1[
_get_seeded_between:
    sub     x11, x1, x0         // interval
    udiv    x12, x2, x11        // x12 = seed / interval
    msub    x13, x12, x11, x2   // x13 = seed % interval

    add     x0, x0, x13
    ret

/// swap two numbers in memory
/// @param x0   address of first
/// @param x1   address of second
/// @return NONE
_swap_numbers:
    ldr     x2, [x0]
    ldr     x3, [x1]
    str     x2, [x1]
    str     x3, [x0]
    ret
