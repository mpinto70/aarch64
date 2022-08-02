#include "sorting/utils.h"

#include <gtest/gtest.h>

#include <array>
#include <vector>

namespace {

TEST(utilsTest, getrandom) {
    std::vector<uint8_t> buffer1(38, 0);
    std::vector<uint8_t> buffer2 = buffer1;

    EXPECT_EQ(_getrandom(buffer1.data(), buffer1.size()), buffer1.size());
    EXPECT_NE(buffer1, buffer2);
    for (size_t i = 0; i < 100; ++i) {
        EXPECT_EQ(_getrandom(buffer2.data(), buffer2.size()), buffer2.size());
        EXPECT_NE(buffer1, buffer2);
    }
}

TEST(utilsTest, getrandom_64) {
    uint64_t a = 0, b = 0;
    for (size_t i = 0; i < 10'000; ++i) {
        a = _getrandom_64();
        EXPECT_NE(a, b);
        b = a;
    }
}

TEST(utilsTest, getsemirandom_64) {
    uint64_t a = 0, b = 0;
    for (size_t i = 0; i < 10'000; ++i) {
        a = _getsemirandom_64();
        EXPECT_NE(a, b);
        b = a;
    }
}

void CheckGetRandomBetween(size_t MIN, size_t MAX) {
    ASSERT_LT(MIN, MAX) << MIN << " / " << MAX;
    std::vector<uint64_t> values(MAX, 0);
    const size_t NUM = (MAX - MIN) * 1000;
    for (size_t i = 0; i < NUM; ++i) {
        const auto value = _getrandom_between(MIN, MAX);
        ASSERT_GE(value, MIN) << i;
        ASSERT_LT(value, MAX) << i;
        ++values[value];
    }
    for (size_t i = 0; i < MIN; ++i) {
        EXPECT_EQ(values[i], 0) << i;
    }
    for (size_t i = MIN; i < MAX; ++i) {
        EXPECT_GT(values[i], 0) << i;
    }
}

TEST(utilsTest, getrandom_between) {
    CheckGetRandomBetween(100, 157);
    CheckGetRandomBetween(0, 12);
    CheckGetRandomBetween(0, 1);
    CheckGetRandomBetween(5, 6);
}

TEST(utilsTest, get_seeded_between) {
    EXPECT_EQ(_get_seeded_between(10, 20, 129), 19);
    constexpr uint64_t min0 = 30;
    constexpr uint64_t max0 = 43;
    constexpr uint64_t min1 = 150;
    constexpr uint64_t max1 = 279;
    for (uint64_t i = 0; i < 1500; ++i) {
        EXPECT_EQ(_get_seeded_between(min0, max0, i), min0 + (i % (max0 - min0)));
        EXPECT_EQ(_get_seeded_between(min1, max1, i), min1 + (i % (max1 - min1)));
    }
}

TEST(utilsTest, swap_numbers) {
    uint64_t a = 30, b = 67;

    _swap_numbers(&a, &b);
    EXPECT_EQ(a, 67);
    EXPECT_EQ(b, 30);
}
} // namespace
