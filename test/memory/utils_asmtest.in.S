.text

.macro prepare_func
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    bl      dirty_x0_x18            // put random values in registers
.endm

.macro prepare_func_inited
    stp     x29, x30, [sp, -32]!
    stp     x19, x20, [sp, 16]

    bl      mem_init
    bl      dirty_x0_x18            // put random values in registers
.endm

.macro finish_func
    bl      mem_deinit

    ldp     x19, x20, [sp, 16]
    ldp     x29, x30, [sp], 32
.endm

test.mem.initial_state:
    prepare_func

    adr     x9, _mem_pbase
    ldr     x0, [x9]
    mov     x1, 0
    adr     x2, UNIT_TEST_ADDRESS
    adr     x3, UNIT_TEST_NAME
    bl      expect_eq_val

    adr     x9, _mem_size
    ldr     x0, [x9]
    mov     x1, 0
    adr     x2, UNIT_TEST_ADDRESS
    adr     x3, UNIT_TEST_NAME
    bl      expect_eq_val

    finish_func
    ret

test.mem_init.successful_call:
    prepare_func

    adr     x8, FUNCTION_UNDER_TEST
    adr     x19, UNIT_TEST_ADDRESS
    adr     x20, UNIT_TEST_NAME

    mov     x9, 0x1                 // active retult register ==> x0
    mov     x10, 0                  // expected value for x0 = 0
    bl      check_call

    adr     x9, _mem_pbase
    ldr     x0, [x9]
    mov     x1, 0                   // now _mem_pbase points to brk
    adr     x2, UNIT_TEST_ADDRESS
    adr     x3, UNIT_TEST_NAME
    bl      expect_ne_val

    adr     x9, _mem_size
    ldr     x0, [x9]
    mov     x1, 0                   // no memory was really allocated
    adr     x2, UNIT_TEST_ADDRESS
    adr     x3, UNIT_TEST_NAME
    bl      expect_eq_val

    finish_func
    ret

test.mem_init.error_already_inited:
    prepare_func

    adr     x8, FUNCTION_UNDER_TEST
    adr     x19, UNIT_TEST_ADDRESS
    adr     x20, UNIT_TEST_NAME

    mov     x9, 0x1                 // active retult register ==> x0
    mov     x10, 0                  // expected value for x0 = 0
    bl      check_call

    adr     x8, FUNCTION_UNDER_TEST
    adr     x19, UNIT_TEST_ADDRESS
    adr     x20, UNIT_TEST_NAME

    mov     x9, 0x1                 // active retult register ==> x0
    mov     x10, 1                  // expected value for x0 = 1 <-- error
    bl      check_call

    finish_func
    ret

test.mem_deinit.successful_call:
    prepare_func_inited

    adr     x8, FUNCTION_UNDER_TEST
    adr     x19, UNIT_TEST_ADDRESS
    adr     x20, UNIT_TEST_NAME

    mov     x9, 0x1                 // active result registers ==> x0
    mov     x10, 0                  // expected value for x0 = 0
    bl      check_call

    adr     x9, _mem_pbase
    ldr     x0, [x9]
    mov     x1, 0                   // now _mem_pbase points to brk
    adr     x2, UNIT_TEST_ADDRESS
    adr     x3, UNIT_TEST_NAME
    bl      expect_eq_val

    adr     x9, _mem_size
    ldr     x0, [x9]
    mov     x1, 0                   // no memory was really allocated
    adr     x2, UNIT_TEST_ADDRESS
    adr     x3, UNIT_TEST_NAME
    bl      expect_eq_val

    finish_func
    ret

test.mem_deinit.calls_are_idempotent:
    prepare_func_inited

    adr     x8, FUNCTION_UNDER_TEST
    adr     x19, UNIT_TEST_ADDRESS
    adr     x20, UNIT_TEST_NAME

    mov     x9, 0x1                 // active result registers ==> x0
    mov     x10, 0                  // expected value for x0 = 0
    bl      check_call

    adr     x8, FUNCTION_UNDER_TEST
    adr     x19, UNIT_TEST_ADDRESS
    adr     x20, UNIT_TEST_NAME

    mov     x9, 0x1                 // active result registers ==> x0
    mov     x10, 0                  // expected value for x0 = 0 <-- idempotent
    bl      check_call

    finish_func
    ret

test.mem_reserve.reserve_new_space:
    prepare_func_inited

    adr     x8, FUNCTION_UNDER_TEST
    adr     x19, UNIT_TEST_ADDRESS
    adr     x20, UNIT_TEST_NAME
    mov     x9, 0x1                 // active result registers ==> x0
    mov     x10, 0                  // expected value for x0 = 0
    mov     x0, 0x1000              // allocate 4096 bytes
    bl      check_call

    adr     x9, _mem_size
    ldr     x0, [x9]
    mov     x1, 0x1000              // size asked was allocated
    adr     x2, UNIT_TEST_ADDRESS
    adr     x3, UNIT_TEST_NAME
    bl      expect_eq_val

    finish_func
    ret

test.mem_reserve.reserve_less_space_will_not_change_size:
    prepare_func_inited

    mov     x0, 0x1000              // allocate 4096 bytes
    bl      mem_reserve

    bl      dirty_x0_x18            // put random values in registers

    adr     x8, FUNCTION_UNDER_TEST
    adr     x19, UNIT_TEST_ADDRESS
    adr     x20, UNIT_TEST_NAME
    mov     x9, 0x1                 // active result registers ==> x0
    mov     x10, 0                  // expected value for x0 = 0
    mov     x0, 0x100               // asks for 256 bytes
    bl      check_call

    adr     x9, _mem_size
    ldr     x0, [x9]
    mov     x1, 0x1000              // no memory was really allocated
    adr     x2, UNIT_TEST_ADDRESS
    adr     x3, UNIT_TEST_NAME
    bl      expect_eq_val

    finish_func
    ret
