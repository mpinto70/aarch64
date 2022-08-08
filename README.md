# Adventures in ARM assembly 64 bit

Just some musings in ARM assembly. I run and test this project in a Raspberry Pi
400 and a Raspberry Pi 3 B+ running Raspberry Pi OS (64-bit).

## Building and testing

To build:

```shell
./runbuild
```

To test (and also build):

```shell
./runbuild test
```

## Dependencies

This project depends on:

* cmake (3.18.4)
* [benchmark](https://github.com/google/benchmark)
* clang-format-11
