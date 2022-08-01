#include "local_unistd.h"

.global _strlen
.global _print_z
.global _print_int
.global _itos
.global _stoi
.global _break_line
.global _print_ln
.global _print_numbers
.global _strings_to_ints
.global _getrandom
.global _getrandom_between
.global _swap_numbers

.text
/// calculate length of a null terminated string
/// @param x0 address of begin of string
/// @return x0 the length of the string
_strlen:
    mov     x9, x0
    mov     x10, x9
    ._strlen.loop:                      // search for '\0'
        ldrb    w11, [x10]
        cbz     w11, ._strlen.loop_end  // null char detected
        add     x10, x10, 1
        b       ._strlen.loop
    ._strlen.loop_end:

    sub     x0, x10, x9                // string size

    ret

.text
/// print a null terminated string
/// @param x0 address of begin of string
/// @return NONE
_print_z:
    stp     x29, x30, [sp, -32]!        // store x29, x30 (LR) on stack and reserve 32 bytes
    stp     x19, x20, [sp, 16]

    mov     x19, x0                     // save pointer to string

    bl      _strlen
    mov     x11, x0                     // string size

    mov     x0, STDOUT_FILENO
    mov     x1, x19
    mov     x2, x11
    mov     x8, __NR_write
    svc     0

    ldp     x19, x20, [sp, 16]

    ldp     x29, x30, [sp], 32          // restore x29, x30 (LR)
    ret

.text
/// print an int
/// @param x0 the value to print
/// @return NONE
_print_int:
    stp     x29, x30, [sp, -64]!    // store x29, x30 (LR) on stack and reserve 32 bytes
    add     x29, sp, 0

    stp     x19, x20, [sp, 16]

    add     x19, x29, 32    // pointer to buffer
    mov     x1, x19
    mov     x2, 32
    bl      _itos

    mov     x20, x1         // number of chars in string

    mov     x0, STDOUT_FILENO
    mov     x1, x19
    mov     x2, x20
    mov     x8, __NR_write
    svc     0

    ldp     x19, x20, [sp, 16]

    ldp     x29, x30, [sp], 64      // restore x29, x30 (LR)
    ret

.text
/// convert a int to a string
/// @param x0       the value to print
/// @param[out] x1  output buffer address
/// @param x2       buffer size
/// @return x0      0 success; 1 error
///         x1      number of chars written
_itos:
    stp     x29, x30, [sp, -64]!    // store x29, x30 (LR) on stack and reserve 32 bytes
    add     x29, sp, 0

    add     x15, x29, 64            // x15 is pointer to internal buffer (1 after the end of buffer)
    mov     x16, xzr                // x16 is the digit counter

    cbz     x0, ._itos.int_is_zero

    // number is converted from right to left
    mov     x11, 10                 // divisor
    ._itos.loop_convert:
        cmp     x16, x2
        b.eq    ._itos.no_space      // not enough space in output buffer
        sub     x15, x15, 1         // move one char back
        add     x16, x16, 1         // mark one more char
        udiv    x12, x0, x11        // x12 = x0 / 10
        msub    x13, x12, x11, x0   // x13 = x0 % 10 (the digit to be converted)
        add     x13, x13, '0'       // convert to char
        strb    w13, [x15]          // put digit in buffer
        mov     x0, x12             // x0 = x0 / 10
        cbz     x0, ._itos.copy_to_output // number is over
        b       ._itos.loop_convert

    ._itos.int_is_zero:
    sub     x15, x15, 1
    mov     x16, 1          // only one digit
    mov     w12, '0'        // put '0' in buffer
    strb    w12, [x15]
    b       ._itos.copy_to_output

    ._itos.no_space:
    mov     x0, 1
    b       ._itos.exit

    ._itos.copy_to_output:
    // x15 points to local converted buffer
    // x1 points to output bufer (x17 will be used to iterate)
    mov     x0, xzr         // success
    mov     x17, x1         // pointer to output buffer
    mov     x1, x16         // number of chars

    ._itos.loop_transfer:
        cbz     x16, ._itos.exit
        sub     x16, x16, 1
        ldrb    w11, [x15]
        strb    w11, [x17]
        add     x15, x15, 1
        add     x17, x17, 1
        b       ._itos.loop_transfer

    ._itos.exit:
    ldp     x29, x30, [sp], 64      // restore x29, x30 (LR)
    ret

.text
/// convert a string to an int
/// @param x0       buffer with integer text
/// @param x1       buffer size
/// @return x0      0 success
///         x1      converted number
/// @return x0      1 error
///         x1      pointer to the char that triggered error
_stoi:
    mov     x15, x0     // X15 points to buffer
    mov     x16, x1     // X16 has buffer size
    mov     x17, xzr    // acumulator for value

    // number is converted from right to left
    mov     x12, 10                 // multiplier
    ._stoi.loop_convert:
        cbz     x16, ._stoi.return   // no more data
        mov     x11, xzr
        ldrb    w11, [x15]      // get digit from buffer
        cmp     x11, 0x30       // verify that it is a digit
        b.lt    ._stoi.error    // not a digit
        cmp     x11, 0x39       // verify that it is a digit
        b.gt    ._stoi.error    // not a digit
        sub     x11, x11, 0x30  // convert digit to int
        mul     x17, x17, x12   // x17 *= 10 + x11
        add     x17, x17, x11
        sub     x16, x16, 1     // consume size
        add     x15, x15, 1     // advance pointer
        b       ._stoi.loop_convert

    ._stoi.return:
    mov     x0, xzr     // sucess
    mov     x1, x17     // converted value
    b       ._stoi.exit

    ._stoi.error:
    mov     x0, 1       // error
    mov     x1, x15     // char that caused error

    ._stoi.exit:
    ret

.text
/// print a line break
/// @param NONE
/// @return NONE
_break_line:    // no param
    mov     x0, STDOUT_FILENO
    adr     x1, ._break_line.new_line_txt
    mov     x2, 1
    mov     x8, __NR_write
    svc     0

    ret

.data
    ._break_line.new_line_txt:
        .ascii "\n"

.text
/// print a null terminated string with a line break at the end
/// @param x0 address of begin of string
/// @return NONE
_print_ln:
    stp     x29, x30, [sp, -16]!      // store x29, x30 (LR) on stack

    bl      _print_z
    bl      _break_line

    ldp     x29, x30, [sp], 16       // restore x29, x30 (LR)
    ret

.text
/// convert an array of null terminated strings into an array of ints
/// @param x0   array of pointer to strings
/// @param x1   # of elements
/// @param x2   array of ints (with space for at least x1 elements)
/// @return x0  0 - success / 1 - error
_strings_to_ints:
    stp     x29, x30, [sp, -32]!    // store x29, x30 (LR) on stack and reserve 32 bytes
    stp     x19, x20, [sp, 16]      // sotre x19 and x20 to restore at the end
    stp     x21, x22, [sp, 32]      // sotre x21 and x22 to restore at the end

    mov     x20, x0
    mov     x21, x1
    mov     x22, x2
    ._strings_to_ints.loop_strs:
        cbz     x21, ._strings_to_ints.loop_strs_end
        // convert current arq
        ldr     x0, [x20]
        bl      _strlen
        mov     x1, x0
        ldr     x0, [x20]
        bl      _stoi
        cbnz    x0, ._strings_to_ints.param_not_number

        // store converted arg
        str     x1, [x22]
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
    ldp     x21, x22, [sp, 32]
    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32      // restore x29, x30 (LR)

    ret

/// print an array of ints
/// @param x0   address of array
/// @param x1   # of elements
/// @return NONE
_print_numbers:
    stp     x29, x30, [sp, -32]!    // store x29, x30 (LR) on stack and reserve 32 bytes
    stp     x21, x22, [sp, 16]      // sotre x21 and x22 to restore at the end

    mov     x21, x1
    mov     x22, x0
    ._print_numbers.loop_print:
        cbz     x21, ._print_numbers.loop_print_end
        // convert current arq
        ldr     x0, [x22]
        bl      _print_int
        sub     x21, x21, 1     // one less arg
        add     x22, x22, 8
        adr     x0, space
        bl      _print_z
        b       ._print_numbers.loop_print
    ._print_numbers.loop_print_end:
    bl      _break_line

    ldp     x21, x22, [sp, 16]
    ldp     x29, x30, [sp], 32      // restore x29, x30 (LR)
    ret

.data
    space:
        .asciz " "

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

    mov     x0, x19
    mov     x1, x20
    ldr     x2, [sp, 32]
    bl      _get_seeded_between

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 128      // restore x29, x30 (LR)
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
