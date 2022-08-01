.global _getrandom
.global _getrandom_between
.global _swap_numbers

.text
// generates random bytes
// @param[out] x0   begin of buffer to receive the random bytes
// @param x1        # of bytes in buffer
_getrandom:
    mov     x2, 0
    mov     x8, 278     // ssize_t getrandom(void *buf, size_t buflen, unsigned int flags)
    svc     0
    ret

// generates random number between two numbers
// @param x0    min
// @param x1    max
// @return x0   the random number in [x0, x1[
_getrandom_between:
    stp     x29, x30, [sp, -128]!
    stp     x19, x20, [sp, 16]

    mov     x19, x0
    mov     x20, x1

    add     x0, sp, 32
    mov     x1, 8
    bl      _getrandom

    ldr     x10, [sp, 32]
    sub     x11, x20, x19       // interval
    udiv    x12, x10, x11       // x12 = x10 / size
    msub    x13, x12, x11, x10  // x13 = x10 % interval

    add     x0, x19, x13

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 128      // restore x29, x30 (LR)
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
