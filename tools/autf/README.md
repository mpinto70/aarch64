# ASM unit test framework (AUTF)

Here is my attempt to create a unit test framework.

In order to test a function (function under test, FUT), registers should be populated as:

* `x0` to `x7`: parameters to FUT;
* `x8`: address of FUT (will be called with `blr`)
* `x9`: a bit mask indicating which registers to check returned values in `x0` to `x7` (if a
  function is supposed to interact with C, it only return one result in `x0` or none at all);
* `x10` to `x17`: expected returned values from FUT;
* `x19`: base address of unit test (to report errors);
* `x20`: address of a null terminated string with unit test name (to report errors).

Note that, since `x19` and `x20` are used, unit test function should push them to the stack and
restore them before returning.

There is a helper function `dirty_x0_x18` that should be used before calling check functions to
avoid spurious values.

Check functions return the number of errors detected in `x0` (so `0` means success).

## Parser

In order to simplify test scaffolding, I created a [script](parser.py) that preprocesses test files,
and create the test driver. There are two ways of calling the parser.

1. To parse each test file

```bash
python <path/to/parser>/parser.py test \
    -i <path/to/test>/test_source.1.in.s \
    -o <path/to/out/test>/test_source.1.s
python <path/to/parser>/parser.py test \
    -i <path/to/test>/test_source.2.in.s \
    -o <path/to/out/test>/test_source.2.s
...
```

2. To create the test driver

```bash
python <path/to/parser>/parser.py driver \
    -i <path/to/test>/test_source.1.in.s \
    <path/to/test>/test_source.2.in.s \
    <path/to/test>/test_source.3.in.s \
    -o <path/to/out/test>/autf_driver.s
```

### Test instrumentation

The parser looks for specific text markers and the test name should have a predefined form. An
example is worth 1 million words:

```asm
.text   // the test should be in the .text section

test._right_pivot.ok:   // the name of the test has to have the form:
                        // test.<name of the FUT>.<complement>
                        // In this example, the function being tested is `_right_pivot`
                        // And the complement of the test is `ok`
    stp     x29, x30, [sp, -32]!        // it is always necessary to save the x29, x30 (stack frame)
    stp     x19, x20, [sp, 16]          // and x19 and x20 that are used to save unit test address and test name

    bl      dirty_x0_x18                // put random values in registers (recommended to do)
    mov     x0, 0xff00                  // x0 to x7 are the parameters to FUT, in this example:
    mov     x1, 0xff80                  // x0 has begin of array and x1 has end of array
    ldr     x8, =FUNCTION_UNDER_TEST    // [verbatim] parsed to FUT
    ldr     x19, =UNIT_TEST_ADDRESS     // [verbatim] parsed to address of this unit test, for error messages
    ldr     x20, =UNIT_TEST_NAME        // [verbatim] parsed to name of this unit test, for error messages
    mov     x9, 0x1                     // bit mask specifying which registers will have return values (in this example only x0)
    sub     x10, x1, 16                 // x10 to x17 the expected return values (in this example 16 in x0)
    bl      check_call                  // [verbatim] call the function to run the tests

    ldp     x19, x20, [sp, 16]          // restore the stack frame
    ldp     x29, x30, [sp], 32
    ret                                 // and return
```

## Implementation

All registers are saved in the stack upon entry in check functions (size is 416):

| offset | value | item                                                  |
| -----: | :---: | :---------------------------------------------------- |
|      0 | `x29` | stack frame                                           |
|      8 | `x30` |                                                       |
|     16 | `x19` | saved to restore before returning from check function |
|     24 | `x20` |                                                       |
|     32 | `x21` |                                                       |
|     40 | `x22` |                                                       |
|     48 | `x23` |                                                       |
|     56 | `x24` |                                                       |
|     64 | `x25` |                                                       |
|     72 | `x26` |                                                       |
|     80 | `x27` |                                                       |
|     88 | `x28` |                                                       |
|     96 | `x8`  | address of FUT                                        |
|    104 | `x9`  | bit mask of expected return values from FUT           |
|    112 | `x10` | expected return value of `x0`                         |
|    120 | `x11` | expected return value of `x1`                         |
|    128 | `x12` | expected return value of `x2`                         |
|    136 | `x13` | expected return value of `x3`                         |
|    144 | `x14` | expected return value of `x4`                         |
|    152 | `x15` | expected return value of `x5`                         |
|    160 | `x16` | expected return value of `x6`                         |
|    168 | `x17` | expected return value of `x7`                         |
|    176 | `x18` | not used                                              |
|    184 |       | error count (only value that changes in the stack)    |
|    192 | `x0`  | saved return from FUT                                 |
|    200 | `x1`  |                                                       |
|    208 | `x2`  |                                                       |
|    216 | `x3`  |                                                       |
|    224 | `x4`  |                                                       |
|    232 | `x5`  |                                                       |
|    240 | `x6`  |                                                       |
|    248 | `x7`  |                                                       |
|    256 | `x19` | random values filled before calling FUT               |
|    264 | `x20` |                                                       |
|    272 | `x21` |                                                       |
|    280 | `x22` |                                                       |
|    288 | `x23` |                                                       |
|    296 | `x24` |                                                       |
|    304 | `x25` |                                                       |
|    312 | `x26` |                                                       |
|    320 | `x27` |                                                       |
|    328 | `x28` |                                                       |
|    336 | `x19` | saved values after FUT is called                      |
|    344 | `x20` |                                                       |
|    352 | `x21` |                                                       |
|    360 | `x22` |                                                       |
|    368 | `x23` |                                                       |
|    376 | `x24` |                                                       |
|    384 | `x25` |                                                       |
|    392 | `x26` |                                                       |
|    400 | `x27` |                                                       |
|    408 | `x28` |                                                       |
