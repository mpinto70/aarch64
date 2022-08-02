#pragma once

#include <cstdint>

extern "C" {
uint64_t _getrandom(uint8_t *buffer, uint64_t size);
uint64_t _getrandom_between(uint64_t min, uint64_t max);
void _swap_numbers(uint64_t *x, uint64_t *y);
}
