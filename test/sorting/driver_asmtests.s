.text

.global main

main:
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    mov     x19, xzr       // error counter

    bl      test._right_pivot.ok
    add     x19, x19, x0
    bl      test._left_pivot.ok
    add     x19, x19, x0
    bl      test._middle_pivot.ok
    add     x19, x19, x0
    bl      test._getsemirandom_64.ok
    add     x19, x19, x0

    mov     x0, 1          // STDOUT
    ldr     x1, =line_break
    mov     x2, 1
    mov     x8, 64
    svc     0

    mov     x0, x19        // return is # of errors
    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
    ret

.data
    line_break:
        .ascii      "\n"

