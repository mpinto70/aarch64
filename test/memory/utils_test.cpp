#include "memory_test_utils.h"

#include "memory/utils.h"

#include <gtest/gtest.h>

#include <algorithm>
#include <cstdint>
#include <numeric>
#include <vector>

namespace memory {
namespace {

constexpr uint64_t NUM_BITS = 64;

class MemoryUtilsTest : public MemoryTestBase {};

TEST_F(MemoryUtilsTest, next_mult_power_of_2) {
    EXPECT_EQ(mem_next_mult_power_of_2(0, 0), 0); // this is wrong, but I don't care
    EXPECT_EQ(mem_next_mult_power_of_2(1, 0), 1);
    EXPECT_EQ(mem_next_mult_power_of_2(1, 1), 2);
    EXPECT_EQ(mem_next_mult_power_of_2(1, 2), 4);
    EXPECT_EQ(mem_next_mult_power_of_2(1, 3), 8);
    EXPECT_EQ(mem_next_mult_power_of_2(1, 4), 16);
    EXPECT_EQ(mem_next_mult_power_of_2(1, 5), 32);

    EXPECT_EQ(mem_next_mult_power_of_2(17, 2), 20);
    EXPECT_EQ(mem_next_mult_power_of_2(18, 2), 20);
    EXPECT_EQ(mem_next_mult_power_of_2(19, 2), 20);
    EXPECT_EQ(mem_next_mult_power_of_2(20, 2), 20);
    EXPECT_EQ(mem_next_mult_power_of_2(21, 2), 24);
    EXPECT_EQ(mem_next_mult_power_of_2(21, 3), 24);
    EXPECT_EQ(mem_next_mult_power_of_2(21, 4), 32);
    EXPECT_EQ(mem_next_mult_power_of_2(21, 5), 32);
    EXPECT_EQ(mem_next_mult_power_of_2(21, 6), 64);

    EXPECT_EQ(mem_next_mult_power_of_2(25, 3), 32);
    EXPECT_EQ(mem_next_mult_power_of_2(25, 0), 25);
}

TEST_F(MemoryUtilsTest, power_of_2_ceiling) {
    EXPECT_EQ(mem_power_of_2_ceiling(0), 1);
    EXPECT_EQ(mem_power_of_2_ceiling(1), 1);
    EXPECT_EQ(mem_power_of_2_ceiling(2), 2);
    EXPECT_EQ(mem_power_of_2_ceiling(3), 4);
    EXPECT_EQ(mem_power_of_2_ceiling(4), 4);
    EXPECT_EQ(mem_power_of_2_ceiling(5), 8);
    EXPECT_EQ(mem_power_of_2_ceiling(7), 8);
    EXPECT_EQ(mem_power_of_2_ceiling(8), 8);
    EXPECT_EQ(mem_power_of_2_ceiling(9), 16);
    EXPECT_EQ(mem_power_of_2_ceiling(10), 16);

    uint64_t expected = 0x08;
    constexpr uint64_t limit = uint64_t{ 1 } << (sizeof(uint64_t) * 8 - 1);
    while (true) {
        const auto value = expected;
        EXPECT_EQ(mem_power_of_2_ceiling(value - 2), expected);
        EXPECT_EQ(mem_power_of_2_ceiling(value - 1), expected);
        EXPECT_EQ(mem_power_of_2_ceiling(value - 0), expected);

        if (expected == limit) {
            break;
        }

        expected <<= 1;

        EXPECT_EQ(mem_power_of_2_ceiling(value + 1), expected);
        EXPECT_EQ(mem_power_of_2_ceiling(value + 2), expected);
    }
}

TEST_F(MemoryUtilsTest, power_of_2_floor) {
    EXPECT_EQ(mem_power_of_2_floor(0), 0);
    EXPECT_EQ(mem_power_of_2_floor(1), 1);
    EXPECT_EQ(mem_power_of_2_floor(2), 2);
    EXPECT_EQ(mem_power_of_2_floor(3), 2);
    EXPECT_EQ(mem_power_of_2_floor(4), 4);
    EXPECT_EQ(mem_power_of_2_floor(5), 4);
    EXPECT_EQ(mem_power_of_2_floor(7), 4);
    EXPECT_EQ(mem_power_of_2_floor(8), 8);
    EXPECT_EQ(mem_power_of_2_floor(9), 8);
    EXPECT_EQ(mem_power_of_2_floor(10), 8);
    EXPECT_EQ(mem_power_of_2_floor(15), 8);
    EXPECT_EQ(mem_power_of_2_floor(16), 16);
    EXPECT_EQ(mem_power_of_2_floor(31), 16);
    EXPECT_EQ(mem_power_of_2_floor(32), 32);
    EXPECT_EQ(mem_power_of_2_floor(63), 32);
    EXPECT_EQ(mem_power_of_2_floor(64), 64);
    EXPECT_EQ(mem_power_of_2_floor(127), 64);
    EXPECT_EQ(mem_power_of_2_floor(128), 128);
    EXPECT_EQ(mem_power_of_2_floor(255), 128);
    EXPECT_EQ(mem_power_of_2_floor(256), 256);
    EXPECT_EQ(mem_power_of_2_floor(0xffff), 0x8000);
    EXPECT_EQ(mem_power_of_2_floor(0x1'ffff), 0x1'0000);
    EXPECT_EQ(mem_power_of_2_floor(0x2'0000), 0x2'0000);
}

TEST_F(MemoryUtilsTest, size_index) {
    EXPECT_EQ(mem_size_index(0), 0);
    EXPECT_EQ(mem_size_index(1), 0);
    EXPECT_EQ(mem_size_index(2), 1);
    EXPECT_EQ(mem_size_index(3), 2);
    EXPECT_EQ(mem_size_index(4), 2);
    EXPECT_EQ(mem_size_index(5), 3);
    EXPECT_EQ(mem_size_index(7), 3);
    EXPECT_EQ(mem_size_index(8), 3);
    EXPECT_EQ(mem_size_index(9), 4);
    EXPECT_EQ(mem_size_index(10), 4);
    EXPECT_EQ(mem_size_index(16), 4);
    EXPECT_EQ(mem_size_index(17), 5);

    const uint64_t v = 1;
    for (uint64_t shift = 0; shift < NUM_BITS; ++shift) {
        EXPECT_EQ(mem_size_index(v << shift), shift);
    }
}

TEST_F(MemoryUtilsTest, fill_n) {
    std::vector<uint8_t> buffer(28, ' ');
    std::vector<uint8_t> expected = buffer;

    mem_fill_n(buffer.data(), buffer.size(), '-');
    std::fill(expected.begin(), expected.end(), '-');
    EXPECT_EQ(buffer, expected);

    mem_fill_n(&buffer[1], buffer.size() - 2, '+');
    std::fill(expected.begin() + 1, expected.begin() + expected.size() - 1, '+');
    EXPECT_EQ(buffer, expected);

    constexpr uint64_t min_size = 7'001;
    constexpr uint64_t max_size = 150'027;

    buffer.reserve(max_size);
    expected.reserve(max_size);

    for (size_t i = 0; i < 1'000; ++i) {
        const auto size = Utils::RandomValue<uint64_t>(min_size, max_size);
        buffer.resize(size);
        expected.resize(size);

        SCOPED_TRACE("for size " + std::to_string(size));
        std::fill(buffer.begin(), buffer.end(), '-');

        mem_fill_n(buffer.data(), buffer.size(), '.');
        std::fill(expected.begin(), expected.end(), '.');
        EXPECT_EQ(buffer, expected);

        // first and last bytes are left with '.' the others are filled with '+'
        mem_fill_n(&buffer[1], buffer.size() - 2, '+');
        std::fill(expected.begin() + 1, expected.begin() + expected.size() - 1, '+');
        EXPECT_EQ(buffer, expected);
    }
}

TEST_F(MemoryUtilsTest, fill) {
    std::vector<uint8_t> buffer(28, ' ');
    std::vector<uint8_t> expected = buffer;

    mem_fill(buffer.data(), buffer.data() + buffer.size(), '-');
    std::fill(expected.begin(), expected.end(), '-');
    EXPECT_EQ(buffer, expected);

    mem_fill(&buffer[1], buffer.data() + buffer.size() - 1, '+');
    std::fill(expected.begin() + 1, expected.begin() + expected.size() - 1, '+');
    EXPECT_EQ(buffer, expected);

    constexpr uint64_t min_size = 7'001;
    constexpr uint64_t max_size = 150'027;

    buffer.reserve(max_size);
    expected.reserve(max_size);

    for (size_t i = 0; i < 1'000; ++i) {
        const auto size = Utils::RandomValue<uint64_t>(min_size, max_size);
        buffer.resize(size);
        expected.resize(size);

        SCOPED_TRACE("for size " + std::to_string(size));
        std::fill(buffer.begin(), buffer.end(), '-');

        mem_fill(buffer.data(), buffer.data() + buffer.size(), '.');
        std::fill(expected.begin(), expected.end(), '.');
        EXPECT_EQ(buffer, expected);

        // first and last bytes are left with '.' the others are filled with '+'
        mem_fill(&buffer[1], buffer.data() + buffer.size() - 1, '+');
        std::fill(expected.begin() + 1, expected.begin() + expected.size() - 1, '+');
        EXPECT_EQ(buffer, expected);
    }
}

TEST_F(MemoryUtilsTest, copy) {
    const auto src = Utils::RandomVector(157, '!', '~');

    SCOPED_TRACE("source = " + Utils::ToString(src));

    std::vector<uint8_t> dst(src.size(), 'x');
    std::vector<uint8_t> expected = src;

    mem_copy(src.data(), src.data() + src.size(), dst.data());
    std::copy(src.begin(), src.end(), expected.begin());
    EXPECT_EQ(dst, expected);

    for (size_t s = 0; s < 10; ++s) {
        std::iota(dst.begin(), dst.end(), 'a');
        expected = dst;
        mem_copy(src.data(), src.data() + s, dst.data());
        std::copy_n(src.begin(), s, expected.begin());
        EXPECT_EQ(dst, expected);
        EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));

        std::iota(dst.begin(), dst.end(), 'b');
        expected = dst;
        mem_copy(src.data() + s, src.data() + src.size(), dst.data());
        std::copy(src.begin() + s, src.end(), expected.begin());
        EXPECT_EQ(dst, expected);
        EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));
    }
}

TEST_F(MemoryUtilsTest, copy_overlap) {
    std::vector<uint8_t> dst(250, ' ');
    std::iota(dst.begin(), dst.end(), 0x3e);
    auto expected = dst;

    mem_copy(dst.data() + 2, dst.data() + dst.size(), dst.data() + 1);
    std::copy(expected.begin() + 2, expected.end(), expected.begin() + 1);
    EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));

    mem_copy(dst.data() + 10, dst.data() + 40, dst.data() + 3);
    std::copy(expected.begin() + 10, expected.begin() + 40, expected.begin() + 3);
    EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));

    mem_copy(dst.data() + 35, dst.data() + dst.size(), dst.data() + 1);
    std::copy(expected.begin() + 35, expected.end(), expected.begin() + 1);
    EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));

    mem_copy(dst.data() + 35, dst.data() + 40, dst.data() + 1);
    std::copy(expected.begin() + 35, expected.begin() + 40, expected.begin() + 1);
    EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));

    mem_copy(dst.data() + 1, dst.data() + 7, dst.data() + 15);
    std::copy(expected.begin() + 1, expected.begin() + 7, expected.begin() + 15);
    EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));

    const std::vector<size_t> offsets = { 0, 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 31, 32, 33 };
    const std::vector<size_t> gaps = { 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 31, 32, 33 };
    const std::vector<size_t> sizes = { 1,  2,  3,  4,  5,  7,  8,  9,   15,  16,
                                        17, 31, 32, 33, 63, 64, 65, 127, 128, 129 };

    for (auto offset_dst : offsets) {
        for (auto gap : gaps) {
            for (auto size : sizes) {
                SCOPED_TRACE(
                      "offset = " + std::to_string(offset_dst) + " / gap = " + std::to_string(gap)
                      + " / size = " + std::to_string(size));
                std::iota(dst.begin(), dst.end(), ' ');
                expected = dst;
                auto offset_src = offset_dst + gap;
                auto end_src = offset_src + size;
                mem_copy(dst.data() + offset_src, dst.data() + end_src, dst.data() + offset_dst);
                std::copy(
                      expected.begin() + offset_src,
                      expected.begin() + end_src,
                      expected.begin() + offset_dst);
                EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));
            }
        }
    }
}

TEST_F(MemoryUtilsTest, copy_random) {
    constexpr uint64_t min_size = 7'001;
    constexpr uint64_t max_size = 150'027;

    for (size_t i = 0; i < 20; ++i) {
        const auto size = Utils::RandomValue<uint64_t>(min_size, max_size);
        const auto src = Utils::RandomVector(size, 'a', 'z');
        auto dst = Utils::RandomVector(size, 'A', 'Z');
        auto expected = dst;

        mem_copy(src.data(), src.data() + src.size(), dst.data());
        std::copy(src.begin(), src.end(), expected.begin());
        EXPECT_EQ(dst, expected);

        const auto space = Utils::RandomValue<size_t>(15, 170);
        dst = Utils::RandomVector(size, 'A', 'Z');
        expected = dst;

        mem_copy(src.data() + space, src.data() + src.size() - space, dst.data() + space);
        std::copy_n(src.begin() + space, src.size() - 2 * space, expected.begin() + space);
        EXPECT_EQ(dst, expected);
    }
}

TEST_F(MemoryUtilsTest, copy_n) {
    const auto src = Utils::RandomVector(57, '!', '~');
    SCOPED_TRACE("source = " + Utils::ToString(src));
    std::vector<uint8_t> dst(src.size(), 'x');
    std::vector<uint8_t> expected = src;

    mem_copy_n(src.data(), src.size(), dst.data());
    std::copy_n(src.begin(), src.size(), expected.begin());
    EXPECT_EQ(dst, expected);

    for (size_t s = 0; s < 10; ++s) {
        std::iota(dst.begin(), dst.end(), 'a');
        expected = dst;
        mem_copy_n(src.data(), s, dst.data());
        std::copy_n(src.begin(), s, expected.begin());
        EXPECT_EQ(dst, expected);
        EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));

        std::iota(dst.begin(), dst.end(), 'b');
        expected = dst;
        mem_copy_n(src.data() + s, src.size() - s, dst.data());
        std::copy(src.begin() + s, src.end(), expected.begin());
        EXPECT_EQ(dst, expected);
        EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));
    }
}

TEST_F(MemoryUtilsTest, copy_n_random) {
    constexpr uint64_t min_size = 7'001;
    constexpr uint64_t max_size = 150'027;

    for (size_t i = 0; i < 20; ++i) {
        const auto size = Utils::RandomValue<uint64_t>(min_size, max_size);
        const auto src = Utils::RandomVector(size, 'a', 'z');
        auto dst = Utils::RandomVector(size, 'A', 'Z');
        auto expected = dst;

        mem_copy_n(src.data(), src.size(), dst.data());
        std::copy_n(src.begin(), src.size(), expected.begin());
        EXPECT_EQ(dst, expected);

        const auto space = Utils::RandomValue<size_t>(15, 170);
        dst = Utils::RandomVector(size, 'A', 'Z');
        expected = dst;

        mem_copy_n(src.data() + space, src.size() - 2 * space, dst.data() + space);
        std::copy_n(src.begin() + space, src.size() - 2 * space, expected.begin() + space);
        EXPECT_EQ(dst, expected);
    }
}

TEST_F(MemoryUtilsTest, copy_backward) {
    const auto src = Utils::RandomVector(190, '!', '~');

    SCOPED_TRACE("source = " + Utils::ToString(src));

    std::vector<uint8_t> dst(src.size(), 'x');
    std::vector<uint8_t> expected = src;

    mem_copy_backward(src.data(), src.data() + src.size(), dst.data() + dst.size());
    std::copy_backward(src.begin(), src.end(), expected.end());
    EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));

    dst = expected = src;

    mem_copy_backward(src.data() + 33, src.data() + 162, dst.data() + dst.size());
    std::copy_backward(src.begin() + 33, src.begin() + 162, expected.end());
    EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));

    const std::vector<size_t> offsets = { 0, 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 31, 32, 33 };
    const std::vector<size_t> sizes = { 1,  2,  3,  4,  5,  7,  8,  9,   15,  16,
                                        17, 31, 32, 33, 63, 64, 65, 127, 128, 129 };

    for (auto offset : offsets) {
        for (auto size : sizes) {
            SCOPED_TRACE(
                  "offset = " + std::to_string(offset) + " / size = " + std::to_string(size));
            const auto end = offset + size;
            dst = expected = src;
            mem_copy_backward(src.data() + offset, src.data() + end, dst.data() + dst.size());
            std::copy_backward(src.begin() + offset, src.begin() + end, expected.end());
            EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));
        }
    }
}

TEST_F(MemoryUtilsTest, copy_backward_overlap) {
    auto dst = Utils::RandomVector(35, ' ', '~');
    std::vector<uint8_t> expected = dst;

    mem_copy_backward(dst.data(), dst.data() + 7, dst.data() + 13);
    std::copy_backward(expected.begin(), expected.begin() + 7, expected.begin() + 13);
    EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));

    dst.resize(220);

    const std::vector<size_t> offsets = { 0, 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 31, 32, 33 };
    const std::vector<size_t> gaps = { 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 31, 32, 33 };
    const std::vector<size_t> sizes = { 1,  2,  3,  4,  5,  7,  8,  9,   15,  16,
                                        17, 31, 32, 33, 63, 64, 65, 127, 128, 129 };

    for (auto offset_src : offsets) {
        for (auto gap : gaps) {
            for (auto size : sizes) {
                SCOPED_TRACE(
                      "offset = " + std::to_string(offset_src) + " / gap = " + std::to_string(gap)
                      + " / size = " + std::to_string(size));
                std::iota(dst.begin(), dst.end(), ' ');
                expected = dst;
                auto offset_dst = offset_src + size + gap;
                auto end_src = offset_src + size;
                mem_copy_backward(
                      dst.data() + offset_src,
                      dst.data() + end_src,
                      dst.data() + offset_dst);
                std::copy_backward(
                      expected.begin() + offset_src,
                      expected.begin() + end_src,
                      expected.begin() + offset_dst);
                EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));
            }
        }
    }
}

TEST_F(MemoryUtilsTest, copy_n_backward) {
    const auto src = Utils::RandomVector(190, '!', '~');

    SCOPED_TRACE("source = " + Utils::ToString(src));

    std::vector<uint8_t> dst(src.size(), 'x');
    std::vector<uint8_t> expected = src;

    mem_copy_n_backward(src.data(), src.size(), dst.data() + dst.size());
    std::copy_backward(src.begin(), src.end(), expected.end());
    EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));

    dst = expected = src;

    mem_copy_n_backward(src.data() + 33, 162 - 33, dst.data() + dst.size());
    std::copy_backward(src.begin() + 33, src.begin() + 162, expected.end());
    EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));

    const std::vector<size_t> offsets = { 0, 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 31, 32, 33 };
    const std::vector<size_t> sizes = { 1,  2,  3,  4,  5,  7,  8,  9,   15,  16,
                                        17, 31, 32, 33, 63, 64, 65, 127, 128, 129 };

    for (auto offset : offsets) {
        for (auto size : sizes) {
            SCOPED_TRACE(
                  "offset = " + std::to_string(offset) + " / size = " + std::to_string(size));
            const auto end = offset + size;
            dst = expected = src;
            mem_copy_n_backward(src.data() + offset, size, dst.data() + dst.size());
            std::copy_backward(src.begin() + offset, src.begin() + end, expected.end());
            EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));
        }
    }
}

TEST_F(MemoryUtilsTest, copy_n_backward_overlap) {
    auto dst = Utils::RandomVector(35, ' ', '~');
    std::vector<uint8_t> expected = dst;

    mem_copy_n_backward(dst.data(), 7, dst.data() + 13);
    std::copy_backward(expected.begin(), expected.begin() + 7, expected.begin() + 13);
    EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));

    dst.resize(220);

    const std::vector<size_t> offsets = { 0, 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 31, 32, 33 };
    const std::vector<size_t> gaps = { 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 31, 32, 33 };
    const std::vector<size_t> sizes = { 1,  2,  3,  4,  5,  7,  8,  9,   15,  16,
                                        17, 31, 32, 33, 63, 64, 65, 127, 128, 129 };

    for (auto offset_src : offsets) {
        for (auto gap : gaps) {
            for (auto size : sizes) {
                SCOPED_TRACE(
                      "offset = " + std::to_string(offset_src) + " / gap = " + std::to_string(gap)
                      + " / size = " + std::to_string(size));
                std::iota(dst.begin(), dst.end(), ' ');
                expected = dst;
                auto offset_dst = offset_src + size + gap;
                auto end_src = offset_src + size;
                mem_copy_n_backward(dst.data() + offset_src, size, dst.data() + offset_dst);
                std::copy_backward(
                      expected.begin() + offset_src,
                      expected.begin() + end_src,
                      expected.begin() + offset_dst);
                EXPECT_EQ(Utils::ToString(dst), Utils::ToString(expected));
            }
        }
    }
}

}
}
