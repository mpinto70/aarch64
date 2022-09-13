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
