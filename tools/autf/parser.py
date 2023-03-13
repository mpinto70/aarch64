"""Parse a asm unit test file to produce a coorect assembly program"""

import argparse
import os
import sys
import re

from typing import Tuple


def add_test_calls(tests):
    res = []
    for test in tests:
        res.append(f"    bl      {test}")
        res.append("    add     x19, x19, x0")
    return res


def test_names(tests):
    res = ["", ".data"]
    for test in tests:
        res.append(f"    {test}.NAME:")
        res.append(f'        .asciz      "{test}"')
    return res


def parse_file(file_path: str) -> Tuple[str, list]:
    pass
    with open(file_path) as file:
        lines = file.read().splitlines()

    FUT_MARKER = "FUNCTION_UNDER_TEST"
    TEST_ADDRESS_MARKER = "UNIT_TEST_ADDRESS"
    TEST_NAME_MARKER = "UNIT_TEST_NAME"
    test_regex = r"^test\.([a-zA-Z0-9_]*)([a-zA-Z0-9_.]*):$"
    fut_regex = r".*\b" + FUT_MARKER + r"\b.*"
    test_address_regex = r".*\b" + TEST_ADDRESS_MARKER + r"\b.*"
    test_name_regex = r".*\b" + TEST_NAME_MARKER + r"\b.*"
    current_test = None
    current_fut = None
    tests = []
    output = []
    line_num = 0
    for line in lines:
        line_num += 1
        matched_test = re.search(test_regex, line)
        if matched_test:
            current_test = matched_test.group(0)[:-1]
            current_fut = matched_test.group(1)
            tests.append(current_test)
        if re.search(fut_regex, line):
            if not current_fut:
                raise ValueError(f"{FUT_MARKER} found without a function @ ({line_num})")
            line = line.replace(FUT_MARKER, current_fut)
        if re.search(test_address_regex, line):
            if not current_fut:
                raise ValueError(f"{TEST_ADDRESS_MARKER} found without a function @ ({line_num})")
            line = line.replace(TEST_ADDRESS_MARKER, current_test)
        if re.search(test_name_regex, line):
            if not current_fut:
                raise ValueError(f"{TEST_NAME_MARKER} found without a function @ ({line_num})")
            line = line.replace(TEST_NAME_MARKER, f"{current_test}.NAME")
        output.append(line)

    return output, tests


def parse_test(input_file: str, output_file: str):
    file_content, file_tests = parse_file(input_file)

    with open(output_file, "w") as file:
        print(".text\n", file=file)
        for line in file_tests:
            print(f".global {line}", file=file)
        print("", file=file)

        for line in file_content:
            print(line, file=file)

        for line in test_names(file_tests):
            print(line, file=file)


def create_driver(input_files: list, output_file: str):
    # only filename no extension
    file_name = os.path.splitext(os.path.basename(output_file))[0]
    all_tests = []
    for input_file in input_files:
        _, file_tests = parse_file(input_file)
        all_tests.extend(file_tests)

    driver = [
        ".text",
        "",
        ".global main",
        "",
        "main:",
        "    stp     x29, x30, [sp, -32]!",
        "    stp     x19, x20, [sp, 16]",
        "",
        "    mov     x0, 1          // STDOUT",
        "    ldr     x1, =driver_name",
        "    ldr     x2, =driver_name_len",
        "    mov     x8, 64",
        "    svc     0",
        "",
        "    mov     x19, xzr       // error counter",
        "",
    ] + add_test_calls(all_tests) + [
        "",
        "    mov     x0, 1          // STDOUT",
        "    ldr     x1, =line_break",
        "    mov     x2, 1",
        "    mov     x8, 64",
        "    svc     0",
        "",
        "    mov     x0, x19        // return is # of errors",
        "    ldp     x19, x20, [sp, 16]",
        "    ldp     x29, x30, [sp], 32",
        "    ret",
        "",
        ".data",
        "    line_break:",
        '        .ascii      "\\n"',
        "    driver_name:",
        f'        .ascii      "{file_name} - "',
        "    driver_name_len = . - driver_name",
    ]

    with open(output_file, "w") as file:
        for line in driver:
            print(line, file=file)


def main():
    parser = argparse.ArgumentParser(
        description="Parse asm unit test files to produce a assembly test program",
        formatter_class=argparse.RawTextHelpFormatter)
    subparsers = parser.add_subparsers(dest="command", help="sub-commands")

    subparser = subparsers.add_parser("test", help="parse a test file")
    subparser.add_argument("-i", "--input", type=str, required=True, help="input test file")
    subparser.add_argument("-o", "--output", type=str, required=True, help="output test file")

    subparser = subparsers.add_parser("driver", help="create a driver test file for sources")
    subparser.add_argument("-i", "--inputs", nargs="+", required=True, help="input test files")
    subparser.add_argument("-o", "--output", type=str, required=True, help="output driver file")

    parser.add_argument("--debug", action="store_true", help="set log level to DEBUG")

    args = parser.parse_args()

    if args.command == "driver":
        input_files = args.inputs
        for input_file in input_files:
            if not os.path.exists(input_file):
                print(f"ERROR: {input_file} does not exist")
                sys.exit(-1)

        output_file = args.output
        if os.path.exists(output_file):
            print(f"ERROR: {output_file} already exist")
            sys.exit(-1)

        create_driver(input_files, output_file)
    else:
        input_file = args.input
        if not os.path.exists(input_file):
            print(f"ERROR: {input_file} does not exist")
            sys.exit(-1)

        output_file = args.output
        if os.path.exists(output_file):
            print(f"ERROR: {output_file} already exist")
            sys.exit(-1)

        parse_test(input_file, output_file)


if __name__ == "__main__":
    main()
    sys.exit(0)
