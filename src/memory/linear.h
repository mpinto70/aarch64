#pragma once

#include <cstdint>

extern "C" {
extern uint64_t _linear_mavh;

// memory operations
int64_t linear_init(uint64_t memory_size);
void linear_deinit();

void* linear_allocate(uint64_t size);
void* linear_allocate_filled(uint64_t size, char c);
int64_t linear_deallocate(const void* ptr);

// MAVH functions
uint64_t _linear_get_mav_size(uint64_t mavh);
uint64_t _linear_get_memory_size(uint64_t mavh);
uint64_t _linear_get_number_of_free_segment_headers(uint64_t mavh);
uint64_t _linear_get_number_of_used_segment_headers(uint64_t mavh);
uint64_t _linear_set_mavh(uint64_t mem_sz, uint64_t mav_sz, uint64_t num_free, uint64_t num_used);

// memory segment header functions
uint64_t _linear_set_msh(uint64_t offset, uint64_t size);
uint64_t _linear_reduce_free_space(uint64_t msh, uint64_t size);
uint64_t _linear_block_offset(uint64_t msh);
uint64_t _linear_block_size(uint64_t msh);
uint64_t* _linear_find_free_msh(uint64_t mavh, const uint8_t* pmem, uint64_t alloc_sz);
uint64_t* _linear_find_used_msh(uint64_t mavh, const uint8_t* pmem, const uint8_t* ptr);
uint64_t _linear_find_index_new_free_msh(uint64_t mavh, const uint8_t* pmem, uint64_t offset);
uint64_t* _linear_find_position_new_used_msh(uint64_t mavh, const uint8_t* pmem, uint64_t offset);
uint64_t _linear_expand_mav_if_necessary(uint64_t mavh, const uint8_t* pmem);
uint64_t _linear_insert_free_msh(uint64_t mavh, uint8_t* pmem, uint64_t msh);
uint64_t _linear_insert_used_msh(uint64_t mavh, uint8_t* pmem, uint64_t msh);
uint64_t _linear_remove_free_msh(uint64_t mavh, uint8_t* pmem, uint64_t* pmsh);
uint64_t _linear_remove_used_msh(uint64_t mavh, uint8_t* pmem, uint64_t* pmsh);
}
