set(sorting_srcs
    bubble_test.cpp
    quick_test.cpp
    utils_test.cpp
)

set(sorting_libs
    sorting
)

add_unit_test(
    sorting
    sorting_srcs
    sorting_libs
)

set(sorting_benchmark_srcs
    quick_benchmark.cpp
)

set(sorting_benchmark_libs
    sorting
)

add_benchmark_test(
    sorting
    sorting_benchmark_srcs
    sorting_benchmark_libs
)

set(sorting_asm_srcs
    bubble_asmtest.in.s
    quick_asmtest.in.s
    utils_asmtest.in.s
)

set(sorting_asm_libs
    sorting
    asm_framework
)

add_asm_test(
    sorting
    sorting_asm_srcs
    sorting_asm_libs
)
