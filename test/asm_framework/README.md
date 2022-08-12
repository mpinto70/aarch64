# ASM unit test framework

Here is my atempt to create a unit test framework.

In order to test a function (function under test, FUT), registers should be populated as:

* `x0` to `x7`: parameters to FUT;
* `x8`: address of FUT (will be called with `blr`)
* `x9`: a bit mask indicating which registers to check returned values in `x0` to `x7` (if a
  function is supposed to interact with C, it only return one result in `x0` or none at all);
* `x10` to `x17`: expected returned values from FUT;
* `x19`: base address of unit test (to report errors);
* `x20`: address of a null terminated string with unit test name (to resport errors).

Note that, since `x19` and `x20` are used, unit test function should push them to the stack and
restore them before returning.

There is a helper function `dirty_x0_x18` that should be used before calling check functions to
avoid spurious values.

Check functions return the number of errors detected in `x0` (so `0` means success).

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
