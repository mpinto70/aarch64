################################################################################
# Google Test Setup - BEGIN ####################################################
################################################################################

FetchContent_Declare(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG        v1.13.0
)

FetchContent_GetProperties(googletest)
if(NOT googletest_POPULATED)
    FetchContent_Populate(googletest)
    add_subdirectory(${googletest_SOURCE_DIR} ${googletest_BINARY_DIR})
endif()

################################################################################
# Google Test Setup - END ######################################################
################################################################################

function(add_unit_test test_name sources_var libs_var)
    set(unit_test_name unit_${test_name})

    add_executable(
        ${unit_test_name}
        ${${sources_var}}
    )

    set_target_properties(
        ${unit_test_name}
        PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/test/bin
    )

    target_link_libraries(
        ${unit_test_name}
        PRIVATE ${${libs_var}}
        PRIVATE gtest gmock_main
    )

    add_test(NAME ${unit_test_name} COMMAND ${unit_test_name})
endfunction(add_unit_test)

find_package(benchmark REQUIRED)

function(add_benchmark_test test_name sources_var libs_var)
    set(benchmark_test_name benchmark_${test_name})

    add_executable(
        ${benchmark_test_name}
        ${${sources_var}}
    )

    set_target_properties(
        ${benchmark_test_name}
        PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/test/bin
    )

    target_link_libraries(
        ${benchmark_test_name}
        PRIVATE ${${libs_var}}
        PRIVATE benchmark::benchmark_main
    )
endfunction(add_benchmark_test)

function(add_asm_test test_name sources_var libs_var)
    set(asm_test_name aut_${test_name})
    set(parser "${AUTF_PATH}/parser.py")
    set(driver_name ${asm_test_name}.s)

    # https://crascit.com/2017/04/18/generated-sources-in-cmake-builds/
    set(sources_out "")
    set(sources_in_full "")
    foreach(source_in ${${sources_var}})
        string(REPLACE ".in" "" source_out "${source_in}")
        add_custom_command(
            OUTPUT ${source_out}
            COMMAND rm -f ${CMAKE_CURRENT_BINARY_DIR}/${source_out} && python ${parser} test
                -i ${CMAKE_CURRENT_SOURCE_DIR}/${source_in}
                -o ${CMAKE_CURRENT_BINARY_DIR}/${source_out}
            DEPENDS ${source_in}
        )
        list(APPEND sources_out ${source_out})
        list(APPEND sources_in_full ${CMAKE_CURRENT_SOURCE_DIR}/${source_in})
    endforeach(source_in)

    add_custom_command(
        OUTPUT ${driver_name}
        COMMAND rm -f ${CMAKE_CURRENT_BINARY_DIR}/${driver_name} && python ${parser} driver
            -i ${sources_in_full}
            -o ${CMAKE_CURRENT_BINARY_DIR}/${driver_name}
        DEPENDS ${sources_out}
    )

    add_executable(
        ${asm_test_name}
        ${driver_name}
        ${sources_out}
    )

    set_target_properties(
        ${asm_test_name}
        PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/test/bin
    )

    target_link_libraries(
        ${asm_test_name}
        PRIVATE ${${libs_var}}
    )

    add_test(NAME ${asm_test_name} COMMAND ${asm_test_name})
endfunction(add_asm_test)

function(_add_lib lib_name sources_var directory)
    add_library(
        ${lib_name}
        ${${sources_var}}
    )

    target_include_directories(
        ${lib_name}
        PRIVATE ${gtest_SOURCE_DIR}/include
        PRIVATE ${gmock_SOURCE_DIR}/include
    )

    set_target_properties(
        ${lib_name}
        PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${directory}/lib
    )
endfunction(_add_lib)

function(add_test_lib test_lib_name sources_var)
    _add_lib(
        ${test_lib_name}
        ${sources_var}
        test
    )
endfunction(add_test_lib)

function(add_mock_lib mck_lib_name sources_var)
    _add_lib(
        ${mck_lib_name}
        ${sources_var}
        mck
    )
endfunction(add_mock_lib)
