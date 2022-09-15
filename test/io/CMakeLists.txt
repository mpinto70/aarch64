set(io_srcs
    print_test.cpp
)

set(io_libs
    io
    string
)

add_unit_test(
    io
    io_srcs
    io_libs
)
