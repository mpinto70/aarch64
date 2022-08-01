#include "local_unistd.h"

.global _quick_sort
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

/// sort an array of ints (inplace) with bubble sort algorithm
/// @param x0   begin of array
/// @param x1   end of array (one after last - open interval)
/// @return NONE
_quick_sort:
    add     x2, x0, 8              // one element or empty
    cmp     x2, x1
    b.ge    ._quick_sort.return     // at most 1 element

    stp     x29, x30, [sp, -64]!    // store x29, x30 (LR) on stack and reserve 32 bytes
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]

    mov     x19, x0             // x19 - begin of array (const)
    mov     x20, x1             // x20 - enf of array (const)

    mov     x0, x19
    mov     x1, x20
    bl      _hoare_partition
    mov     x21, x0             // save pivot position

    mov     x0, x19
    add     x1, x21, 8
    bl      _quick_sort
    ._quick_sort.skip_left_sort:

    add     x21, x21, 8
    mov     x0, x21
    mov     x1, x20
    bl      _quick_sort
    ._quick_sort.skip_right_sort:

    ldp     x23, x24, [sp, 48]
    ldp     x21, x22, [sp, 32]
    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 64      // restore x29, x30 (LR)

    ._quick_sort.return:
    ret

/// sort an array of ints (inplace) with bubble sort algorithm
/// @param x0   begin of array
/// @param x1   end of array (one after last - open interval)
/// @return NONE
_hoare_partition:
    stp     x29, x30, [sp, -64]!    // store x29, x30 (LR) on stack and reserve 32 bytes
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    sub     x19, x0, 8          // x19 - left iterator
    mov     x20, x1             // x20 - right iterator

    bl      _getrandom_between  // get a random position in [x0, x1[
    lsr     x0, x0, 3           // make sure x0 is aligned
    lsl     x0, x0, 3           // to 8 bytes
    ldr     x21, [x0]           // pivot value (const)

    ._hoare_partition.loop_forever:
        ._hoare_partition.left_loop:
            add     x19, x19, 8
            ldr     x8, [x19]
            cmp     x8, x21
            b.lt    ._hoare_partition.left_loop
        ._hoare_partition.right_loop:
            sub     x20, x20, 8
            ldr     x8, [x20]
            cmp     x8, x21
            b.gt    ._hoare_partition.right_loop

        cmp     x19, x20
        b.ge    _hoare_partition.return

        // swap numbers
        mov     x0, x19
        mov     x1, x20
        bl      _swap_numbers

        b       ._hoare_partition.loop_forever

    _hoare_partition.return:
    mov     x0, x20     // pivot position

    ldp     x21, x22, [sp, 32]
    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 64      // restore x29, x30 (LR)
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

