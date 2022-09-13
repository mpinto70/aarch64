.global _strz_len

.text
/// calculate length of a null terminated string
/// @param x0 address of begin of string
/// @return x0 the length of the string
_strz_len:
    mov     x9, x0
    mov     x10, x9
    ._strz_len.loop:                        // search for '\0'
        ldrb    w11, [x10]
        cbz     w11, ._strz_len.loop_end    // null char detected
        add     x10, x10, 1
        b       ._strz_len.loop
    ._strz_len.loop_end:

    sub     x0, x10, x9                     // string size

    ret
