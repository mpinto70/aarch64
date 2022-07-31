.global _bubble_sort

.text

/// sort an array of ints (inplace) with bubble sort algorithm
/// @param x0   address of array
/// @param x1   end of array (one after last - open interval)
/// @return NONE
_bubble_sort:
    stp     x29, x30, [sp, -64]!    // store x29, x30 (LR) on stack and reserve 32 bytes
    stp     x19, x20, [sp, 16]      // sotre x19 and x20 to restore at the end
    stp     x21, x22, [sp, 32]      // sotre x21 and x22 to restore at the end
    stp     x23, x24, [sp, 48]      // sotre x23 and x24 to restore at the end

    sub     x20, x1, x0             // # of elements times 8
    lsr     x20, x20, 3             // divided by 8
    sub     x20, x20, 1             // x20 is the end of iterations
    mov     x19, x0                 // x19 points to begin of array
    ._bubble_sort.outer_loop:
        cbz     x20, ._bubble_sort.outer_loop_end
        mov     x21, xzr                // first element for the pair comparison
        ._bubble_sort.inner_loop:
            cmp     x21, x20
            b.eq    ._bubble_sort.inner_loop_end
            add     x22, x21, 1
            ldr     x0, [x19, x21, lsl 3]
            ldr     x1, [x19, x22, lsl 3]
            bl      _sort_two
            str     x0, [x19, x21, lsl 3]
            str     x1, [x19, x22, lsl 3]
            add     x21, x21, 1
            b       ._bubble_sort.inner_loop
        ._bubble_sort.inner_loop_end:
        sub     x20, x20, 1
        b ._bubble_sort.outer_loop
    ._bubble_sort.outer_loop_end:

    ldp     x23, x24, [sp, 48]
    ldp     x21, x22, [sp, 32]
    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 64      // restore x29, x30 (LR)

    ret

_sort_two:
    cmp     x0, x1
    b.le    ._sort_two.exit
    mov     x2, x0
    mov     x0, x1
    mov     x1, x2
    ._sort_two.exit:
    ret
