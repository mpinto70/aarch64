.global _quick_sort
.global _left_pivot
.global _right_pivot
.global _middle_pivot
.global _random_pivot
.global _semi_random_pivot

.text
/// sort an array of ints (inplace) with bubble sort algorithm
/// @param x0   begin of array
/// @param x1   end of array (one after last - open interval)
/// @param x2   pivot function
/// @return NONE
_quick_sort:
    add     x10, x0, 8              // one element or empty
    cmp     x10, x1
    b.ge    ._quick_sort.return     // at most 1 element

    stp     x29, x30, [sp, -64]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]

    mov     x19, x0             // x19 - begin of array (const)
    mov     x20, x1             // x20 - enf of array (const)
    mov     x23, x2             // x23 - pivot function

    mov     x0, x19
    mov     x1, x20
    mov     x2, x23
    bl      _hoare_partition
    mov     x21, x0             // save pivot position

    mov     x0, x19
    add     x1, x21, 8
    mov     x2, x23
    bl      _quick_sort
    ._quick_sort.skip_left_sort:

    add     x21, x21, 8
    mov     x0, x21
    mov     x1, x20
    mov     x2, x23
    bl      _quick_sort
    ._quick_sort.skip_right_sort:

    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x29, x30, [sp], 64

    ._quick_sort.return:
    ret

/// sort an array of ints (inplace) with bubble sort algorithm
/// @param x0   begin of array
/// @param x1   end of array (one after last - open interval)
/// @param x2   pivot function
/// @return NONE
_hoare_partition:
    stp     x29, x30, [sp, -64]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    sub     x19, x0, 8          // x19 - left iterator
    mov     x20, x1             // x20 - right iterator

    blr     x2                  // get the pivot in [x0, x1[
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

    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x29, x30, [sp], 64
    ret

/// Return the first element as the pivot
/// @param x0   begin of array
/// @param x1   end of array (one after last - open interval)
/// @return x0  pointer to pivot
_left_pivot:
    ret

/// Return (almost) the last element as the pivot (1 before last to avoid stack overflow)
/// @param x0   begin of array
/// @param x1   end of array (one after last - open interval)
/// @return (x1 - 16) pointer to pivot
_right_pivot:
    sub     x0, x1, 16
    ret

/// Return the pivot position in the middle of the sequence
/// @param x0   begin of array
/// @param x1   end of array (one after last - open interval)
/// @return x0  pointer to pivot
_middle_pivot:
    sub     x10, x1, x0     // distance
    sub     x10, x10, 8     // to avoid giving the right when only 2 are left and cause stack overflow
    lsr     x10, x10, 4     // x10 = x10 / 2 / 8
    lsl     x10, x10, 3     // x0 = x10 * 8 to assure alignment
    add     x0, x0, x10

    ret

/// Return the random pivot position
/// @param x0   begin of array
/// @param x1   end of array (one after last - open interval)
/// @return x0  pointer to pivot in the interval [x0, x1[
_random_pivot:
    stp     x29, x30, [sp, -16]!

    bl      _getrandom_between  // get a random position in [x0, x1[
    lsr     x0, x0, 3           // make sure x0 is aligned
    lsl     x0, x0, 3           // to 8 bytes

    ldp     x29, x30, [sp], 16
    ret

/// Return a semi random pivot position (random value is cached and rotated)
/// @param x0   begin of array
/// @param x1   end of array (one after last - open interval)
/// @return x0  pointer to pivot in the interval [x0, x1[
_semi_random_pivot:
    stp     x29, x30, [sp, -16]!

    bl      _getsemirandom_between  // get a random position in [x0, x1[
    lsr     x0, x0, 3               // make sure x0 is aligned
    lsl     x0, x0, 3               // to 8 bytes

    ldp     x29, x30, [sp], 16
    ret
