.global _str_to_uint64
.global _hex_to_uint64
.global _strz_to_uint64
.global _hexz_to_uint64

.global _strsz_to_uint64s

.global _uint64_to_str
.global _uint64_to_hex
.global _uint64_to_strz
.global _uint64_to_hexz

.global _convert_hex_digit

.text
/// convert a string to an int
/// @param x0       buffer with integer text
/// @param x1       buffer size
/// @param[out] x2  address of output paramter
/// @return x0      0 success (nullptr)
/// @return x0      address of first offending char in the string
_str_to_uint64:
    mov     x15, x0     // X15 points to buffer
    mov     x16, x1     // X16 has buffer size
    mov     x17, x2     // output address
    mov     x18, xzr    // acumulator for value

    // number is converted from right to left
    mov     x12, 10                         // multiplier
    ._str_to_uint64.loop_convert:
        cbz     x16, ._str_to_uint64.return // no more data
        mov     x11, xzr
        ldrb    w11, [x15]                  // get digit from buffer
        sub     x11, x11, '0'
        cmp     x11, 10                     // verify that it is a digit
        b.hs    ._str_to_uint64.error       // not a digit
        mul     x18, x18, x12               // x18 = x18*10 + x11
        add     x18, x18, x11
        sub     x16, x16, 1                 // consume size
        add     x15, x15, 1                 // advance pointer
        b       ._str_to_uint64.loop_convert

    ._str_to_uint64.return:
    mov     x0, xzr             // sucess
    str     x18, [x17]          // converted value
    b       ._str_to_uint64.exit

    ._str_to_uint64.error:
    mov     x0, x15             // pointer to offending char

    ._str_to_uint64.exit:
    ret

.text
/// convert a character to its hex value
/// @return x0 0 on success and 1 on error
/// @return x1 the value (on success)
_convert_hex_digit:
    sub     x1, x0, '0'
    cmp     x1, 10
    b.hs    ._convert_hex_digit.not_decimal

    mov     x0, xzr
    ret

    ._convert_hex_digit.not_decimal:
    orr     x0, x0, 0x20    // convert to lower case
    sub     x1, x0, 'a'
    cmp     x1, 6
    b.hs    ._convert_hex_digit.not_hex_digit

    add     x1, x1, 10
    mov     x0, xzr
    ret

    ._convert_hex_digit.not_hex_digit:
    mov     x0, 1
    ret

.text
/// convert a hex string to an int
/// @param x0       buffer with hex text
/// @param x1       buffer size
/// @param[out] x2  address of output paramter
/// @return x0      0 success (nullptr)
/// @return x0      address of first offending char in the hex string
_hex_to_uint64:
    stp     x29, x30, [sp, -48]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    mov     x19, x0     // x19 points to buffer
    mov     x20, x1     // x20 has buffer size
    mov     x21, x2     // output address
    mov     x22, xzr    // acumulator for value

    // number is converted from left to right
    ._hex_to_uint64.loop_convert:
        cbz     x20, ._hex_to_uint64.return // no more data
        mov     x0, xzr
        ldrb    w0, [x19]                   // get hex digit from buffer

        bl      _convert_hex_digit

        cbnz    x0, ._hex_to_uint64.error
        mov     x11, x1

        lsl     x22, x22, 4                 // one digit shift
        add     x22, x22, x11               // add current digit
        sub     x20, x20, 1                 // consume size
        add     x19, x19, 1                 // advance pointer
        b       ._hex_to_uint64.loop_convert

    ._hex_to_uint64.return:
    mov     x0, xzr             // sucess
    str     x22, [x21]          // converted value
    b       ._hex_to_uint64.exit

    ._hex_to_uint64.error:
    mov     x0, x19             // pointer to offending char

    ._hex_to_uint64.exit:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x29, x30, [sp], 48
    ret

.text
/// convert a null terminated string to an int
/// @param x0       buffer with integer text
/// @param[out] x1  address of output paramter
/// @return x0      0 success (nullptr)
/// @return x0      address of first offending char in the string
_strz_to_uint64:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    mov     x19, x0     // save string pointer
    mov     x20, x1     // save output parameter

    bl      _strz_len

    mov     x1, x0      // # of chars
    mov     x0, x19     // restore string pointer
    mov     x2, x20     // output parameter that was in x1
    bl      _str_to_uint64

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret

.text
/// convert a null terminated hex string to an int
/// @param x0       buffer with hex text
/// @param[out] x1  address of output paramter
/// @return x0      0 success (nullptr)
/// @return x0      address of first offending char in the hex string
_hexz_to_uint64:
    stp     x29, x30, [sp, -48]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    mov     x19, x0     // x19 points to buffer
    mov     x21, x1     // output address
    mov     x22, xzr    // acumulator for value

    // number is converted from left to right
    ._hexz_to_uint64.loop_convert:
        mov     x0, xzr
        ldrb    w0, [x19]                   // get hex digit from buffer
        cbz     x0, ._hexz_to_uint64.return // no more data

        bl      _convert_hex_digit

        cbnz    x0, ._hexz_to_uint64.error
        mov     x11, x1

        lsl     x22, x22, 4                 // one digit shift
        add     x22, x22, x11               // add current digit
        add     x19, x19, 1                 // advance pointer
        b       ._hexz_to_uint64.loop_convert

    ._hexz_to_uint64.return:
    mov     x0, xzr             // sucess
    str     x22, [x21]          // converted value
    b       ._hexz_to_uint64.exit

    ._hexz_to_uint64.error:
    mov     x0, x19             // pointer to offending char

    ._hexz_to_uint64.exit:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x29, x30, [sp], 48
    ret

.text
/// convert an array of null terminated strings into an array of ints
/// @param x0   array of pointer to strings
/// @param x1   # of elements
/// @param x2   array of ints (with space for at least x1 elements)
/// @return x0  0 - success / address of ofending string
_strsz_to_uint64s:
    stp     x29, x30, [sp, -48]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    mov     x20, x0     // begin of array of strings (will be incremented)
    mov     x21, x1     // # of strings (will be decremented)
    mov     x22, x2     // begin array of ints (will be incremented)
    ._strsz_to_uint64s.loop_strs:
        cbz     x21, ._strsz_to_uint64s.loop_strs_end
        // convert current arq
        ldr     x0, [x20]
        mov     x1, x22
        bl      _strz_to_uint64
        cbnz    x0, ._strsz_to_uint64s.param_not_number

        add     x22, x22, 8     // next number
        add     x20, x20, 8     // next str
        sub     x21, x21, 1     // one less str
        b       ._strsz_to_uint64s.loop_strs
    ._strsz_to_uint64s.loop_strs_end:

    mov     x0, xzr
    b ._strsz_to_uint64s.exit
    // error processing
    ._strsz_to_uint64s.param_not_number:
    ldr     x0, [x20]           // ofending string
    b       ._strsz_to_uint64s.exit

    ._strsz_to_uint64s.exit:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x29, x30, [sp], 48
    ret

.text
/// convert a uint64 to a string
/// @param x0       the value to convert
/// @param[out] x1  output buffer address
/// @param x2       buffer size
/// @return x0      number of chars written (0 means there was no space in buffer)
_uint64_to_str:
    stp     x29, x30, [sp, -64]!

    cbz     x2, ._uint64_to_str.no_space
    cbz     x0, ._uint64_to_str.int_is_zero

    add     x29, sp, 0              // x29 is the bottom of stack
    add     x15, x29, 64            // x15 is pointer to internal buffer (1 after the end of buffer)
    mov     x16, xzr                // x16 is the digit counter

    // number is converted from right to left
    mov     x11, 10                 // divisor
    ._uint64_to_str.loop_convert:
        cmp     x16, x2
        b.eq    ._uint64_to_str.no_space    // not enough space in output buffer
        sub     x15, x15, 1         // move one char back
        add     x16, x16, 1         // mark one more char
        udiv    x12, x0, x11        // x12 = x0 / 10
        msub    x13, x12, x11, x0   // x13 = x0 % 10 (the digit to be converted)
        add     x13, x13, '0'       // convert to char
        strb    w13, [x15]          // put digit in buffer
        mov     x0, x12             // x0 = x0 / 10
        cbz     x0, ._uint64_to_str.copy_to_output  // number is over
        b       ._uint64_to_str.loop_convert

    ._uint64_to_str.int_is_zero:
    sub     x15, x15, 1
    mov     x16, 1          // only one digit
    mov     w12, '0'        // put '0' in buffer
    strb    w12, [x15]
    b       ._uint64_to_str.copy_to_output

    ._uint64_to_str.no_space:
    mov     x0, 0
    b       ._uint64_to_str.exit

    ._uint64_to_str.copy_to_output:
    // x15 points to local converted buffer
    // x1 points to output bufer (x17 is used to iterate)
    mov     x0, x16         // success (number of chars)
    mov     x17, x1         // pointer to output buffer

    ._uint64_to_str.loop_transfer:
        cbz     x16, ._uint64_to_str.exit   // are we done yet
        sub     x16, x16, 1
        ldrb    w11, [x15]
        strb    w11, [x17]
        add     x15, x15, 1 // next input char
        add     x17, x17, 1 // next output char
        b       ._uint64_to_str.loop_transfer

    ._uint64_to_str.exit:
    ldp     x29, x30, [sp], 64
    ret

.text
/// convert a uint64 to a hex string
/// @param x0       the value to convert
/// @param[out] x1  output buffer address
/// @param x2       buffer size
/// @return x0      number of chars written (0 means there was no space in buffer)
_uint64_to_hex:
    stp     x29, x30, [sp, -64]!

    cbz     x2, ._uint64_to_hex.no_space
    cbz     x0, ._uint64_to_hex.int_is_zero

    add     x29, sp, 0              // x29 is the bottom of stack
    add     x15, x29, 64            // x15 is pointer to internal buffer (1 after the end of buffer)
    mov     x16, xzr                // x16 is the digit counter

    // number is converted from right to left
    mov     x12, 10                 // limit value for conversion
    ._uint64_to_hex.loop_convert:
        cmp     x16, x2
        b.eq    ._uint64_to_hex.no_space    // not enough space in output buffer
        sub     x15, x15, 1         // move one char back
        add     x16, x16, 1         // mark one more char
        and     x13, x0, 0xf        // get lower nibble
        cmp     x13, x12
        b.ge    ._uint64_to_hex.if_hexa
        add     x13, x13, '0'       // converted decimal char
        b       ._uint64_to_hex.if_hexa_end
        ._uint64_to_hex.if_hexa:
        sub     x13, x13, 10        // reduce 10
        add     x13, x13, 'a'       // converted hex char
        ._uint64_to_hex.if_hexa_end:

        strb    w13, [x15]          // put digit in buffer
        lsr     x0, x0, 4           // x0 = x0 / 16
        cbz     x0, ._uint64_to_hex.copy_to_output  // number is over
        b       ._uint64_to_hex.loop_convert

    ._uint64_to_hex.int_is_zero:
    sub     x15, x15, 1
    mov     x16, 1          // only one digit
    mov     w12, '0'        // put '0' in buffer
    strb    w12, [x15]
    b       ._uint64_to_hex.copy_to_output

    ._uint64_to_hex.no_space:
    mov     x0, 0
    b       ._uint64_to_hex.exit

    ._uint64_to_hex.copy_to_output:
    // x15 points to local converted buffer
    // x1 points to output bufer (x17 is used to iterate)
    mov     x0, x16         // success (number of chars)
    mov     x17, x1         // pointer to output buffer

    ._uint64_to_hex.loop_transfer:
        cbz     x16, ._uint64_to_hex.exit   // are we done yet
        sub     x16, x16, 1
        ldrb    w11, [x15]
        strb    w11, [x17]
        add     x15, x15, 1 // next input char
        add     x17, x17, 1 // next output char
        b       ._uint64_to_hex.loop_transfer

    ._uint64_to_hex.exit:
    ldp     x29, x30, [sp], 64
    ret

.text
/// convert a uint64 to a null terminated string
/// @param x0       the value to convert
/// @param[out] x1  output buffer address
/// @param x2       buffer size
/// @return x0      number of chars written except the null terminator (0 means there was no space in buffer)
_uint64_to_strz:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    cbz     x2, ._uint64_to_strz.no_space

    sub     x2, x2, 1           // reserve space for the null

    mov     x19, x0             // save x0
    mov     x20, x1             //     and x1

    bl      _uint64_to_str

    cbz     x0, ._uint64_to_strz.exit

    add     x10, x20, x0
    mov     w11, wzr
    strb    w11, [x10]          // put null terminator in buffer

    b       ._uint64_to_strz.exit

    ._uint64_to_strz.no_space:
    mov     x0, 0
    b       ._uint64_to_strz.exit

    ._uint64_to_strz.exit:
    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret

.text
/// convert a uint64 to a null terminated hex string
/// @param x0       the value to convert
/// @param[out] x1  output buffer address
/// @param x2       buffer size
/// @return x0      number of chars written except the null terminator (0 means there was no space in buffer)
_uint64_to_hexz:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    cbz     x2, ._uint64_to_hexz.no_space

    sub     x2, x2, 1           // reserve space for the null

    mov     x19, x0             // save x0
    mov     x20, x1             //     and x1

    bl      _uint64_to_hex

    cbz     x0, ._uint64_to_hexz.exit

    add     x10, x20, x0
    mov     w11, wzr
    strb    w11, [x10]          // put null terminator in buffer

    b       ._uint64_to_hexz.exit

    ._uint64_to_hexz.no_space:
    mov     x0, 0
    b       ._uint64_to_hexz.exit

    ._uint64_to_hexz.exit:
    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret
