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
