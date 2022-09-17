.global _print_out_n
.global _print_out_z
.global _print_err_n
.global _print_err_z
.global _brk_ln_out
.global _brk_ln_err

.text
/// print string of len chars to the passed stream
/// @param x0 address of begin of string
/// @param x1 number of chars (len)
/// @param x2 stream number
/// @return number of chars written
._print_stream_n:
    mov     x10, x2             // stream number
    mov     x11, x0             // string buffer
    mov     x12, x1             // length of string

    mov     x0, x10             // stream
    mov     x1, x11             // buffer
    mov     x2, x12             // length
    mov     x8, 64              // write
    svc     0

    ret

.text
/// print null terminated string to the passed stream
/// @param x0 address of begin of string
/// @param x1 stream number
/// @return number of chars written
._print_stream_z:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    mov     x19, x0             // save pointer to string
    mov     x20, x1             // save the stream number
    bl      _strz_len

    mov     x1, x0              // string length
    mov     x0, x19             // string buffer
    mov     x2, x20             // stream number
    bl      ._print_stream_n

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret

.text
/// print string of len chars to stdout
/// @param x0 address of begin of string
/// @param x1 number of chars (len)
/// @return number of chars written
_print_out_n:
    stp     x29, x30, [sp, -16]!

    mov     x2, 1               // stdout
    bl      ._print_stream_n

    ldp     x29, x30, [sp], 16
    ret

.text
/// print null terminated string to stdout
/// @param x0 address of begin of string
/// @return number of chars written
_print_out_z:
    stp     x29, x30, [sp, -16]!

    mov     x1, 1               // stdout
    bl      ._print_stream_z

    ldp     x29, x30, [sp], 16
    ret

.text
/// print string of len chars to stderr
/// @param x0 address of begin of string
/// @param x1 number of chars (len)
/// @return number of chars written
_print_err_n:
    stp     x29, x30, [sp, -16]!

    mov     x2, 2               // stderr
    bl      ._print_stream_n

    ldp     x29, x30, [sp], 16
    ret

.text
/// print null terminated string to stderr
/// @param x0 address of begin of string
/// @return number of chars written
_print_err_z:
    stp     x29, x30, [sp, -16]!

    mov     x1, 2               // stderr
    bl      ._print_stream_z

    ldp     x29, x30, [sp], 16
    ret

.text
/// Break line in stdout
/// @return number of chars written (1)
_brk_ln_out:
    stp     x29, x30, [sp, -16]!

    ldr     x0, =._line_break
    mov     x1, 1
    mov     x2, 1
    bl      ._print_stream_n

    ldp     x29, x30, [sp], 16
    ret

/// Break line in stderr
/// @return number of chars written (1)
_brk_ln_err:
    stp     x29, x30, [sp, -16]!

    ldr     x0, =._line_break
    mov     x1, 1
    mov     x2, 2
    bl      ._print_stream_n

    ldp     x29, x30, [sp], 16
    ret

.data
    ._line_break:
        .ascii      "\n"
