#include "sorting/bubble.h"

#include <gtest/gtest.h>

#include <algorithm>
#include <numeric>
#include <random>
#include <vector>

namespace {

constexpr size_t NUM_ELEMENTS = 1'000;

TEST(bubbleTest, random) {
    std::vector<uint64_t> values(NUM_ELEMENTS, 0);
    std::iota(values.begin(), values.end(), 0);
    const auto verify = values; // sorted

    std::random_device rd;
    std::mt19937 g(rd());
    std::shuffle(values.begin(), values.end(), g);

    EXPECT_NE(verify, values);

    _bubble_sort(values.data(), values.data() + values.size());

    EXPECT_EQ(verify, values);
}

TEST(bubbleTest, ordered) {
    std::vector<uint64_t> values(NUM_ELEMENTS, 0);
    std::iota(values.begin(), values.end(), 0);
    const auto verify = values; // sorted

    _bubble_sort(values.data(), values.data() + values.size());

    EXPECT_EQ(verify, values);
}

TEST(bubbleTest, inverted) {
    std::vector<uint64_t> values(NUM_ELEMENTS, 0);
    std::iota(values.rbegin(), values.rend(), 0); // inverted
    auto verify = values;
    std::iota(verify.begin(), verify.end(), 0); // sorted

    EXPECT_NE(verify, values);

    _bubble_sort(values.data(), values.data() + values.size());

    EXPECT_EQ(verify, values);
}

TEST(bubbleTest, constant) {
    std::vector<uint64_t> values(NUM_ELEMENTS, 7);
    const auto verify = values;

    _bubble_sort(values.data(), values.data() + values.size());

    EXPECT_EQ(verify, values);
}
} // namespace
