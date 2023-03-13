#pragma once

#include <cstdint>

extern "C" {
extern uint8_t* _mem_pbase;
extern uint64_t _mem_size;

uint64_t mem_next_mult_power_of_2(uint64_t value, uint64_t power);
uint64_t mem_power_of_2_ceiling(uint64_t value);
uint64_t mem_power_of_2_floor(uint64_t value);
uint64_t mem_size_index(uint64_t value);
void mem_fill(void* begin, void* end, char c);
void mem_fill_n(void* begin, uint64_t n, char c);
void mem_copy(const void* src_begin, const void* src_end, void* dst_end);
void mem_copy_n(const void* src_begin, uint64_t n, void* dst_end);
void mem_copy_backward(const void* src_begin, const void* src_end, void* dst_end);
void mem_copy_n_backward(const void* src_begin, uint64_t n, void* dst_end);
}
