add_executable(quick_sort
    quick_sort.s
)

target_link_libraries(quick_sort
    PRIVATE
    io
    sorting
    string
)
