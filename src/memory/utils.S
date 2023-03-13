.global _mem_pbase
.global _mem_size
// functions that should not be called if there are other allocation functions (malloc, ...)
.global mem_init
.global mem_deinit
.global mem_reserve

// general use functions
.global mem_next_mult_power_of_2
.global mem_power_of_2_ceiling
.global mem_power_of_2_floor
.global mem_size_index
.global mem_fill
.global mem_fill_n
.global mem_copy
.global mem_copy_n
.global mem_copy_backward
.global mem_copy_n_backward

////////////////////////////////////////////////////////////////////////////////////////////////////
// data ////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

.data
_mem_pbase      : .dword 0
_mem_size       : .dword 0

////////////////////////////////////////////////////////////////////////////////////////////////////
// allocation functions ////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

// load _mem_pbase and _mem_size into \xM and \xN
.macro load_pbase_and_size xM, xN
    adr     \xM, _mem_pbase
    ldp     \xM, \xN, [\xM]
.endm

// load _mem_pbase into \xM
.macro load_pbase xM
    adr     \xM, _mem_pbase
    ldr     \xM, [\xM]
.endm

// load _mem_size into \xM
.macro load_size xM
    adr     \xM, _mem_size
    ldr     \xM, [\xM]
.endm

// store \xM and \xN to _mem_pbase and _mem_size (dirties x9)
.macro store_pbase_and_size xM, xN
    adr     x9, _mem_pbase
    stp     \xM, \xN, [x9]
.endm

// store \xM into _mem_pbase (dirties x9)
.macro store_pbase xM
    adr     x9, _mem_pbase
    str     \xM, [x9]
.endm

// store \xM into _mem_size (dirties x9)
.macro store_size xM
    adr     x9, _mem_size
    str     \xM, [x9]
.endm

.text
/// initializes memory pool
/// @return x0  0 - on success
/// @return x0  1 - on failure to allocate or if it is already initialized
mem_init:
    mov     x0, xzr                 // leave x0 at success
    load_pbase      x10
    cbnz    x10, .mem_init.error    // already initialized

    // get end of heap memory
    mov     x0, xzr
    mov     x8, 214                 // __NR_brk
    svc     0                       // x0 has brk

    cbz     x0, .mem_init.error     // it was not possible to get brk

    store_pbase     x0              // store brk in _mem_pbase
    mov     x0, xzr
    b       .mem_init.return

    .mem_init.error:
    mov     x0, 1

    .mem_init.return:
    ret

.text
/// deinitializes memory pool
/// @return x0  0 - on success
/// @return x0  1 - on failure
mem_deinit:
    mov     x0, xzr                 // leave x0 at success
    load_pbase      x10
    cbz     x10, .mem_deinit.return // not initialized

    mov     x0, x10                 // x0 now has _mem_pbase value
    mov     x8, 214                 // __NR_brk
    svc     0                       // x0 has brk

    cbz     x0, .mem_deinit.error

    store_pbase_and_size    xzr, xzr
    mov     x0, xzr
    b       .mem_deinit.return

    .mem_deinit.error:
    mov     x0, 1

    .mem_deinit.return:
    ret

/// assure that memory pool size is at least x0
/// @param x0   the size
/// @return x0  0 - on success or if space already is at least x0
/// @return x0  1 - on failure to allocate more space
mem_reserve:
#define size        x19
#define pbase       x20
#define mem_sz      x21
#define mem_new_sz  x22
    stp     x29, x30, [sp, -48]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    mov     size, x0
    load_pbase_and_size     pbase, mem_sz
    cbz     pbase, .mem_reserve.error

    cmp     size, mem_sz
    b.ls    .mem_reserve.already_done

    add     x0, pbase, size         // x0 now has new target end
    mov     x8, 214                 // __NR_brk
    svc     0                       // x0 has brk

    cbz     x0, .mem_reserve.error

    sub     mem_new_sz, x0, pbase
    store_size      mem_new_sz

    .mem_reserve.already_done:
    mov     x0, 0
    b       .mem_reserve.return

    .mem_reserve.error:
    mov     x0, 1

    .mem_reserve.return:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x29, x30, [sp], 48
    ret
#undef size
#undef pbase
#undef mem_sz
#undef mem_new_sz

////////////////////////////////////////////////////////////////////////////////////////////////////
// utility functions ///////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

.text
/// return the index in the buddy system
/// @param x0   the size
/// @return     the index
mem_size_index:
    cbz     x0, .mem_size_index.zero

    sub     x0, x0, 1
    clz     x0, x0

    mov     x1, 64
    sub     x0, x1, x0

    .mem_size_index.zero:
    ret

.text
/// return the power of 2 at or above passed number
/// @param x0   the number
/// @return     the power of 2 at or above x0
mem_power_of_2_ceiling:
    stp     x29, x30, [sp, -16]!

    bl      mem_size_index

    mov     x9, 1

    lsl     x0, x9, x0

    ldp     x29, x30, [sp], 16
    ret

.text
/// return the power of 2 at or below passed number
/// @param x0   the number
/// @return     the power of 2 at or below x0
/// From Hacker's Delight 2nd edition, figure 3.1
mem_power_of_2_floor:
    orr     x0, x0, x0, lsr 1
    orr     x0, x0, x0, lsr 2
    orr     x0, x0, x0, lsr 4
    orr     x0, x0, x0, lsr 8
    orr     x0, x0, x0, lsr 16
    orr     x0, x0, x0, lsr 32

    sub     x0, x0, x0, lsr 1
    ret

.text
/// return the number at or above x0 that is a multiple of 2^x1
/// @param x0   the value
/// @param x1   the power
/// @return     the number at or above x0 that is a multiple of 2^x1
mem_next_mult_power_of_2:
    sub     x0, x0, 1
    mov     x9, 1
    lsl     x9, x9, x1
    add     x0, x0, x9

    lsr     x0, x0, x1
    lsl     x0, x0, x1

    ret

// /////////////////////////////////////////////////////////////////////////////////////////////////
// mem fill functions //////////////////////////////////////////////////////////////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////

.text
/// Fills one byte if there is space
/// @param x0   pointer to begin of buffer
/// @param x1   number of bytes to fill
/// @param x2   char to fill
/// @return x0  the pointer after the byte copied
/// @return x1  the remaining number of bytes to fill
/// @return x2  char to fill
_mem_fill_byte:
    cbz     x1, _mem_fill_byte.return          // nothing to do

    strb    w2, [x0], 1
    sub     x1, x1, 1   // reduce number of bytes

    _mem_fill_byte.return:
    ret

.text
/// Fills 2 bytes if there is space
/// @param x0   pointer to begin of buffer
/// @param x1   number of bytes to fill
/// @param x2   char to fill copyed in 2 bytes
/// @return x0  the pointer after the bytes copied
/// @return x1  the remaining number of bytes to fill
/// @return x2  char to fill
_mem_fill_half_word:
    cmp     x1, 2
    b.lo    _mem_fill_half_word.return         // nothing to do

    strh    w2, [x0], 2
    sub     x1, x1, 2   // reduce number of bytes

    _mem_fill_half_word.return:
    ret

.text
/// Fills 4 bytes if there is space
/// @param x0   pointer to begin of buffer
/// @param x1   number of bytes to fill
/// @param x2   char to fill copyed in 2 bytes
/// @return x0  the pointer after the bytes copied
/// @return x1  the remaining number of bytes to fill
/// @return x2  char to fill
_mem_fill_word:
    cmp     x1, 4
    b.lo    _mem_fill_word.return              // nothing to do

    str     w2, [x0], 4
    sub     x1, x1, 4   // reduce number of bytes

    _mem_fill_word.return:
    ret

.text
/// Fills memory in range [x0 .. x1[ with char in x2 8 bytes at a time
/// @param x0   pointer to begin of buffer
/// @param x1   number of bytes to fill
/// @param x2   char to fill copyed in 8 bytes
/// @return x0  the pointer after the bytes copied
/// @return x1  the remaining number of bytes to fill
/// @return x2  char to fill
_mem_fill_all_dwords:
    lsr     x8, x1, 3
    _mem_fill_all_dwords.loop.blit8:
    cbz     x8, _mem_fill_all_dwords.loop.blit8.end
    str     x2, [x0], 8
    sub     x8, x8, 1
    b       _mem_fill_all_dwords.loop.blit8
    _mem_fill_all_dwords.loop.blit8.end:

    and     x1, x1, 0x7
    ret

.text
/// Fills memory in range [x0 .. x1[ with char in x2 16 bytes at a time
/// @param x0   pointer to begin of buffer
/// @param x1   number of bytes to fill
/// @param x2   char to fill copyed in 8 bytes
/// @return x0  the pointer after the bytes copied
/// @return x1  the remaining number of bytes to fill
/// @return x2  char to fill
_mem_fill_all_double_dwords:
    lsr     x8, x1, 4
    _mem_fill_all_double_dwords.loop.blit8:
    cbz     x8, _mem_fill_all_double_dwords.loop.blit8.end
    stp     x2, x2, [x0], 16
    sub     x8, x8, 1
    b       _mem_fill_all_double_dwords.loop.blit8
    _mem_fill_all_double_dwords.loop.blit8.end:

    and     x1, x1, 0xf
    ret

.text
/// Fills memory in range [x0 .. x1[ with char in x2 16 bytes at a time
/// @param x0   pointer to begin of buffer
/// @param x1   number of bytes to fill
/// @param x2   char to fill copyed in 8 bytes
/// @return x0  the pointer after the bytes copied
/// @return x1  the remaining number of bytes to fill
/// @return x2  char to fill
_mem_fill_all_double_qwords:
    mov     v2.d[0], x2
    mov     v2.d[1], x2

    lsr     x8, x1, 5
    _mem_fill_all_double_qwords.loop.blit8:
    cbz     x8, _mem_fill_all_double_qwords.loop.blit8.end
    stp     q2, q2, [x0], 32
    sub     x8, x8, 1
    b       _mem_fill_all_double_qwords.loop.blit8
    _mem_fill_all_double_qwords.loop.blit8.end:

    and     x1, x1, 0x1f
    ret

.text
/// Fills memory in range [x0 .. x1[ with char in x2
/// @param x0   pointer to begin of buffer
/// @param x1   pointer to one after the last byte in buffer
/// @param x2   char to fill
/// @return     NONE
mem_fill:
    stp     x29, x30, [sp, -16]!

    sub     x1, x1, x0      // calculate size

    bl      mem_fill_n

    ldp     x29, x30, [sp], 16
    ret

.text
/// Fills memory starting in x0 of size x1 with char in x2
/// @param x0   pointer to begin of buffer
/// @param x1   number of bytes to fill
/// @param x2   char to fill
/// @return     NONE
mem_fill_n:
    stp     x29, x30, [sp, -16]!

    // spread char over all x2
    add     x2, x2, x2, lsl 8
    add     x2, x2, x2, lsl 16
    add     x2, x2, x2, lsl 32

    cmp     x1, 16
    b.lo    .mem_fill_n.less.than.16

    // align src to 16 bytes
    stp     x2, x2, [x0]    // first fill the first 16 bytes
    and     x8, x0, 0xf     // calculate offset to 16 byte boundary ==> 16 - (x0 & 0xf)
    mov     x9, 16
    sub     x8, x9, x8
    add     x0, x0, x8      // now memory is aligned
    sub     x1, x1, x8      // remove already copied from count

    bl      _mem_fill_all_double_qwords
    bl      _mem_fill_all_double_dwords

    .mem_fill_n.less.than.16:

    bl      _mem_fill_all_dwords

    bl      _mem_fill_word
    bl      _mem_fill_half_word
    bl      _mem_fill_byte

    ldp     x29, x30, [sp], 16
    ret

// /////////////////////////////////////////////////////////////////////////////////////////////////
// mem copy functions //////////////////////////////////////////////////////////////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////

.text
/// Determine the maximum blit possible
/// @param x0   pointer to begin of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to begin of dst buffer
/// @return x0  (not changed) pointer to begin of src buffer
/// @return x1  (not changed) number of bytes to copy
/// @return x2  (not changed) pointer to begin of dst buffer
/// @return x3  maximum blit possible one of (1, 2, 4, 8, 16, 32)
_mem_copy_maximum_blit:
    stp     x29, x30, [sp, -48]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    mov     x19, x0
    mov     x20, x1
    mov     x21, x2

    cmp     x21, x19
    b.lo    ._mem_copy_maximum_blit.overlaps
    mov     x3, 32
    b ._mem_copy_maximum_blit.return

    ._mem_copy_maximum_blit.overlaps:
    sub     x3, x19, x21        // distance between begin of dst and begin of src
    mov     x4, 32
    cmp     x3, x4
    csel    x3, x3, x4, lo      // get the smallest

    ._mem_copy_maximum_blit.return:
    cmp     x3, x20
    csel    x3, x3, x20, lo     // get the smallest
    mov     x0, x3
    bl      mem_power_of_2_floor
    mov     x3, x0
    // recover input parameters
    mov     x0, x19
    mov     x1, x20
    mov     x2, x21

    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x29, x30, [sp], 48
    ret

.text
/// Copy memory in range [x0 .. x0 + x1[ to memory starting at x2 one byte at a time
/// @param x0   pointer to begin of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to begin of dst buffer
/// @return x0  pointer after the last copied byte (source)
/// @return x1  number of bytes left after last byte is copied
/// @return x2  pointer after the last copied byte (destination)
_mem_copy_blit_bytes:
    _mem_copy_blit_bytes.loop:
    cbz     x1, _mem_copy_blit_bytes.loop.end
    ldrb    w8, [x0], 1
    strb    w8, [x2], 1
    sub     x1, x1, 1
    b       _mem_copy_blit_bytes.loop
    _mem_copy_blit_bytes.loop.end:

    ret

.text
/// Copy memory in range [x0 .. x0 + x1[ to memory starting at x2 two bytes at a time
/// @param x0   pointer to begin of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to begin of dst buffer
/// @return x0  pointer after the last copied byte (source)
/// @return x1  number of bytes left after last byte is copied
/// @return x2  pointer after the last copied byte (destination)
_mem_copy_blit_half_words:
    _mem_copy_blit_half_words.loop:
    cmp     x1, 2
    b.lo    _mem_copy_blit_half_words.loop.end
    ldrh    w8, [x0], 2
    strh    w8, [x2], 2
    sub     x1, x1, 2
    b       _mem_copy_blit_half_words.loop
    _mem_copy_blit_half_words.loop.end:

    ret

.text
/// Copy memory in range [x0 .. x0 + x1[ to memory starting at x2 four bytes at a time
/// @param x0   pointer to begin of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to begin of dst buffer
/// @return x0  pointer after the last copied byte (source)
/// @return x1  number of bytes left after last byte is copied
/// @return x2  pointer after the last copied byte (destination)
_mem_copy_blit_words:
    _mem_copy_blit_words.loop:
    cmp     x1, 4
    b.lo    _mem_copy_blit_words.loop.end
    ldr     w8, [x0], 4
    str     w8, [x2], 4
    sub     x1, x1, 4
    b       _mem_copy_blit_words.loop
    _mem_copy_blit_words.loop.end:

    ret

.text
/// Copy memory in range [x0 .. x0 + x1[ to memory starting at x2 eight bytes at a time
/// @param x0   pointer to begin of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to begin of dst buffer
/// @return x0  pointer after the last copied byte (source)
/// @return x1  number of bytes left after last byte is copied
/// @return x2  pointer after the last copied byte (destination)
_mem_copy_blit_dwords:
    _mem_copy_blit_dwords.loop:
    cmp     x1, 8
    b.lo    _mem_copy_blit_dwords.loop.end
    ldr     x8, [x0], 8
    str     x8, [x2], 8
    sub     x1, x1, 8
    b       _mem_copy_blit_dwords.loop
    _mem_copy_blit_dwords.loop.end:

    ret

.text
/// Copy memory in range [x0 .. x0 + x1[ to memory starting at x2 16 bytes at a time
/// @param x0   pointer to begin of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to begin of dst buffer
/// @return x0  pointer after the last copied byte (source)
/// @return x1  number of bytes left after last byte is copied
/// @return x2  pointer after the last copied byte (destination)
_mem_copy_blit_double_dwords:
    _mem_copy_blit_double_dwords.loop:
    cmp     x1, 16
    b.lo    _mem_copy_blit_double_dwords.loop.end
    ldp     x8, x9, [x0], 16
    stp     x8, x9, [x2], 16
    sub     x1, x1, 16
    b       _mem_copy_blit_double_dwords.loop
    _mem_copy_blit_double_dwords.loop.end:

    ret

.text
/// Copy memory in range [x0 .. x0 + x1[ to memory starting at x2 32 bytes at a time
/// @param x0   pointer to begin of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to begin of dst buffer
/// @return x0  pointer after the last copied byte (source)
/// @return x1  number of bytes left after last byte is copied
/// @return x2  pointer after the last copied byte (destination)
_mem_copy_blit_double_qwords:
    _mem_copy_blit_double_qwords.loop:
    cmp     x1, 32
    b.lo    _mem_copy_blit_double_qwords.loop.end
    ldp     q8, q9, [x0], 32
    stp     q8, q9, [x2], 32
    sub     x1, x1, 32
    b       _mem_copy_blit_double_qwords.loop
    _mem_copy_blit_double_qwords.loop.end:

    ret

.text
/// Align src memory access
/// @param x0   pointer to begin of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to begin of dst buffer
/// @param x3   maximum blit
/// @return x0  aligned pointer to begin of src buffer
/// @return x1  number of bytes to copy left after alignment
/// @return x2  pointer to begin of dst buffer after src has been aligned
/// @return x3  (not changed) maximum blit
_mem_copy_align_src_buffer:
    cmp     x3, 16                              // maximum allowed alignment is 16
    b.lo    ._mem_copy_align_src_buffer.less.than.16
    ldp     x8, x9, [x0]
    stp     x8, x9, [x2]
    mov     x8, 16
    and     x9, x0, 0xf
    b       ._mem_copy_align_src_buffer.return

    ._mem_copy_align_src_buffer.less.than.16:
    cmp     x3, 8
    b.lo    ._mem_copy_align_src_buffer.less.than.8
    ldr     x8, [x0]
    str     x8, [x2]
    mov     x8, 8
    and     x9, x0, 0x7
    b       ._mem_copy_align_src_buffer.return

    ._mem_copy_align_src_buffer.less.than.8:
    cmp     x3, 4
    b.lo    ._mem_copy_align_src_buffer.less.than.4
    ldr     w8, [x0]
    str     w8, [x2]
    mov     x8, 4
    and     x9, x0, 0x3
    b       ._mem_copy_align_src_buffer.return

    ._mem_copy_align_src_buffer.less.than.4:
    cmp     x3, 2
    b.lo    ._mem_copy_align_src_buffer.less.than.2
    ldrh    w8, [x0]
    strh    w8, [x2]
    mov     x8, 2
    and     x9, x0, 0x1
    b       ._mem_copy_align_src_buffer.return

    ._mem_copy_align_src_buffer.less.than.2:
    ldrb    w8, [x0]
    strb    w8, [x2]
    mov     x8, 1
    mov     x9, xzr

    ._mem_copy_align_src_buffer.return:

    sub     x8, x8, x9
    add     x0, x0, x8
    sub     x1, x1, x8
    add     x2, x2, x8

    ret

.text
/// Copy memory in range [x0 .. x1[ to memory starting at x2
/// @attention begin of destination cannot overlap with source range
/// @param x0   pointer to begin of src buffer
/// @param x1   pointer to one after the last byte in src buffer
/// @param x2   pointer to begin of dst buffer
/// @return     NONE
mem_copy:
    stp     x29, x30, [sp, -16]!

    sub     x1, x1, x0      // calculate number of bytes to copy
    bl      mem_copy_n

    ldp     x29, x30, [sp], 16
    ret

.text
/// Copy memory in range [x0 .. x0 + x1[ to memory starting at x2
/// @attention begin of destination cannot overlap with source range
/// @param x0   pointer to begin of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to begin of dst buffer
/// @return     NONE
mem_copy_n:
    stp     x29, x30, [sp, -16]!
    cbz     x1, .mem_copy_n.return

    bl      _mem_copy_maximum_blit
    bl      _mem_copy_align_src_buffer

    cmp     x3, 32
    b.eq    .mem_copy_n.max.blit.32
    cmp     x3, 16
    b.eq    .mem_copy_n.max.blit.16
    cmp     x3, 8
    b.eq    .mem_copy_n.max.blit.8
    cmp     x3, 4
    b.eq    .mem_copy_n.max.blit.4
    cmp     x3, 2
    b.eq    .mem_copy_n.max.blit.2
    b       .mem_copy_n.max.blit.1

    .mem_copy_n.max.blit.32:
    bl      _mem_copy_blit_double_qwords
    .mem_copy_n.max.blit.16:
    bl      _mem_copy_blit_double_dwords
    .mem_copy_n.max.blit.8:
    bl      _mem_copy_blit_dwords
    .mem_copy_n.max.blit.4:
    bl      _mem_copy_blit_words
    .mem_copy_n.max.blit.2:
    bl      _mem_copy_blit_half_words
    .mem_copy_n.max.blit.1:
    bl      _mem_copy_blit_bytes

    .mem_copy_n.return:
    ldp     x29, x30, [sp], 16
    ret

// /////////////////////////////////////////////////////////////////////////////////////////////////
// mem copy functions //////////////////////////////////////////////////////////////////////////////
// /////////////////////////////////////////////////////////////////////////////////////////////////

/// Copy memory in range [x0 - x1 .. x0[ to memory ending at x2 32 bytes at a time (backward)
/// @param x0   pointer to END of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to end of dst buffer
/// @return x0  pointer to the last read double qword
/// @return x1  number of bytes left after last byte is copied
/// @return x2  pointer at the last copied double qword
_mem_copy_backward_blit_double_qwords:
    _mem_copy_backward_blit_double_qwords.loop:
    cmp     x1, 32
    b.lo    _mem_copy_backward_blit_double_qwords.loop.end
    ldp     q8, q9, [x0, -32]!
    stp     q8, q9, [x2, -32]!
    sub     x1, x1, 32
    b       _mem_copy_backward_blit_double_qwords.loop
    _mem_copy_backward_blit_double_qwords.loop.end:
    ret

/// Copy memory in range [x0 - x1 .. x0[ to memory ending at x2 16 bytes at a time (backward)
/// @param x0   pointer to END of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to end of dst buffer
/// @return x0  pointer to the last read double dword
/// @return x1  number of bytes left after last byte is copied
/// @return x2  pointer at the last copied double dword
_mem_copy_backward_blit_double_dwords:
    _mem_copy_backward_blit_double_dwords.loop:
    cmp     x1, 16
    b.lo    _mem_copy_backward_blit_double_dwords.loop.end
    ldp     x8, x9, [x0, -16]!
    stp     x8, x9, [x2, -16]!
    sub     x1, x1, 16
    b       _mem_copy_backward_blit_double_dwords.loop
    _mem_copy_backward_blit_double_dwords.loop.end:
    ret

/// Copy memory in range [x0 - x1 .. x0[ to memory ending at x2 8 bytes at a time (backward)
/// @param x0   pointer to END of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to end of dst buffer
/// @return x0  pointer to the last read dword
/// @return x1  number of bytes left after last byte is copied
/// @return x2  pointer at the last copied dword
_mem_copy_backward_blit_dwords:
    _mem_copy_backward_blit_dwords.loop:
    cmp     x1, 8
    b.lo    _mem_copy_backward_blit_dwords.loop.end
    ldr     x8, [x0, -8]!
    str     x8, [x2, -8]!
    sub     x1, x1, 8
    b       _mem_copy_backward_blit_dwords.loop
    _mem_copy_backward_blit_dwords.loop.end:
    ret

/// Copy memory in range [x0 - x1 .. x0[ to memory ending at x2 4 bytes at a time (backward)
/// @param x0   pointer to END of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to end of dst buffer
/// @return x0  pointer to the last read word
/// @return x1  number of bytes left after last byte is copied
/// @return x2  pointer at the last copied word
_mem_copy_backward_blit_words:
    _mem_copy_backward_blit_words.loop:
    cmp     x1, 4
    b.lo    _mem_copy_backward_blit_words.loop.end
    ldr     w8, [x0, -4]!
    str     w8, [x2, -4]!
    sub     x1, x1, 4
    b       _mem_copy_backward_blit_words.loop
    _mem_copy_backward_blit_words.loop.end:
    ret

/// Copy memory in range [x0 - x1 .. x0[ to memory ending at x2 2 bytes at a time (backward)
/// @param x0   pointer to END of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to end of dst buffer
/// @return x0  pointer to the last read half word
/// @return x1  number of bytes left after last byte is copied
/// @return x2  pointer at the last copied half word
_mem_copy_backward_blit_half_words:
    _mem_copy_backward_blit_half_words.loop:
    cmp     x1, 2
    b.lo    _mem_copy_backward_blit_half_words.loop.end
    ldrh    w8, [x0, -2]!
    strh    w8, [x2, -2]!
    sub     x1, x1, 2
    b       _mem_copy_backward_blit_half_words.loop
    _mem_copy_backward_blit_half_words.loop.end:
    ret

/// Copy memory in range [x0 - x1 .. x0[ to memory ending at x2 1 byte at a time (backward)
/// @param x0   pointer to END of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to end of dst buffer
/// @return x0  pointer to the last read byte
/// @return x1  number of bytes left after last byte is copied
/// @return x2  pointer at the last copied byte
_mem_copy_backward_blit_bytes:
    _mem_copy_backward_blit_bytes.loop:
    cmp     x1, 1
    b.lo    _mem_copy_backward_blit_bytes.loop.end
    ldrb    w8, [x0, -1]!
    strb    w8, [x2, -1]!
    sub     x1, x1, 1
    b       _mem_copy_backward_blit_bytes.loop
    _mem_copy_backward_blit_bytes.loop.end:
    ret

/// Determine the maximum blit possible
/// @param x0   pointer to end of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to end of dst buffer
/// @return x0  (not changed) pointer to end of src buffer
/// @return x1  (not changed) number of bytes to copy
/// @return x2  (not changed) pointer to end of dst buffer
/// @return x3  maximum blit possible one of (1, 2, 4, 8, 16, 32)
_mem_copy_backward_maximum_blit:
    stp     x29, x30, [sp, -48]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    mov     x19, x0             // end of src
    mov     x20, x1             // n
    mov     x21, x2             // end of dst

    cmp     x21, x19            // if end of dst is after end of src
    b.hi    ._mem_copy_backward_maximum_blit.overlaps
    mov     x3, 32
    b ._mem_copy_backward_maximum_blit.return

    ._mem_copy_backward_maximum_blit.overlaps:
    mov     x4, 32
    sub     x3, x21, x19        // distance between end of dst and end of src
    cmp     x3, x4
    csel    x3, x3, x4, lo      // get the smallest

    ._mem_copy_backward_maximum_blit.return:
    cmp     x3, x20
    csel    x3, x3, x20, lo
    mov     x0, x3
    bl      mem_power_of_2_floor
    mov     x3, x0
    // recover input parameters
    mov     x0, x19
    mov     x1, x20
    mov     x2, x21

    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x29, x30, [sp], 48
    ret

.text
/// Align end of src memory access
/// @param x0   pointer to end of src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to end of dst buffer
/// @param x3   maximum blit
/// @return x0  aligned pointer to end of src buffer
/// @return x1  number of bytes to copy left after alignment
/// @return x2  pointer to end of dst buffer after src has been aligned
/// @return x3  (not changed) maximum blit
_mem_copy_backward_align_src_buffer:
    mov     x4, x0          // end of src

    cmp     x3, 16          // maximum allowed alignment is 16
    b.lo    ._mem_copy_backward_align_src_buffer.less.than.16
    ldp     x8, x9, [x4, -16]
    stp     x8, x9, [x2, -16]
    and     x8, x4, 0xf
    b       ._mem_copy_backward_align_src_buffer.return

    ._mem_copy_backward_align_src_buffer.less.than.16:
    cmp     x3, 8
    b.lo    ._mem_copy_backward_align_src_buffer.less.than.8
    ldr     x8, [x4, -8]
    str     x8, [x2, -8]
    and     x8, x4, 0x7
    b       ._mem_copy_backward_align_src_buffer.return

    ._mem_copy_backward_align_src_buffer.less.than.8:
    cmp     x3, 4
    b.lo    ._mem_copy_backward_align_src_buffer.less.than.4
    ldr     w8, [x4, -4]
    str     w8, [x2, -4]
    and     x8, x4, 0x3
    b       ._mem_copy_backward_align_src_buffer.return

    ._mem_copy_backward_align_src_buffer.less.than.4:
    cmp     x3, 2
    b.lo    ._mem_copy_backward_align_src_buffer.less.than.2
    ldrh    w8, [x4, -2]
    strh    w8, [x2, -2]
    and     x8, x4, 0x1
    b       ._mem_copy_backward_align_src_buffer.return

    ._mem_copy_backward_align_src_buffer.less.than.2:
    ldrb    w8, [x4, -1]
    strb    w8, [x2, -1]
    mov     x8, xzr

    ._mem_copy_backward_align_src_buffer.return:

    sub     x0, x0, x8
    sub     x1, x1, x8
    sub     x2, x2, x8

    ret

.text
/// Copy memory in range [x0 .. x1[ to memory ending at x2 (backward)
/// @attention begin of destination cannot overlap with source range
/// @param x0   pointer pointer to first byte in src buffer
/// @param x1   pointer to one after the last byte in src buffer
/// @param x2   pointer to the end of destination range (one after the last)
/// @return     NONE
mem_copy_backward:
    stp     x29, x30, [sp, -16]!

    sub     x1, x1, x0      // calculate number of bytes to copy
    bl      mem_copy_n_backward

    ldp     x29, x30, [sp], 16
    ret

.text
/// Copy memory in range [x0 .. x0 + x1[ to memory ending at x2 (backward)
/// @attention begin of destination cannot overlap with source range
/// @param x0   pointer pointer to first byte in src buffer
/// @param x1   number of bytes to copy
/// @param x2   pointer to the end of destination range (one after the last)
/// @return     NONE
mem_copy_n_backward:
    stp     x29, x30, [sp, -16]!
    cbz     x1, .mem_copy_n_backward.return

    add     x0, x0, x1          // x0 now is the pointer to end of src

    bl      _mem_copy_backward_maximum_blit
    bl      _mem_copy_backward_align_src_buffer

    cmp     x3, 32
    b.eq    .mem_copy_n_backward.max.blit.32
    cmp     x3, 16
    b.eq    .mem_copy_n_backward.max.blit.16
    cmp     x3, 8
    b.eq    .mem_copy_n_backward.max.blit.8
    cmp     x3, 4
    b.eq    .mem_copy_n_backward.max.blit.4
    cmp     x3, 2
    b.eq    .mem_copy_n_backward.max.blit.2
    b       .mem_copy_n_backward.max.blit.1

    .mem_copy_n_backward.max.blit.32:
    bl      _mem_copy_backward_blit_double_qwords
    .mem_copy_n_backward.max.blit.16:
    bl      _mem_copy_backward_blit_double_dwords
    .mem_copy_n_backward.max.blit.8:
    bl      _mem_copy_backward_blit_dwords
    .mem_copy_n_backward.max.blit.4:
    bl      _mem_copy_backward_blit_words
    .mem_copy_n_backward.max.blit.2:
    bl      _mem_copy_backward_blit_half_words
    .mem_copy_n_backward.max.blit.1:
    bl      _mem_copy_backward_blit_bytes

    .mem_copy_n_backward.return:
    ldp     x29, x30, [sp], 16
    ret
