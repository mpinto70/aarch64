#pragma once

#include <cstdint>

extern "C" {
uint64_t _getrandom(uint8_t* buffer, uint64_t size);
uint64_t _getrandom_64();
uint64_t _getsemirandom_64();
uint64_t _getrandom_between(uint64_t min, uint64_t max);
uint64_t _getsemirandom_between(uint64_t min, uint64_t max);
uint64_t _get_seeded_between(uint64_t min, uint64_t max, uint64_t seed);
void _swap_numbers(uint64_t* x, uint64_t* y);

typedef uint64_t (*random_between)(uint64_t min, uint64_t max);
}
