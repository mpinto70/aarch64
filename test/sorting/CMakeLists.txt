set(sorting_srcs
    quick_test.cpp
    bubble_test.cpp
)

set(sorting_libs
    sorting
)

add_unit_test(
    sorting
    sorting_srcs
    sorting_libs
)
