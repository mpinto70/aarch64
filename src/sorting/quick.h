#pragma once

#include <cstdint>

extern "C" {
typedef uint64_t* (*pivot_f)(uint64_t* begin, uint64_t* end);
void _quick_sort(uint64_t* begin, uint64_t* end, pivot_f pivot);

uint64_t* _left_pivot(uint64_t* begin, uint64_t* end);
uint64_t* _right_pivot(uint64_t* begin, uint64_t* end);
uint64_t* _middle_pivot(uint64_t* begin, uint64_t* end);
uint64_t* _random_pivot(uint64_t* begin, uint64_t* end);
uint64_t* _semi_random_pivot(uint64_t* begin, uint64_t* end);
}
