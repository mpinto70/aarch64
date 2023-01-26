set(memory_srcs
    memory_test_utils.cpp
    utils_test.cpp
)

set(memory_libs
    memory
)

add_unit_test(
    memory
    memory_srcs
    memory_libs
)

set(memory_asm_srcs
    utils_asmtest.in.S
)

set(memory_asm_libs
    memory
    asm_framework
)

add_asm_test(
    memory
    memory_asm_srcs
    memory_asm_libs
)
