#pragma once

#include "memory/utils.h"

#include <gtest/gtest.h>

#include <cstdint>
#include <limits>
#include <ostream>
#include <random>
#include <string>

namespace memory {
class Utils {
public:
    template <typename T>
    static T RandomValue(T min, T max) {
        std::uniform_int_distribution<T> distrib(min, max);
        return distrib(gen_);
    }

    template <typename T>
    static T RandomValue() {
        return RandomValue<T>(std::numeric_limits<T>::min(), std::numeric_limits<T>::max());
    }

    static std::string ToString(const std::vector<uint8_t>& buffer);
    static std::vector<uint8_t> RandomVector(size_t size);
    static std::vector<uint8_t> RandomVector(size_t size, uint8_t min, uint8_t max);
    static void Print(std::ostream& out, const uint8_t* pmem, size_t size);
    static void Print(const uint8_t* pmem, size_t size);

private:
    static std::mt19937 gen_;
};

class MemoryTestBase : public ::testing::Test {
public:
    void SetUp() override;
    void TearDown() override;

    uint8_t pool_[0x100'0000]; // 16 megs
};

}