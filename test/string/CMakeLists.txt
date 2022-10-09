set(string_srcs
    convert_test.cpp
    operation_test.cpp
)

set(string_libs
    string
)

add_unit_test(
    string
    string_srcs
    string_libs
)

set(string_benchmark_srcs
    convert_benchmark.cpp
)

set(string_benchmark_libs
    string
    sorting
)

add_benchmark_test(
    string
    string_benchmark_srcs
    string_benchmark_libs
)

set(string_asm_srcs
    convert_asmtest.in.s
)

set(string_asm_libs
    string
    sorting
    asm_framework
)

add_asm_test(
    string
    string_asm_srcs
    string_asm_libs
)
