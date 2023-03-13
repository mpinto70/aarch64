#include <errno.h>

// memory operations
.global linear_init
.global linear_deinit
.global linear_allocate
.global linear_allocate_filled
.global linear_deallocate
// global variables fpr testing
.global _linear_mavh

// MAVH functions
.global _linear_get_mav_size
.global _linear_get_memory_size
.global _linear_get_number_of_free_segment_headers
.global _linear_get_number_of_used_segment_headers
.global _linear_set_mavh
// memory segments header functions
.global _linear_set_msh
.global _linear_reduce_free_space
.global _linear_block_offset
.global _linear_block_size
.global _linear_find_free_msh
.global _linear_find_used_msh
.global _linear_find_index_new_free_msh
.global _linear_find_position_new_used_msh
.global _linear_expand_mav_if_necessary
.global _linear_insert_free_msh
.global _linear_insert_used_msh
.global _linear_remove_free_msh
.global _linear_remove_used_msh

////////////////////////////////////////////////////////////////////////////////////////////////////
// memory operations ///////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

// load pmem into \xM
.macro load_pmem xM
    adr     \xM, _mem_pbase
    ldr     \xM, [\xM]
.endm

// load pmem into \xM
.macro load_mavh xM
    adr     \xM, _linear_mavh
    ldr     \xM, [\xM]
.endm

// store \xM into _linear_mavh (dirties x9)
.macro store_mavh xM
    adr     x9, _linear_mavh
    str     \xM, [x9]
.endm

.text
/// initializes memory pool for allocation/deallocation
/// @param x0   the size of memory (real size will be power of 2)
/// @return x0  0 if successful
/// @return x0  error code if unsuccessful
linear_init:
#define STACK_SPACE     80
#define SIZE            x19
#define MEM_SZ          x20
#define MAV_SZ          x21
#define FULL_SZ         x22
#define PMEM            x23
#define MAVH            x24
#define PMAV_F          x25
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]
    stp     x25, x26, [sp, 64]

    mov     SIZE, x0

    bl      mem_init

    // check if already initialized
    load_mavh   x9
    cbz     x9, .linear_init.not.initialized
    mov     x0, -EBUSY
    b       .linear_init.return

    .linear_init.not.initialized:
    // calculate memory size
    mov     x0, SIZE
    bl      mem_power_of_2_ceiling
    mov     MEM_SZ, x0
    mov     MAV_SZ, 4096
    add     FULL_SZ, MAV_SZ, MEM_SZ

    mov     x0, FULL_SZ
    bl      mem_reserve
    cbz     x0, .linear_init.allocated
    mov     x0, -ENOMEM
    b       .linear_init.return

    .linear_init.allocated:
    // calculate memory positions
    load_pmem   PMEM
    add     PMAV_F, PMEM, MEM_SZ

    // build MAVH
    mov     x0, MEM_SZ
    mov     x1, MAV_SZ
    mov     x2, 1
    mov     x3, 0
    bl      _linear_set_mavh
    mov     MAVH, x0

    // store MAVH
    store_mavh  MAVH

    // fill memory with '-'
    mov     x0, PMEM
    mov     x1, FULL_SZ
    mov     x2, '-'
    bl      mem_fill_n

    // build the first segment header and store it in memory (x26 --> pmav_f)
    mov     x0, xzr
    mov     x1, MEM_SZ
    bl      _linear_set_msh
    str     x0, [PMAV_F]

    mov     x0, xzr             // success

    .linear_init.return:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x25, x26, [sp, 64]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef SIZE
#undef MEM_SZ
#undef MAV_SZ
#undef FULL_SZ
#undef PMEM
#undef MAVH
#undef PMAV_F

.text
/// return memory pool back to OS
linear_deinit:
    store_mavh  xzr
    ret

.text
/// allocate memory from the pool and return the pointer to its start
/// @param x0   the size of memory to allocate (it will be rounded up to 8 bytes)
/// @return x0  pointer to the begin of memory allocated
/// @return x0  0 - if there are no free memory to allocate the requested size
linear_allocate:
#define STACK_SPACE     80
#define ALLOC_SZ        x19
#define mavh            x20
#define PMEM            x21
#define PMSH_F          x22
#define msh_f           x23
#define MSH_U           x24
#define PALLOCATED      x25
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]
    stp     x25, x26, [sp, 64]

    cbz     x0, .linear_allocate.return // NO-OP

    // get allocation size aligned to 8 bytes
    mov     x1, 3
    bl      mem_next_mult_power_of_2
    mov     ALLOC_SZ, x0

    // load pointer to begin of memory pool and mavh (preprocessing for space)
    load_pmem   PMEM
    load_mavh   x0
    mov     x1, PMEM
    bl      _linear_expand_mav_if_necessary
    cbz     x0, .linear_allocate.not.enough.memory
    mov     mavh, x0

    // find first segment with enough free memory
    mov     x0, mavh
    mov     x1, PMEM
    mov     x2, ALLOC_SZ
    bl      _linear_find_free_msh
    cbz     x0, .linear_allocate.not.enough.memory
    mov     PMSH_F, x0
    ldr     msh_f, [PMSH_F]
    // adjust info from msh_f (size -= ALLOC_SZ)
    mov     x0, msh_f
    mov     x1, ALLOC_SZ
    bl      _linear_reduce_free_space
    mov     msh_f, x0
    // get pointer to allocated memory and build mhs_u
    bl      _linear_dissect_msh     // dissect msh_f
    add     x0, x0, x1              // offset of allocated memory
    add     PALLOCATED, PMEM, x0    //
    // build used memory segment header (x0 has the offset already)
    mov     x1, ALLOC_SZ
    bl      _linear_set_msh
    mov     MSH_U, x0
    // put msh_u in MAV
    mov     x0, mavh
    mov     x1, PMEM
    mov     x2, MSH_U
    bl      _linear_insert_used_msh
    cbz     x0, .linear_allocate.not.enough.memory

    // store new state of free segment header or remove it if empty
    mov     x0, msh_f
    bl      _linear_dissect_msh
    cbnz    x1, .linear_allocate.if.empty.non.empty
    mov     x0, mavh
    mov     x1, PMEM
    mov     x2, PMSH_F
    bl      _linear_remove_free_msh
    mov     x0, mavh
    bl      _linear_dissect_mavh
    sub     x2, x2, 1
    bl      _linear_set_mavh
    mov     mavh, x0
    b       .linear_allocate.if.empty.endif
    .linear_allocate.if.empty.non.empty:
    str     msh_f, [PMSH_F]
    .linear_allocate.if.empty.endif:
    // store new state of MAVH
    mov     x0, mavh
    bl      _linear_dissect_mavh
    add     x3, x3, 1       // increase number of used segments
    bl      _linear_set_mavh
    store_mavh  x0          // store new state of mavh
    // prepare return address
    mov     x0, PALLOCATED
    b       .linear_allocate.return

    .linear_allocate.not.enough.memory:
    mov     x0, 0
    b       .linear_allocate.return

    .linear_allocate.return:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x25, x26, [sp, 64]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef ALLOC_SZ
#undef mavh
#undef PMEM
#undef PMSH_F
#undef msh_f
#undef MSH_U
#undef PALLOCATED

.text
/// allocate memory from the pool and return the pointer to its start
/// @param x0   the size of memory to allocate (it will be rounded up to 8 bytes)
/// @param x1   the character to fill the memory
/// @return x0  pointer to the begin of memory allocated
/// @return x0  0 - if there are no free memory to allocate the requested size
linear_allocate_filled:
#define STACK_SPACE     48
#define ALLOC_SZ        x19
#define CHAR            x20
#define PTR             x21
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    cbz     x0, .linear_allocate_filled.return // NO-OP

    mov     CHAR, x1

    // get allocation size aligned to 8 bytes
    mov     x1, 3
    bl      mem_next_mult_power_of_2
    mov     ALLOC_SZ, x0

    mov     x0, ALLOC_SZ
    bl      linear_allocate

    cbz     x0, .linear_allocate_filled.return // failed to allocate

    mov     PTR, x0
    mov     x1, ALLOC_SZ
    mov     x2, CHAR
    bl      mem_fill_n

    mov     x0, PTR

    .linear_allocate_filled.return:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef ALLOC_SZ
#undef CHAR
#undef PTR

.text
/// deallocate memory pinted to by ptr
/// @param x0   the pointer to memory to be deallocated
/// @return x0  0 if succeded
linear_deallocate:
#define STACK_SPACE     64
#define PTR             x19
#define PMSH            x20
#define MSH             x21
#define mavh            x22
#define PMEM            x23
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]

    mov     PTR, x0

    load_mavh   mavh
    load_pmem   PMEM

    mov     x0, mavh
    mov     x1, PMEM
    mov     x2, PTR
    bl      _linear_find_used_msh
    mov     x9, -1
    cbz     x0, .linear_deallocate.error
    mov     PMSH, x0
    ldr     MSH, [PMSH, -8]

    mov     x0, mavh
    mov     x1, PMEM
    mov     x2, PMSH
    bl      _linear_remove_used_msh
    mov     x9, -2
    cbz     x0, .linear_deallocate.error
    mov     mavh, x0        // update mavh

    //      x0 is already mavh
    mov     x1, PMEM
    mov     x2, MSH
    bl      _linear_insert_free_msh
    mov     x9, -3
    cbz     x0, .linear_deallocate.error
    mov     mavh, x0        // update mavh

    store_mavh  mavh
    mov     x0, xzr
    b       .linear_deallocate.return

    .linear_deallocate.error:
    mov     x0, x9

    .linear_deallocate.return:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef PTR
#undef PMSH
#undef MSH
#undef mavh
#undef PMEM

.data
_linear_mavh    : .dword 0

////////////////////////////////////////////////////////////////////////////////////////////////////
// MAVH functions //////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

.text
/// return the size of the memory allocation vector from memory allocation vector header (MAVH)
/// @param x0   the MAVH
/// @return x0  the size of the MAT
_linear_get_mav_size:
    lsl     x9, x0, 6
    lsr     x9, x9, 58
    mov     x0, 1
    lsl     x0, x0, x9

    ret

.text
/// return the size of the allocatable memory from memory allocation vector header (MAVH)
/// @param x0   the MAVH
/// @return x0  the size of the memory
_linear_get_memory_size:
    lsr     x9, x0, 58
    mov     x0, 1
    lsl     x0, x0, x9

    ret

.text
/// return the number of free segments from memory allocation vector header (MAVH)
/// @param x0   the MAVH
/// @return x0  the number of free segment headers
_linear_get_number_of_free_segment_headers:
    lsl     x9, x0, 12
    lsr     x0, x9, 38

    ret

.text
/// return the number of used segments from memory allocation vector header (MAVH)
/// @param x0   the MAVH
/// @return x0  the number of used segment headers
_linear_get_number_of_used_segment_headers:
    and     x0, x0, 0x3ffffff

    ret

.text
/// return the MAVH
/// @param x0   mem_sz
/// @param x1   mav_sz
/// @param x2   # of free segments
/// @param x3   # of used segments
/// @return x0  the mavh
_linear_set_mavh:
#define STACK_SPACE     64
#define MEM_SZ          x19
#define MAV_SZ          x20
#define NUM_FREE        x21
#define NUM_USED        x22
#define result          x23
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]

    mov     MEM_SZ,     x0
    mov     MAV_SZ,     x1
    mov     NUM_FREE,   x2
    mov     NUM_USED,   x3

    // build mavh value to store in memory
    mov     result, xzr

    // get power of 2 of memory size and put it in top 6 bits
    mov     x0, MEM_SZ
    bl      mem_size_index
    add     result, result, x0, lsl 58

    // get power of 2 of mav size and put it in the following 6 bits
    mov     x0, MAV_SZ
    bl      mem_size_index
    add     result, result, x0, lsl 52

    // put number of free segments in position 26
    mov     x0, NUM_FREE
    add     result, result, x0, lsl 26

    // number of used segments go in to the bottom
    add     x0, result, NUM_USED

    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef MEM_SZ
#undef MAV_SZ
#undef NUM_FREE
#undef NUM_USED
#undef result

.text
/// return the components of MAVH
/// @param x0   mavh
/// @return x0  memory size in bytes
/// @return x1  MAV size in bytes
/// @return x2  number of free segments
/// @return x3  number of used segments
_linear_dissect_mavh:
#define STACK_SPACE     64
#define MAVH            x19
#define MEM_SZ          x20
#define MAV_SZ          x21
#define NUM_FREE        x22
#define NUM_USED        x23
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]

    mov     MAVH, x0

    mov     x0, MAVH
    bl      _linear_get_memory_size
    mov     MEM_SZ, x0

    mov     x0, MAVH
    bl      _linear_get_mav_size
    mov     MAV_SZ, x0

    mov     x0, MAVH
    bl      _linear_get_number_of_free_segment_headers
    mov     NUM_FREE, x0

    mov     x0, MAVH
    bl      _linear_get_number_of_used_segment_headers
    mov     NUM_USED, x0

    mov     x0, MEM_SZ
    mov     x1, MAV_SZ
    mov     x2, NUM_FREE
    mov     x3, NUM_USED

    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef MAVH
#undef MEM_SZ
#undef MAV_SZ
#undef NUM_FREE
#undef NUM_USED

.text
/// return the components of a MSH
/// @param x0   msh
/// @return x0  offset in bytes
/// @return x1  size in bytes
_linear_dissect_msh:
#define STACK_SPACE     48
#define MSH             x19
#define OFFSET          x20
#define SIZE            x21
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]

    mov     MSH, x0

    mov     x0, MSH
    bl      _linear_block_offset
    mov     OFFSET, x0

    mov     x0, MSH
    bl      _linear_block_size
    mov     SIZE, x0

    mov     x0, OFFSET
    mov     x1, SIZE

    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef MSH
#undef OFFSET
#undef SIZE

////////////////////////////////////////////////////////////////////////////////////////////////////
// memory segments header functions ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

.text
/// return a segment header
/// @param x0   block offset
/// @param x1   block size
/// @return x0  the segment header
_linear_set_msh:
    lsr     x0, x0, 3           // devide offset by 8 (cleaning 3 lower bits)
    lsl     x0, x0, 32          // shift to upper word
    lsl     x1, x1, 29          // shift left to clean everything above bit 34
    lsr     x1, x1, 32          // shift right dividing by 8
    add     x0, x0, x1          // add size divided by 8

    ret

/// reduce the amount of free space in MSH
/// @param x0   the MSH
/// @param x1   the ammount to reduce
/// @return x0  the MSH in its new state
_linear_reduce_free_space:
#define STACK_SPACE     64
#define MSH             x19
#define ALLOC_SZ        x20
#define OFFSET          x21
#define SIZE            x22
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]

    mov     MSH, x0
    mov     ALLOC_SZ, x1

    bl      _linear_dissect_msh
    mov     OFFSET, x0
    mov     SIZE, x1

    mov     x0, OFFSET
    sub     x1, SIZE, ALLOC_SZ  // new size
    bl      _linear_set_msh

    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef MSH
#undef ALLOC_SZ
#undef OFFSET
#undef SIZE

.text
/// return the offset of the block to which the segment header refers to
/// @param x0   the memory segment header
/// @return x0  the offset of the block
_linear_block_offset:
    lsr     x0, x0, 32  // upper word
    lsl     x0, x0, 3   // multiply by 8

    ret

.text
/// return the size of the block to which the segment header refers to
/// @param x0   the memory segment header
/// @return x0  the size of the block
_linear_block_size:
    and     x0, x0, 0xffffffff // lower word
    lsl     x0, x0, 3   // multiply by 8

    ret

/// find a free segment that can fit the new memory
/// @param x0   mavh
/// @param x1   pmem
/// @param x2   the size of memory to allocate
/// @return x0  pointer to MSH of free block
/// @return x0  0 - if there are no segment with enough free space
_linear_find_free_msh:
#define STACK_SPACE     64
#define MAVH            x19
#define PMEM            x20
#define ALLOC_SZ        x21
#define pmsh_f          x22
#define counter         x23
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]

    mov     MAVH, x0
    mov     PMEM, x1
    mov     ALLOC_SZ, x2

    mov     x0, MAVH
    bl      _linear_dissect_mavh
    add     pmsh_f, PMEM, x0        // initially, pmsh_f == pmav_f = pmem + mem_sz
    mov     counter, x2             // number of free segments

    ._linear_find_free_msh.loop.search.free.memory:
    cbz     counter, ._linear_find_free_msh.not.enough.memory
    ldr     x0, [pmsh_f]                // load MSH into x0 to get free size
    bl      _linear_block_size
    cmp     x0, ALLOC_SZ                // compare free memory with alloc size
    b.hs    ._linear_find_free_msh.loop.end
    sub     counter, counter, 1
    add     pmsh_f, pmsh_f, 8
    b       ._linear_find_free_msh.loop.search.free.memory
    ._linear_find_free_msh.loop.end:

    mov     x0, pmsh_f
    b       ._linear_find_free_msh.return

    ._linear_find_free_msh.not.enough.memory:
    mov     x0, xzr
    b       ._linear_find_free_msh.return

    ._linear_find_free_msh.return:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef MAVH
#undef PMEM
#undef ALLOC_SZ
#undef pmsh_f
#undef counter

/// find a used segment that is pointed to by ptr
/// @param x0   mavh
/// @param x1   pmem
/// @param x2   ptr
/// @return x0  pointer to MSH of free block
/// @return x0  0 - if there are no segment with enough free space
_linear_find_used_msh:
#define STACK_SPACE     64
#define MAVH            x19
#define PMEM            x20
#define PTR             x21
#define OFFSET          x22
#define pmsh_u          x23
#define counter         x24
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]

    mov     MAVH, x0
    mov     PMEM, x1
    mov     PTR, x2
    sub     OFFSET, PTR, PMEM

    cmp     PTR, PMEM
    b.lo    ._linear_find_used_msh.msh_not_found

    mov     x0, MAVH
    bl      _linear_dissect_mavh
    cmp     OFFSET, x0              // compare offset to memory size
    b.hs    ._linear_find_used_msh.msh_not_found
    add     pmsh_u, PMEM, x0        // initially, pmsh_u == pmem + mem_sz + mav_sz
    add     pmsh_u, pmsh_u, x1
    mov     counter, x3             // number of used segments

    ._linear_find_used_msh.loop_search_used_memory:
    cbz     counter, ._linear_find_used_msh.msh_not_found
    ldr     x0, [pmsh_u, -8]            // load MSH into x0 to get free size
    bl      _linear_block_offset
    cmp     x0, OFFSET                  // compare free memory with alloc size
    b.eq    ._linear_find_used_msh.loop_search_end
    b.hs    ._linear_find_used_msh.msh_not_found
    sub     counter, counter, 1
    sub     pmsh_u, pmsh_u, 8
    b       ._linear_find_used_msh.loop_search_used_memory
    ._linear_find_used_msh.loop_search_end:

    mov     x0, pmsh_u
    b       ._linear_find_used_msh.return

    ._linear_find_used_msh.msh_not_found:
    mov     x0, xzr
    b       ._linear_find_used_msh.return

    ._linear_find_used_msh.return:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef MAVH
#undef PMEM
#undef PTR
#undef OFFSET
#undef pmsh_u
#undef counter

/// return the pointer to the end of the MSH of the first available on MAV
/// @param x0   mavh
/// @param x1   pmem
/// @param x2   offset
/// @return x0  pointer to the point where the used MSH must be inserted
_linear_find_position_new_used_msh:
#define STACK_SPACE     64
#define MAVH            x19
#define PMEM            x20
#define OFFSET          x21
#define counter         x23
#define pmsh_u          x24
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]

    mov     MAVH, x0
    mov     PMEM, x1
    mov     OFFSET, x2

    mov     x0, MAVH
    bl      _linear_dissect_mavh
    add     x8, x0, x1              // full size = mem_sz + mav_sz
    add     pmsh_u, PMEM, x8        // pmsh_u == pmav_u = pmem + mem_sz + mav_sz
    mov     counter, x3

    _linear_find_position_new_used_msh.loop:
    cbz     counter, _linear_find_position_new_used_msh.loop.end
    ldr     x0, [pmsh_u, -8]
    bl      _linear_block_offset
    cmp     x0, OFFSET
    b.hi    _linear_find_position_new_used_msh.loop.end
    sub     pmsh_u, pmsh_u, 8
    sub     counter, counter, 1
    b       _linear_find_position_new_used_msh.loop
    _linear_find_position_new_used_msh.loop.end:
    mov     x0, pmsh_u

    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef MAVH
#undef PMEM
#undef OFFSET
#undef counter
#undef pmsh_u

/// return the index in MAV to insert MSH based on its offset
/// @param x0   mavh
/// @param x1   pmem
/// @param x2   offset
/// @return x0  the index of the position in MAV to insert the MSH
_linear_find_index_new_free_msh:
#define STACK_SPACE     80
#define MAVH            x19
#define PMEM            x20
#define OFFSET          x21
#define MAX_IDX         x23
#define idx             x24
#define pmsh_f          x25
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]
    stp     x25, x26, [sp, 64]

    mov     MAVH, x0
    mov     PMEM, x1
    mov     OFFSET, x2

    mov     x0, MAVH
    bl      _linear_dissect_mavh
    add     pmsh_f, PMEM, x0        // pmsh_f = pmem + mem_sz
    mov     MAX_IDX, x2             // # of free segment headers
    mov     idx, xzr

    _linear_find_position_new_free_segment.loop:
    cmp     idx, MAX_IDX
    b.hs    _linear_find_position_new_free_segment.loop.end
    ldr     x0, [pmsh_f]
    bl      _linear_block_offset
    cmp     x0, OFFSET
    b.hi    _linear_find_position_new_free_segment.loop.end
    add     pmsh_f, pmsh_f, 8
    add     idx, idx, 1
    b       _linear_find_position_new_free_segment.loop
    _linear_find_position_new_free_segment.loop.end:
    mov     x0, idx

    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x25, x26, [sp, 64]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef MAVH
#undef PMEM
#undef OFFSET
#undef MAX_IDX
#undef idx
#undef pmsh_f

/// If MAV has no more space for a new SH, it will double in size
/// @param x0   mavh
/// @param x1   pmem
/// @return x0  the new MAVH
/// @return x0  0 if in error
_linear_expand_mav_if_necessary:
#define STACK_SPACE     96
#define MAVH0           x19
#define PMEM            x20
#define PMAV_U          x21
#define MEM_SZ          x22
#define MAV_SZ          x23
#define NUM_FREE        x24
#define NUM_USED        x25
#define NEW_MAV_SZ      x26
#define NEW_PMAV_U      x27
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]
    stp     x25, x26, [sp, 64]
    stp     x27, x28, [sp, 80]

    mov     MAVH0, x0
    mov     PMEM, x1

    mov     x0, MAVH0
    bl      _linear_dissect_mavh
    mov     MEM_SZ, x0
    mov     MAV_SZ, x1
    mov     NUM_FREE, x2
    mov     NUM_USED, x3
    add     x8, MEM_SZ, MAV_SZ  // full_sz
    add     PMAV_U, PMEM, x8    // pmav_u = pmem + full_sz

    add     x8, NUM_FREE, NUM_USED  // tot = f + u
    lsl     x8, x8, 3               // multiply tot by 8 to get size
    cmp     x8, MAV_SZ
    b.hs    _linear_expand_mav_if_necessary.necessary

    mov     x0, MAVH0
    b       _linear_expand_mav_if_necessary.return

    _linear_expand_mav_if_necessary.necessary:
    lsl     NEW_MAV_SZ, MAV_SZ, 1       // new_mav_sz = mav_sz * 2
    add     NEW_PMAV_U, PMAV_U, MAV_SZ

    // request more memory
    sub     x0, NEW_PMAV_U, PMEM
    bl      mem_reserve
    cbnz    x0, _linear_expand_mav_if_necessary.return  // no memory

    _linear_expand_mav_if_necessary.already.allocated:
    // copy used HS to end of MAV
    sub     x0, PMAV_U, NUM_USED, lsl 3
    lsl     x1, NUM_USED, 3
    sub     x2, NEW_PMAV_U, NUM_USED, lsl 3
    bl      mem_copy_n

    // adjust mavh
    mov     x0, MEM_SZ
    mov     x1, NEW_MAV_SZ
    mov     x2, NUM_FREE
    mov     x3, NUM_USED
    bl      _linear_set_mavh            // new mavh is in x0

    _linear_expand_mav_if_necessary.return:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x25, x26, [sp, 64]
    ldp     x27, x28, [sp, 80]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef MAVH0
#undef PMEM
#undef PMAV_U
#undef MEM_SZ
#undef MAV_SZ
#undef NUM_FREE
#undef NUM_USED
#undef NEW_MAV_SZ
#undef NEW_PMAV_U

/// insert new free segment header into MAV (joining if necessary)
/// @param x0   mavh
/// @param x1   pmem
/// @param x2   MSH to insert
/// @return x0  new mavh
/// @return x0  0 if in error
_linear_insert_free_msh:
#define STACK_SPACE     96
#define mavh            x19
#define PMEM            x20
#define MSH             x21
#define offset          x22
#define size            x23
#define IDX             x24
#define num_free        x25
#define PMAV_F          x26
#define pmsh            x27
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]
    stp     x25, x26, [sp, 64]
    stp     x27, x28, [sp, 80]

    mov     mavh, x0
    mov     PMEM, x1
    mov     MSH, x2

    // find position to insert MSH
    mov     x0, MSH
    bl      _linear_dissect_msh
    mov     offset, x0
    mov     size, x1

    // save info from mavh
    mov     x0, mavh
    bl      _linear_dissect_mavh
    add     PMAV_F, PMEM, x0
    mov     num_free, x2        // this will be changed (probably)

    mov     x0, mavh
    mov     x1, PMEM
    mov     x2, offset
    bl      _linear_find_index_new_free_msh
    mov     IDX, x0     // index to insert new segment

    cmp     IDX, num_free
    b.hs    ._linear_insert_free_msh.not_adjoint_ahead
    add     pmsh, PMAV_F, IDX, lsl 3
    ldr     x0, [pmsh]          // load MSH at idx
    bl      _linear_dissect_msh
    add     x9, offset, size    // position of end of MSH
    cmp     x0, x9
    b.ne    ._linear_insert_free_msh.not_adjoint_ahead
    add     size, size, x1      // add size of msh at idx to size of MSH
    mov     x0, mavh
    mov     x1, PMEM
    mov     x2, pmsh
    bl      _linear_remove_free_msh
    mov     mavh, x0            // save new mavh
    sub     num_free, num_free, 1

    ._linear_insert_free_msh.not_adjoint_ahead:

    cbz     IDX, ._linear_insert_free_msh.not_adjoint_behind
    sub     x9, IDX, 1
    add     pmsh, PMAV_F, x9, lsl 3
    ldr     x0, [pmsh]          // load msh behind idx
    bl      _linear_dissect_msh
    add     x9, x0, x1          // end of ms at behind idx
    cmp     x9, offset          // check if matches MSH
    b.ne    ._linear_insert_free_msh.not_adjoint_behind
    add     size, size, x1      // increment size with size of ms behind
    mov     offset, x0          // get offset of ms behind
    mov     x0, offset
    mov     x1, size
    bl      _linear_set_msh
    str     x0, [pmsh]

    // mavh does not change for adjoining behind
    mov     x0, mavh
    b       ._linear_insert_free_msh.return

    ._linear_insert_free_msh.not_adjoint_behind:
    // create space for new msh
    add     pmsh, PMAV_F, IDX, lsl 3
    mov     x0, pmsh
    add     x1, PMAV_F, num_free, lsl 3
    add     x2, x1, 8
    bl      mem_copy_backward
    // store new msh
    mov     x0, offset
    mov     x1, size
    bl      _linear_set_msh
    str     x0, [pmsh]

    add     num_free, num_free, 1

    // update mavh
    mov     x0, mavh
    bl      _linear_dissect_mavh
    mov     x2, num_free
    bl      _linear_set_mavh
    // new mavh is in x0

    ._linear_insert_free_msh.return:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x25, x26, [sp, 64]
    ldp     x27, x28, [sp, 80]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef mavh
#undef PMEM
#undef MSH
#undef offset
#undef size
#undef IDX
#undef num_free
#undef PMAV_F
#undef pmsh

/// insert new used segment header into MAV
/// @param x0   mavh
/// @param x1   pmem
/// @param x2   msh to insert
/// @return x0  new MAVH
/// @return x0  0 if in error
_linear_insert_used_msh:
#define STACK_SPACE     96
#define MAVH0           x19
#define PMEM            x20
#define MSH             x21
#define PMSH            x22
#define LAST_PMAV_U     x23
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]
    stp     x25, x26, [sp, 64]
    stp     x27, x28, [sp, 80]

    mov     MAVH0, x0
    mov     PMEM, x1
    mov     MSH, x2

    // find position to insert MSH
    mov     x0, MSH
    bl      _linear_block_offset

    mov     x2, x0      // offset
    mov     x0, MAVH0
    mov     x1, PMEM
    bl      _linear_find_position_new_used_msh
    cbz     x0, ._linear_insert_used_msh.return // could not find the place
    mov     PMSH, x0    // save position

    // compute address of last (lower address) used segment header
    mov     x0, MAVH0
    bl      _linear_dissect_mavh

    add     LAST_PMAV_U, x0, x1                 // full size
    add     LAST_PMAV_U, LAST_PMAV_U, PMEM      // pmav_u --> pmem + full size
    sub     LAST_PMAV_U, LAST_PMAV_U, x3, lsl 3 // last_pmav_h = pmav_u - (# used * 8)

    // copy all bytes between last_pmav_u and pmsh to open space for pmsh
    mov     x0, LAST_PMAV_U         // begin of src range
    mov     x1, PMSH                // end of src range
    sub     x2, LAST_PMAV_U, 8      // begin of dst range
    bl      mem_copy

    str     MSH, [PMSH, -8]

    mov     x0, MAVH0
    bl      _linear_dissect_mavh
    add     x3, x3, 1               // increase number of used segments
    bl      _linear_set_mavh

    ._linear_insert_used_msh.return:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x25, x26, [sp, 64]
    ldp     x27, x28, [sp, 80]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef MAVH0
#undef PMEM
#undef MSH
#undef PMSH
#undef LAST_PMAV_U

/// remove the free segment header pointed to by pmsh from MAV
/// @param x0   mavh
/// @param x1   pmem
/// @param x2   pmsh to remove
/// @return x0  new MAVH
/// @return x0  0 if in error
_linear_remove_free_msh:
#define STACK_SPACE     96
#define MAVH0           x19
#define PMEM            x20
#define PMSH            x21
#define PMAV_F          x22
#define END_PMSH        x23
#define MEM_SZ          x24
#define MAV_SZ          x25
#define NUM_FREE        x26
#define NUM_USED        x27
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]
    stp     x25, x26, [sp, 64]
    stp     x27, x28, [sp, 80]

    mov     MAVH0, x0
    mov     PMEM, x1
    mov     PMSH, x2

    mov     x0, MAVH0
    bl      _linear_dissect_mavh
    mov     MEM_SZ, x0
    mov     MAV_SZ, x1
    mov     NUM_FREE, x2
    mov     NUM_USED, x3

    add     PMAV_F, PMEM, MEM_SZ
    add     END_PMSH, PMAV_F, NUM_FREE, lsl 3

    add     x0, PMSH, 8
    mov     x1, END_PMSH
    mov     x2, PMSH
    bl      mem_copy

    mov     x0, MEM_SZ
    mov     x1, MAV_SZ
    sub     x2, NUM_FREE, 1
    mov     x3, NUM_USED
    bl      _linear_set_mavh

    ._linear_remove_free_msh.return:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x25, x26, [sp, 64]
    ldp     x27, x28, [sp, 80]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef MAVH0
#undef PMEM
#undef PMSH
#undef PMAV_F
#undef END_PMSH
#undef MEM_SZ
#undef MAV_SZ
#undef NUM_FREE
#undef NUM_USED

/// remove the used segment header pointed to by pmsh from MAV
/// @param x0   mavh
/// @param x1   pmem
/// @param x2   pmsh to remove (since it is used, it is the end of the msh)
/// @return x0  new MAVH
/// @return x0  0 if in error
_linear_remove_used_msh:
#define STACK_SPACE     96
#define MAVH0           x19
#define PMEM            x20
#define PMSH            x21
#define PMAV_U          x22
#define BEGIN_PMSH      x23
#define MEM_SZ          x24
#define MAV_SZ          x25
#define NUM_FREE        x26
#define NUM_USED        x27
    stp     x29, x30, [sp, -STACK_SPACE]!
    stp     x19, x20, [sp, 16]
    stp     x21, x22, [sp, 32]
    stp     x23, x24, [sp, 48]
    stp     x25, x26, [sp, 64]
    stp     x27, x28, [sp, 80]

    mov     MAVH0, x0
    mov     PMEM, x1
    sub     PMSH, x2, 8     // because x2 point to end of msh

    mov     x0, MAVH0
    bl      _linear_dissect_mavh
    mov     MEM_SZ, x0
    mov     MAV_SZ, x1
    mov     NUM_FREE, x2
    mov     NUM_USED, x3

    add     PMAV_U, PMEM, MEM_SZ
    add     PMAV_U, PMAV_U, MAV_SZ
    sub     BEGIN_PMSH, PMAV_U, NUM_USED, lsl 3

    mov     x0, BEGIN_PMSH
    mov     x1, PMSH
    add     x2, PMSH, 8
    bl      mem_copy_backward

    mov     x0, MEM_SZ
    mov     x1, MAV_SZ
    mov     x2, NUM_FREE
    sub     x3, NUM_USED, 1
    bl      _linear_set_mavh

    ._linear_remove_used_msh.return:
    ldp     x19, x20, [sp, 16]
    ldp     x21, x22, [sp, 32]
    ldp     x23, x24, [sp, 48]
    ldp     x25, x26, [sp, 64]
    ldp     x27, x28, [sp, 80]
    ldp     x29, x30, [sp], STACK_SPACE
    ret
#undef STACK_SPACE
#undef MAVH0
#undef PMEM
#undef PMSH
#undef PMAV_U
#undef BEGIN_PMSH
#undef MEM_SZ
#undef MAV_SZ
#undef NUM_FREE
#undef NUM_USED
